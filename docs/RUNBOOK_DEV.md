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
- Public map feed JSON: `GET /api/v1/listings/map`
- Internal ingest endpoint: `POST /internal/v1/listings/import`

## Kiểm tra nhanh tính năng map UI

- Home -> Map:
  - vào `GET /map` phải hiển thị map ngay lần đầu, không cần reload.
- Listing detail:
  - `GET /listings/:id` (listing có `geom`) phải hiển thị mini map.
  - nút `Mở trong bản đồ` điều hướng về `/map` và focus đúng listing.
- Bộ lọc map:
  - Nút vị trí hiện tại (`my_location`) phải pan map, **không** gọi lại feed.
  - Pan/zoom map không gọi lại feed.
  - Tìm kiếm theo tên listing lọc tức thời ở client, không gọi lại feed.
  - Đổi tab môn thể thao (`Tất cả/Cầu lông/Pickleball`) phải lọc đúng marker + danh sách ngay trên client.
  - Trên desktop: đổi `from/to` phải gọi lại feed với thời gian mới.
  - Trên mobile: không hiển thị bộ lọc thời gian.
  - Thanh ngang ở panel dưới map phải bấm được để ẩn/hiện danh sách, mở rộng vùng nhìn bản đồ.
  - Mở tab Network: vào `/map` chỉ có 1 request feed ban đầu; không phát sinh request feed thêm khi pan/zoom/gõ text.

## Lưu ý contract filter thời gian

- API `GET /api/v1/listings/map` trả `422` nếu:
  - `from` hoặc `to` không phải ISO8601.
  - `to < from`.
- Ví dụ hợp lệ:
  - `/api/v1/listings/map?from=2026-04-03T10:00:00Z&to=2026-04-03T14:00:00Z`

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
  - Kiểm tra `GOOGLE_MAPS_API_KEY`.
