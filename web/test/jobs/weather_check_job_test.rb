# frozen_string_literal: true

require "test_helper"

class WeatherCheckJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # Listing stub để test không phụ thuộc vào geom trong fixture DB
  def build_listing_stub(attrs = {})
    Listing.new(
      id: 9999,
      sport: "pickleball",
      title: "Test PK",
      location_name: "Sân test",
      start_at: 2.hours.from_now,
      end_at: 4.hours.from_now,
      slots_needed: 2,
      contact_info: "test",
      source: "user_submitted",
      schema_version: 3,
      skill_level_min: "trung_binh",
      skill_level_max: "kha",
      listing_type: "match_finding",
      active: true,
      **attrs
    ).tap do |l|
      # Giả lập lat/lng như khi query dùng ST_Y/ST_X
      l.define_singleton_method(:[]) { |k| { "lat" => "10.762", "lng" => "106.660" }[k.to_s] }
    end
  end

  test "updates rain_probability and weather_checked_at on success" do
    listing = build_listing_stub(rain_probability: nil, weather_checked_at: nil)

    updated_attrs = {}
    listing.define_singleton_method(:update_columns) { |attrs| updated_attrs.merge!(attrs) }

    job = WeatherCheckJob.new
    job.stub(:listings_needing_check, ->(_now) { [ listing ] }) do
      WeatherService.stub(:fetch, 70) do
        job.perform
        assert_equal 70, updated_attrs[:rain_probability]
        assert_not_nil updated_attrs[:weather_checked_at]
      end
    end
  end

  test "does not update when WeatherService returns nil" do
    listing = build_listing_stub(rain_probability: nil, weather_checked_at: nil)

    updated_attrs = {}
    listing.define_singleton_method(:update_columns) { |attrs| updated_attrs.merge!(attrs) }

    job = WeatherCheckJob.new
    job.stub(:listings_needing_check, ->(_now) { [ listing ] }) do
      WeatherService.stub(:fetch, nil) do
        job.perform
        assert_empty updated_attrs, "update_columns should not be called when fetch returns nil"
      end
    end
  end

  test "perform does nothing when no listings qualify" do
    job = WeatherCheckJob.new
    job.stub(:listings_needing_check, ->(_now) { [] }) do
      WeatherService.stub(:fetch, ->(**_kwargs) { raise "should not be called" }) do
        assert_nothing_raised { job.perform }
      end
    end
  end

  test "rain_probability high means warning threshold met" do
    assert WeatherCheckJob::RAIN_THRESHOLD <= 100
    assert WeatherCheckJob::RAIN_THRESHOLD >= 1
  end
end
