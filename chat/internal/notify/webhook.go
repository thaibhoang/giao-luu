// Package notify gửi webhook HTTP về Rails khi có message mới.
// Pattern HMAC theo ADR-002: header X-SportMatch-Timestamp + X-SportMatch-Signature.
package notify

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"
)

// ChatEvent là payload POST tới Rails /internal/chat_events.
type ChatEvent struct {
	Event        string `json:"event"`
	ChatRoomID   int64  `json:"chat_room_id"`
	ListingID    int64  `json:"listing_id"`
	SenderUserID int64  `json:"sender_user_id"`
	MessageID    int64  `json:"message_id"`
}

// Notifier gửi webhook về Rails.
type Notifier struct {
	railsURL   string // e.g. "http://web:80"
	hmacSecret string // CHAT_HMAC_SECRET (dùng chung với auth token, hoặc tách ra)
	client     *http.Client
}

// New khởi tạo Notifier.
func New(railsURL, hmacSecret string) *Notifier {
	return &Notifier{
		railsURL:   railsURL,
		hmacSecret: hmacSecret,
		client:     &http.Client{Timeout: 5 * time.Second},
	}
}

// SendNewMessage gửi event "new_message" về Rails, có retry đơn giản (3 lần).
func (n *Notifier) SendNewMessage(ctx context.Context, event ChatEvent) {
	event.Event = "new_message"
	body, err := json.Marshal(event)
	if err != nil {
		log.Printf("notify: marshal error: %v", err)
		return
	}

	url := n.railsURL + "/internal/chat_events"
	var lastErr error
	for attempt := 1; attempt <= 3; attempt++ {
		if err := n.post(ctx, url, body); err != nil {
			lastErr = err
			wait := time.Duration(attempt*attempt) * 200 * time.Millisecond
			log.Printf("notify: attempt %d failed: %v — retry in %s", attempt, err, wait)
			select {
			case <-ctx.Done():
				return
			case <-time.After(wait):
			}
			continue
		}
		return // thành công
	}
	// Fire-and-forget: log lỗi cuối, không crash service
	log.Printf("notify: all attempts failed for message_id=%d: %v", event.MessageID, lastErr)
}

func (n *Notifier) post(ctx context.Context, url string, body []byte) error {
	ts := strconv.FormatInt(time.Now().Unix(), 10)
	sig := computeHMAC(n.hmacSecret, ts, body)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-SportMatch-Timestamp", ts)
	req.Header.Set("X-SportMatch-Signature", sig)

	resp, err := n.client.Do(req)
	if err != nil {
		return fmt.Errorf("http: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("rails returned %d", resp.StatusCode)
	}
	return nil
}

// computeHMAC theo ADR-002: HMAC-SHA256(secret, timestamp + "." + body).
func computeHMAC(secret, timestamp string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(timestamp + "."))
	mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}
