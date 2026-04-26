# frozen_string_literal: true

module LocationLandingHelper
  # Meta description cho trang landing địa điểm.
  # Ví dụ: "Tìm buổi giao lưu Cầu lông tại TP. Hồ Chí Minh. 12 buổi sắp diễn ra gần bạn trên SportMatch."
  def location_landing_meta_description(sport_label, city, listings_count)
    "Tìm buổi giao lưu #{sport_label} tại #{city[:name]}. " \
      "#{listings_count} buổi sắp diễn ra gần bạn trên SportMatch."
  end

  # og:title cho trang landing
  def location_landing_og_title(sport_label, city)
    "#{sport_label} #{city[:name]} — Giao lưu & Tìm đối | SportMatch"
  end

  # Tên sport hiển thị (viết hoa chữ đầu)
  def sport_display_name(sport_slug)
    CityRegistry::SPORT_DISPLAY_NAMES.fetch(sport_slug, sport_slug)
  end
end
