# Agent SOPs — SportMatch

Quy chuẩn làm việc đầy đủ cho mọi agent tham gia dự án. Bản rút gọn nằm trong [AGENTS.md](../AGENTS.md).

## [All] Git và code

- **Branching**: `feature/<feature-name>`, `hotfix/<issue-name>`.
- **Commit message**: [Conventional Commits](https://www.conventionalcommits.org/) — `type(scope): description`.
  - Ví dụ: `feat(api): add postgis indexing for listings`, `fix(scraper): backoff on 429`.
- **Documentation trong code**: Hàm xử lý logic phức tạp phải có comment giải thích; Ruby dùng Sorbet/RBS nếu repo đã bật, hoặc YARD `@param` / `@return`; Go dùng comment godoc rõ kiểu và hợp đồng lỗi.

## [Backend] Dữ liệu không gian (PostGIS)

- Mọi tọa độ lưu dưới dạng **POINT(longitude, latitude)** trong cột **`geography(Point,4326)`** (hoặc tương đương kiểu geography).
- Phép tính bán kính, khoảng cách: dùng **đơn vị mét** (ví dụ `ST_DWithin(geom::geography, center::geography, radius_meters)`).
- Không đảo lon/lat; kiểm tra migration và fixture bằng một bản ghi test cố định (ví dụ điểm tại Hà Nội).

## [Frontend] Giao diện và UX

- **Icons**: Bộ icon riêng cho **cầu lông** (vợt cầu) và **pickleball** (vợt phẳng); không dùng chung một icon cho cả hai môn.
- **Map**: Bắt buộc **clustering** khi nhiều điểm trong viewport; chi tiết triển khai xem [MAPS_AND_COSTS.md](MAPS_AND_COSTS.md) và ADR-001.

## [Scraper] Hành vi và tuân thủ

- **Rate limit**: Luôn có backoff/ngẫu nhiên hóa nhẹ giữa request tới nguồn bên ngoài; log và retry có giới hạn.
- **Privacy**: Không lưu PII nhạy cảm của người đăng Facebook ngoài những gì charter cho phép; ưu tiên `source_url` làm `contact_info`.
- **Geocoding**: Tra cứu cache DB trước khi gọi Google Geocoding API.

## [Architect] Thay đổi stack

- Thay đổi database, job system, hoặc frontend map stack **phải** có ADR mới trong [docs/decisions/](decisions/) và cập nhật [TECH_STACK.md](TECH_STACK.md).
- Thay đổi luồng nghiệp vụ đáng kể (API công khai, ingest, map feed, job nền): cập nhật [FLOWS_SEQUENCE.md](FLOWS_SEQUENCE.md) cho đồng bộ sơ đồ.

