# Feature Roadmap V3 — SportMatch

> Tạo: 2026-04-25
> Trạng thái: Lên kế hoạch
> Thời gian dự kiến: **~2 tháng** (từ 2026-04-28)
> Tiền đề: Phase 2 (V2) đã hoàn thành hoặc đang song song

---

## Tổng quan Phase 3

Phase 3 tập trung vào **3 trụ cột**:

| Trụ cột | Mục tiêu |
|---------|----------|
| 🔍 **SEO** | Tăng traffic organic bền vững qua search engine |
| 💬 **Chat** | Người dùng liên lạc trong app — không cần rời sang Zalo/Messenger |
| 🔔 **Smart Notifications** | Giữ người dùng quay lại thụ động, tăng retention |

---

## 1. SEO — Structured Data & On-page

### 1.1 JSON-LD (Schema.org `SportsEvent`) — **Ưu tiên #1**

Mỗi trang chi tiết listing (`/listings/:id`) nhúng JSON-LD để Google hiểu và hiển thị rich snippet.

**Schema mapping:**

| Schema.org field | Mapping từ `listings` |
|------------------|-----------------------|
| `@type` | `SportsEvent` |
| `name` | `title` |
| `description` | `body` |
| `sport` | `sport` (Badminton / Pickleball) |
| `startDate` | `start_at` (ISO 8601, timezone `Asia/Ho_Chi_Minh`) |
| `endDate` | `end_at` |
| `location` | `Place` → `name: location_name`, `geo: GeoCoordinates` |
| `organizer` | `user.email_address` (nếu có) |
| `url` | canonical URL của listing |

**Việc cần làm:**
- [ ] Tạo helper `structured_data_tag(listing)` trong `ListingsHelper` (trả về `<script type="application/ld+json">`)
- [ ] Nhúng helper vào `views/listings/show.html.erb` trong `<head>`
- [ ] Viết test: verify JSON-LD output hợp lệ với schema (model test hoặc helper test)

### 1.2 Dynamic Meta Tags

- [ ] Thêm `meta description` động: tóm tắt từ `title + location_name + start_at`
- [ ] Thêm `og:title`, `og:description`, `og:url` cho mỗi listing (Facebook / Zalo share preview)
- [ ] Thêm `og:image` — fallback về ảnh mặc định theo môn thể thao (`badminton.png` / `pickleball.png`)
- [ ] Cân nhắc `twitter:card` nếu cần

### 1.3 Sitemap XML

- [ ] Dùng gem `sitemap_generator` hoặc implement thủ công với Rails route `/sitemap.xml`
- [ ] Tự động include tất cả listing `upcoming` + public
- [ ] Tạo Solid Queue job tái generate sitemap khi có listing mới
- [ ] Submit URL sitemap trong `robots.txt`

### 1.4 Trang landing theo địa điểm *(sprint 2)*

Trang tĩnh + listing động cho SEO long-tail: `/cau-long/ho-chi-minh`, `/pickleball/ha-noi`, v.v.

- [ ] Tạo `LocationLandingController` + route `/[sport]/[city-slug]`
- [ ] Dữ liệu: query listing theo `sport` + `ST_DWithin` vùng thành phố (polygon hoặc radius lớn từ centroid)
- [ ] Content tĩnh nhúng vào layout: mô tả khu vực, tip chơi — tránh thin content
- [ ] Breadcrumb + canonical URL để tránh duplicate

### 1.5 Technical SEO

- [x] Canonical URL cho tất cả trang có filter/pagination
- [ ] `hreflang` nếu sau này hỗ trợ song ngữ (VI/EN) — *bỏ qua, chưa có kế hoạch đa ngôn ngữ*
- [x] Kiểm tra Core Web Vitals: tối ưu Largest Contentful Paint cho trang listing (ảnh, font)
- [x] `preload` Google Maps JS chỉ khi cần (tránh load trên trang không dùng map)

---

## 2. Chat Service (Go) — `chat/`

> **Quyết định kiến trúc**: Tạo service Go mới tại `chat/` — **độc lập hoàn toàn** với `scraper/`. Cần viết **ADR-005** trước khi implement.

