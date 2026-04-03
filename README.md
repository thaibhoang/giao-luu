# SportMatch (giao-luu)

Nền tảng kết nối **cầu lông** và **pickleball** — tìm đối / giao lưu, hiển thị tin trên bản đồ.

**Tài liệu cho AI và dev**: bắt đầu từ [AGENTS.md](AGENTS.md), sau đó [docs/PROJECT_CHARTER.md](docs/PROJECT_CHARTER.md) và [docs/TECH_STACK.md](docs/TECH_STACK.md).

## Cấu trúc repo

| Thư mục | Nội dung |
|---------|----------|
| `web/` | Rails 8 — web, API, PostGIS |
| `scraper/` | Go — scraper (stub; xem [docs/SCRAPER_AGENT.md](docs/SCRAPER_AGENT.md)) |
| `docs/` | Charter, kiến trúc, API, schema JSON |

## Yêu cầu môi trường (dev)

- Ruby (theo [web/.ruby-version](web/.ruby-version))
- PostgreSQL **có extension PostGIS** (hoặc chỉ dùng DB trong Docker Compose)
- Node.js + Yarn hoặc npm (cho bundle map React khi ADR-001 được implement)
- Go 1.22+ (cho `scraper/`)
- Docker / Docker Compose (tuỳ chọn, để chạy PostGIS + web + scraper cùng lúc)

## Docker Compose (PostGIS + Rails + scraper)

Từ gốc repo:

```bash
docker compose build
docker compose up
```

Ứng dụng Rails: **http://localhost:3000** (map cổng host `3000` → `80` trong container). Nếu cần giải mã `credentials`, đặt `RAILS_MASTER_KEY` trong môi trường hoặc file `.env` (xem [.env.example](.env.example)).

## Cài đặt nhanh (Rails, native)

```bash
cd web
bin/setup
```

Cấu hình DB trong `web/config/database.yml`. Sau khi bật PostGIS, tạo DB và migration theo [docs/DATA_MODEL.md](docs/DATA_MODEL.md).

## Biến môi trường (gợi ý)

| Biến | Mô tả |
|------|--------|
| `DATABASE_URL` | Postgres + PostGIS |
| `GOOGLE_MAPS_API_KEY` | Maps JS / hoặc tách key server cho Geocoding |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` | Pipeline extract |
| `SCRAPER_HMAC_SECRET` | Ký request ingest Go → Rails |
| `RAILS_INTERNAL_URL` | URL nội bộ tới Rails (scraper; trong compose đã gán `http://web:80`) |

Chi tiết: [docs/TECH_STACK.md](docs/TECH_STACK.md), [docs/API_CONTRACTS.md](docs/API_CONTRACTS.md).

## Chạy ứng dụng (Rails)

```bash
cd web
bin/dev
```

## Scraper (Go)

```bash
cd scraper
go test ./...
# hoặc
docker compose run --rm scraper
```

## Kiểm tra

```bash
cd web
bin/ci
```

## Triển khai (Kamal)

Chạy Kamal từ **`web/`** (`cd web && bin/kamal ...`) để build context đúng app Rails.

## License / compliance

Pipeline tự động từ Facebook có rủi ro ToS — đọc [docs/SCRAPER_AGENT.md](docs/SCRAPER_AGENT.md).
