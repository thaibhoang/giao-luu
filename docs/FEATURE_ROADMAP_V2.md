# Feature Roadmap V2 — SportMatch

> Cập nhật: 2026-04-22  
> Trạng thái: Lên kế hoạch

---

## Tổng quan

Danh sách tính năng chuẩn bị triển khai, được nhóm theo nhóm chức năng và mức ưu tiên.

---

## 1. Mở rộng loại tin đăng

Hiện tại chỉ có **Tuyển giao lưu**. Nâng lên 3 loại tin ngang hàng:

| # | Loại tin | Slug | Mô tả ngắn |
|---|----------|------|------------|
| 1 | Tuyển giao lưu | `match_finding` | Tìm người chơi cùng trình độ để giao lưu |
| 2 | Pass sân | `court_pass` | Nhượng lại slot sân đã đặt |
| 3 | Tuyển giải đấu | `tournament` | Tìm đội / tuyển thủ tham gia giải đấu |

### 1.1 Tin Pass sân (`court_pass`)

- Tương tự luồng đăng tin tuyển giao lưu: vị trí, thời gian, môn thể thao, trình độ.
- Thêm các trường đặc thù:
  - `court_name` — tên sân cụ thể
  - `original_price` — giá gốc (VND)
  - `pass_price` — giá nhượng lại
  - `slots_available` — số suất còn lại
  - `booking_proof` *(optional)* — link / ảnh xác nhận đặt sân

### 1.2 Tin Tuyển giải đấu (`tournament`)

- Thêm các trường đặc thù:
  - `tournament_name` — tên giải
  - `organizer` — đơn vị tổ chức
  - `registration_deadline` — hạn đăng ký
  - `format` — đơn / đôi / đồng đội
  - `prize_info` *(optional)* — thông tin giải thưởng
  - `registration_link` *(optional)* — link đăng ký chính thức

### Việc cần làm

- [ ] Thêm cột `listing_type` (enum: `match_finding | court_pass | tournament`) vào bảng `listings`
- [ ] Migration + cập nhật `structure.sql`
- [ ] Thêm bảng/cột mở rộng cho từng loại tin (hoặc dùng `jsonb metadata`)
- [ ] Cập nhật form đăng tin — hiển thị trường động theo loại tin được chọn
- [ ] Cập nhật serializer / API response
- [ ] Cập nhật UI card & trang chi tiết để phân biệt 3 loại

---

## 2. Filter & Tìm kiếm

### 2.1 Tìm kiếm & Filter trên trang chủ

- Thanh tìm kiếm theo **địa điểm** (tên sân, quận/huyện, tỉnh/thành phố).
- Bộ lọc:
  - Loại tin (`listing_type`)
  - Môn thể thao (`badminton | pickleball`)
  - Ngày / giờ
  - Bán kính (km) xung quanh vị trí hiện tại / vị trí chọn

### 2.2 Filter theo Giới tính

- Thêm trường `gender_requirement` vào `listings`:
  - `any` — không giới hạn
  - `male` — nam
  - `female` — nữ
  - `mixed` — hỗn hợp nam nữ
- Hiển thị badge giới tính trên card tin.
- Thêm option filter giới tính trên trang chủ và trang danh sách.

### 2.3 Filter Đánh đơn / Đánh đôi (Tuyển giao lưu)

- Thêm trường `play_format` vào `listings` (áp dụng cho `match_finding` và `tournament`):
  - `singles` — đánh đơn
  - `doubles` — đánh đôi
  - `both` — cả hai
- Hiển thị trên card và trang chi tiết.
- Thêm vào bộ lọc trang chủ khi loại tin là Tuyển giao lưu.

### Việc cần làm

- [ ] Thêm cột `gender_requirement` (enum) vào `listings`
- [ ] Thêm cột `play_format` (enum) vào `listings`
- [ ] Cập nhật scope/query trên `Listing` model
- [ ] Xây dựng component filter UI (Stimulus + Turbo hoặc React theo ADR-001)
- [ ] API hỗ trợ params: `gender`, `play_format`, `listing_type`, `sport`, `date`, `lat`, `lng`, `radius`

---

## 3. Lọc dữ liệu theo thời gian

### 3.1 Trang chủ chỉ hiển thị tin từ thời điểm hiện tại trở đi

- Mặc định query: `WHERE play_time >= NOW()` (hoặc `starts_at >= NOW()`).
- Tin đã hết giờ sẽ tự động ẩn khỏi trang chủ / bản đồ.
- *Tuỳ chọn:* Giữ lại tin cũ trong trang "Lịch sử" của người đăng.

### Việc cần làm

- [ ] Thêm scope `upcoming` vào `Listing` model: `where('play_time >= ?', Time.current)`
- [ ] Áp dụng scope `upcoming` làm mặc định cho trang chủ, bản đồ, và API listing index
- [ ] Cân nhắc index `play_time` nếu chưa có

---

## 4. Phân loại trình độ Pickleball

Trình độ pickleball dùng hệ **DUPR / UTPR** (phổ biến tại VN hiện tại):

| Nhãn | DUPR | Mô tả nhanh |
|------|------|-------------|
| Mới bắt đầu | 2.0 – 2.5 | Mới học luật, chưa ổn định |
| Cơ bản | 2.5 – 3.0 | Biết đánh cơ bản, rally ngắn |
| Trung cấp thấp | 3.0 – 3.5 | Có chiến thuật đơn giản |
| Trung cấp | 3.5 – 4.0 | Chơi ổn định, biết dink / drive |
| Trung cấp cao | 4.0 – 4.5 | Chiến thuật tốt, tốc độ xử lý nhanh |
| Nâng cao | 4.5 – 5.0 | Gần chuyên nghiệp |
| Chuyên nghiệp | 5.0+ | Thi đấu chuyên nghiệp / giải lớn |

> **Cầu lông** giữ nguyên thang điểm hiện tại (hoặc tham khảo BWF level).

### Việc cần làm

- [ ] Cập nhật enum/lookup `skill_level` để tách riêng theo `sport`
- [ ] Migration thêm cột `skill_level_pickleball` hoặc dùng cấu trúc JSON linh hoạt
- [ ] Cập nhật form đăng tin: khi chọn môn Pickleball → hiển thị thang DUPR
- [ ] Cập nhật trang profile người dùng
- [ ] Cập nhật filter trình độ trên trang chủ theo môn được chọn

---

## 5. Thứ tự ưu tiên đề xuất

| Thứ tự | Tính năng | Lý do |
|--------|-----------|-------|
| 1 | Lọc tin từ hiện tại trở đi | Nhanh, ít rủi ro, cải thiện UX ngay |
| 2 | Filter giới tính + đơn/đôi | Thêm cột + UI filter đơn giản |
| 3 | Tìm kiếm & filter trang chủ | Cần trước khi mở rộng loại tin |
| 4 | Trình độ Pickleball (DUPR) | Cải thiện data quality |
| 5 | Pass sân | Loại tin mới đơn giản hơn |
| 6 | Tuyển giải đấu | Loại tin mới phức tạp hơn |

---

## 6. Ghi chú kỹ thuật

- Tất cả enum mới dùng **PostgreSQL native enum** hoặc `string` với validation ở Rails — không dùng integer enum để dễ debug.
- Mỗi tính năng cần có **migration riêng**, không gộp.
- Cập nhật `docs/DATA_MODEL.md` và `docs/API_CONTRACTS.md` song song với code.
- Viết test (model + controller) trước khi merge theo quy trình ở `docs/CONTRIBUTING.md`.