### 2.0 ADR-005 — Chat Service Architecture

**Quyết định cần ghi lại trước khi code:**

| Điểm quyết định | Lựa chọn đề xuất | Lý do |
|----------------|-------------------|-------|
| Protocol | WebSocket (gorilla/websocket) | Long-lived connection, low latency; phù hợp chat realtime |
| Auth | Rails tạo **signed token** (JWT ngắn hạn), Go verify bằng shared HMAC secret | Không duplicate session logic; nhất quán với ADR-002 |
| Message storage | PostgreSQL (cùng DB domain) — bảng `messages` | Đơn giản, tận dụng PostGIS DB đã có; tách DB riêng khi scale |
| Chat room | 1 room per listing — tạo tự động khi user đầu tiên join | Phù hợp use case hiện tại |
| Rails ↔ Go | Go POST webhook `POST /internal/chat_events` về Rails (HTTP + HMAC, tương tự ADR-002) khi có tin nhắn mới (Solid Queue trigger notify) | Rails giữ quyền kiểm soát notification; HTTP webhook đủ dùng, tránh overhead gRPC |

- [x] Viết `docs/decisions/005-chat-service-go.md`

### 2.1 Data Model mới

**Bảng `chat_rooms`:**

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `listing_id` | `bigint` FK | Mỗi listing có 1 room |
| `created_at` | `timestamptz` | |

**Bảng `messages`:**

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `chat_room_id` | `bigint` FK | |
| `user_id` | `bigint` FK | Người gửi |
| `body` | `text` | Nội dung (max 2000 ký tự) |
| `created_at` | `timestamptz` | |

- [x] Migration: `create_chat_rooms`, `create_messages`
- [x] Index: `index_messages_on_chat_room_id_and_created_at`
- [x] Cập nhật `docs/DATA_MODEL.md`

### 2.2 Go Chat Service (`chat/`)

```
chat/
  cmd/
    chat/
      main.go        # HTTP server + WebSocket upgrade
  internal/
    hub/             # Chat hub: quản lý rooms + broadcast
    handler/         # WebSocket handler, auth middleware
    store/           # Persist message → PostgreSQL
    notify/          # Webhook POST về Rails khi có message mới
  go.mod
  Dockerfile
```

- [x] Khởi tạo `chat/go.mod` (module `github.com/thaibhoang/giao-luu/chat`)
- [x] Implement `Hub`: map `roomID → []client`, broadcast goroutine
- [x] Implement auth middleware: nhận `token` query param, verify HMAC với `CHAT_HMAC_SECRET`
- [x] Implement store: insert message vào PostgreSQL (`pgx` driver)
- [x] Implement notify: POST `POST /internal/chat_events` về Rails (signed, tương tự ADR-002)
- [x] Dockerfile cho `chat/` service
- [x] Thêm service `chat` vào `docker-compose.yml`

### 2.3 Rails side — Chat integration

- [x] Endpoint `GET /listings/:id/chat_token` — trả JWT ngắn hạn (15 phút) để Go verify
- [x] Controller `ChatRoomsController`: tạo room nếu chưa có, load history `messages`
- [x] View: embed chat UI trong trang chi tiết listing (Stimulus controller kết nối WebSocket Go)
- [x] Internal webhook `POST /internal/chat_events` — trigger Solid Queue job gửi notification

### 2.4 Chat UI (Rails + Stimulus)

- [x] Stimulus controller `chat_controller.js`: connect WS, append message, scroll to bottom
- [x] UI: panel chat bên dưới listing detail, hiển thị messages, input gửi
- [x] Giới hạn: chỉ user đã join listing (hoặc chủ listing) mới xem được chat room
- [x] Rate limiting phía Go: max 10 messages/phút/user

---

## 3. Smart Notification — Alert theo khu vực & điều kiện - Tạm thời bỏ qua vì tốn phí gửi mail

> Người dùng cài đặt trước bộ điều kiện → tự động nhận thông báo khi có listing mới khớp.

