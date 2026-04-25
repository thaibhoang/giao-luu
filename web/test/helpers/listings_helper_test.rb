# frozen_string_literal: true

require "ostruct"
require "test_helper"

class ListingsHelperTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  # Trả về listing stub không cần DB — dùng OpenStruct hoặc Listing.new
  def build_listing(overrides = {})
    user = OpenStruct.new(email_address: overrides.delete(:email_address) { "player@example.com" })
    Listing.new({
      id:            1,
      title:         "Tìm người chơi cầu lông",
      body:          "Cần thêm 2 người, trình độ trung bình.",
      sport:         "badminton",
      listing_type:  "match_finding",
      location_name: "Nhà thi đấu Phan Đình Phùng",
      start_at:      Time.zone.parse("2026-05-01 07:00:00"),
      end_at:        Time.zone.parse("2026-05-01 09:00:00"),
      contact_info:  "0901234567",
      source:        "user_submitted",
      schema_version: 3,
      skill_level_min: "trung_binh",
      skill_level_max: "trung_binh",
      slots_needed:  2,
      active:        true
    }.merge(overrides)).tap { |l| l.define_singleton_method(:user) { user } }
  end

  # Helper để parse JSON-LD từ kết quả trả về
  def extract_json_ld(html_tag)
    # Lấy nội dung trong thẻ <script>
    content = html_tag.to_s.match(%r{<script[^>]*>(.*?)</script>}m)&.captures&.first
    JSON.parse(content)
  end

  setup do
    @default_url_options = { host: ENV.fetch("TEST_APP_HOST", "example.com") }
  end

  # URL helper — dùng nhất quán thay vì hardcode string
  def canonical_url_for(listing)
    listing_url(listing)
  end

  # --- Các trường bắt buộc ---

  test "structured_data_tag returns script tag with type application/ld+json" do
    listing = build_listing
    result  = structured_data_tag(listing, lat: 10.823, lng: 106.629)
    assert_includes result, 'type="application/ld+json"'
  end

  test "JSON-LD has @context and @type SportsEvent" do
    listing = build_listing
    data    = extract_json_ld(structured_data_tag(listing, lat: 10.823, lng: 106.629))
    assert_equal "https://schema.org", data["@context"]
    assert_equal "SportsEvent",        data["@type"]
  end

  test "JSON-LD maps name from listing title" do
    listing = build_listing(title: "Giao lưu pickleball cuối tuần")
    data    = extract_json_ld(structured_data_tag(listing))
    assert_equal "Giao lưu pickleball cuối tuần", data["name"]
  end

  test "JSON-LD maps description from listing body" do
    listing = build_listing(body: "Nội dung mô tả chi tiết.")
    data    = extract_json_ld(structured_data_tag(listing))
    assert_equal "Nội dung mô tả chi tiết.", data["description"]
  end

  test "JSON-LD maps sport Badminton for badminton sport" do
    listing = build_listing(sport: "badminton")
    data    = extract_json_ld(structured_data_tag(listing))
    assert_equal "Badminton", data["sport"]
  end

  test "JSON-LD maps sport Pickleball for pickleball sport" do
    listing = build_listing(
      sport:           "pickleball",
      skill_level_min: nil,
      skill_level_max: nil
    )
    data = extract_json_ld(structured_data_tag(listing))
    assert_equal "Pickleball", data["sport"]
  end

  test "JSON-LD startDate is ISO 8601 in Asia/Ho_Chi_Minh timezone" do
    listing = build_listing(start_at: Time.utc(2026, 5, 1, 0, 0, 0)) # 07:00 HCM
    data    = extract_json_ld(structured_data_tag(listing))
    # Asia/Ho_Chi_Minh = UTC+7, không có DST → offset +07:00
    assert_match(/2026-05-01T07:00:00\+07:00/, data["startDate"])
  end

  test "JSON-LD endDate is ISO 8601 in Asia/Ho_Chi_Minh timezone" do
    listing = build_listing(end_at: Time.utc(2026, 5, 1, 2, 0, 0)) # 09:00 HCM
    data    = extract_json_ld(structured_data_tag(listing))
    assert_match(/2026-05-01T09:00:00\+07:00/, data["endDate"])
  end

  test "JSON-LD url uses listing canonical URL" do
    listing = build_listing
    data    = extract_json_ld(structured_data_tag(listing))
    assert_equal listing_url(listing), data["url"]
  end

  # --- Location ---

  test "JSON-LD location has @type Place and name" do
    listing = build_listing(location_name: "Sân cầu lông ABC")
    data    = extract_json_ld(structured_data_tag(listing))
    assert_equal "Place",            data.dig("location", "@type")
    assert_equal "Sân cầu lông ABC", data.dig("location", "name")
  end

  test "JSON-LD location includes GeoCoordinates when lat/lng provided" do
    listing = build_listing
    data    = extract_json_ld(structured_data_tag(listing, lat: 10.8231, lng: 106.6297))
    geo = data.dig("location", "geo")
    assert_equal "GeoCoordinates", geo["@type"]
    assert_in_delta 10.8231,  geo["latitude"],  0.0001
    assert_in_delta 106.6297, geo["longitude"], 0.0001
  end

  test "JSON-LD location omits geo when lat/lng are nil" do
    listing = build_listing
    data    = extract_json_ld(structured_data_tag(listing, lat: nil, lng: nil))
    assert_nil data.dig("location", "geo")
  end

  # --- Organizer ---

  test "JSON-LD includes organizer when user has email" do
    listing = build_listing(email_address: "owner@example.com")
    data    = extract_json_ld(structured_data_tag(listing))
    assert_equal "Person",           data.dig("organizer", "@type")
    assert_equal "owner@example.com", data.dig("organizer", "email")
  end

  test "JSON-LD omits organizer when user is nil" do
    listing = build_listing
    listing.define_singleton_method(:user) { nil }
    data = extract_json_ld(structured_data_tag(listing))
    assert_nil data["organizer"]
  end
end
