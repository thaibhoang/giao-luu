# ADR-002: Xác thực ingest Scraper (Go) → Rails

## Status

Accepted

## Context

- Go scraper gửi listing đã trích xuất tới Rails qua HTTP.
- Endpoint không được public cho internet mà không có xác thực.

## Decision

- Endpoint nội bộ `POST /internal/v1/listings/import` yêu cầu:
  - **HMAC-SHA256** trên chuỗi `timestamp + "." + raw_body` (UTF-8).
  - Header `X-SportMatch-Timestamp`: Unix epoch **giây** (string).
  - Header `X-SportMatch-Signature`: **hex chữ thường** (chuẩn thống nhất trong code; không dùng base64 trừ khi đồng bộ lại mọi tài liệu).
- Rails từ chối nếu `|now - timestamp| > 300` giây (chống replay tùy chỉnh được).
- Secret: `SCRAPER_HMAC_SECRET` chia sẻ qua vault/env; xoay key có quy trình.

## Alternatives considered

- mTLS: mạnh hơn nhưng nặng vận hành cho MVP.
- Bearer token tĩnh: đơn giản nhưng kém hơn HMAC+body cho toàn vẹn payload.

## Links

- [API_CONTRACTS.md](../API_CONTRACTS.md)