### 3.1 Data Model — `notification_subscriptions`

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `user_id` | `bigint` FK | Chủ subscription |
| `label` | `string` (optional) | Tên tự đặt, ví dụ "Cầu lông gần nhà" |
| `sport` | `string` | `badminton` \| `pickleball` \| `any` |
| `listing_type` | `string` | `match_finding` \| `court_pass` \| `tournament` \| `any` |
| `center_geom` | `geography(Point,4326)` | Tâm khu vực quan tâm |
| `radius_meters` | `integer` | Bán kính (mét); tối đa 50,000 (50km) |
| `skill_level_min` | `string` (nullable) | Lọc trình độ thấp nhất (cùng slug với `listings`) |
| `skill_level_max` | `string` (nullable) | Lọc trình độ cao nhất |
| `day_of_week` | `integer[]` (nullable) | 0=CN, 1=T2, …, 6=T7 — bỏ trống = tất cả ngày |
| `time_from` | `time` (nullable) | Giờ bắt đầu mong muốn (VD: 06:00) |
| `time_to` | `time` (nullable) | Giờ kết thúc mong muốn (VD: 08:00) |
| `notify_via` | `string[]` | `["email"]` — (web_push khi có PWA) |
| `active` | `boolean` | Bật/tắt nhanh |
| `last_notified_at` | `timestamptz` | Cooldown: không gửi trùng trong 1h |
| `created_at` / `updated_at` | `timestamptz` | |

- [ ] Migration: `create_notification_subscriptions`
- [ ] Index: GIST trên `center_geom`; B-tree trên `user_id`; partial index `WHERE active = true`
- [ ] Model validation: `radius_meters` ∈ [500, 50_000]; `time_from < time_to` nếu cả hai có giá trị
- [ ] Cập nhật `docs/DATA_MODEL.md`

### 3.2 Subscription UI

- [ ] Trang `/notifications/subscriptions` — danh sách subscriptions của user
- [ ] Form tạo/sửa subscription:
  - Chọn vị trí tâm: dùng Google Maps picker (click-on-map) hoặc nhập địa chỉ → geocode
  - Kéo slider bán kính (0.5km → 50km)
  - Checkbox môn thể thao, loại tin, ngày trong tuần
  - Picker giờ từ / đến
  - Toggle bật/tắt
- [ ] Giới hạn: tối đa **5 subscriptions/user** (tránh spam query)
- [ ] Cập nhật `config/routes.rb`: `resources :notification_subscriptions`

### 3.3 Matching & Dispatch (Solid Queue)

- [ ] **Job `MatchNotificationsJob`**: trigger sau khi listing mới được tạo thành công
  - Query: `SELECT ns.* FROM notification_subscriptions ns WHERE ns.active = true AND ST_DWithin(ns.center_geom, :listing_geom, ns.radius_meters)` → lọc tiếp theo `sport`, `listing_type`, `skill_level`, `day_of_week`, `time_from/to`
  - Cooldown check: `last_notified_at < 1.hour.ago`
  - Enqueue `SendNotificationJob` cho từng subscription khớp
- [ ] **Job `SendNotificationJob`**: gửi email (ActionMailer) với nội dung listing
  - Cập nhật `last_notified_at` sau khi gửi thành công
- [ ] **Mailer `NotificationMailer#new_listing_alert`**: email đẹp, có link listing, có link unsubscribe 1-click
- [ ] **Recurring job** (optional): re-scan daily lúc 7:00 SA cho listing upcoming hôm nay khớp subscription → nhắc lại nếu chưa từng notify cho listing đó

### 3.4 Unsubscribe & Quản lý

- [ ] Token unsubscribe 1-click trong email (không cần đăng nhập)
- [ ] Trang quản lý: bật/tắt, xóa subscription
- [ ] Tự động deactivate subscription nếu email bounce 3 lần (optional — ghi note để làm sau)

---

## 4. Tính năng bổ sung đề xuất

### 4.1 Thời tiết Realtime (Pickleball sân ngoài trời)

