# Contributing — SportMatch

## Trước khi mở PR

1. Đọc [AGENTS.md](../AGENTS.md) và tài liệu domain liên quan (API, DATA_MODEL, SCRAPER).
2. Đảm bảo thay đổi **không vi phạm** stack trong [TECH_STACK.md](TECH_STACK.md).

## Branch và commit

- Branch: `feature/<tên-ngắn>`, `hotfix/<issue>`.
- Commit: [Conventional Commits](https://www.conventionalcommits.org/).
  - `feat(map): add listing clusters`
  - `fix(api): correct st_dwithin radius meters`

## Checklist PR (người + agent)

- [ ] PostGIS: `geom` là `geography(Point,4326)`, bán kính tính bằng **mét**.
- [ ] Thay đổi JSON extract hoặc ingest: cập nhật [schemas/listing_extraction.schema.json](schemas/listing_extraction.schema.json) và [API_CONTRACTS.md](API_CONTRACTS.md) (+ bump `schema_version` ingest nếu breaking).
- [ ] Privacy: không thêm lưu PII Facebook ngoài chính sách trong [SCRAPER_AGENT.md](SCRAPER_AGENT.md).
- [ ] Map: clustering + icon riêng hai môn ([MAPS_AND_COSTS.md](MAPS_AND_COSTS.md)).
- [ ] Thay đổi kiến trúc: ADR mới trong [decisions/](decisions/).
- [ ] Thay đổi luồng nghiệp vụ (map, ingest, job): cập nhật [FLOWS_SEQUENCE.md](FLOWS_SEQUENCE.md).

## Test

- Khi đã có suite: trong `web/`, chạy `bin/ci` hoặc lệnh CI địa phương trước khi push.
- Thêm test cho truy vấn spatial nếu sửa scope map feed.
