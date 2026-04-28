// Package store persist messages vào PostgreSQL qua pgx/v5.
package store

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Message là bản ghi đã lưu trong bảng messages.
type Message struct {
	ID         int64
	ChatRoomID int64
	UserID     int64
	Body       string
	CreatedAt  time.Time
}

// Store wraps pgxpool và cung cấp các method đọc/ghi messages.
type Store struct {
	pool *pgxpool.Pool
}

// New khởi tạo Store với connection pool.
func New(pool *pgxpool.Pool) *Store {
	return &Store{pool: pool}
}

// InsertMessage lưu message mới và trả về bản ghi đầy đủ (kèm ID, created_at).
func (s *Store) InsertMessage(ctx context.Context, roomID, userID int64, body string) (*Message, error) {
	if len(body) > 2000 {
		return nil, fmt.Errorf("store: body exceeds 2000 characters")
	}
	const q = `
		INSERT INTO messages (chat_room_id, user_id, body, created_at)
		VALUES ($1, $2, $3, NOW())
		RETURNING id, chat_room_id, user_id, body, created_at`

	row := s.pool.QueryRow(ctx, q, roomID, userID, body)
	var m Message
	if err := row.Scan(&m.ID, &m.ChatRoomID, &m.UserID, &m.Body, &m.CreatedAt); err != nil {
		return nil, fmt.Errorf("store: insert message: %w", err)
	}
	return &m, nil
}

// GetHistory trả về tối đa limit messages gần nhất của room, sắp xếp cũ → mới.
func (s *Store) GetHistory(ctx context.Context, roomID int64, limit int) ([]Message, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	const q = `
		SELECT id, chat_room_id, user_id, body, created_at
		FROM messages
		WHERE chat_room_id = $1
		ORDER BY created_at DESC
		LIMIT $2`

	rows, err := s.pool.Query(ctx, q, roomID, limit)
	if err != nil {
		return nil, fmt.Errorf("store: get history: %w", err)
	}
	defer rows.Close()

	var msgs []Message
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.ChatRoomID, &m.UserID, &m.Body, &m.CreatedAt); err != nil {
			return nil, fmt.Errorf("store: scan message: %w", err)
		}
		msgs = append(msgs, m)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("store: rows error: %w", err)
	}

	// Đảo lại thành cũ → mới
	for i, j := 0, len(msgs)-1; i < j; i, j = i+1, j-1 {
		msgs[i], msgs[j] = msgs[j], msgs[i]
	}
	return msgs, nil
}

// RoomExists kiểm tra chat_room_id có tồn tại không.
// Go không tự tạo room — chỉ Rails mới upsert room (ADR-005).
func (s *Store) RoomExists(ctx context.Context, roomID int64) (bool, error) {
	const q = `SELECT 1 FROM chat_rooms WHERE id = $1 LIMIT 1`
	row := s.pool.QueryRow(ctx, q, roomID)
	var dummy int
	err := row.Scan(&dummy)
	if err != nil {
		// pgx trả về pgx.ErrNoRows khi không có row — không phải lỗi thực sự
		return false, nil
	}
	return true, nil
}
