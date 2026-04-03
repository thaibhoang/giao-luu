# SportMatch — Prompt thiết kế UI cho Stitch

Tài liệu này triển khai kế hoạch **Danh sách màn SportMatch + prompt Stitch** (đã phê duyệt trong Cursor). Dùng **Prompt 0** một lần, sau đó copy từng prompt màn theo [thứ tự gửi Stitch](#thứ-tự-gửi-stitch-khuyến-nghị).

Tham chiếu sản phẩm: [PROJECT_CHARTER.md](PROJECT_CHARTER.md), [API_CONTRACTS.md](API_CONTRACTS.md), [DATA_MODEL.md](DATA_MODEL.md), [MAPS_AND_COSTS.md](MAPS_AND_COSTS.md).

---

## Prompt 0 — Design system (UI kit)

**Copy nguyên khối cho Stitch (hoặc dán đầu mỗi prompt màn):**

> Thiết kế UI kit mobile cho app **SportMatch** — kết nối người chơi cầu lông và pickleball để giao lưu / tìm đối.
>
> **Phong cách:** nền trắng, chữ xám đậm đến đen, typography hiện đại tối giản, nhiều whitespace. Bo góc lớn cho card, nút, ô nhập liệu (12–16px). Viền mảnh `#E5E7EB`; shadow cực nhẹ hoặc không dùng shadow. Không gradient rực, không neon.
>
> **Màu:** nền chính `#FFFFFF`; nền phụ `#F5F5F5`; tiêu đề `#111827`; nội dung `#374151`; chữ phụ / placeholder `#6B7280`; viền `#E5E7EB`; nút primary fill `#111827` chữ trắng, hoặc outline xám đen trên nền trắng.
>
> **Icon:** line, minimal. Hai icon thể thao **khác nhau**: cầu lông (vợt cầu) và pickleball (vợt pickleball) — không trùng icon.
>
> **Khung:** mobile-first 375×812, có safe area (notch). Map có thể full-bleed; phần còn lại giữ padding 16–20px ngang.
>
> **Thành phần:** input bo góc, label nhỏ phía trên hoặc trong ô; chip lọc bo tròn; bottom sheet có handle kéo; card danh sách có divider nhẹ hoặc khoảng cách.

---

## Nhóm A — Khám phá (public)

### A1 — Trang chủ / Hub (tùy chọn)

> Màn **landing** app SportMatch, mobile 375×812. Nền trắng, typography xám–đen, bo góc, tối giản.
>
> **Trên cùng:** logo hoặc chữ **SportMatch** (wordmark đơn giản).
>
> **Giữa:** một dòng value prop (ví dụ: “Tìm đối cầu lông & pickleball gần bạn”).
>
> **CTA chính:** nút full width “Xem bản đồ” (primary đen/xám đậm).
>
> **Phía dưới:** hàng link văn bản “Đăng nhập” và “Đăng ký” (hoặc một dòng “Đã có tài khoản? Đăng nhập”).
>
> Không dùng màu brand mạnh; giữ đúng design system Prompt 0.

### A2 — Bản đồ (màn chính)

> Màn hình **chính** SportMatch: **bản đồ** chiếm phần lớn màn hình (placeholder ô xám nhạt grid mô phỏng Google Map — không cần logo Google).
>
> **Top bar (floating trên map):** ô tìm kiếm địa điểm (placeholder “Tìm khu vực, sân…”); bên phải nút tròn **vị trí của tôi** (icon GPS).
>
> **Dưới ô tìm:** hàng **chip** lọc môn: “Cầu lông”, “Pickleball”, “Tất cả” (một chip active).
>
> **Tiếp theo:** hàng điều khiển **bán kính**: slider hoặc chip 1 / 3 / 5 / 10 km.
>
> **Tùy chọn:** hai ô nhỏ hoặc date picker cho khoảng thời gian (từ–đến).
>
> **Trên map:** vài **marker** mẫu — hai kiểu icon khác nhau cho hai môn; một **cluster** tròn hiển thị số (ví dụ 12).
>
> **Bottom sheet** kéo lên ~40% chiều cao: danh sách **card** tin rút gọn — mỗi card: tiêu đề, tên địa điểm, khung giờ, nhãn trình độ; có thể vuốt ngang. Handle kéo ở mép trên sheet.
>
> Áp dụng Prompt 0: trắng–xám–đen, bo góc card, tối giản.

### A3 — Chi tiết listing

> Màn **chi tiết một tin** SportMatch, mobile, scroll dọc. Nền trắng, chữ xám–đen, bo góc các khối.
>
> **Header sticky:** nút back trái; có thể có icon chia sẻ phải.
>
> **Tiêu đề** lớn (1–2 dòng).
>
> **Badge** nhỏ nguồn tin: ví dụ “Người dùng đăng” hoặc “Từ Facebook” (viền nhẹ, chữ xám).
>
> **Khối thông tin** dạng hàng: icon + text cho — môn thể thao; địa điểm; thời gian bắt đầu–kết thúc (ghi rõ giờ VN); trình độ; số người cần; giá ước lượng (VND).
>
> **Map nhỏ** (optional): khung bo góc, placeholder xám.
>
> **Khối nội dung** mô tả (paragraph).
>
> **Khối liên hệ:** ưu tiên dạng link (gạch chân hoặc màu xám đậm); có thể icon “mở ngoài”.
>
> **Nút:** “Mở trong bản đồ” (secondary outline); có thể thêm “Sao chép liên kết”.
>
> Không cần form đăng nhập trên màn này. Đúng design system Prompt 0.

### A4 — Trạng thái rỗng / lỗi (map)

> Màn trạng thái **không có tin** hoặc **lỗi tải** trong ngữ cảnh bản đồ SportMatch. Mobile, nền trắng hoặc xám nhạt rất nhẹ.
>
> **Illustration** tối giản (line art, xám) — gợi ý bản đồ trống hoặc marker có dấu hỏi.
>
> **Tiêu đề:** “Chưa có tin nào gần đây” hoặc “Không tải được dữ liệu”.
>
> **Mô tả ngắn:** gợi ý tăng bán kính, đổi bộ lọc môn, hoặc thử lại sau.
>
> **Nút:** “Thử lại” hoặc “Mở rộng bán kính” (primary theo Prompt 0).
>
> Bo góc, tối giản, không minh họa màu mạnh.

---

## Nhóm B — Xác thực

### B1 — Đăng nhập

> Màn **đăng nhập** SportMatch, mobile, nền trắng, form căn giữa theo chiều dọc hoặc top-aligned với logo nhỏ phía trên.
>
> **Tiêu đề:** “Đăng nhập”.
>
> **Trường:** Email (keyboard email); Mật khẩu (ẩn, có icon hiện/ẩn tùy chọn).
>
> **Link văn bản:** “Quên mật khẩu?” căn phải dưới ô mật khẩu.
>
> **Nút** full width “Đăng nhập”.
>
> **Cuối:** “Chưa có tài khoản? Đăng ký” (link).
>
> Input bo góc, viền nhẹ; đúng Prompt 0.

### B2 — Đăng ký

> Màn **đăng ký** SportMatch, mobile, cùng design system.
>
> **Tiêu đề:** “Tạo tài khoản”.
>
> **Trường:** Email; Mật khẩu; Xác nhận mật khẩu.
>
> **Checkbox:** “Tôi đồng ý với Điều khoản và Chính sách quyền riêng tư” (link xám đậm trên hai cụm từ).
>
> **Nút** full width “Đăng ký”.
>
> **Cuối:** “Đã có tài khoản? Đăng nhập”.

### B3 — Quên mật khẩu

> Màn **quên mật khẩu** SportMatch, mobile.
>
> **Tiêu đề:** “Đặt lại mật khẩu”.
>
> **Mô tả ngắn** một dòng: nhập email để nhận liên kết đặt lại.
>
> **Trường:** Email.
>
> **Nút** “Gửi liên kết”.
>
> **Link:** “Quay lại đăng nhập”.
>
> Nền trắng, input bo góc, Prompt 0.

### B4 — Đặt lại mật khẩu

> Màn **đặt mật khẩu mới** (từ link email), SportMatch, mobile.
>
> **Tiêu đề:** “Mật khẩu mới”.
>
> **Trường:** Mật khẩu mới; Xác nhận mật khẩu.
>
> **Nút** full width “Cập nhật mật khẩu”.
>
> Thông báo thành công có thể là toast hoặc màn nhỏ “Đã cập nhật — chuyển đến đăng nhập”. Giữ palette xám–đen, bo góc.

---

## Nhóm C — Đã đăng nhập

### C1 — Tạo / đăng tin

> Màn **đăng tin mới** SportMatch, mobile, scroll dọc. Form dài một trang hoặc wizard 2 bước — nếu wizard, hiển thị thanh bước (1/2).
>
> **Các trường (theo thứ tự gợi ý):** Chọn môn (segmented hoặc radio: Cầu lông / Pickleball); Tiêu đề; Tên địa điểm + khu vực map nhỏ hoặc nút “Chọn trên bản đồ” (placeholder); Ngày giờ bắt đầu; Ngày giờ kết thúc; Số người cần (số); Trình độ (dropdown — nhãn tiếng Việt: Yếu, Trung bình, Khá, …); Giá ước lượng (VND, optional); Thông tin liên hệ (text hoặc URL).
>
> **Validation:** hiển thị lỗi dưới từng ô (chữ đỏ nhạt hoặc xám đậm + icon cảnh báo tối giản — tránh đỏ chói).
>
> **Nút cố định cuối:** “Đăng tin” full width.
>
> Header có nút đóng/back. Prompt 0: trắng–xám–đen, bo góc.

### C2 — Sửa tin

> Giống **C1 — Đăng tin**, nhưng tiêu đề màn “Sửa tin”; nút chính “Lưu thay đổi”. Có thể hiển thị dòng trạng thái nhỏ “Đã đăng” / thời gian đăng. Cùng design system SportMatch.

### C3 — Tin của tôi

> Màn **danh sách tin của tôi** SportMatch, mobile.
>
> **Header:** tiêu đề “Tin của tôi”; có thể nút “+ Đăng tin” phải.
>
> **Danh sách** card: mỗi card — tiêu đề rút gọn; môn + icon; khung giờ; địa điểm; badge trạng thái (ví dụ “Đang hiển thị”). Hành động phụ: icon “…” hoặc hai nút nhỏ “Sửa” / “Xóa”.
>
> **Empty state:** “Bạn chưa đăng tin nào” + nút “Đăng tin đầu tiên”.
>
> Nền trắng, card bo góc viền nhẹ, Prompt 0.

---

## Nhóm D — Hệ thống & niềm tin

### D1 — Lỗi 404 / 500

> Màn **lỗi** tối giản SportMatch, mobile, căn giữa nội dung.
>
> **Mã hoặc tiêu đề:** “Không tìm thấy trang” hoặc “Đã có lỗi xảy ra”.
>
> **Một dòng** mô tả ngắn.
>
> **Nút** “Về bản đồ” hoặc “Về trang chủ” (primary).
>
> Illustration line nhẹ tùy chọn. Màu xám–đen, không đỏ chói.

### D2 — Quyền riêng tư / Điều khoản

> Màn **văn bản pháp lý** SportMatch (Quyền riêng tư hoặc Điều khoản), mobile, **đọc dài**.
>
> **Header:** back + tiêu đề trang.
>
> **Nội dung:** placeholder 3–4 đoạn Lorem ipsum tiếng Việt ngắn; tiêu đề phụ H3; danh sách bullet có thể có.
>
> Typography rõ: line-height thoáng, màu chữ `#374151`, tiêu đề `#111827`. Nền trắng, không sidebar.

---

## Thứ tự gửi Stitch (khuyến nghị)

Gửi lần lượt để thiết kế bám cùng một design system và ưu tiên luồng chính:

1. **Prompt 0** — Design system (một lần).
2. **A2** — Bản đồ (màn chính).
3. **A3** — Chi tiết listing.
4. **C1** — Đăng tin.
5. **B1** — Đăng nhập.
6. **A4** — Empty / lỗi map.
7. **D1** — 404 / 500.
8. **B2** — Đăng ký.
9. **B3** — Quên mật khẩu.
10. **B4** — Đặt lại mật khẩu.
11. **C3** — Tin của tôi.
12. **C2** — Sửa tin (có thể gộp prompt “giống C1 với…” để tiết kiệm).
13. **D2** — Quyền riêng tư / Điều khoản.
14. **A1** — Hub (nếu không gộp root với bản đồ).

Mỗi lần gửi màn mới, **dán lại đoạn ngắn từ Prompt 0** (palette + bo góc + tên app) để Stitch không lệch tone.

---

## Đối chiếu MVP khi implement FE

Khi nối UI với backend, đối chiếu [API_CONTRACTS.md](API_CONTRACTS.md) và [DATA_MODEL.md](DATA_MODEL.md). Checklist ngắn:

| Hạng mục | Ghi nhớ |
|----------|---------|
| Map feed | `GET /api/v1/listings/map` — query `lat`, `lng`, `radius_meters`, `sport`, `from`, `to`; response `listings[]` với `sport`, `title`, `location_name`, `lat`, `lng`, `start_at`, `end_at`, `skill_level`, `source`. |
| Chi tiết | `GET /api/v1/listings/:id` hoặc HTML Turbo `GET /listings/:id` — đồng bộ field hiển thị với model `listings`. |
| Tạo tin | `POST /api/v1/listings` — cần phiên đăng nhập; body `listing` gồm `sport`, `title`, `location_name`, `lat`, `lng`, `start_at`, `end_at`, `slots_needed`, `skill_level`, `price_estimate`, `contact_info`, v.v. |
| Trình độ | Slug trong DB/API; nhãn tiếng Việt trên UI khớp bảng `skill_level` trong DATA_MODEL. |
| Nguồn tin | `source`: `user_submitted` vs `facebook_scrape` — badge/copy trên A3. |
| Tọa độ | Lưu POINT(lon, lat) SRID 4326; UI gửi `lat`/`lng` đúng thứ tự API. |

Nếu route Rails thực tế khác bản draft trong repo, cập nhật contract trong `API_CONTRACTS.md` khi đổi shape JSON.

---

## Liên kết

- Map frontend: [decisions/001-map-frontend-react-esbuild.md](decisions/001-map-frontend-react-esbuild.md)
- Clustering & icon: [MAPS_AND_COSTS.md](MAPS_AND_COSTS.md)
