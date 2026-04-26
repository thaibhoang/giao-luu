# frozen_string_literal: true

require "test_helper"

class LocationLandingControllerTest < ActionDispatch::IntegrationTest
  # ── Route matching ──────────────────────────────────────────────────────
  test "GET /cau-long/ho-chi-minh trả về 200" do
    get "/cau-long/ho-chi-minh"
    assert_response :success
  end

  test "GET /pickleball/ha-noi trả về 200" do
    get "/pickleball/ha-noi"
    assert_response :success
  end

  test "GET /pickleball/da-nang trả về 200" do
    get "/pickleball/da-nang"
    assert_response :success
  end

  # ── 404 cho city không tồn tại ─────────────────────────────────────────
  test "GET /cau-long/thanh-pho-khong-ton-tai trả về 404" do
    get "/cau-long/thanh-pho-khong-ton-tai"
    assert_response :not_found
  end

  # ── Route constraint: sport không hợp lệ không match route này ─────────
  test "GET /bong-da/ho-chi-minh trả về 404 (không match route)" do
    get "/bong-da/ho-chi-minh"
    assert_response :not_found
  end

  # ── Nội dung trang ─────────────────────────────────────────────────────
  test "trang cau-long/ho-chi-minh chứa H1 đúng" do
    get "/cau-long/ho-chi-minh"
    assert_match(/Giao lưu Cầu lông tại TP\. Hồ Chí Minh/, response.body)
  end

  test "trang pickleball/ha-noi chứa H1 đúng" do
    get "/pickleball/ha-noi"
    assert_match(/Giao lưu Pickleball tại Hà Nội/, response.body)
  end

  test "trang có canonical URL đúng" do
    get "/cau-long/ho-chi-minh"
    assert_match %r{<link rel="canonical" href="http://www\.example\.com/cau-long/ho-chi-minh"}, response.body
  end

  test "trang có meta description" do
    get "/cau-long/ho-chi-minh"
    assert_match(/<meta name="description"/, response.body)
  end

  test "trang có og:title" do
    get "/cau-long/ho-chi-minh"
    assert_match(/og:title/, response.body)
  end

  test "trang có breadcrumb với link trang chủ" do
    get "/cau-long/ho-chi-minh"
    assert_match(/Trang chủ/, response.body)
  end

  test "trang có breadcrumb với tên thành phố" do
    get "/cau-long/ho-chi-minh"
    assert_match(/TP\. Hồ Chí Minh/, response.body)
  end

  test "trang chứa nội dung mô tả khu vực (SEO content tĩnh)" do
    get "/cau-long/ho-chi-minh"
    assert_match(/trung tâm thể thao/, response.body)
  end

  test "trang chứa tips chơi" do
    get "/cau-long/ho-chi-minh"
    assert_match(/Mẹo cho người chơi/, response.body)
  end

  # ── Cache header ───────────────────────────────────────────────────────
  test "response có Cache-Control max-age 15 phút" do
    get "/cau-long/ho-chi-minh"
    assert_match(/max-age=900/, response.headers["Cache-Control"] || "")
  end
end
