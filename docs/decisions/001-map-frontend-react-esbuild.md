# ADR-001: Trang bản đồ dùng React + esbuild (Google Maps)

## Status

Accepted

## Context

- Stack web hiện tại: Rails 8 + Hotwire + importmap.
- Yêu cầu dự án: dùng `@react-google-maps/api` và **clustering** trên map.
- Cần một quyết định rõ ràng để agent không implement map bằng Stimulus thuần trong khi tài liệu gốc nêu thư viện React.

## Decision

- Trang **browse map** dùng **React** mount vào một container trong view Rails.
- Bundle JS qua **`jsbundling-rails` + esbuild** (npm dependencies cho React, `@react-google-maps/api`, marker clusterer).
- Trang **chi tiết listing** vẫn ưu tiên **HTML Rails** cho SEO (Turbo/Stimulus).

## Consequences

- Cần thêm bước `yarn`/`npm install` và `bin/dev` hoặc build pipeline cho assets; cập nhật README.
- Importmap-only cho toàn app **không** đủ cho map bundle; chỉ áp dụng React trên các trang cần map.

## Links

- [TECH_STACK.md](../TECH_STACK.md)
- [MAPS_AND_COSTS.md](../MAPS_AND_COSTS.md)
