# frozen_string_literal: true

class ListingsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  def index
    @listings = Listing.order(start_at: :asc).limit(100)
  end

  def show
    @listing = Listing.find(params[:id])
  end

  def new
    @listing = Listing.new(
      sport: "badminton",
      skill_level: "trung_binh",
      slots_needed: 1,
      start_at: Time.zone.now.change(min: 0) + 1.day,
      end_at: Time.zone.now.change(min: 0) + 1.day + 2.hours
    )
  end

  def create
    attrs = listing_params.except(:lat, :lng)
    @listing = Listing.new(attrs.merge(source: Listing::SOURCE_USER_SUBMITTED, schema_version: 2, user: Current.session&.user))
    lat = listing_params[:lat].to_f
    lng = listing_params[:lng].to_f

    unless lat.between?(-90, 90) && lng.between?(-180, 180)
      @listing.errors.add(:base, "Tọa độ không hợp lệ")
      return render :new, status: :unprocessable_entity
    end

    if @listing.valid?
      Listing.insert_with_point!(
        @listing.attributes.symbolize_keys.slice(
          :sport, :title, :body, :location_name, :start_at, :end_at,
          :slots_needed, :skill_level, :price_estimate, :contact_info,
          :source, :source_url, :schema_version, :user_id
        ),
        longitude: lng,
        latitude: lat
      )
      redirect_to listings_path, notice: "Đăng tin thành công"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def listing_params
    params.require(:listing).permit(
      :sport, :title, :body, :location_name, :lat, :lng, :start_at, :end_at,
      :slots_needed, :skill_level, :price_estimate, :contact_info
    )
  end
end
