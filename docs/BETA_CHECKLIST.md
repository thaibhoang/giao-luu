# Beta Checklist — SportMatch

## Trước khi chạy beta nội bộ

- [ ] `docker compose up --build` chạy thành công `web`, `postgres`, `scraper`.
- [ ] `web` migrate xong với PostGIS (`enable_extension "postgis"` thành công).
- [ ] Chạy `bin/rails db:seed` có dữ liệu demo map/listing.
- [ ] Có `SCRAPER_HMAC_SECRET` ở cả `web` và `scraper`.
- [ ] Có API key cần thiết theo môi trường (`GOOGLE_MAPS_API_KEY`, `OPENAI_API_KEY` hoặc `ANTHROPIC_API_KEY`).

## Smoke test chức năng

- [ ] Truy cập `GET /listings` xem được danh sách công khai.
- [ ] Đăng nhập và tạo mới listing qua `GET/POST /listings`.
- [ ] Gọi `GET /api/v1/listings/map?lat=10.8231&lng=106.6297&radius_meters=5000` trả dữ liệu marker.
- [ ] Mở `GET /listings/:id` thấy meta SEO + JSON-LD.
- [ ] Chạy scraper và ingest thành công vào `POST /internal/v1/listings/import`.

## Quan sát vận hành cơ bản

- [ ] Không có lỗi 500 trong logs khi tạo listing/map feed/import.
- [ ] Không tạo bản ghi trùng khi ingest cùng `source_url`.
- [ ] Có thể kiểm tra nhanh tỷ lệ cache geocoding qua số bản ghi `geocoding_caches`.
