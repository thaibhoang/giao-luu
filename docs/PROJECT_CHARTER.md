# Project Charter — SportMatch

## Tên và mục tiêu

| Trường | Nội dung |
|--------|----------|
| Code name | **SportMatch** |
| Mục tiêu | Ứng dụng tìm đồng đội / giao lưu cho **cầu lông** và **pickleball** |
| Đối tượng | Người chơi phong trào; chủ sân; người cần đối thủ trình độ tương đương |

## MVP scope

1. Hiển thị **bài đăng tuyển / giao lưu** trên **bản đồ** (theo vị trí địa lý).
2. **Nguồn dữ liệu hybrid**:
   - Người dùng **tự đăng tin** qua ứng dụng.
   - Pipeline **tự động** từ nội dung nhóm Facebook (Go scraper + LLM extract) — kèm rủi ro ToS / pháp lý, xem [SCRAPER_AGENT.md](SCRAPER_AGENT.md).
3. **Tìm kiếm theo vị trí**: lọc theo bán kính (mét) quanh điểm người dùng chọn hoặc GPS.
4. **SEO**: trang chi tiết tin tuyển giao lưu thân thiện công cụ tìm kiếm (meta, URL, nội dung có cấu trúc — chi tiết khi implement).

## Ngoài MVP (định hướng)

- Hệ thống **uy tín / check-in**: [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md).
- **Thời tiết realtime** cho pickleball (sân ngoài trời): [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md).

## Success metrics (gợi ý ngắn)

- Số listing hợp lệ có tọa độ trên map / tuần.
- Tỷ lệ tin có đủ khung giờ + môn + mức trình bày rõ.
- Chi phí API Maps/Geocoding có kiểm soát (cache hit rate).

## Phê duyệt thay đổi scope

Mọi thay đổi MVP cần cập nhật file này + [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md) để agent không implement sai phạm vi.
