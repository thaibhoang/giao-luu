# frozen_string_literal: true

class Rack::Attack
  self.cache.store = Rails.cache

  GLOBAL_REQ_PER_MIN = ENV.fetch("RATE_LIMIT_GLOBAL_REQ_PER_MIN", "120").to_i
  GEOCODE_REQ_PER_MIN = ENV.fetch("RATE_LIMIT_GEOCODE_REQ_PER_MIN", "20").to_i
  LISTING_WRITE_REQ_PER_WINDOW = ENV.fetch("RATE_LIMIT_LISTING_WRITE_REQ_PER_WINDOW", "30").to_i
  LISTING_WRITE_WINDOW_SECONDS = ENV.fetch("RATE_LIMIT_LISTING_WRITE_WINDOW_SECONDS", "900").to_i

  throttle("req/ip/global", limit: GLOBAL_REQ_PER_MIN, period: 1.minute) do |req|
    req.ip
  end

  throttle("req/ip/geocoding_lookup", limit: GEOCODE_REQ_PER_MIN, period: 1.minute) do |req|
    req.ip if req.get? && req.path == "/geocoding/lookup"
  end

  throttle("req/ip/listing_write", limit: LISTING_WRITE_REQ_PER_WINDOW, period: LISTING_WRITE_WINDOW_SECONDS) do |req|
    req.ip if req.path.match?(%r{\A/listings(?:/\d+)?\z}) && %w[POST PATCH].include?(req.request_method)
  end

  self.throttled_responder = lambda do |request|
    body = {
      error: "too_many_requests",
      message: "Bạn đang thao tác quá nhanh. Vui lòng thử lại sau.",
      match_discriminator: request.env["rack.attack.match_discriminator"],
      match_type: request.env["rack.attack.match_type"],
      match_data: request.env["rack.attack.match_data"]
    }

    [ 429, { "Content-Type" => "application/json" }, [ body.to_json ] ]
  end
end
