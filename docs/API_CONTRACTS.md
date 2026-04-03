# API Contracts — SportMatch

Các endpoint và payload **mục tiêu** cho MVP. Đường dẫn cụ thể có thể đổi khi implement nhưng **shape JSON** và header auth ingest **không đổi** mà không bump `schema_version`.

## [Backend] Quy ước chung

- JSON: `Content-Type: application/json`.
- Thời gian trong body phải **ISO 8601** với offset hoặc `Z` (UTC) — align ADR-003.
- Lỗi validation: `422` + body `{ "errors": [ { "field", "message" } ] }` (hình thức cụ thể có thể dùng JSON:API sau; nếu đổi, cập nhật file này).

---

## [Backend] Map feed (public)

`GET /api/v1/listings/map`

### Query params

| Param | Kiểu | Bắt buộc | Mô tả |
|-------|------|----------|--------|
| `lat` | float | có* | Vĩ độ |
| `lng` | float | có* | Kinh độ |
| `radius_meters` | integer | không | Mặc định 5000 |
| `sport` | string | không | `badminton` \| `pickleball` |
| `from` | ISO8601 | không | Lọc `start_at >= from` |
| `to` | ISO8601 | không | Lọc `start_at <= to` |

\* Hoặc bbox `north,south,east,west` — khi bổ sung, ghi rõ trong PR và tại đây.

### Response 200 (mảng rút gọn)

```json
{
  "listings": [
    {
      "id": 1,
      "sport": "badminton",
      "title": "Cần 2 nam vãng lai",
      "location_name": "Sân 583 Nguyễn Trãi",
      "lat": 10.123,
      "lng": 106.456,
      "start_at": "2026-04-03T19:00:00Z",
      "end_at": "2026-04-03T21:00:00Z",
      "skill_level": "beginner-intermediate",
      "source": "facebook_scrape"
    }
  ]
}
```

---

## [Backend] Chi tiết listing (public + SEO)

`GET /listings/:id` — HTML Turbo.

`GET /api/v1/listings/:id` — JSON đầy đủ hơn (optional cho frontend).

---

## [Backend] Tạo listing thủ công (authenticated — sau MVP auth)

`POST /api/v1/listings`

Body minh họa:

```json
{
  "listing": {
    "sport": "pickleball",
    "title": "Pickle sáng CN",
    "location_name": "Công viên XYZ",
    "lat": 10.78,
    "lng": 106.69,
    "start_at": "2026-04-05T07:00:00+07:00",
    "end_at": "2026-04-05T09:00:00+07:00",
    "slots_needed": 2,
    "skill_level": "intermediate",
    "price_estimate": 0,
    "contact_info": "Liên hệ qua app"
  }
}
```

---

## [Scraper] Ingest từ Go → Rails (internal)

`POST /internal/v1/listings/import`

### Headers

| Header | Mô tả |
|--------|--------|
| `Content-Type` | `application/json` |
| `X-SportMatch-Timestamp` | Unix epoch giây (string) |
| `X-SportMatch-Signature` | HMAC-SHA256 **hex chữ thường** của `timestamp + "." + raw_body` (UTF-8) — xem ADR-002 |

### Body

Khớp semantic với [listing_extraction.schema.json](schemas/listing_extraction.schema.json) + trường hệ thống:

```json
{
  "schema_version": 1,
  "extracted": {
    "sport": "badminton",
    "location_name": "Sân 583 Nguyễn Trãi",
    "start_time": "2026-04-03T19:00:00Z",
    "end_time": "2026-04-03T21:00:00Z",
    "slots_needed": 3,
    "skill_level": "beginner-intermediate",
    "price_estimate": 50000,
    "contact_info": "https://www.facebook.com/groups/example/posts/123"
  },
  "source_url": "https://www.facebook.com/groups/example/posts/123",
  "raw_text": "Cần 2 nam 1 nữ vãng lai sân 583 Nguyễn Trãi..."
}
```

### Hành vi

- Nếu `source_url` đã tồn tại: **200** với `{ "status": "duplicate", "listing_id": ... }` (hoặc cập nhật — ghi rõ khi implement).
- Nếu thiếu tọa độ: Rails enqueue job geocode hoặc Go đã geocode trước khi gửi; tối thiểu phải có `lat`/`lng` trong payload mở rộng nếu đã geocode:

```json
"geocode": { "lat": 10.123, "lng": 106.456, "from_cache": true }
```

Khi thêm trường breaking, tăng `schema_version` và sửa schema JSON + file này.

## Liên kết

- [SCRAPER_AGENT.md](SCRAPER_AGENT.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
