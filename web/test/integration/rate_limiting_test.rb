# frozen_string_literal: true

require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
    sign_in_as(users(:one))
  end

  teardown do
    Rack::Attack.cache.store.clear
  end

  test "throttles geocoding lookup by ip" do
    Geocoding::LookupService.stub(:call, {
      ok: true,
      data: {
        query: "san abc",
        lat: 10.8,
        lng: 106.6,
        provider: "nominatim",
        from_cache: true,
        display_name: "San ABC"
      }
    }) do
      20.times do
        get "/geocoding/lookup", params: { query: "san abc" }
        assert_response :success
      end

      get "/geocoding/lookup", params: { query: "san abc" }
      assert_response :too_many_requests
    end
  end

  test "throttles listing write endpoint by ip" do
    30.times do
      post "/listings", params: { listing: { title: "x" } }
      assert_not_equal 429, response.status
    end

    post "/listings", params: { listing: { title: "x" } }
    assert_response :too_many_requests
  end
end
