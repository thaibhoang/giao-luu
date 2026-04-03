# Scraper Agent — SportMatch (Go + LLM)

Tài liệu cho agent triển khai pipeline **thu thập → trích xuất → geocode → ingest Rails**.

## [Scraper] Input

- **Text thô** từ bài đăng nhóm Facebook (hoặc nguồn tương tự), ví dụ:
  - *"Cần 2 nam 1 nữ vãng lai sân 583 Nguyễn Trãi, 19h-21h tối nay, trình trung bình yếu, phí 50k"*
- Metadata kèm theo khi có: `source_url`, thời điểm crawl.

## [Scraper] Output / validation

- LLM **chỉ** trả một JSON object khớp [listing_extraction.schema.json](schemas/listing_extraction.schema.json) (không gồm `schema_version`; Go gắn `schema_version` khi đóng gói ingest lên Rails).
- Go parse + **validate** bằng schema (vd. `github.com/santhosh-tekuri/jsonschema` hoặc generate struct + validator).
- Nếu parse/validate thất bại: log, dead-letter queue hoặc retry có giới hạn; không POST partial lên Rails.

## [LLM] Prompt contract (khuyến nghị)

1. Hệ thống: "You output a single JSON object matching the provided JSON Schema. No markdown fences."
2. User: nội dung text + ngày tham chiếu (để resolve "tối nay", "CN tuần sau") theo **Asia/Ho_Chi_Minh**, sau đó chuyển `start_time`/`end_time` sang **ISO 8601 UTC** trong output.
3. `sport`: suy luận từ ngữ cảnh; mặc định an toàn theo nhóm nguồn nếu được cấu hình.
4. `skill_level`: map cụm tiếng Việt sang enum:
   - "mới chơi", "sơ cấp" → `beginner`
   - "trung bình yếu", "yếu trung bình" → `beginner-intermediate`
   - "trung bình" → `intermediate`
   - "khá", "trên trung bình" → `intermediate-advanced`
   - "mạnh", "cao thủ" → `advanced`
5. `price_estimate`: số nguyên VND; nếu không rõ → `null`.
6. `contact_info`: ưu tiên URL bài viết gốc.

## [Scraper] Geocoding

1. Chuẩn hóa `location_query` từ `location_name` (+ optional thành phố từ config).
2. **Tra `geocoding_cache`** (qua API nội bộ Rails hoặc DB shared — tuỳ triển khai; MVP khuyến nghị **Rails là source of cache** qua endpoint nội bộ hoặc scraper chỉ gửi string và để Rails geocode + cache).
3. Nếu cache miss: gọi **Google Geocoding API**, lưu cache, rồi tiếp tục.
4. Nếu không tìm được địa chỉ cụ thể sau khi đã thử: vẫn có thể ingest với `geom` null và để Solid Queue job retry geocode — **nhưng** map feed có thể ẩn tin cho đến khi có `geom`; ghi rõ trong implement.

## [Scraper] Ingest Rails

- `POST /internal/v1/listings/import` với HMAC theo [API_CONTRACTS.md](API_CONTRACTS.md) và ADR-002.
- **Idempotent** theo `source_url`.

## [Scraper] Rate limit và bot behavior

- Sleep ngẫu nhiên trong khoảng cấu hình giữa các request tới Facebook (hoặc nguồn).
- Retry exponential backoff trên 429/5xx; giới hạn số lần.
- User-Agent và volume tuân chính sách nội bộ; **giả định rủi ro ToS** (xem dưới).

## [All] Privacy

- Không lưu PII nhạy cảm của người đăng Facebook ngoài **link gốc** và dữ liệu cần cho listing (môn, giờ, sân, mức, phí).
- `raw_text` gửi Rails: có thể bật/tắt theo môi trường; production có thể hash hoặc cắt bớt nếu policy yêu cầu.

## [All] Cảnh báo pháp lý / ToS (không phải tư vấn luật)

- **Tự động thu thập dữ liệu từ Facebook** thường xung đột với điều khoản sử dụng của Meta và có rủi ro pháp lý/khoá tài khoản.
- **Chiến lược sản phẩm**: coi **đăng tay + ingest có kiểm duyệt** hoặc **Graph API chính thức** (nếu đ applicable) là lộ trình giảm rủi ro; MVP **hybrid** được mô tả trong [PROJECT_CHARTER.md](PROJECT_CHARTER.md).

## Liên kết

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [MAPS_AND_COSTS.md](MAPS_AND_COSTS.md)
