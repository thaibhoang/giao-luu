# frozen_string_literal: true

class SitemapController < ApplicationController
  allow_unauthenticated_access

  # GET /sitemap.xml
  # Trả về Sitemap XML gồm:
  #   - root URL
  #   - tất cả listing upcoming
  #   - các trang landing địa điểm (sport × city)
  # Header Cache-Control 1 giờ để tránh load DB quá thường xuyên.
  def index
    @listings = Listing.upcoming.select(:id, :updated_at).order(updated_at: :desc)
    @landing_combinations = CityRegistry.all_combinations
    expires_in 1.hour, public: true
    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
