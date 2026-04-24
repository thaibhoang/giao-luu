# frozen_string_literal: true

require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @listing = Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Keo test bookmark",
        body: "body",
        location_name: "San test",
        start_at: Time.current + 1.day,
        end_at: Time.current + 1.day + 1.hour,
        slots_needed: 2,
        skill_level_min: "trung_binh",
        skill_level_max: "kha",
        price_estimate: 0,
        contact_info: "https://example.com",
        source: Listing::SOURCE_USER_SUBMITTED,
        source_url: nil,
        schema_version: 3,
        user_id: @other_user.id
      },
      longitude: 106.6297,
      latitude: 10.8231
    )
  end

  test "user can bookmark a listing" do
    bookmark = Bookmark.create!(listing: @listing, user: @user)
    assert bookmark.persisted?
  end

  test "duplicate bookmark is invalid" do
    Bookmark.create!(listing: @listing, user: @user)
    duplicate = Bookmark.new(listing: @listing, user: @user)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:listing_id], "đã được lưu"
  end

  test "user has bookmarked_listings association" do
    Bookmark.create!(listing: @listing, user: @user)
    assert_includes @user.bookmarked_listings, @listing
  end

  test "listing has bookmarks association" do
    Bookmark.create!(listing: @listing, user: @user)
    assert_equal 1, @listing.bookmarks.count
  end

  test "destroying user destroys associated bookmarks" do
    temp_user = User.create!(email_address: "temp@example.com", password: "password123")
    Bookmark.create!(listing: @listing, user: temp_user)
    assert_difference("Bookmark.count", -1) { temp_user.destroy }
  end
end
