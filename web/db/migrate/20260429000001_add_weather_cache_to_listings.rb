# frozen_string_literal: true

# Thêm 2 cột cache thời tiết vào listings:
#   - rain_probability: xác suất mưa (0–100) lấy từ Open-Meteo, nil = chưa check
#   - weather_checked_at: thời điểm fetch cuối cùng — dùng làm TTL 30 phút
#
# Chỉ áp dụng cho listing pickleball (sport = 'pickleball') và chỉ khi có geom.
class AddWeatherCacheToListings < ActiveRecord::Migration[8.0]
  def change
    add_column :listings, :rain_probability,   :integer,  default: nil
    add_column :listings, :weather_checked_at, :timestamptz, default: nil

    add_check_constraint :listings,
      "rain_probability IS NULL OR (rain_probability >= 0 AND rain_probability <= 100)",
      name: "listings_rain_probability_range"
  end
end
