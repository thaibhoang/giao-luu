# frozen_string_literal: true

class GeocodingController < ApplicationController
  MIN_QUERY_LENGTH = 3
  MAX_QUERY_LENGTH = 180

  def lookup
    query = params[:query].to_s
    normalized_query = query.strip
    if normalized_query.blank?
      return render json: { error: "query is required" }, status: :unprocessable_entity
    end

    if normalized_query.length < MIN_QUERY_LENGTH
      return render json: { error: "query quá ngắn" }, status: :unprocessable_entity
    end

    if normalized_query.length > MAX_QUERY_LENGTH
      return render json: { error: "query quá dài" }, status: :unprocessable_entity
    end

    result = Geocoding::LookupService.call(query: normalized_query)
    unless result[:ok]
      Rails.logger.info(
        "geocode_lookup_failed ip=#{request.remote_ip} user_id=#{Current.session&.user&.id} query=#{normalized_query.inspect} reason=#{result[:error]}"
      )
      return render json: { error: result[:error] }, status: :unprocessable_entity
    end

    data = result.fetch(:data)
    Rails.logger.info(
      "geocode_lookup_ok ip=#{request.remote_ip} user_id=#{Current.session&.user&.id} provider=#{data[:provider]} from_cache=#{data[:from_cache]} query=#{normalized_query.inspect}"
    )
    render json: {
      query: data[:query],
      lat: data[:lat],
      lng: data[:lng],
      provider: data[:provider],
      from_cache: data[:from_cache],
      display_name: data[:display_name]
    }
  end
end
