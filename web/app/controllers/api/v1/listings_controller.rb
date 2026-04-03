# frozen_string_literal: true

module Api
  module V1
    class ListingsController < ApplicationController
      allow_unauthenticated_access only: %i[map show]

      def map
        from = parse_time!(params[:from], "from")
        to = parse_time!(params[:to], "to")
        validate_time_range!(from:, to:)

        listings = Listing.map_rows_for(
          sport: params[:sport],
          from:,
          to:
        )

        render json: {
          listings: listings.map do |l|
            {
              id: l.id,
              sport: l.sport,
              title: l.title,
              location_name: l.location_name,
              lat: l.attributes["lat"].to_f,
              lng: l.attributes["lng"].to_f,
              start_at: l.start_at&.iso8601,
              end_at: l.end_at&.iso8601,
              skill_level: l.skill_level,
              price_estimate: l.price_estimate,
              source: l.source
            }
          end
        }
        Rails.logger.info("map_feed listings_count=#{listings.size} sport=#{params[:sport]}")
      rescue InvalidTimeFilter => e
        render json: { errors: [{ field: e.field, message: e.message }] }, status: :unprocessable_entity
      end

      def show
        listing = Listing.find(params[:id])
        render json: listing.as_json(only: %i[
                                       id sport title body location_name start_at end_at slots_needed
                                       skill_level price_estimate contact_info source source_url schema_version
                                     ])
      end

      def create
        attrs = listing_create_params.except(:lat, :lng).merge(
          source: Listing::SOURCE_USER_SUBMITTED,
          schema_version: 2,
          user: Current.session&.user
        )
        listing = Listing.new(attrs)
        if listing.valid?
          created = Listing.insert_with_point!(
            listing.attributes.symbolize_keys.slice(
              :sport, :title, :body, :location_name, :start_at, :end_at,
              :slots_needed, :skill_level, :price_estimate, :contact_info,
              :source, :source_url, :schema_version, :user_id
            ),
            longitude: listing_create_params[:lng].to_f,
            latitude: listing_create_params[:lat].to_f
          )
          render json: { id: created.id }, status: :created
        else
          render json: {
            errors: listing.errors.map { |error| { field: error.attribute, message: error.message } }
          }, status: :unprocessable_entity
        end
      end

      private

      def listing_create_params
        params.require(:listing).permit(
          :sport, :title, :body, :location_name, :lat, :lng, :start_at, :end_at,
          :slots_needed, :skill_level, :price_estimate, :contact_info
        )
      end

      class InvalidTimeFilter < StandardError
        attr_reader :field

        def initialize(field:, message:)
          @field = field
          super(message)
        end
      end

      def parse_time!(value, field)
        return nil if value.blank?

        Time.iso8601(value)
      rescue ArgumentError
        raise InvalidTimeFilter.new(field:, message: "must be ISO8601")
      end

      def validate_time_range!(from:, to:)
        return if from.blank? || to.blank?
        return unless to < from

        raise InvalidTimeFilter.new(field: "to", message: "must be greater than or equal to from")
      end
    end
  end
end
