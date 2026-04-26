# frozen_string_literal: true

require "test_helper"

class SitemapControllerTest < ActionDispatch::IntegrationTest
  test "GET /sitemap.xml trả về 200 và content-type XML" do
    get sitemap_path(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "sitemap chứa root URL" do
    get sitemap_path(format: :xml)
    assert_includes response.body, root_url
  end

  test "sitemap chứa URL của listing upcoming" do
    listing = listings(:upcoming_listing)
    get sitemap_path(format: :xml)
    assert_includes response.body, listing_url(listing)
  end

  test "sitemap KHÔNG chứa URL của listing hết hạn (inactive)" do
    listing = listings(:expired_listing)
    get sitemap_path(format: :xml)
    assert_not_includes response.body, listing_url(listing)
  end

  test "sitemap XML hợp lệ và có xmlns sitemap 0.9" do
    get sitemap_path(format: :xml)
    assert_includes response.body, "http://www.sitemaps.org/schemas/sitemap/0.9"
  end

  test "sitemap chứa URL trang landing cau-long/ho-chi-minh" do
    get sitemap_path(format: :xml)
    assert_includes response.body, location_landing_url("cau-long", "ho-chi-minh")
  end

  test "sitemap chứa URL trang landing pickleball/ha-noi" do
    get sitemap_path(format: :xml)
    assert_includes response.body, location_landing_url("pickleball", "ha-noi")
  end

  test "sitemap chứa tất cả combinations landing page" do
    get sitemap_path(format: :xml)
    CityRegistry.all_combinations.each do |sport_slug, city_slug|
      assert_includes response.body, location_landing_url(sport_slug, city_slug),
        "Thiếu landing URL: #{sport_slug}/#{city_slug}"
    end
  end
end