> Đã có trong `FEATURE_ROADMAP.md` — đưa vào Phase 3 vì liên quan đến notification.

- [ ] Tích hợp **Open-Meteo API** (miễn phí, không cần key)
- [ ] Job `WeatherCheckJob`: chạy trước `start_at` 3h và 1h — lấy forecast tại `geom` của listing
- [ ] Nếu xác suất mưa > 60%: hiển thị badge ⚠️ "Có thể mưa" trên listing card
- [ ] Cache kết quả trong Redis/Solid Cache (tránh gọi lại trong 30 phút)
- [ ] Không áp dụng cho listing `sport = badminton` (sân trong nhà)

### 4.2 Check-in & Điểm Uy tín *(từ V1 roadmap)*

> Bảng `reputation_events` đã có trong data model — implement logic.

- [ ] Sau `end_at`, người đã join listing nhận email/notification → "Bạn có đến giao lưu không?"
- [ ] Cả hai bên confirm → tạo `reputation_events` với `points_delta = +10`
- [ ] Hiển thị tổng điểm uy tín trên profile user (badge + số)
- [ ] Nếu listing bị hủy không báo trước: chủ listing bị trừ điểm (`points_delta = -5`)

### 4.3 Trang Profile Công khai

- [ ] `GET /users/:id` — hiển thị: ảnh đại diện (Gravatar fallback), điểm uy tín, lịch sử listing đã đăng, môn thể thao, trình độ
- [ ] SEO: meta tag đủ để Google index (tên người dùng + môn thể thao + thành phố)
- [ ] Liên kết từ listing detail → profile của chủ tin

---

## 5. Kiến trúc cập nhật — Sơ đồ luồng Phase 3

```
                    ┌─────────────────────────────────┐
                    │           Browser                │
                    │  (Rails HTML + Stimulus + React) │
                    └──────────┬──────────┬────────────┘
                               │          │ WebSocket
                    ┌──────────▼──┐   ┌───▼────────────┐
                    │  Rails 8    │   │  Go Chat Svc   │
                    │  Web + API  │◄──│  (chat/)       │
                    └──────┬──────┘   └────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐  ┌─────────┐  ┌──────────────┐
        │ PostGIS  │  │  Solid  │  │ Open-Meteo   │
        │    DB    │  │  Queue  │  │  (weather)   │
        └──────────┘  └────┬────┘  └──────────────┘
                           │
                  ┌─────────────────┐
                  │ ActionMailer    │
                  │ (notifications) │
                  └─────────────────┘
```

**Service mới trong `docker-compose.yml`:**
- `chat` — Go service, port 8081, env `CHAT_HMAC_SECRET`, `DATABASE_URL`

---

## 6. Thứ tự triển khai (Sprint Plan — 2 tháng)

### Sprint 1 (tuần 1–2): SEO Foundation

| # | Task | File/Module | Loại |
|---|------|-------------|------|
| 1 | JSON-LD helper + test | `app/helpers/listings_helper.rb` | sequential |
| 2 | Dynamic meta tags | `app/views/layouts/application.html.erb`, `views/listings/show` | sequential |
| 3 | og:image per sport | `app/assets/images/` | parallel |
| 4 | Sitemap XML + robots.txt | `config/routes.rb`, `SitemapController` | parallel |

### Sprint 2 (tuần 3–4): SEO Nâng cao + ADR-005

| # | Task | File/Module | Loại |
|---|------|-------------|------|
| 5 | Trang landing địa điểm | `LocationLandingController` | sequential |
| 6 | Canonical URL + pagination | layout + controllers | parallel |
| 7 | Viết ADR-005 (Chat arch) | `docs/decisions/005-chat-service-go.md` | sequential |
| 8 | Migration chat_rooms + messages | `db/migrate/` | sequential |

### Sprint 3 (tuần 5–6): Chat Service Go

