# frozen_string_literal: true

require "test_helper"

class ApiV1ListingsControllerTest < ActionDispatch::IntegrationTest
  test "map returns listings in radius" do
    Listing.delete_all
    Listing.insert_with_point!(
      {
        sport: "badminton",
        title: "API map listing",
        body: "map",
        location_name: "Q1",
        start_at: Time.current + 1.day,
        end_at: Time.current + 1.day + 2.hours,
        slots_needed: 2,
        skill_level_min: "trung_binh",
        skill_level_max: "kha",
        price_estimate: 100_000,
        contact_info: "https://example.com/a",
        source: "facebook_scrape",
        source_url: nil,
        schema_version: 3,
        user_id: nil
      },
      longitude: 106.6297,
      latitude: 10.8231
    )

    get "/api/v1/listings/map", params: { lat: 10.8231, lng: 106.6297, radius_meters: 5_000 }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.fetch("listings").size
    assert_equal "trung_binh", body.dig("listings", 0, "skill_level_min")
    assert_equal "kha", body.dig("listings", 0, "skill_level_max")
  end
end
