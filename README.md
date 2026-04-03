# SportMatch (giao-luu)

Nền tảng kết nối **cầu lông** và **pickleball** — tìm đối / giao lưu, hiển thị tin trên bản đồ.

**Tài liệu cho AI và dev**: bắt đầu từ [AGENTS.md](AGENTS.md), sau đó [docs/PROJECT_CHARTER.md](docs/PROJECT_CHARTER.md) và [docs/TECH_STACK.md](docs/TECH_STACK.md).

## Yêu cầu môi trường (dev)

- Ruby (theo [.ruby-version](.ruby-version))
- PostgreSQL **có extension PostGIS**
- Node.js + Yarn hoặc npm (cho bundle map React khi ADR-001 được implement)
- Go 1.22+ (cho service scraper, thư mục `scraper/` khi được thêm)

## Cài đặt nhanh (Rails)

```bash
bin/setup
```

Cấu hình DB trong `config/database.yml`. Sau khi bật PostGIS, tạo DB và migration theo [docs/DATA_MODEL.md](docs/DATA_MODEL.md).

## Biến môi trường (gợi ý)

| Biến | Mô tả |
|------|--------|
| `DATABASE_URL` | Postgres + PostGIS |
| `GOOGLE_MAPS_API_KEY` | Maps JS / hoặc tách key server cho Geocoding |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` | Pipeline extract |
| `SCRAPER_HMAC_SECRET` | Ký request ingest Go → Rails |

Chi tiết: [docs/TECH_STACK.md](docs/TECH_STACK.md), [docs/API_CONTRACTS.md](docs/API_CONTRACTS.md).

## Chạy ứng dụng

```bash
bin/dev
```

## Kiểm tra

```bash
bin/ci
```

## License / compliance

Pipeline tự động từ Facebook có rủi ro ToS — đọc [docs/SCRAPER_AGENT.md](docs/SCRAPER_AGENT.md).
