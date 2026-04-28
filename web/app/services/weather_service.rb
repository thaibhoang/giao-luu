# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

# WeatherService — lấy xác suất mưa tại tọa độ và thời điểm cho trước
# từ Open-Meteo API (miễn phí, không cần key).
#
# API docs: https://open-meteo.com/en/docs
# Endpoint: https://api.open-meteo.com/v1/forecast
# Params:   latitude, longitude, hourly=precipitation_probability,
#           timezone=Asia/Ho_Chi_Minh, forecast_days=3
#
# Trả về Integer (0–100) hoặc nil nếu không lấy được dữ liệu.
#
# Ví dụ:
#   WeatherService.fetch(lat: 10.762622, lng: 106.660172, time: 3.hours.from_now)
#   # => 75
module WeatherService
  BASE_URL     = "https://api.open-meteo.com/v1/forecast"
  OPEN_TIMEOUT = 5   # giây
  READ_TIMEOUT = 10  # giây
  RAIN_HOURLY_PARAM = "precipitation_probability"

  # @param lat [Float]   Latitude
  # @param lng [Float]   Longitude
  # @param time [Time]   Thời điểm cần forecast (thường là start_at của listing)
  # @return [Integer, nil]  Xác suất mưa 0–100, hoặc nil nếu lỗi
  def self.fetch(lat:, lng:, time:)
    uri    = build_uri(lat, lng)
    target = time.in_time_zone("Asia/Ho_Chi_Minh")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                               open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.get(uri.request_uri)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("WeatherService: HTTP #{response.code} for lat=#{lat} lng=#{lng}")
      return nil
    end

    parse_probability(JSON.parse(response.body), target)
  rescue StandardError => e
    Rails.logger.error("WeatherService error: #{e.class} — #{e.message}")
    nil
  end

  # @private
  def self.build_uri(lat, lng)
    params = URI.encode_www_form(
      latitude:   lat.round(4),
      longitude:  lng.round(4),
      hourly:     RAIN_HOURLY_PARAM,
      timezone:   "Asia/Ho_Chi_Minh",
      forecast_days: 3
    )
    URI("#{BASE_URL}?#{params}")
  end

  # Tìm index giờ gần `target` nhất trong mảng hourly, trả về probability.
  # @private
  def self.parse_probability(body, target)
    times = body.dig("hourly", "time")
    probs = body.dig("hourly", RAIN_HOURLY_PARAM)

    return nil if times.blank? || probs.blank?

    # Open-Meteo trả format "2026-04-29T07:00" (local timezone)
    target_str = target.strftime("%Y-%m-%dT%H:00")

    index = times.index(target_str)

    if index.nil?
      # Fallback: tìm giờ gần nhất nếu không khớp chính xác
      target_epoch = target.to_i
      index = times.each_with_index.min_by { |t, _i|
        (Time.zone.parse(t).to_i - target_epoch).abs
      }&.last
    end

    return nil if index.nil?

    prob = probs[index]
    prob.is_a?(Numeric) ? prob.to_i : nil
  end
  private_class_method :build_uri, :parse_probability
end
