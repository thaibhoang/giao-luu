# frozen_string_literal: true

module Internal
  module V1
    class ListingsImportsController < ApplicationController
      allow_unauthenticated_access
      skip_forgery_protection

      def create
        return render_unauthorized unless valid_signature?

        payload = params.permit(
          :schema_version, :source_url, :raw_text,
          extracted: %i[sport location_name start_time end_time slots_needed skill_level price_estimate contact_info title body],
          geocode: %i[lat lng from_cache]
        ).to_h

        source_url = payload["source_url"]
        if source_url.present? && (existing = Listing.find_by(source_url:))
          Rails.logger.info("ingest_duplicate source_url=#{source_url} listing_id=#{existing.id}")
          return render json: { status: "duplicate", listing_id: existing.id }, status: :ok
        end

        geocode = payload["geocode"] || {}
        lat = geocode["lat"]
        lng = geocode["lng"]
        extracted = payload.fetch("extracted", {})

        listing_attrs = {
          sport: extracted["sport"],
          title: extracted["title"].presence || extracted["location_name"].to_s,
          body: extracted["body"].presence || payload["raw_text"],
          location_name: extracted["location_name"],
          start_at: extracted["start_time"],
          end_at: extracted["end_time"],
          slots_needed: extracted["slots_needed"],
          skill_level: extracted["skill_level"],
          price_estimate: extracted["price_estimate"],
          contact_info: extracted["contact_info"].presence || source_url,
          source: Listing::SOURCE_FACEBOOK_SCRAPE,
          source_url:,
          schema_version: payload["schema_version"] || 2,
          user_id: nil
        }

        if lat.present? && lng.present?
          listing = Listing.insert_with_point!(listing_attrs, latitude: lat.to_f, longitude: lng.to_f)
        else
          listing = Listing.create!(listing_attrs)
        end

        render json: { status: "imported", listing_id: listing.id }, status: :created
        Rails.logger.info("ingest_imported listing_id=#{listing.id} source_url=#{source_url}")
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.map { |error| { field: error.attribute, message: error.message } } },
               status: :unprocessable_entity
      end

      private

      def valid_signature?
        secret = ENV["SCRAPER_HMAC_SECRET"].to_s
        return false if secret.blank?

        timestamp = request.headers["X-SportMatch-Timestamp"].to_s
        signature = request.headers["X-SportMatch-Signature"].to_s
        return false if timestamp.blank? || signature.blank?
        return false if (Time.now.to_i - timestamp.to_i).abs > 300

        raw_body = request.raw_post
        digest = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{raw_body}")
        ActiveSupport::SecurityUtils.secure_compare(digest, signature)
      end

      def render_unauthorized
        render json: { errors: [{ field: "signature", message: "invalid" }] }, status: :unauthorized
      end
    end
  end
end
