# frozen_string_literal: true

# LocationLandingController — trang landing SEO long-tail theo môn thể thao + thành phố.
#
# URL pattern: /:sport/:city_slug
#   sport      — "cau-long" hoặc "pickleball"
#   city_slug  — key trong CityRegistry::CITIES (ví dụ: "ho-chi-minh", "ha-noi")
#
# Cache 15 phút (public) để giảm tải PostGIS query khi Google bot crawl.
class LocationLandingController < ApplicationController
  allow_unauthenticated_access

  before_action :set_sport_and_city

  # GET /cau-long/ho-chi-minh
  # GET /pickleball/ha-noi
  def show
    @listings = Listing
      .upcoming
      .by_sport(@sport_db)
      .near_point(@city[:lat], @city[:lng], @city[:radius_meters])
      .order(start_at: :asc)
      .limit(20)

    @canonical_url = location_landing_url(@sport_slug, @city_slug)

    expires_in 15.minutes, public: true
  end

  private

    def set_sport_and_city
      @sport_slug = params[:sport]
      @city_slug  = params[:city_slug]

      @sport_db    = CityRegistry.resolve_sport(@sport_slug)
      @city        = CityRegistry.find_city(@city_slug)
      @sport_label = CityRegistry::SPORT_DISPLAY_NAMES[@sport_slug]

      render_not_found if @sport_db.nil? || @city.nil?
    end

    def render_not_found
      render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
    end
end
