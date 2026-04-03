# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Geocoding
  class LookupService
    NOMINATIM_ENDPOINT = "https://nominatim.openstreetmap.org/search".freeze
    GOOGLE_GEOCODING_ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json".freeze

    def self.call(query:)
      new(query:).call
    end

    def initialize(query:)
      @raw_query = query.to_s
      @query = GeocodingCache.normalize_query(query)
    end

    def call
      return failure("Query trống") if @query.blank?

      cached = GeocodingCache.lookup(@query)
      return success(cached.merge(from_cache: true)) if cached.present?

      nominatim = fetch_from_nominatim
      if nominatim.present?
        persist_cache!(nominatim)
        return success(nominatim.merge(from_cache: false))
      end

      google = fetch_from_google
      if google.present?
        persist_cache!(google)
        return success(google.merge(from_cache: false))
      end

      failure("Không tìm thấy địa điểm phù hợp")
    rescue StandardError => e
      Rails.logger.warn("geocode_lookup_failed query=#{@query.inspect} error=#{e.class}:#{e.message}")
      failure("Không thể tra cứu địa điểm lúc này")
    end

    private

    def success(payload)
      { ok: true, data: payload }
    end

    def failure(message)
      { ok: false, error: message }
    end

    def persist_cache!(result)
      GeocodingCache.upsert_with_point!(
        location_query: @query,
        provider: result.fetch(:provider),
        raw_response: result[:raw_response],
        longitude: result.fetch(:lng),
        latitude: result.fetch(:lat)
      )
    end

    def fetch_from_nominatim
      uri = URI("#{NOMINATIM_ENDPOINT}?#{URI.encode_www_form(q: @raw_query, format: "jsonv2", limit: 1)}")
      response = perform_get(uri, headers: { "User-Agent" => "SportMatch/1.0 (contact: support@sportmatch.local)" })
      return nil unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      first = payload.first
      return nil if first.blank?

      {
        provider: "nominatim",
        query: @query,
        lat: Float(first.fetch("lat")),
        lng: Float(first.fetch("lon")),
        display_name: first["display_name"],
        raw_response: first
      }
    rescue JSON::ParserError, KeyError, ArgumentError
      nil
    end

    def fetch_from_google
      key = ENV["GOOGLE_MAPS_API_KEY"].to_s
      return nil if key.blank?

      uri = URI("#{GOOGLE_GEOCODING_ENDPOINT}?#{URI.encode_www_form(address: @raw_query, key:)}")
      response = perform_get(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      return nil unless payload["status"] == "OK"

      first = payload.fetch("results", []).first
      return nil if first.blank?

      location = first.fetch("geometry", {}).fetch("location", {})
      {
        provider: "google",
        query: @query,
        lat: Float(location.fetch("lat")),
        lng: Float(location.fetch("lng")),
        display_name: first["formatted_address"],
        raw_response: first
      }
    rescue JSON::ParserError, KeyError, ArgumentError
      nil
    end

    def perform_get(uri, headers: {})
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 2
      http.read_timeout = 3
      request = Net::HTTP::Get.new(uri)
      headers.each { |key, value| request[key] = value }
      http.request(request)
    end
  end
end
