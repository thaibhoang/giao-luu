# frozen_string_literal: true

require "test_helper"

class ListingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test "index is public" do
    get "/listings"
    assert_response :success
  end

  test "new requires login" do
    get "/listings/new"
    assert_redirected_to new_session_path
  end

  test "create fails when coordinates are missing" do
    sign_in_as(users(:one))

    assert_no_difference("Listing.count") do
      post "/listings", params: { listing: valid_listing_params.except(:lat, :lng) }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Vui lòng chọn địa điểm trên bản đồ"
  end

  test "create succeeds with valid coordinates" do
    sign_in_as(users(:one))

    assert_difference("Listing.count", 1) do
      post "/listings", params: { listing: valid_listing_params }
    end

    assert_redirected_to listings_path
  end

  test "update fails when coordinates are missing" do
    sign_in_as(users(:one))
    listing = Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Tin cu",
        body: "body",
        location_name: "Q1",
        start_at: Time.current + 1.day,
        end_at: Time.current + 1.day + 1.hour,
        slots_needed: 2,
        skill_level_min: "trung_binh",
        skill_level_max: "kha",
        price_estimate: 0,
        contact_info: "https://example.com/old",
        source: Listing::SOURCE_USER_SUBMITTED,
        source_url: nil,
        schema_version: 3,
        user_id: users(:one).id
      },
      longitude: 106.6,
      latitude: 10.7
    )

    patch "/listings/#{listing.id}", params: { listing: valid_listing_params.except(:lat, :lng).merge(title: "Tin moi") }
    assert_response :unprocessable_entity
    assert_includes response.body, "Vui lòng chọn địa điểm trên bản đồ"
  end

  test "create fails when daily write quota is exceeded" do
    sign_in_as(users(:one))
    seed_daily_write_quota_for(users(:one), 5)

    assert_no_difference("Listing.count") do
      post "/listings", params: { listing: valid_listing_params }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Bạn đã vượt giới hạn 5 lượt chỉnh sửa/đăng tin trong hôm nay"
  end

  test "update fails when daily write quota is exceeded" do
    sign_in_as(users(:one))
    seed_daily_write_quota_for(users(:one), 5)
    listing = Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Tin update quota",
        body: "body",
        location_name: "Q3",
        start_at: Time.current + 1.day,
        end_at: Time.current + 1.day + 1.hour,
        slots_needed: 2,
        skill_level_min: "trung_binh",
        skill_level_max: "kha",
        price_estimate: 0,
        contact_info: "https://example.com/q",
        source: Listing::SOURCE_USER_SUBMITTED,
        source_url: nil,
        schema_version: 3,
        user_id: users(:one).id
      },
      longitude: 106.6,
      latitude: 10.7
    )

    patch "/listings/#{listing.id}", params: { listing: valid_listing_params.merge(title: "Khong duoc update") }
    assert_response :unprocessable_entity
    assert_includes response.body, "Bạn đã vượt giới hạn 5 lượt chỉnh sửa/đăng tin trong hôm nay"
  end

  private

  def seed_daily_write_quota_for(user, count)
    key = "listing-write-quota:v1:user:#{user.id}:date:#{Time.zone.today.iso8601}"
    Rails.cache.write(key, count, expires_in: 1.hour)
  end

  def valid_listing_params
    {
      sport: "badminton",
      title: "Keo giao luu",
      body: "Can them 2 nguoi",
      location_name: "San ABC",
      lat: "10.8231",
      lng: "106.6297",
      start_at: (Time.current + 1.day).iso8601,
      end_at: (Time.current + 1.day + 1.hour).iso8601,
      slots_needed: 2,
      skill_level_min: "trung_binh",
      skill_level_max: "kha",
      price_estimate: 50_000,
      contact_info: "https://example.com/contact"
    }
  end
end
