# frozen_string_literal: true

require "test_helper"

class InternalV1ListingsImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_secret = ENV["SCRAPER_HMAC_SECRET"]
    ENV["SCRAPER_HMAC_SECRET"] = "test-secret"
  end

  teardown do
    ENV["SCRAPER_HMAC_SECRET"] = @original_secret
  end

  test "imports listing with valid hmac" do
    payload = {
      schema_version: 2,
      extracted: {
        sport: "badminton",
        location_name: "Sân thử",
        start_time: (Time.current + 1.day).iso8601,
        end_time: (Time.current + 1.day + 1.hour).iso8601,
        slots_needed: 2,
        skill_level: "trung_binh",
        price_estimate: 0,
        contact_info: "https://example.com/contact"
      },
      source_url: "https://example.com/source-1",
      raw_text: "test",
      geocode: { lat: 10.0, lng: 106.0, from_cache: true }
    }
    raw = payload.to_json
    ts = Time.now.to_i.to_s
    sig = OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("SCRAPER_HMAC_SECRET"), "#{ts}.#{raw}")

    post "/internal/v1/listings/import",
         params: raw,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-SportMatch-Timestamp" => ts,
           "X-SportMatch-Signature" => sig
         }

    assert_response :created
    assert_equal "imported", JSON.parse(response.body).fetch("status")
  end
end
