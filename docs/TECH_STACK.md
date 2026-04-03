# Technical Stack & Standards — SportMatch

Tài liệu dành cho **Architect Agent** và mọi implementer. Không thêm framework thay thế mà không có ADR.

## Bảng stack

| Thành phần | Công nghệ quy định | Ghi chú |
|------------|-------------------|---------|
| Backend | **Ruby on Rails 8** | App hiện tại: Rails ~> 8.1, Solid Cache/Queue/Cable |
| Job nền | **Solid Queue** | Job enrich listing, retry geocode, v.v. — xem `config/queue.yml` |
| Database | **PostgreSQL + PostGIS** | Bắt buộc kiểu **`geography`** cho tọa độ (xem [DATA_MODEL.md](DATA_MODEL.md)) |
| Scraper | **Go** | Concurrency, HTTP client, validate JSON trước khi gửi Rails |
| Frontend web | **Rails** (Hotwire: Turbo + Stimulus) | SEO trang tin; trang map theo **ADR-001** |
| Map (UI) | **Google Maps Platform** | JavaScript API; clustering bắt buộc; thư viện React theo ADR-001 |
| LLM | **OpenAI / Anthropic API** | Chỉ output tuân [listing_extraction.schema.json](schemas/listing_extraction.schema.json) |

## Quyết định đã chốt

| ID | Nội dung | File |
|----|----------|------|
| ADR-001 | Trang bản đồ dùng **React** (Google Maps qua `@react-google-maps/api`) build bằng **`jsbundling-rails` + esbuild**; mount vào layout Rails | [decisions/001-map-frontend-react-esbuild.md](decisions/001-map-frontend-react-esbuild.md) |
| ADR-002 | Ingest scraper → Rails: **HMAC-signed JSON** qua HTTPS nội bộ; không public không auth | [decisions/002-scraper-to-rails-auth.md](decisions/002-scraper-to-rails-auth.md) |
| ADR-003 | Thời gian lưu DB: **UTC** (`timestamptz`); hiển thị theo timezone người dùng (mặc định `Asia/Ho_Chi_Minh`) | [decisions/003-timezone-storage.md](decisions/003-timezone-storage.md) |

## PostGIS trong Rails

- Kích hoạt extension `postgis` trong migration.
- Có thể dùng gem `activerecord-postgis-adapter` **hoặc** SQL/raw `ST_GeogFromText` tùy ADR bổ sung; cho đến khi có ADR mới, ưu tiên **một** cách nhất quán được ghi trong migration đầu tiên có `geography`.

## Môi trường và secrets

- `DATABASE_URL` trỏ Postgres có PostGIS.
- `GOOGLE_MAPS_API_KEY` (tách key server Geocoding vs browser Maps nếu được).
- `OPENAI_API_KEY` hoặc `ANTHROPIC_API_KEY` cho scraper/pipeline.
- `SCRAPER_HMAC_SECRET` (shared với Go) cho [API_CONTRACTS.md](API_CONTRACTS.md).

## Liên kết

- [ARCHITECTURE.md](ARCHITECTURE.md) — luồng hệ thống
- [agent-sop.md](agent-sop.md) — quy tắc spatial và UX
