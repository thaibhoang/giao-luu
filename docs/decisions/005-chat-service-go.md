# ADR-005: Chat Service Go — Kiến trúc & Tích hợp Rails

## Status

Accepted

## Context

Phase 3 yêu cầu tính năng chat realtime trong app để người dùng liên lạc trực tiếp mà không cần rời sang Zalo/Messenger. Yêu cầu kỹ thuật:

- Kết nối realtime, độ trễ thấp giữa browser và server.
- Mỗi listing có 1 phòng chat (chat room) riêng.
- Rails giữ quyền kiểm soát authentication và notification — không duplicate logic.
- Message phải được lưu lại (persistent) để user mới join vẫn đọc được lịch sử.
- Service chat phải **độc lập hoàn toàn** với `scraper/` — nằm tại `chat/`, module Go riêng.

## Decision

### 1. Protocol: WebSocket (`gorilla/websocket`)

Browser kết nối trực tiếp tới Go Chat Service qua WebSocket (`ws://chat:8081/ws?room=<listing_id>&token=<signed_token>`). Go dùng thư viện `gorilla/websocket` để quản lý long-lived connection và broadcast message trong room.

**Lý do chọn WebSocket thay vì Server-Sent Events (SSE):**
- Chat cần bidirectional — cả nhận lẫn gửi message trên cùng connection.
- SSE chỉ server → client; nếu dùng SSE phải thêm REST endpoint riêng để gửi → phức tạp hơn mà không có lợi ích rõ ràng.

### 2. Auth: Rails ký token, Go verify bằng HMAC

**Luồng:**

```
Browser                     Rails                          Go Chat
   |                           |                              |
   |-- GET /listings/:id/chat_token -->                       |
   |                           |-- sign token (HMAC-SHA256) ->|
   |<-- { token, expires_in } -|                              |
   |                                                          |
   |-- WebSocket ws://chat:8081/ws?token=<token>&room=<id> -->|
   |                           |                   verify token|
   |<======= WebSocket open ===============================-->|
```

**Cấu trúc token** (HMAC-SHA256, không dùng JWT để tránh thêm dependency):

```
payload  = "<user_id>.<listing_id>.<expires_unix>"
signature = HMAC-SHA256(CHAT_HMAC_SECRET, payload)
token    = base64url(payload) + "." + hex(signature)
```

- TTL: **15 phút** — đủ để browser connect ngay sau khi nhận token.
- Go verify: decode payload → kiểm tra `expires_unix` → recompute HMAC → so sánh constant-time.
- Secret dùng chung: `CHAT_HMAC_SECRET` (biến môi trường, tách biệt với `SCRAPER_HMAC_SECRET`).

**Lý do không dùng JWT:**
- Tránh thêm dependency `golang-jwt` vào Go và `jwt` gem vào Rails chỉ cho một use case nhỏ.
- Pattern HMAC đã được thiết lập trong ADR-002 — nhất quán, team đã quen.

### 3. Message Storage: PostgreSQL (cùng DB)

Hai bảng mới trong DB chính (PostGIS):

**`chat_rooms`**
| Cột | Kiểu | Ghi chú |
|-----|------|---------|
| `id` | `bigserial` PK | |
| `listing_id` | `bigint` FK | UNIQUE — 1 room per listing |
| `created_at` | `timestamptz` | |

**`messages`**
| Cột | Kiểu | Ghi chú |
|-----|------|---------|
| `id` | `bigserial` PK | |
| `chat_room_id` | `bigint` FK | |
| `user_id` | `bigint` FK | Người gửi |
| `body` | `text` | Max 2000 ký tự — validate ở Go trước khi insert |
| `created_at` | `timestamptz` | |

Index: `index_messages_on_chat_room_id_and_created_at` (composite, dùng cho load history).

Go kết nối DB qua `pgx/v5` driver. Rails quản lý migration — Go chỉ đọc/ghi, không tự migrate.

**Lý do không tách DB riêng:** Đủ đơn giản cho MVP; tận dụng PostGIS instance đã có; tách DB khi thực sự cần scale (ghi lại trong roadmap V4).

### 4. Chat Room: 1 room per listing, tạo lazy

- `chat_rooms` có ràng buộc `UNIQUE (listing_id)`.
- Rails tạo room trong `ChatRoomsController` khi user đầu tiên mở trang chat (upsert).
- Go không tự tạo room — chỉ accept connection nếu `room_id` tồn tại trong DB.

### 5. Rails ↔ Go: HTTP Webhook + HMAC (không dùng gRPC)

