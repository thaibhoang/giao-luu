# frozen_string_literal: true

# CityRegistry — danh sách thành phố hỗ trợ cho trang landing SEO.
#
# Mỗi entry:
#   slug          — xuất hiện trong URL, dùng chữ thường + dấu gạch ngang
#   name          — tên hiển thị tiếng Việt
#   lat / lng     — centroid thành phố (WGS-84 / SRID 4326)
#   radius_meters — bán kính tìm kiếm tính từ centroid (ST_DWithin)
#   description   — đoạn mô tả SEO (≥ 120 ký tự, tránh thin content)
#   tips          — mảng tip chơi cho trang landing
module CityRegistry
  CITIES = {
    "ho-chi-minh" => {
      name: "TP. Hồ Chí Minh",
      lat: 10.8231,
      lng: 106.6297,
      radius_meters: 25_000,
      description: "TP. Hồ Chí Minh là trung tâm thể thao sôi động nhất phía Nam với hàng trăm sân cầu lông " \
                   "và pickleball trải khắp các quận. Cộng đồng giao lưu hoạt động mạnh từ sáng sớm đến tối muộn, " \
                   "phù hợp mọi trình độ từ người mới bắt đầu đến bán chuyên.",
      tips: [
        "Đặt sân trước 2–3 ngày vào giờ cao điểm (6–8 giờ sáng và 5–8 giờ tối).",
        "Nhiều sân tập trung ở Quận 1, Bình Thạnh, Gò Vấp và Thủ Đức.",
        "Thời tiết TP.HCM dễ chơi quanh năm — mùa mưa lưu ý chọn sân trong nhà."
      ]
    },
    "ha-noi" => {
      name: "Hà Nội",
      lat: 21.0285,
      lng: 105.8542,
      radius_meters: 20_000,
      description: "Hà Nội có phong trào cầu lông và pickleball phát triển mạnh, đặc biệt ở các quận Đống Đa, " \
                   "Cầu Giấy, Nam Từ Liêm và Long Biên. Người chơi thủ đô nổi tiếng với kỹ thuật chắc chắn " \
                   "và tinh thần giao lưu thân thiện.",
      tips: [
        "Thời tiết Hà Nội mùa đông lạnh — ưu tiên sân trong nhà từ tháng 11 đến tháng 2.",
        "Khu vực Cầu Giấy và Mỹ Đình có mật độ sân cao nhất.",
        "Cuối tuần nên đặt sân trước ít nhất 3 ngày."
      ]
    },
    "da-nang" => {
      name: "Đà Nẵng",
      lat: 16.0544,
      lng: 108.2022,
      radius_meters: 15_000,
      description: "Đà Nẵng đang nổi lên như một điểm đến thể thao hấp dẫn với nhiều sân cầu lông và pickleball " \
                   "hiện đại. Khí hậu thuận lợi cho hoạt động ngoài trời và cộng đồng người chơi trẻ, năng động.",
      tips: [
        "Mùa hè Đà Nẵng nóng — chọn khung giờ sáng sớm (5–7h) hoặc tối (19–21h).",
        "Pickleball sân ngoài trời rất phổ biến ở khu vực ven biển.",
        "Cộng đồng giao lưu cuối tuần rất sôi động tại các CLB quận Hải Châu."
      ]
    },
    "can-tho" => {
      name: "Cần Thơ",
      lat: 10.0452,
      lng: 105.7469,
      radius_meters: 15_000,
      description: "Cần Thơ — trung tâm đồng bằng sông Cửu Long — có cộng đồng cầu lông giao lưu đoàn kết " \
                   "và sôi nổi. Các sân tập trung chủ yếu ở quận Ninh Kiều và Cái Răng.",
      tips: [
        "Thời tiết Cần Thơ thuận lợi cho chơi ngoài trời hầu hết các tháng trong năm.",
        "Nên liên hệ sân trước vì số lượng sân có hạn so với nhu cầu vào cuối tuần.",
        "Cộng đồng pickleball đang phát triển nhanh, dễ tìm bạn giao lưu trình độ mới."
      ]
    },
    "hai-phong" => {
      name: "Hải Phòng",
      lat: 20.8449,
      lng: 106.6881,
      radius_meters: 15_000,
      description: "Hải Phòng có phong trào cầu lông truyền thống lâu đời với nhiều CLB hoạt động thường xuyên " \
                   "tại các quận Ngô Quyền, Lê Chân và Hồng Bàng.",
      tips: [
        "Khí hậu miền Bắc — mùa đông ưu tiên sân nhà thi đấu có mái che.",
        "Nhiều giải giao lưu phong trào tổ chức cuối tuần, rất dễ tìm đối trình độ phù hợp.",
        "Các sân ven biển Đồ Sơn phù hợp cho pickleball ngoài trời mùa hè."
      ]
    }
  }.freeze

  SPORT_SLUGS = {
    "cau-long"   => "badminton",
    "pickleball" => "pickleball"
  }.freeze

  SPORT_DISPLAY_NAMES = {
    "cau-long"   => "Cầu lông",
    "pickleball" => "Pickleball"
  }.freeze

  # Trả về City hash hoặc nil
  def self.find_city(city_slug)
    CITIES[city_slug]
  end

  # Trả về DB sport value hoặc nil
  def self.resolve_sport(sport_slug)
    SPORT_SLUGS[sport_slug]
  end

  # Tất cả combination [sport_slug, city_slug] — dùng cho sitemap
  def self.all_combinations
    SPORT_SLUGS.keys.flat_map do |sport_slug|
      CITIES.keys.map { |city_slug| [ sport_slug, city_slug ] }
    end
  end
end
