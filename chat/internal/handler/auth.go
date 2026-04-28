// Package handler xử lý auth token WebSocket từ query param.
// Token format (ADR-005): base64url(payload) + "." + hex(HMAC-SHA256)
// payload = "<user_id>.<room_id>.<expires_unix>"
package handler

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Claims chứa thông tin đã được verify từ token.
type Claims struct {
	UserID int64
	RoomID int64
}

var (
	ErrTokenInvalid = errors.New("auth: token invalid")
	ErrTokenExpired = errors.New("auth: token expired")
)

// VerifyToken parse và verify HMAC token theo ADR-005.
// secret là giá trị của CHAT_HMAC_SECRET.
func VerifyToken(token, secret string) (*Claims, error) {
	// Tách payload và signature
	idx := strings.LastIndex(token, ".")
	if idx < 0 {
		return nil, ErrTokenInvalid
	}
	encodedPayload := token[:idx]
	sigHex := token[idx+1:]

	// Decode payload
	payloadBytes, err := base64.RawURLEncoding.DecodeString(encodedPayload)
	if err != nil {
		return nil, fmt.Errorf("%w: base64 decode: %v", ErrTokenInvalid, err)
	}
	payload := string(payloadBytes)

	// Verify HMAC
	expectedSig := computeHMAC(secret, payload)
	if !hmac.Equal([]byte(sigHex), []byte(expectedSig)) {
		return nil, ErrTokenInvalid
	}

	// Parse payload: "<user_id>.<room_id>.<expires_unix>"
	parts := strings.Split(payload, ".")
	if len(parts) != 3 {
		return nil, ErrTokenInvalid
	}
	userID, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return nil, fmt.Errorf("%w: user_id: %v", ErrTokenInvalid, err)
	}
	roomID, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return nil, fmt.Errorf("%w: room_id: %v", ErrTokenInvalid, err)
	}
	expiresUnix, err := strconv.ParseInt(parts[2], 10, 64)
	if err != nil {
		return nil, fmt.Errorf("%w: expires: %v", ErrTokenInvalid, err)
	}

	// Kiểm tra TTL
	if time.Now().Unix() > expiresUnix {
		return nil, ErrTokenExpired
	}

	return &Claims{UserID: userID, RoomID: roomID}, nil
}

// GenerateToken tạo token (dùng trong test hoặc Rails side để tham khảo logic).
func GenerateToken(userID, roomID, expiresUnix int64, secret string) string {
	payload := fmt.Sprintf("%d.%d.%d", userID, roomID, expiresUnix)
	sig := computeHMAC(secret, payload)
	encoded := base64.RawURLEncoding.EncodeToString([]byte(payload))
	return encoded + "." + sig
}

func computeHMAC(secret, payload string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(payload))
	return hex.EncodeToString(mac.Sum(nil))
}
