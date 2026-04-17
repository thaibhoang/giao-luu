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

Stack dùng image Rails **target `development`** (đủ gem nhóm `:development`, khớp `RAILS_ENV=development` trong compose) và PostGIS 16. Service `web` map **http://localhost:3000** → cổng 80 trong container (Thruster + Puma).

Từ gốc repo:

```bash
docker compose build
docker compose up
```

Tuỳ chọn: `export RAILS_MASTER_KEY=...` trước khi `up` nếu cần giải mã `credentials` (không có `web/config/master.key` trong image). Xem [.env.example](.env.example).

**Lưu ý:** `docker compose` chỉ dùng **một** Postgres (primary). Chạy full Solid Cache/Queue/Cable như `production` trong `database.yml` không nằm trong luồng compose này.

**Build image production (Kamal / không compose),** mặc định stage cuối của [web/Dockerfile](web/Dockerfile):

```bash
docker build -f web/Dockerfile -t giao_luu_web web
```

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


# AGENTS.md — SportMatch (code name)

Tài liệu điểm vào cho con người và AI agent làm việc trong repo này. Đọc **theo thứ tự** trước khi sửa code.

## Cấu trúc monorepo

- **`web/`** — ứng dụng Rails 8 (lệnh `bin/rails`, `bin/dev`, `bin/setup` chạy trong thư mục này).
- **`scraper/`** — service Go (pipeline thu thập / LLM / ingest; hiện là stub có thể build/chạy).
- **`docs/`** — tài liệu dùng chung.
- **Docker Compose** — file `docker-compose.yml` ở gốc repo: PostGIS + image `web` + `scraper` (dev). Build Rails: context `./web`.

## Thứ tự đọc bắt buộc

1. [docs/PROJECT_CHARTER.md](docs/PROJECT_CHARTER.md) — mục tiêu, MVP, persona.
2. [docs/TECH_STACK.md](docs/TECH_STACK.md) — stack cứng; không đổi framework tự phát.
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — luồng dữ liệu, ranh giới Rails / Go / queue.
4. Theo vai trò:
   - Backend / DB: [docs/DATA_MODEL.md](docs/DATA_MODEL.md), [docs/API_CONTRACTS.md](docs/API_CONTRACTS.md)
   - Map / FE: [docs/MAPS_AND_COSTS.md](docs/MAPS_AND_COSTS.md), ADR map stack trong [docs/decisions/](docs/decisions/)
   - Scraper / LLM: [docs/SCRAPER_AGENT.md](docs/SCRAPER_AGENT.md), [docs/schemas/listing_extraction.schema.json](docs/schemas/listing_extraction.schema.json)
5. Quy tắc làm việc đầy đủ: [docs/agent-sop.md](docs/agent-sop.md)
6. PR / đóng góp: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## Tóm tắt sản phẩm (10 dòng)

- **SportMatch**: kết nối người chơi **cầu lông** và **pickleball** để giao lưu / tìm đối trình độ tương đương.
- **Nguồn tin**: người dùng đăng trực tiếp; pipeline tự động từ nội dung nhóm Facebook (kèm rủi ro ToS — xem SCRAPER_AGENT).
- **MVP**: hiển thị tin trên **bản đồ**, tìm theo **vị trí / bán kính**, hỗ trợ SEO cho trang tin.
- **Backend**: Ruby on Rails 8, PostgreSQL + **PostGIS** (`geography`), **không** thay Solid Queue cho job nền trừ khi có ADR mới.
- **Scraper**: Go (concurrency); extract cấu trúc qua LLM; geocode có cache.

## Stack cứng (không vi phạm)

| Thành phần | Công nghệ |
|------------|-----------|
| Web + API | Rails 8 |
| DB | PostgreSQL + PostGIS |
| Job nền | Solid Queue |
| Scraper | Go |
| Map | Google Maps Platform; FE theo ADR-001 |
| LLM | OpenAI hoặc Anthropic (extract JSON theo schema) |

## Out of scope mặc định (trừ khi charter/roadmap cập nhật)

- Thay thế PostGIS bằng DB không gian khác.
- Lưu trữ dữ liệu cá nhân nhạy cảm từ Facebook ngoài **link bài viết gốc** và metadata listing đã thỏa privacy policy.
- Bỏ qua cache geocoding khi tên địa điểm đã có trong DB.

---

## Khối copy — SOP rút gọn (đưa vào system prompt agent)

**Git & code**

- Branch: `feature/<tên-ngắn>`, `hotfix/<issue>`.
- Commit: [Conventional Commits](https://www.conventionalcommits.org/) — ví dụ `feat(api): add postgis index for listings`.
- Logic phức tạp: comment ngắn + type hints / kiểu rõ ràng theo ngôn ngữ.

**Dữ liệu không gian**

- Tọa độ lưu **POINT(longitude, latitude)**, SRID 4326, kiểu **`geography`** cho khoảng cách.
- Tìm kiếm bán kính dùng **mét** (ví dụ `ST_DWithin` trên geography).

**Giao diện & map**

- Icon tách biệt: cầu lông vs pickleball.
- Bản đồ: bật **clustering** khi mật độ marker cao.

**Privacy**

- Không persist PII Facebook (sđt, email user…) ngoài phạm vi đã mô tả trong tài liệu; `contact_info` ưu tiên link nguồn.

Chi tiết: [docs/agent-sop.md](docs/agent-sop.md).
