# frozen_string_literal: true

require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @listing = Listing.insert_with_point!(
      {
        sport: "badminton",
        listing_type: "match_finding",
        title: "Keo test ctrl bookmark",
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
        user_id: users(:two).id
      },
      longitude: 106.6297,
      latitude: 10.8231
    )
  end

  test "create requires login" do
    post listing_bookmark_path(@listing)
    assert_redirected_to new_session_path
  end

  test "destroy requires login" do
    delete listing_bookmark_path(@listing)
    assert_redirected_to new_session_path
  end

  test "create bookmarks a listing" do
    sign_in_as(@user)
    assert_difference("Bookmark.count", 1) do
      post listing_bookmark_path(@listing)
    end
    assert_redirected_to @listing
  end

  test "create is idempotent — no duplicate" do
    sign_in_as(@user)
    Bookmark.create!(listing: @listing, user: @user)

    assert_no_difference("Bookmark.count") do
      post listing_bookmark_path(@listing)
    end
  end

  test "destroy removes bookmark" do
    sign_in_as(@user)
    Bookmark.create!(listing: @listing, user: @user)

    assert_difference("Bookmark.count", -1) do
      delete listing_bookmark_path(@listing)
    end
    assert_redirected_to @listing
  end

  test "destroy is safe when no bookmark exists" do
    sign_in_as(@user)
    assert_no_difference("Bookmark.count") do
      delete listing_bookmark_path(@listing)
    end
    assert_redirected_to @listing
  end

  test "my bookmarks page is accessible" do
    sign_in_as(@user)
    Bookmark.create!(listing: @listing, user: @user)
    get my_bookmarks_path
    assert_response :success
    assert_includes response.body, @listing.title
  end

  test "my bookmarks requires login" do
    get my_bookmarks_path
    assert_redirected_to new_session_path
  end
end
