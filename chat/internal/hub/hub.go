// Package hub quản lý WebSocket rooms và broadcast message tới tất cả client trong room.
package hub

import (
	"log"
	"sync"
)

// Client đại diện cho một WebSocket connection trong một room.
type Client struct {
	RoomID int64
	UserID int64
	Send   chan []byte // buffered channel để gửi message
}

// Hub quản lý tất cả client đang kết nối, nhóm theo roomID.
type Hub struct {
	mu      sync.RWMutex
	rooms   map[int64]map[*Client]struct{} // roomID → set of clients

	Register   chan *Client
	Unregister chan *Client
	Broadcast  chan Message
}

// Message là payload broadcast vào một room cụ thể.
type Message struct {
	RoomID  int64
	Payload []byte
}

// New khởi tạo Hub và trả về pointer.
func New() *Hub {
	return &Hub{
		rooms:      make(map[int64]map[*Client]struct{}),
		Register:   make(chan *Client, 64),
		Unregister: make(chan *Client, 64),
		Broadcast:  make(chan Message, 256),
	}
}

// Run là goroutine chính của Hub — phải chạy trong một goroutine riêng.
func (h *Hub) Run() {
	for {
		select {
		case c := <-h.Register:
			h.mu.Lock()
			if h.rooms[c.RoomID] == nil {
				h.rooms[c.RoomID] = make(map[*Client]struct{})
			}
			h.rooms[c.RoomID][c] = struct{}{}
			h.mu.Unlock()
			log.Printf("hub: user %d joined room %d (total in room: %d)", c.UserID, c.RoomID, h.roomSize(c.RoomID))

		case c := <-h.Unregister:
			h.mu.Lock()
			if clients, ok := h.rooms[c.RoomID]; ok {
				delete(clients, c)
				if len(clients) == 0 {
					delete(h.rooms, c.RoomID)
				}
			}
			h.mu.Unlock()
			close(c.Send)
			log.Printf("hub: user %d left room %d", c.UserID, c.RoomID)

		case msg := <-h.Broadcast:
			h.mu.RLock()
			clients := h.rooms[msg.RoomID]
			h.mu.RUnlock()
			for c := range clients {
				select {
				case c.Send <- msg.Payload:
				default:
					// client quá chậm — drop message, tránh block hub
					log.Printf("hub: dropping message for slow client user=%d room=%d", c.UserID, msg.RoomID)
				}
			}
		}
	}
}

func (h *Hub) roomSize(roomID int64) int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.rooms[roomID])
}
