# Runbook Dev — SportMatch

## Khởi động local bằng Docker

1. Tạo `.env` từ `.env.example` và điền tối thiểu:
   - `RAILS_MASTER_KEY` (nếu dùng credentials)
   - `SCRAPER_HMAC_SECRET`
2. Chạy:
   - `docker compose up --build`
3. Trong service `web`, chạy migration/seed:
   - `bin/rails db:migrate`
   - `bin/rails db:seed`

## Kiểm tra nhanh endpoints chính

- Public listing page: `GET /listings`
- Listing SEO detail: `GET /listings/:id`
- Public map feed JSON: `GET /api/v1/listings/map?lat=10.8231&lng=106.6297&radius_meters=5000`
- Internal ingest endpoint: `POST /internal/v1/listings/import`

## Chạy scraper ingest thử

- Set env:
  - `RAILS_INTERNAL_URL=http://web:80`
  - `SCRAPER_HMAC_SECRET=<same-as-web>`
- Chạy `scraper`; service sẽ tạo payload mẫu và gửi về endpoint internal.

## Troubleshooting nhanh

- Lỗi PostGIS khi test/migrate:
  - Đảm bảo DB đang dùng image `postgis/postgis` hoặc server có cài extension PostGIS.
- Lỗi 401 ingest:
  - Kiểm tra `SCRAPER_HMAC_SECRET` đồng nhất giữa `web` và `scraper`.
- Không thấy marker map:
  - Kiểm tra có bản ghi `geom` khác `NULL`.
  - Kiểm tra query `lat/lng/radius_meters` và `GOOGLE_MAPS_API_KEY`.
