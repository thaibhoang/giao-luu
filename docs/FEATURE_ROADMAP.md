# Feature roadmap — SportMatch

## MVP (đồng bộ [PROJECT_CHARTER.md](PROJECT_CHARTER.md))

- Map hiển thị listing có `geom`.
- Tìm theo vị trí + bán kính (mét).
- Đăng tin thủ công + ingest từ pipeline (khi bật).
- SEO trang tin cơ bản.

## Wildcard — Check-in uy tín

**Mục tiêu**: Người đăng tin và người tham gia xác nhận được giao lưu → cộng điểm uy tín, giảm no-show.

**Acceptance criteria (gợi ý)**

- Sau khi listing `start_at` đã qua, người chơi đã “join” có thể **xác nhận tham gia**; chủ listing **xác nhận đối tác**.
- Mỗi sự kiện hợp lệ tạo `reputation_events` (xem [DATA_MODEL.md](DATA_MODEL.md)) với `points_delta` dương.
- Hiển thị điểm uy tín tối thiểu trên profile (khi có auth).

## Wildcard — Thời tiết realtime (pickleball)

**Mục tiêu**: Pickleball ngoài trời — cảnh báo mưa / điều kiện xấu tại **tọa độ sân** vào khung giờ chơi.

**Acceptance criteria (gợi ý)**

- Trước `start_at` (vd. 3h và 1h), job hoặc request hiển thị gọi **weather API** (Open-Meteo, Visual Crossing, v.v. — chọn khi implement, ghi ADR).
- UI: banner hoặc badge trên listing pickleball ngoài trời khi xác suất mưa vượt ngưỡng cấu hình.
- Tuân cache rate limit của provider; không gọi trùng cho cùng listing trong cửa sổ thời gian ngắn.

## Liên kết

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [agent-sop.md](agent-sop.md)
