# Maps & API costs — SportMatch

## [Frontend] Google Maps (browser)

- Dùng **Maps JavaScript API** với UI React theo [decisions/001-map-frontend-react-esbuild.md](decisions/001-map-frontend-react-esbuild.md).
- Thư viện: `@react-google-maps/api` — hiển thị marker, fit bounds, lazy load script.

## [Frontend] Clustering (bắt buộc)

- Khi mật độ marker cao trong viewport, bật **marker clustering** (ví dụ `@googlemaps/markerclusterer` hoặc API tương thích với React wrapper).
- Ngưỡng cụ thể có thể cấu hình; mặc định gợi ý: bật clustering khi > 20 marker trong bbox hiện tại.

## [Frontend] Icon theo môn

- **Cầu lông**: icon vợt cầu (SVG/PNG riêng).
- **Pickleball**: icon vợt phẳng — **không** tái sử dụng icon cầu lông.

## [Backend] Geocoding & cache (cost control)

- **Không** gọi lại Google Geocoding nếu `location_query` đã có trong `geocoding_cache` (xem [DATA_MODEL.md](DATA_MODEL.md)).
- Rails hoặc scraper phải chuẩn hóa query (trim, Unicode normalize NFC, có thể lower-case) trước khi tra cache.
- Theo dõi hit rate cache trong logging/metrics khi có.

## [All] API keys

- Tách key **server** (Geocoding) và key **browser** (Maps JS) khi khả thi; hạn chế referrer/domain trên key client.

## Liên kết

- [API_CONTRACTS.md](API_CONTRACTS.md) — map feed
- [SCRAPER_AGENT.md](SCRAPER_AGENT.md) — geocode pipeline
