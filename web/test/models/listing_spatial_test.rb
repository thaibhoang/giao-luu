# frozen_string_literal: true

require "test_helper"

class ListingSpatialTest < ActiveSupport::TestCase
  setup do
    @connection = ActiveRecord::Base.connection
    unless @connection.adapter_name.casecmp("postgresql").zero? && @connection.extension_enabled?("postgis")
      skip "Cần PostgreSQL có extension postgis"
    end
    unless @connection.table_exists?("listings")
      skip "Chưa chạy migration listings"
    end
  end

  test "ST_DWithin trả về bản ghi có geom trong bán kính (mét)" do
    Listing.delete_all
    center_lng = 106.6297
    center_lat = 10.8231

    Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Spatial test listing",
        body: nil,
        location_name: "Gần trung tâm HCM",
        start_at: Time.utc(2026, 4, 10, 10, 0, 0),
        end_at: Time.utc(2026, 4, 10, 12, 0, 0),
        slots_needed: 1,
        skill_level_min: "yeu",
        skill_level_max: "trung_binh",
        price_estimate: nil,
        contact_info: "https://example.com/spatial-test",
        source: "facebook_scrape",
        source_url: nil,
        schema_version: 3,
        user_id: nil
      },
      longitude: center_lng,
      latitude: center_lat
    )

    count = Listing.count_by_sql(
      Listing.sanitize_sql_array(
        [
          <<~SQL.squish,
            SELECT COUNT(*) FROM listings
            WHERE geom IS NOT NULL
              AND ST_DWithin(
                geom,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ?
              )
          SQL
          center_lng,
          center_lat,
          5_000
        ]
      )
    )

    assert_equal 1, count
  end

  test "scope near_point trả về listing trong bán kính" do
    Listing.delete_all
    center_lng = 106.6297
    center_lat = 10.8231

    Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Near point scope test",
        body: nil,
        location_name: "Gần trung tâm HCM",
        start_at: 2.days.from_now,
        end_at:   2.days.from_now + 2.hours,
        slots_needed: 1,
        skill_level_min: "yeu",
        skill_level_max: "trung_binh",
        price_estimate: nil,
        contact_info: "https://example.com/near-point-test",
        source: "facebook_scrape",
        source_url: nil,
        schema_version: 3,
        user_id: nil,
        active: true
      },
      longitude: center_lng,
      latitude: center_lat
    )

    # Listing nằm trong bán kính 5km phải được trả về
    assert_equal 1, Listing.near_point(center_lat, center_lng, 5_000).count

    # Listing không nằm trong bán kính 100m phải không được trả về
    assert_equal 0, Listing.near_point(center_lat, center_lng, 100).count
  end

  test "scope near_point kết hợp with by_sport lọc đúng môn" do
    Listing.delete_all
    center_lng = 106.6297
    center_lat = 10.8231

    Listing.insert_with_point!(
      { sport: "badminton", listing_type: "match_finding", title: "Badminton gần", body: nil,
        location_name: "Sân cầu lông", start_at: 2.days.from_now, end_at: 2.days.from_now + 2.hours,
        slots_needed: 1, skill_level_min: "yeu", skill_level_max: "trung_binh",
        contact_info: "https://example.com/1", source: "facebook_scrape",
        schema_version: 3, user_id: nil, active: true },
      longitude: center_lng, latitude: center_lat
    )
    Listing.insert_with_point!(
      { sport: "pickleball", listing_type: "match_finding", title: "Pickleball gần", body: nil,
        location_name: "Sân pickleball", start_at: 2.days.from_now, end_at: 2.days.from_now + 2.hours,
        slots_needed: 2, contact_info: "https://example.com/2", source: "facebook_scrape",
        schema_version: 3, user_id: nil, active: true },
      longitude: center_lng, latitude: center_lat
    )

    badminton_results = Listing.upcoming.by_sport("badminton").near_point(center_lat, center_lng, 25_000)
    assert_equal 1, badminton_results.count
    assert_equal "badminton", badminton_results.first.sport
  end
end
