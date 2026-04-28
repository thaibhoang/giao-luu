# frozen_string_literal: true

module ListingsHelper
  SPORT_SCHEMA_LABELS = {
    "badminton"   => "Badminton",
    "pickleball"  => "Pickleball"
  }.freeze

  SPORT_OG_IMAGES = {
    "badminton"  => "badminton.svg",
    "pickleball" => "pickleball.svg"
  }.freeze

  # Tạo chuỗi meta description động từ title + location_name + start_at.
  #
  # Ví dụ: "Tìm người chơi cầu lông · Nhà thi đấu Phan Đình Phùng · 07:00, 01/05/2026"
  #
  # @param listing [Listing]
  # @return [String]
  def listing_meta_description(listing)
    tz       = "Asia/Ho_Chi_Minh"
    time_str = listing.start_at.in_time_zone(tz).strftime("%H:%M, %d/%m/%Y")
    "#{listing.title} · #{listing.location_name} · #{time_str}"
  end

  # Trả về absolute URL của ảnh OG theo môn thể thao.
  # Fallback về badminton.svg nếu sport không khớp.
  #
  # @param listing [Listing]
  # @return [String] absolute URL
  def listing_og_image_url(listing)
    filename = SPORT_OG_IMAGES.fetch(listing.sport, "badminton.svg")
    asset_url(filename)
  end

  # Kiểm tra có nên hiển thị badge cảnh báo mưa không.
  # Điều kiện:
  #   - sport = pickleball (sân ngoài trời)
  #   - rain_probability >= 60%
  #   - weather_checked_at không quá 3 giờ trước (dữ liệu còn tươi)
  #
  # @param listing [Listing]
  # @return [Boolean]
  def listing_rain_warning?(listing)
    return false unless listing.sport == "pickleball"
    return false if listing.rain_probability.nil?
    return false if listing.weather_checked_at.nil?
    return false if listing.weather_checked_at < 3.hours.ago

    listing.rain_probability >= WeatherCheckJob::RAIN_THRESHOLD
  end

  # Tạo thẻ <script type="application/ld+json"> với dữ liệu Schema.org SportsEvent
  # cho trang chi tiết listing.
  #
  # @param listing [Listing]
  # @param lat [Float, nil]  latitude (từ ST_Y trên controller) — nil nếu chưa geocode
  # @param lng [Float, nil]  longitude (từ ST_X trên controller) — nil nếu chưa geocode
  # @param url [String]      canonical URL của listing (dùng listing_url helper)
  # @return [ActiveSupport::SafeBuffer] thẻ <script> an toàn để nhúng vào <head>
  def structured_data_tag(listing, lat: nil, lng: nil, url: listing_url(listing))
    data = build_sports_event_schema(listing, lat: lat, lng: lng, url: url)
    tag.script(data.to_json.html_safe, type: "application/ld+json")
  end

  private

  def build_sports_event_schema(listing, lat:, lng:, url:)
    tz = "Asia/Ho_Chi_Minh"
    schema = {
      "@context"    => "https://schema.org",
      "@type"       => "SportsEvent",
      "name"        => listing.title,
      "description" => listing.body.to_s.truncate(300),
      "sport"       => SPORT_SCHEMA_LABELS.fetch(listing.sport, listing.sport.humanize),
      "startDate"   => listing.start_at.in_time_zone(tz).iso8601,
      "endDate"     => listing.end_at.in_time_zone(tz).iso8601,
      "url"         => url,
      "location"    => build_location(listing, lat: lat, lng: lng)
    }

    if listing.user&.email_address.present?
      schema["organizer"] = {
        "@type" => "Person",
        "email" => listing.user.email_address
      }
    end

    schema
  end

  def build_location(listing, lat:, lng:)
    location = {
      "@type" => "Place",
      "name"  => listing.location_name
    }

    if lat.present? && lng.present?
      location["geo"] = {
        "@type"     => "GeoCoordinates",
        "latitude"  => lat.to_f.round(6),
        "longitude" => lng.to_f.round(6)
      }
    end

    location
  end
end
