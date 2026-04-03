# ADR-003: Lưu thời gian theo UTC trong database

## Status

Accepted

## Context

- Người dùng ở Việt Nam nhắc "tối nay", "19h-21h" theo giờ địa phương.
- Cần nhất quán khi query map feed theo `from`/`to` và khi hiển thị.

## Decision

- Cột thời gian trong PostgreSQL: **`timestamptz`**, luôn lưu **UTC** trong DB.
- LLM/scraper chuyển mọi suy luận từ `Asia/Ho_Chi_Minh` sang ISO 8601 UTC trong JSON extract.
- Hiển thị web: format theo timezone người dùng (mặc định `Asia/Ho_Chi_Minh` nếu chưa có cấu hình).

## Consequences

- Test phải cố định timezone hoặc assert theo UTC để tránh flake.

## Links

- [DATA_MODEL.md](../DATA_MODEL.md)
- [SCRAPER_AGENT.md](../SCRAPER_AGENT.md)
