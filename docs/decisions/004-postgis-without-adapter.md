# ADR-004: PostGIS trong Rails — migration SQL + `structure.sql`

## Status

Accepted

## Context

- Dự án dùng PostgreSQL + PostGIS với cột `geography(Point,4326)` ([DATA_MODEL.md](../DATA_MODEL.md)).
- Gem `activerecord-postgis-adapter` / RGeo có thể lệch phiên bản so với Rails 8.1.x tại thời điểm triển khai MVP.
- Dump `schema.rb` mặc định của Rails không mô tả đầy đủ kiểu PostGIS.

## Decision

- **Không** thêm gem PostGIS cho ActiveRecord trong giai đoạn MVP.
- Bật extension `postgis` trong migration; tạo cột `geography`, chỉ mục GIST, ràng buộc CHECK/partial unique bằng `execute` / `add_check_constraint` / `CREATE UNIQUE INDEX ... WHERE` trong migration.
- Đặt `config.active_record.schema_format = :sql` để dump schema ra **`db/structure.sql`** thay vì `schema.rb`, đảm bảo kiểu spatial và index được giữ nguyên.

## Consequences

- Model `Listing` có thể đọc/ghi `geom` qua SQL thô hoặc helper ứng dụng; không có type casting RGeo sẵn trong ActiveRecord.
- Dev cần chạy `db:schema:load` từ `structure.sql` hoặc `db:migrate`; không dùng `schema.rb` cho bảng chính.

## Links

- [DATA_MODEL.md](../DATA_MODEL.md)
- [TECH_STACK.md](../TECH_STACK.md)
