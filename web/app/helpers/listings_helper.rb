# frozen_string_literal: true

module ListingsHelper
  SPORT_SCHEMA_LABELS = {
    "badminton"   => "Badminton",
    "pickleball"  => "Pickleball"
  }.freeze

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
