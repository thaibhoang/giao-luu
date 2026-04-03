# Flow sequence diagrams — SportMatch

Tài liệu bổ sung [ARCHITECTURE.md](ARCHITECTURE.md): **sequence diagram** (Mermaid) cho các luồng MVP và wildcard roadmap. Thời gian API/DB theo **UTC** ([ADR-003](decisions/003-timezone-storage.md)).

## Mục lục

- [Quy ước participant](#quy-ước-participant)
- [MVP — Duyệt bản đồ (map feed)](#mvp--duyệt-bản-đồ-map-feed)
- [MVP — Chi tiết tin (SEO + Turbo)](#mvp--chi-tiết-tin-seo--turbo)
- [MVP — Tạo listing thủ công](#mvp--tạo-listing-thủ-công)
- [MVP — Ingest có chữ ký (Go → Rails)](#mvp--ingest-có-chữ-ký-go--rails)
- [MVP — Pipeline Facebook → LLM → geocode → ingest](#mvp--pipeline-facebook--llm--geocode--ingest)
- [MVP — Job geocode nền (Solid Queue)](#mvp--job-geocode-nền-solid-queue)
- [Roadmap — Uy tín / check-in](#roadmap--uy-tín--check-in)
- [Roadmap — Thời tiết pickleball](#roadmap--thời-tiết-pickleball)

## Quy ước participant

| Id trong diagram | Ý nghĩa |
|------------------|---------|
| `Browser` | Trình duyệt người dùng |
| `ReactMap` | React island trên trang map ([ADR-001](decisions/001-map-frontend-react-esbuild.md)) |
| `Rails` | Rails 8 web + API |
| `PostGIS` | PostgreSQL + PostGIS (listings, `geocoding_cache`) |
| `SolidQueueWorker` | Worker Solid Queue |
| `GoScraper` | Service Go (scrape + orchestrate) |
| `FacebookSource` | Nguồn bài đăng (Facebook / tương đương) |
| `LLM` | Nhà cung cấp LLM (JSON schema) |
| `GoogleGeocoding` | Google Geocoding API |

Chỉ các diagram **Roadmap** dùng `UserAuth`, `ListingOwner`, `WeatherAPI` — hợp đồng API chi tiết có thể bổ sung sau.

---

## MVP — Duyệt bản đồ (map feed)

Theo [API_CONTRACTS.md](API_CONTRACTS.md) `GET /api/v1/listings/map`, [MAPS_AND_COSTS.md](MAPS_AND_COSTS.md) (clustering, icon theo môn).

```mermaid
sequenceDiagram
  autonumber
  participant Browser
  participant Rails
  participant ReactMap as ReactMapIsland
  participant PostGIS

  Browser->>Rails: GET trang map (HTML)
  Rails-->>Browser: HTML + Turbo + bundle React map
  Browser->>ReactMap: mount (khởi tạo Google Maps)
  ReactMap->>Rails: GET /api/v1/listings/map?lat&lng&radius_meters&sport&from&to
  Rails->>PostGIS: ST_DWithin(geom, center, radius_meters) + filters
  PostGIS-->>Rails: listings có geom
  Rails-->>ReactMap: 200 JSON { listings: [...] }
  ReactMap-->>Browser: marker + clustering + icon theo sport
```

---

## MVP — Chi tiết tin (SEO + Turbo)

Theo [API_CONTRACTS.md](API_CONTRACTS.md): HTML `GET /listings/:id`; JSON `GET /api/v1/listings/:id` (tuỳ chọn).

```mermaid
sequenceDiagram
  autonumber
  participant Browser
  participant Rails
  participant PostGIS

  Browser->>Rails: GET /listings/:id (Accept HTML)
  Rails->>PostGIS: SELECT listing :id
  PostGIS-->>Rails: row
  Rails-->>Browser: 200 HTML Turbo (SEO meta, nội dung)

  opt Frontend island cần JSON đầy đủ
    Browser->>Rails: GET /api/v1/listings/:id
    Rails->>PostGIS: SELECT listing :id
    PostGIS-->>Rails: row
    Rails-->>Browser: 200 JSON
  end
```

---

## MVP — Tạo listing thủ công

Theo [API_CONTRACTS.md](API_CONTRACTS.md) `POST /api/v1/listings`: **cần đăng nhập**; `skill_level` là slug mới ([listing_extraction.schema.json](schemas/listing_extraction.schema.json)). Có thể enqueue geocode khi thiếu `geom` ([SCRAPER_AGENT.md](SCRAPER_AGENT.md)).

```mermaid
sequenceDiagram
  autonumber
  participant Client
  participant Rails
  participant PostGIS
  participant SolidQueueWorker

  Client->>Rails: POST /api/v1/listings + cookie/session hợp lệ
  alt chưa đăng nhập
    Rails-->>Client: 401 hoặc redirect đăng nhập (tuỳ implement)
  else đã đăng nhập
    Client->>Rails: POST body listing (ISO 8601 UTC) + skill_level slug
    alt validation lỗi
      Rails-->>Client: 422 { errors: [...] }
    else hợp lệ
      Rails->>PostGIS: INSERT listing user_id + geom nếu có lat/lng
      PostGIS-->>Rails: ok
      opt Chưa có geom, chỉ có location_name
        Rails->>SolidQueueWorker: enqueue GeocodeListingJob
        Note over SolidQueueWorker: xử lý bất đồng bộ — xem diagram job geocode
      end
      Rails-->>Client: 201 (hoặc 200 tuỳ implement) + listing
    end
  end
```

---

## MVP — Ingest có chữ ký (Go → Rails)

Theo [API_CONTRACTS.md](API_CONTRACTS.md), [ADR-002](decisions/002-scraper-to-rails-auth.md): HMAC trên `timestamp + "." + raw_body`, cửa sổ thời gian, idempotent `source_url`.

```mermaid
sequenceDiagram
  autonumber
  participant GoScraper
  participant Rails
  participant PostGIS

  GoScraper->>GoScraper: raw_body JSON + X-SportMatch-Timestamp
  GoScraper->>GoScraper: X-SportMatch-Signature = HMAC-SHA256(secret, ts + "." + raw_body) hex lower
  GoScraper->>Rails: POST /internal/v1/listings/import + headers
  alt timestamp ngoài cửa sổ hoặc chữ ký sai
    Rails-->>GoScraper: 401/403
  else chữ ký hợp lệ
    Rails->>PostGIS: SELECT theo source_url (unique)
    alt source_url đã tồn tại
      PostGIS-->>Rails: listing_id
      Rails-->>GoScraper: 200 { status: duplicate, listing_id }
    else bản ghi mới
      Rails->>PostGIS: INSERT listing (+ geom nếu payload có geocode)
      PostGIS-->>Rails: listing_id
      Rails-->>GoScraper: 201 hoặc 200 success (theo implement)
    end
  end
```

---

## MVP — Pipeline Facebook → LLM → geocode → ingest

Theo [SCRAPER_AGENT.md](SCRAPER_AGENT.md): rate limit, validate schema, geocode **cache-first**, rồi POST internal import. Hai cách triển khai geocode được tài liệu cho phép.

```mermaid
sequenceDiagram
  autonumber
  participant GoScraper
  participant FacebookSource
  participant LLM
  participant PostGIS
  participant GoogleGeocoding
  participant Rails

  GoScraper->>FacebookSource: fetch post (sleep/backoff theo config)
  FacebookSource-->>GoScraper: raw_text, source_url, metadata

  GoScraper->>LLM: prompt + raw_text + ngày tham chiếu Asia/Ho_Chi_Minh
  LLM-->>GoScraper: JSON khớp listing_extraction.schema.json (UTC)

  GoScraper->>GoScraper: parse + validate schema
  alt validate thất bại
    GoScraper->>GoScraper: log / dead-letter / retry có giới hạn
  else hợp lệ
    alt Geocode tại Go (cache trong PostGIS qua Rails hoặc shared DB)
      GoScraper->>PostGIS: lookup geocoding_cache theo location_query
      alt cache hit
        PostGIS-->>GoScraper: lat, lng
      else cache miss
        GoScraper->>GoogleGeocoding: geocode query
        GoogleGeocoding-->>GoScraper: lat, lng
        GoScraper->>PostGIS: UPSERT geocoding_cache
      end
      GoScraper->>Rails: POST /internal/... + geocode trong body (tuỳ shape)
    else Geocode sau ingest (Rails / Solid Queue)
      GoScraper->>Rails: POST /internal/... (có thể thiếu geom)
      Note over Rails: enqueue GeocodeListingJob nếu thiếu geom
    end
  end
```

---

## MVP — Job geocode nền (Solid Queue)

Khi listing không có `geom`, [SCRAPER_AGENT.md](SCRAPER_AGENT.md) cho phép job retry; map feed có thể ẩn tin cho đến khi có `geom`.

```mermaid
sequenceDiagram
  autonumber
  participant Rails
  participant SolidQueueWorker
  participant PostGIS
  participant GoogleGeocoding

  Rails->>SolidQueueWorker: GeocodeListingJob (listing_id / location_query)

  SolidQueueWorker->>PostGIS: SELECT listing + tra geocoding_cache
  alt cache hit
    PostGIS-->>SolidQueueWorker: geom
    SolidQueueWorker->>PostGIS: UPDATE listings SET geom
  else cache miss
    SolidQueueWorker->>GoogleGeocoding: forward geocode
    GoogleGeocoding-->>SolidQueueWorker: lat, lng
    SolidQueueWorker->>PostGIS: UPSERT geocoding_cache + UPDATE listings.geom
  end

  opt Không resolve được địa chỉ
    SolidQueueWorker->>SolidQueueWorker: log / retry / bỏ qua theo policy
  end
```

---

## Roadmap — Uy tín / check-in

**Wildcard** — chi tiết API chưa có trong [API_CONTRACTS.md](API_CONTRACTS.md); tham chiếu [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md), [DATA_MODEL.md](DATA_MODEL.md) `reputation_events`.

```mermaid
sequenceDiagram
  autonumber
  participant Participant as ParticipantUser
  participant Owner as ListingOwner
  participant Rails
  participant PostGIS

  Note over Participant,PostGIS: Sau start_at; người đã join xác nhận tham gia

  Participant->>Rails: submit participation confirmation
  Owner->>Rails: confirm counterpart(s)

  Rails->>PostGIS: INSERT reputation_events (points_delta, listing_id, user_id, event_type)
  PostGIS-->>Rails: ok
  Rails-->>Participant: updated reputation/profile (khi có auth đầy đủ)
```

---

## Roadmap — Thời tiết pickleball

**Wildcard** — provider và endpoint cụ thể chọn khi implement; [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md).

```mermaid
sequenceDiagram
  autonumber
  participant Scheduler as SolidQueueOrScheduler
  participant Rails
  participant WeatherAPI as WeatherProvider
  participant Cache as RailsCacheOrDB
  participant Browser
  participant PostGIS

  Scheduler->>Rails: job trước start_at (vd. T-3h, T-1h)
  Rails->>PostGIS: SELECT pickleball listings ngoài trời + geom + start_at

  Rails->>Cache: GET forecast key(lat,lng,window)
  alt cache hit
    Cache-->>Rails: forecast snapshot
  else cache miss
    Rails->>WeatherAPI: forecast theo tọa độ + khung giờ
    WeatherAPI-->>Rails: precipitation probability / summary
    Rails->>Cache: SET với TTL ngắn
  end

  Browser->>Rails: GET listing page
  Rails-->>Browser: HTML/JSON kèm badge hoặc banner cảnh báo mưa (nếu vượt ngưỡng)
```

## Liên kết

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [API_CONTRACTS.md](API_CONTRACTS.md)
- [SCRAPER_AGENT.md](SCRAPER_AGENT.md)
- [MAPS_AND_COSTS.md](MAPS_AND_COSTS.md)
- [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md)
