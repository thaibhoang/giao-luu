# frozen_string_literal: true

require "test_helper"

# Test scope upcoming và ExpireListingsJob
class ListingActiveTest < ActiveSupport::TestCase
  # Không load fixtures — tự tạo data trong từng test
  self.use_transactional_tests = true
  fixtures :users

  setup do
    skip "Cần PostgreSQL + PostGIS" unless pg_with_postgis?
    Listing.delete_all
    @user = users(:one)
  end

  # ── Helpers ────────────────────────────────────────────────────────────────

  def pg_with_postgis?
    conn = ActiveRecord::Base.connection
    conn.adapter_name.casecmp("postgresql").zero? && conn.extension_enabled?("postgis")
  end

  def make_listing(start_at:, active: true)
    Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Test listing #{SecureRandom.hex(4)}",
        body: nil,
        location_name: "Sân A",
        start_at:,
        end_at: start_at + 2.hours,
        slots_needed: 2,
        skill_level_min: "trung_binh",
        skill_level_max: "kha",
        price_estimate: nil,
        contact_info: "https://example.com",
        source: "user_submitted",
        source_url: nil,
        schema_version: 3,
        user_id: @user.id,
        active:
      },
      longitude: 106.6297,
      latitude: 10.8231
    )
  end

  # ── scope :upcoming ────────────────────────────────────────────────────────

  test "upcoming chỉ trả listing active + start_at >= hiện tại" do
    future   = make_listing(start_at: 1.day.from_now)
    _past    = make_listing(start_at: 1.day.ago)
    _inactive = make_listing(start_at: 1.day.from_now, active: false)

    ids = Listing.upcoming.pluck(:id)
    assert_includes ids, future.id
    assert_equal 1, ids.size
  end

  test "upcoming không trả listing đã qua dù active=true" do
    make_listing(start_at: 2.hours.ago)
    assert_empty Listing.upcoming
  end

  test "upcoming không trả listing active=false dù start_at tương lai" do
    make_listing(start_at: 1.day.from_now, active: false)
    assert_empty Listing.upcoming
  end

  # ── ExpireListingsJob ───────────────────────────────────────────────────────

  test "ExpireListingsJob deactivate các listing start_at trong quá khứ" do
    past1   = make_listing(start_at: 3.hours.ago)
    past2   = make_listing(start_at: 1.day.ago)
    future  = make_listing(start_at: 2.hours.from_now)

    count = ExpireListingsJob.new.perform

    assert_equal 2, count
    assert_equal false, past1.reload.active
    assert_equal false, past2.reload.active
    assert_equal true,  future.reload.active
  end

  test "ExpireListingsJob không đụng tới listing đã active=false" do
    already_inactive = make_listing(start_at: 2.hours.ago, active: false)
    count = ExpireListingsJob.new.perform
    assert_equal 0, count
    assert_equal false, already_inactive.reload.active
  end
end
