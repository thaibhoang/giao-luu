# Data Model — SportMatch (PostGIS)

## [Backend] Quy ước không gian

- Cột geometry địa lý: **`geography(Point,4326)`** — lưu **POINT(longitude latitude)**.
- Mọi truy vấn bán kính dùng **mét** trên geography (ví dụ `ST_DWithin`).
- SRID: **4326** (WGS 84).

### SQL minh họa tạo điểm

```sql
ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography
```

### Index

- `CREATE INDEX index_listings_on_geom ON listings USING GIST (geom);`

### Truy vấn mẫu: listings trong bán kính (mét)

```sql
SELECT *
FROM listings
WHERE ST_DWithin(
  listings.geom,
  ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
  :radius_meters
);
```

## [Backend] Thực thể chính

### `listings`

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `sport` | `string` / `enum` | `badminton` \| `pickleball` |
| `title` | `string` | Tiêu đề hiển thị / SEO |
| `body` | `text` (optional) | Nội dung gốc hoặc mô tả |
| `location_name` | `string` | Tên sân / địa chỉ ngắn |
| `geom` | `geography(Point,4326)` | Vị trí bản đồ |
| `start_at` | `timestamptz` | Bắt đầu (UTC) |
| `end_at` | `timestamptz` | Kết thúc (UTC) |
| `slots_needed` | `integer` | Số slot / người cần |
| `skill_level` | `string` | Giá trị chuẩn hóa — xem schema LLM |
| `price_estimate` | `integer` (optional) | Ví dụ VND |
| `contact_info` | `string` | Ưu tiên URL bài FB hoặc hướng dẫn liên hệ an toàn |
| `source` | `string` | `user_submitted` \| `facebook_scrape` \| … |
| `source_url` | `string` (unique khi có) | URL canonical để idempotent ingest |
| `schema_version` | `integer` | Phiên bản payload extract (align với JSON schema) |
| `created_at` / `updated_at` | `timestamptz` | |

### `geocoding_cache` (hoặc tên tương đương)

Dùng để **giảm chi phí** Google Geocoding khi cùng `location_query` đã tra trước.

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `location_query` | `string` | Chuỗi chuẩn hóa (trim, lower locale-safe) — unique |
| `geom` | `geography(Point,4326)` | Kết quả |
| `provider` | `string` | `google` |
| `raw_response` | `jsonb` (optional) | Debug — có thể tắt trong production |
| `created_at` | `timestamptz` | |

### `reputation_events` (wildcard — roadmap)

Cho check-in uy tín; chi tiết acceptance: [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md).

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `user_id` | `bigint` (FK) | Nếu có tài khoản |
| `listing_id` | `bigint` (FK) | |
| `event_type` | `string` | `check_in_confirmed` / … |
| `points_delta` | `integer` | |
| `created_at` | `timestamptz` | |

## [Backend] Migration conventions

1. Migration đầu tiên có spatial: `enable_extension "postgis"`.
2. Không dùng `float` riêng lẻ thay cho `geom` cho truy vấn bản đồ — luôn có cột `geom` geography.
3. Seed dev: một listing test tại tọa độ cố định để kiểm tra map và `ST_DWithin`.

## Liên kết

- [schemas/listing_extraction.schema.json](schemas/listing_extraction.schema.json)
- [API_CONTRACTS.md](API_CONTRACTS.md)
