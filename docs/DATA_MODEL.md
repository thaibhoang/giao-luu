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
| `geom` | `geography(Point,4326)` nullable | Vị trí bản đồ (tin chưa geocode có `NULL`; map feed chỉ dùng bản ghi có geom) |
| `start_at` | `timestamptz` | Bắt đầu (UTC) |
| `end_at` | `timestamptz` | Kết thúc (UTC) |
| `slots_needed` | `integer` | Số slot / người cần |
| `skill_level_min` | `string` | Slug trình độ thấp nhất (CHECK DB) |
| `skill_level_max` | `string` | Slug trình độ cao nhất (CHECK DB; phải `>= skill_level_min`) |
| `user_id` | `bigint` FK → `users` (nullable) | Bắt buộc khi `source = user_submitted`; `NULL` với tin scrape / ingest nội bộ |
| `price_estimate` | `integer` (optional) | Ví dụ VND |
| `contact_info` | `string` | Ưu tiên URL bài FB hoặc hướng dẫn liên hệ an toàn |
| `source` | `string` | `user_submitted` \| `facebook_scrape` \| … |
| `source_url` | `string` (unique khi có) | URL canonical để idempotent ingest |
| `schema_version` | `integer` | Phiên bản payload extract (align với JSON schema) |
| `created_at` / `updated_at` | `timestamptz` | |

**Trình độ (`skill_level_min`/`skill_level_max`) — slug lưu DB / API (nhãn tiếng Việt cho UI trong `Listing::SKILL_LEVEL_LABELS`):**

| Slug | Nhãn gợi ý |
|------|------------|
| `yeu` | Yếu |
| `trung_binh_yeu` | Trung bình yếu |
| `trung_binh_minus` | Trung bình - |
| `trung_binh` | Trung bình |
| `trung_binh_plus` | Trung bình + |
| `trung_binh_plus_plus` | Trung bình ++ |
| `trung_binh_kha` | Trung bình khá |
| `kha` | Khá |
| `ban_chuyen` | Bán chuyên |
| `chuyen_nghiep` | Chuyên nghiệp |

### `users` (đăng nhập — Rails `has_secure_password`)

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `email_address` | `string` unique | Email đăng nhập (chuẩn hóa lowercase) |
| `password_digest` | `string` | BCrypt |
| `created_at` / `updated_at` | `timestamptz` | |

Phiên đăng nhập có thể dùng bảng `sessions` (cookie) theo generator Rails — xem migration `create_sessions`.

**Quy tắc sản phẩm**: xem tin / map **không** cần user; **đăng** tin (`user_submitted`) cần user — `listings.user_id` NOT NULL trong trường hợp đó (enforce ở model/controller).

### `geocoding_caches` (bảng Rails)

Tên bảng theo quy ước plural của ActiveRecord; model **`GeocodingCache`**. Dùng để **giảm chi phí** Google Geocoding khi cùng `location_query` đã tra trước.

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| `id` | `bigserial` | PK |
| `location_query` | `string` | Chuỗi chuẩn hóa (trim, lower locale-safe) — unique |
| `geom` | `geography(Point,4326)` NOT NULL | Kết quả |
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

## [Backend] Triển khai hiện tại (MVP schema)

- **PostGIS trong Rails (không dùng gem adapter)**: [ADR-004](decisions/004-postgis-without-adapter.md) — migration dùng SQL cho `geography`/GIST; `config.active_record.schema_format = :sql`; dump schema tại [`db/structure.sql`](../db/structure.sql).
- **Migration domain**: [`db/migrate/20260403034734_sportmatch_mvp_schema.rb`](../db/migrate/20260403034734_sportmatch_mvp_schema.rb), [`db/migrate/20260403040001_create_users.rb`](../db/migrate/20260403040001_create_users.rb), [`db/migrate/20260403040002_create_sessions.rb`](../db/migrate/20260403040002_create_sessions.rb), [`db/migrate/20260403040003_add_user_and_skill_levels_to_listings.rb`](../db/migrate/20260403040003_add_user_and_skill_levels_to_listings.rb), [`db/migrate/20260403110000_convert_skill_level_to_range_on_listings.rb`](../db/migrate/20260403110000_convert_skill_level_to_range_on_listings.rb) (FK `listings.user_id`, CHECK range `skill_level_min/max`).
- **Ứng dụng web**: `ApplicationController` gồm `Authentication` — mặc định `require_authentication`; controller công khai (`HomeController`, đăng nhập, reset mật khẩu) gọi `allow_unauthenticated_access`. Trang xem tin/map khi có controller riêng cũng cần `allow_unauthenticated_access`; action tạo listing dùng mặc định (đã đăng nhập).
- **Môi trường dev**: PostgreSQL phải có extension PostGIS (vd. image `postgis/postgis`, hoặc gói `postgresql-*-postgis-*` trên máy chủ). Không có PostGIS thì `enable_extension "postgis"` sẽ lỗi.
- **Ràng buộc `listings`** (CHECK): `listings_sport_valid`, `listings_skill_level_min_valid`, `listings_skill_level_max_valid`, `listings_skill_level_range_valid`, `listings_slots_needed_positive`, `listings_time_range_valid` (`end_at >= start_at`).
- **Chỉ mục `listings`**: GIST `index_listings_on_geom`; B-tree `index_listings_on_start_at`; composite `index_listings_on_sport_and_start_at`; partial unique `index_listings_on_source_url_nonnull` trên `(source_url) WHERE source_url IS NOT NULL`.
- **Chỉ mục `geocoding_caches`**: unique `location_query`; GIST `index_geocoding_caches_on_geom`.
- **Solid Queue / Cache / Cable**: bảng job và cache nằm theo cấu hình đa DB trong `config/database.yml` (production) — không trộn vào bảng domain ở trên.
- **Ghi chú ActiveRecord**: kiểu `geography` có OID tùy DB; pg có thể log `unknown OID ... geom` và coi cột như `String` khi đọc — chấp nhận trong MVP; ghi `geom` nên qua SQL (`Listing.insert_with_point!`, `GeocodingCache.insert_with_point!`) hoặc migration/raw query.
- **Kiểm thử**: `test/models/listing_spatial_test.rb` (cần PostGIS).

## Liên kết

- [decisions/004-postgis-without-adapter.md](decisions/004-postgis-without-adapter.md)
- [schemas/listing_extraction.schema.json](schemas/listing_extraction.schema.json)
- [API_CONTRACTS.md](API_CONTRACTS.md)