| # | Task | File/Module | Loại |
|---|------|-------------|------|
| 9 | Scaffold `chat/` Go project | `chat/` | sequential |
| 10 | Hub + WebSocket handler | `chat/internal/hub/`, `handler/` | sequential |
| 11 | Store (PostgreSQL persist) | `chat/internal/store/` | sequential |
| 12 | Auth middleware (HMAC token) | `chat/internal/handler/` | sequential |
| 13 | Rails: chat token endpoint + ChatRoomsController | `app/controllers/` | parallel |
| 14 | Notify webhook Go → Rails | `chat/internal/notify/` | parallel |

### Sprint 4 (tuần 7–8): Notification Subscription + Polish

| # | Task | File/Module | Loại |
|---|------|-------------|------|
| 15 | Chat UI (Stimulus) | `app/javascript/controllers/chat_controller.js` | sequential |
| 16 | Migration notification_subscriptions | `db/migrate/` | sequential |
| 17 | SubscriptionsController + form UI | `app/controllers/`, `app/views/` | sequential |
| 18 | MatchNotificationsJob + SendNotificationJob | `app/jobs/` | sequential |
| 19 | NotificationMailer template | `app/mailers/`, `app/views/mailers/` | sequential |
| 20 | Thời tiết realtime (Open-Meteo) | `WeatherCheckJob`, listing view | parallel |
| 21 | Check-in uy tín MVP | `reputation_events`, mailer | parallel |
| 22 | Trang profile công khai | `UsersController#show` | parallel |

---

## 7. Biến môi trường mới cần thêm

| Biến | Service | Mô tả |
|------|---------|--------|
| `CHAT_HMAC_SECRET` | Rails + Go chat | Ký/verify auth token chat (tương tự `SCRAPER_HMAC_SECRET`) |
| `CHAT_SERVICE_URL` | Rails | URL nội bộ tới Go chat service (`http://chat:8081` trong compose) |

Cập nhật `.env.example` và `docs/TECH_STACK.md` khi implement.

---

## 8. ADR cần viết mới

| ID | Nội dung | Ưu tiên |
|----|----------|---------|
| ADR-005 | Chat service Go: protocol, auth, storage, Rails integration | Trước Sprint 3 |
| ADR-006 | Notification subscription: match algorithm, cooldown, rate limit | Trước Sprint 4 |

---

## 9. Ghi chú kỹ thuật

- **Chat service Go** nằm ở `chat/` — **không** sửa `scraper/`.
- Tất cả migration vẫn tuân quy tắc: **mỗi tính năng 1 migration riêng**.
- Bảng `notification_subscriptions` dùng GIST index trên `center_geom` — spatial query `ST_DWithin` để match listing mới.
- JSON-LD phải validate với [schema.org/SportsEvent](https://schema.org/SportsEvent) trước khi merge.
- Open-Meteo: không cần API key, giới hạn 10,000 calls/ngày free — đủ cho MVP.
- Cập nhật `docs/DATA_MODEL.md` và `docs/API_CONTRACTS.md` song song với từng migration.
- Viết test cho mọi Job (unit test với mock mailer) trước khi merge.

---

## 10. Trạng thái tổng thể

| Nhóm | Tính năng | Trạng thái |
|------|-----------|------------|
| SEO | JSON-LD + meta tags | `[ ]` |
| SEO | Sitemap XML | `[ ]` |
| SEO | Trang landing địa điểm | `[ ]` |
| SEO | Technical SEO (canonical, CWV) | `[x]` |
| Chat | ADR-005 | `[x]` |
| Chat | Go chat service | `[x]` |
| Chat | Rails integration + UI | `[x]` |
| Notification | Data model subscription | `[ ]` |
| Notification | UI cài đặt subscription | `[ ]` |
| Notification | Match + dispatch jobs | `[ ]` |
| Notification | Email template | `[ ]` |
| Bổ sung | Thời tiết realtime | `[ ]` |
| Bổ sung | Check-in uy tín | `[ ]` |
| Bổ sung | Profile công khai | `[ ]` |

---

*Liên kết liên quan: [FEATURE_ROADMAP_V2.md](FEATURE_ROADMAP_V2.md) · [DATA_MODEL.md](DATA_MODEL.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [API_CONTRACTS.md](API_CONTRACTS.md) · [decisions/](decisions/)*
