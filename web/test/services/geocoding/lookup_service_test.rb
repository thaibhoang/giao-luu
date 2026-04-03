# frozen_string_literal: true

require "test_helper"

module Geocoding
  class LookupServiceTest < ActiveSupport::TestCase
    setup do
      GeocodingCache.delete_all
    end

    test "returns cached coordinates first" do
      GeocodingCache.insert_with_point!(
        location_query: "san abc",
        provider: "nominatim",
        raw_response: { "display_name" => "San ABC" }.to_json,
        longitude: 106.7,
        latitude: 10.8
      )

      service = LookupService.new(query: "San ABC")
      service.stub(:fetch_from_nominatim, -> { raise "should not call nominatim on cache hit" }) do
        result = service.call
        assert_equal true, result[:ok]
        assert_equal true, result.dig(:data, :from_cache)
        assert_equal "nominatim", result.dig(:data, :provider)
      end
    end

    test "falls back to nominatim and persists cache" do
      service = LookupService.new(query: "Sân Cộng Hoà")
      nominatim_result = {
        provider: "nominatim",
        query: "san cong hoa",
        lat: 10.803,
        lng: 106.665,
        display_name: "San Cong Hoa",
        raw_response: { "display_name" => "San Cong Hoa" }
      }

      service.stub(:fetch_from_nominatim, nominatim_result) do
        service.stub(:fetch_from_google, nil) do
          result = service.call
          assert_equal true, result[:ok]
          assert_equal false, result.dig(:data, :from_cache)
          cached = GeocodingCache.lookup("san cong hoa")
          assert_in_delta 10.803, cached[:lat], 0.0001
          assert_in_delta 106.665, cached[:lng], 0.0001
          assert_equal "nominatim", cached[:provider]
        end
      end
    end

    test "falls back to google when nominatim misses" do
      service = LookupService.new(query: "Sân fallback")
      google_result = {
        provider: "google",
        query: "san fallback",
        lat: 10.701,
        lng: 106.601,
        display_name: "Google fallback",
        raw_response: { "formatted_address" => "Google fallback" }
      }

      service.stub(:fetch_from_nominatim, nil) do
        service.stub(:fetch_from_google, google_result) do
          result = service.call
          assert_equal true, result[:ok]
          assert_equal "google", result.dig(:data, :provider)
          cached = GeocodingCache.lookup("san fallback")
          assert_equal "google", cached[:provider]
        end
      end
    end

    test "returns failure when all providers miss" do
      service = LookupService.new(query: "khong ton tai")
      service.stub(:fetch_from_nominatim, nil) do
        service.stub(:fetch_from_google, nil) do
          result = service.call
          assert_equal false, result[:ok]
          assert_equal "Không tìm thấy địa điểm phù hợp", result[:error]
        end
      end
    end
  end
end
