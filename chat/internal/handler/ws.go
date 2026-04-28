// Package handler xử lý WebSocket upgrade, read/write pump, và tích hợp hub + store + notify.
package handler

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/thaibhoang/giao-luu/chat/internal/hub"
	"github.com/thaibhoang/giao-luu/chat/internal/notify"
	"github.com/thaibhoang/giao-luu/chat/internal/store"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 4096

	// Rate limiting — token bucket per user per room
	rateLimitMax    = 10              // max messages per window
	rateLimitWindow = 1 * time.Minute // reset window
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Trong production cần kiểm tra Origin; tạm thời allow all để dev dễ test
	CheckOrigin: func(r *http.Request) bool { return true },
}

// incomingMsg là JSON message từ browser gửi lên.
type incomingMsg struct {
	Body string `json:"body"`
}

// outgoingMsg là JSON message broadcast xuống browser.
type outgoingMsg struct {
	MessageID int64     `json:"message_id"`
	UserID    int64     `json:"user_id"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"created_at"`
}

// rateLimitError gửi về browser khi vượt rate limit.
type rateLimitError struct {
	Error string `json:"error"`
}

// userRateKey định danh bucket theo (userID, roomID).
type userRateKey struct {
	UserID int64
	RoomID int64
}

// bucket đếm số message trong window hiện tại.
type bucket struct {
	count     int
	resetAt   time.Time
}

// WSHandler wraps các dependency cần thiết cho WebSocket handler.
type WSHandler struct {
	Hub      *hub.Hub
	Store    *store.Store
	Notifier *notify.Notifier
	Secret   string // CHAT_HMAC_SECRET

	rateMu      sync.Mutex
	rateBuckets map[userRateKey]*bucket
}

// NewWSHandler khởi tạo WSHandler với rate limiter.
func NewWSHandler(h *hub.Hub, s *store.Store, n *notify.Notifier, secret string) *WSHandler {
	return &WSHandler{
		Hub:         h,
		Store:       s,
		Notifier:    n,
		Secret:      secret,
		rateBuckets: make(map[userRateKey]*bucket),
	}
}

// checkRateLimit trả về true nếu user được phép gửi message (token bucket).
func (h *WSHandler) checkRateLimit(userID, roomID int64) bool {
	key := userRateKey{UserID: userID, RoomID: roomID}
	now := time.Now()

	h.rateMu.Lock()
	defer h.rateMu.Unlock()

	b, ok := h.rateBuckets[key]
	if !ok || now.After(b.resetAt) {
		h.rateBuckets[key] = &bucket{count: 1, resetAt: now.Add(rateLimitWindow)}
		return true
	}
	if b.count >= rateLimitMax {
		return false
	}
	b.count++
	return true
}

// ServeWS là HTTP handler cho endpoint GET /ws?room=<room_id>&token=<token>.
func (h *WSHandler) ServeWS(w http.ResponseWriter, r *http.Request) {
	// 1. Auth — verify HMAC token
	token := r.URL.Query().Get("token")
	claims, err := VerifyToken(token, h.Secret)
	if err != nil {
		log.Printf("ws: auth failed: %v", err)
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// 2. Kiểm tra room param khớp với token (defense-in-depth)
	roomParam := r.URL.Query().Get("room")
	roomID, err := strconv.ParseInt(roomParam, 10, 64)
	if err != nil || roomID != claims.RoomID {
		http.Error(w, "room mismatch", http.StatusBadRequest)
		return
	}

	// 3. Kiểm tra room tồn tại trong DB (Go không tự tạo room — ADR-005)
	exists, err := h.Store.RoomExists(r.Context(), claims.RoomID)
	if err != nil || !exists {
		http.Error(w, "room not found", http.StatusNotFound)
		return
	}

	// 4. Upgrade HTTP → WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("ws: upgrade failed: %v", err)
		return
	}

	client := &hub.Client{
		RoomID: claims.RoomID,
		UserID: claims.UserID,
		Send:   make(chan []byte, 256),
	}
	h.Hub.Register <- client

	// 5. Gửi lịch sử chat khi vừa kết nối
	go h.sendHistory(conn, claims.RoomID)

	// Read + Write pump chạy concurrent
	go h.writePump(conn, client)
	h.readPump(r.Context(), conn, client)
}

// readPump đọc message từ browser, persist, broadcast.
func (h *WSHandler) readPump(ctx context.Context, conn *websocket.Conn, c *hub.Client) {
	defer func() {
		h.Hub.Unregister <- c
		conn.Close()
	}()

	conn.SetReadLimit(maxMessageSize)
	conn.SetReadDeadline(time.Now().Add(pongWait))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, raw, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("ws: read error user=%d: %v", c.UserID, err)
			}
			break
		}

		var incoming incomingMsg
		if err := json.Unmarshal(raw, &incoming); err != nil || incoming.Body == "" {
			continue
		}

		// Rate limiting: max rateLimitMax messages per rateLimitWindow per user per room
		if !h.checkRateLimit(c.UserID, c.RoomID) {
			errMsg, _ := json.Marshal(rateLimitError{Error: "rate_limit"})
			_ = conn.WriteMessage(websocket.TextMessage, errMsg)
			continue
		}

		// Persist message
		msg, err := h.Store.InsertMessage(ctx, c.RoomID, c.UserID, incoming.Body)
		if err != nil {
			log.Printf("ws: store error: %v", err)
			continue
		}

		// Broadcast tới tất cả client trong room
		out, _ := json.Marshal(outgoingMsg{
			MessageID: msg.ID,
			UserID:    msg.UserID,
			Body:      msg.Body,
			CreatedAt: msg.CreatedAt,
		})
		h.Hub.Broadcast <- hub.Message{RoomID: c.RoomID, Payload: out}

		// Notify Rails qua webhook (async, fire-and-forget)
		go h.Notifier.SendNewMessage(ctx, notify.ChatEvent{
			ChatRoomID:   msg.ChatRoomID,
			SenderUserID: msg.UserID,
			MessageID:    msg.ID,
		})
	}
}

// writePump gửi message từ channel Send xuống WebSocket.
func (h *WSHandler) writePump(conn *websocket.Conn, c *hub.Client) {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.Send:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-ticker.C:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// sendHistory gửi lịch sử 50 message gần nhất ngay sau khi client kết nối.
func (h *WSHandler) sendHistory(conn *websocket.Conn, roomID int64) {
	msgs, err := h.Store.GetHistory(context.Background(), roomID, 50)
	if err != nil {
		log.Printf("ws: get history error: %v", err)
		return
	}
	for _, m := range msgs {
		out, _ := json.Marshal(outgoingMsg{
			MessageID: m.ID,
			UserID:    m.UserID,
			Body:      m.Body,
			CreatedAt: m.CreatedAt,
		})
		conn.SetWriteDeadline(time.Now().Add(writeWait))
		if err := conn.WriteMessage(websocket.TextMessage, out); err != nil {
			return
		}
	}
}
