# frozen_string_literal: true

# WeatherCheckJob — fetch xác suất mưa từ Open-Meteo cho các listing pickleball
# sắp diễn ra, cập nhật cột rain_probability + weather_checked_at.
#
# Chạy mỗi 15 phút (recurring.yml). Job tự lọc:
#   - Chỉ listing pickleball (sân ngoài trời)
#   - Còn active và có tọa độ geom
#   - start_at trong khoảng 45 phút → 4 giờ từ bây giờ
#     (bao trùm cả 2 mốc: ~3h trước và ~1h trước)
#   - Chưa check HOẶC đã check > 30 phút trước (cache TTL)
#
# Cache: lưu trực tiếp vào cột DB — không cần Redis riêng.
class WeatherCheckJob < ApplicationJob
  queue_as :default

  RAIN_THRESHOLD = 60      # % — hiển thị badge nếu >= giá trị này
  CACHE_TTL      = 30.minutes
  WINDOW_MIN     = 45.minutes   # start_at ít nhất 45 phút nữa
  WINDOW_MAX     = 4.hours      # ... nhưng không quá 4 giờ nữa

  def perform
    now = Time.current
    listings = listings_needing_check(now)
    Rails.logger.info("WeatherCheckJob: checking #{listings.size} listing(s)")

    listings.each do |listing|
      lat = listing["lat"].to_f
      lng = listing["lng"].to_f

      prob = WeatherService.fetch(lat: lat, lng: lng, time: listing.start_at)

      if prob.nil?
        Rails.logger.warn("WeatherCheckJob: no data for listing ##{listing.id}")
        next
      end

      listing.update_columns(
        rain_probability:   prob,
        weather_checked_at: Time.current
      )

      Rails.logger.info(
        "WeatherCheckJob: listing ##{listing.id} rain_probability=#{prob}% " \
        "(#{prob >= RAIN_THRESHOLD ? 'WARN' : 'OK'})"
      )
    end
  end

  private

  # Trả về ActiveRecord::Relation với lat/lng được select thêm qua ST_Y/ST_X.
  def listings_needing_check(now)
    Listing
      .select("listings.*, ST_Y(geom::geometry) AS lat, ST_X(geom::geometry) AS lng")
      .where(sport: "pickleball", active: true)
      .where.not(geom: nil)
      .where(start_at: (now + WINDOW_MIN)..(now + WINDOW_MAX))
      .where(
        "weather_checked_at IS NULL OR weather_checked_at < ?",
        now - CACHE_TTL
      )
  end
end