Khi Go nhận message mới và đã persist thành công, Go gọi webhook về Rails để trigger notification:

```
POST /internal/chat_events
Headers:
  X-SportMatch-Timestamp: <unix_epoch_giây>
  X-SportMatch-Signature: <hmac-sha256-hex>
Body (JSON):
  {
    "event": "new_message",
    "chat_room_id": 123,
    "listing_id": 456,
    "sender_user_id": 789,
    "message_id": 1011
  }
```

Rails verify bằng cùng cơ chế ADR-002 (timestamp window 300s + HMAC body). Sau khi verify, Rails enqueue `ChatNotificationJob` vào Solid Queue.

**Lý do chọn HTTP Webhook thay vì gRPC:**
- Rails (Puma/Thruster) là HTTP server — mount thêm gRPC server sẽ thêm port, phức tạp Dockerfile và compose.
- Không có gRPC infrastructure nào trong project; thêm `.proto` + codegen là overhead không cần thiết cho MVP.
- Pattern HTTP + HMAC đã có ở ADR-002 (scraper → Rails) — tái dùng, không phải học thêm.
- Fire-and-forget webhook đủ cho use case: Go không cần response từ Rails để tiếp tục.
- Có thể thêm retry đơn giản phía Go (exponential backoff) nếu Rails tạm thời down.

## Cấu trúc thư mục `chat/`

```
chat/
  cmd/
    chat/
      main.go          # HTTP server, graceful shutdown, env config
  internal/
    hub/
      hub.go           # map[roomID][]Client, broadcast goroutine, register/unregister
    handler/
      ws.go            # WebSocket upgrade, read/write pump
      auth.go          # Verify HMAC token từ query param
    store/
      store.go         # Insert message, get history (pgx/v5)
    notify/
      webhook.go       # POST /internal/chat_events về Rails (HMAC signed)
  go.mod               # module github.com/thaibhoang/giao-luu/chat
  Dockerfile
```

## Biến môi trường

| Biến | Bên dùng | Mô tả |
|------|----------|-------|
| `CHAT_HMAC_SECRET` | Rails + Go | Ký/verify auth token WebSocket |
| `CHAT_WEBHOOK_SECRET` | Rails + Go | Ký/verify webhook Go → Rails (có thể dùng chung `CHAT_HMAC_SECRET`) |
| `CHAT_SERVICE_URL` | Rails | `http://chat:8081` trong compose |
| `RAILS_INTERNAL_URL` | Go | `http://web:80` trong compose |
| `DATABASE_URL` | Go | Cùng Postgres với Rails |

> **Lưu ý triển khai:** `CHAT_HMAC_SECRET` và `SCRAPER_HMAC_SECRET` là hai secret riêng biệt — xoay key độc lập.

## Alternatives Considered

| Phương án | Lý do từ chối |
|-----------|---------------|
| Rails Action Cable thay vì Go | Action Cable dùng Redis pub/sub; thêm dependency; Go tốt hơn cho long-lived WS connections ở scale; quyết định dùng Go đã trong charter |
| gRPC cho Go → Rails | Không có gRPC infra trong project; overhead codegen; Rails không native-friendly; HTTP webhook đủ dùng |
| Redis pub/sub giữa Go ↔ Rails | Thêm service Redis; over-engineering cho MVP — dùng trực tiếp HTTP webhook đơn giản hơn |
| Tách DB riêng cho chat | Chưa cần; PostGIS DB đủ tải cho MVP; ghi chú scale path trong roadmap V4 |
| JWT cho auth token | Tránh thêm dependency; pattern HMAC đã có ở ADR-002 |

## Consequences

- Go chat service chạy tại port `8081` — thêm service `chat` vào `docker-compose.yml`.
- Rails cần 2 endpoint mới: `GET /listings/:id/chat_token` và `POST /internal/chat_events`.
- Migration `create_chat_rooms` + `create_messages` chạy trong Rails (`db/migrate/`).
- Cập nhật `docs/DATA_MODEL.md` và `docs/API_CONTRACTS.md` song song với migration.
- Cần thêm `CHAT_HMAC_SECRET` vào `.env.example` và tài liệu `TECH_STACK.md`.

## Links

- [ADR-002 — Scraper → Rails auth (HMAC pattern)](002-scraper-to-rails-auth.md)
- [FEATURE_ROADMAP_V3.md — Section 2](../FEATURE_ROADMAP_V3.md)
- [API_CONTRACTS.md](../API_CONTRACTS.md)
- [DATA_MODEL.md](../DATA_MODEL.md)
