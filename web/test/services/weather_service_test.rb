# frozen_string_literal: true

require "test_helper"

class WeatherServiceTest < ActiveSupport::TestCase
  SAMPLE_RESPONSE = {
    "hourly" => {
      "time" => [
        "2026-04-29T06:00",
        "2026-04-29T07:00",
        "2026-04-29T08:00"
      ],
      "precipitation_probability" => [ 20, 75, 55 ]
    }
  }.freeze

  test "returns precipitation_probability for matching hour" do
    target = Time.zone.parse("2026-04-29T07:00")
    prob = call_parse(SAMPLE_RESPONSE, target)
    assert_equal 75, prob
  end

  test "returns closest hour when exact match not found" do
    target = Time.zone.parse("2026-04-29T07:30")
    prob = call_parse(SAMPLE_RESPONSE, target)
    # 07:30 gần 07:00 hơn 08:00 (delta 30 phút vs 30 phút) — min_by sẽ lấy cái đầu tiên
    assert_includes [ 75, 55 ], prob
  end

  test "returns nil when hourly data missing" do
    prob = call_parse({ "hourly" => {} }, Time.zone.now)
    assert_nil prob
  end

  test "returns nil on HTTP error" do
    stub_http_error do
      result = WeatherService.fetch(lat: 10.76, lng: 106.66, time: Time.zone.now)
      assert_nil result
    end
  end

  test "returns nil on network exception" do
    WeatherService.stub(:build_uri, ->(_lat, _lng) { raise Errno::ECONNREFUSED, "connection refused" }) do
      # build_uri is private — test via fetch
      result = WeatherService.fetch(lat: 10.76, lng: 106.66, time: Time.zone.now)
      assert_nil result
    end
  end

  private

  # Gọi private method parse_probability để test parsing logic trực tiếp
  def call_parse(body, target)
    WeatherService.send(:parse_probability, body, target)
  end

  def stub_http_error
    bad_response = Net::HTTPServiceUnavailable.new("1.1", 503, "Service Unavailable")
    Net::HTTP.stub(:start, ->(*_args, **_kwargs, &_block) { bad_response }) do
      yield
    end
  end
end
