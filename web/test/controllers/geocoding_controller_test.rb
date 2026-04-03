# frozen_string_literal: true

require "test_helper"

class GeocodingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "rejects blank query" do
    get "/geocoding/lookup", params: { query: " " }
    assert_response :unprocessable_entity
  end

  test "rejects too short query" do
    get "/geocoding/lookup", params: { query: "ab" }
    assert_response :unprocessable_entity
    assert_includes response.body, "query quá ngắn"
  end

  test "rejects too long query" do
    get "/geocoding/lookup", params: { query: "a" * 181 }
    assert_response :unprocessable_entity
    assert_includes response.body, "query quá dài"
  end

  test "returns lookup payload" do
    Geocoding::LookupService.stub(:call, {
      ok: true,
      data: {
        query: "san abc",
        lat: 10.8,
        lng: 106.6,
        provider: "nominatim",
        from_cache: false,
        display_name: "San ABC"
      }
    }) do
      get "/geocoding/lookup", params: { query: "San ABC" }
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal "san abc", body["query"]
      assert_equal "nominatim", body["provider"]
      assert_equal false, body["from_cache"]
    end
  end
end
