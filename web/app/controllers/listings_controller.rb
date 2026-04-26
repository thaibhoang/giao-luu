# frozen_string_literal: true

class ListingsController < ApplicationController
  include Pagy::Method

  allow_unauthenticated_access only: %i[index show map]
  before_action :require_authentication, only: %i[my new create edit update]

  def index
    @pagy, @listings = pagy(
      Listing.upcoming
             .by_sport(params[:sport])
             .by_listing_type(params[:listing_type])
             .by_gender(params[:gender])
             .by_play_format(params[:play_format])
             .by_keyword(params[:q])
             .order(start_at: :asc),
      items: 20
    )
    @bookmarked_listing_ids = current_user_bookmark_ids(@listings)
  end

  def map
    @pagy, @listings = pagy(Listing.upcoming.order(start_at: :asc), items: 20)
    @map_center_lat = parse_coordinate(params[:lat], default: 10.8231, range: -90.0..90.0)
    @map_center_lng = parse_coordinate(params[:lng], default: 106.6297, range: -180.0..180.0)
    @map_focus_listing_id = params[:listing_id]
    @bookmarked_listing_ids = current_user_bookmark_ids(@listings)
  end

  def show
    @listing = Listing.find(params[:id])
    @listing_lat, @listing_lng = Listing.where(id: @listing.id).pick(
      Arel.sql("ST_Y(geom::geometry)"),
      Arel.sql("ST_X(geom::geometry)")
    )
    @bookmarked = authenticated? &&
                  Current.session.user.bookmarks.exists?(listing: @listing)
  end

  def my
    @status = my_listings_params[:status] if my_listings_params[:status].present?
    @published_listings = Current.session.user.listings.order(created_at: :desc)
    @active_listings = @published_listings.where("end_at >= ?", Time.current).order(end_at: :asc)
    @finished_listings = Current.session.user.listings.where("end_at < ?", Time.current).order(end_at: :desc)
  end

  def new
    @listing = Listing.new(
      listing_type: params[:listing_type].presence_in(Listing::LISTING_TYPES) || "match_finding",
      sport: "badminton",
      skill_level_min: "trung_binh",
      skill_level_max: "trung_binh",
      slots_needed: 1,
      start_at: Time.zone.now.change(min: 0) + 1.day,
      end_at: Time.zone.now.change(min: 0) + 1.day + 2.hours
    )
    @listing.build_court_pass_detail if @listing.court_pass?
    @listing.build_tournament_detail if @listing.tournament?
    @lat_value = listing_params_from_request[:lat]
    @lng_value = listing_params_from_request[:lng]
  end

  def edit
    @listing = Current.session.user.listings.find(params[:id])
    @listing.build_court_pass_detail if @listing.court_pass? && @listing.court_pass_detail.nil?
    @listing.build_tournament_detail if @listing.tournament? && @listing.tournament_detail.nil?
    @lat_value, @lng_value = Listing.where(id: @listing.id).pick(
      Arel.sql("ST_Y(geom::geometry)"),
      Arel.sql("ST_X(geom::geometry)")
    )
    @lat_value = listing_params_from_request[:lat] if listing_params_from_request[:lat].present?
    @lng_value = listing_params_from_request[:lng] if listing_params_from_request[:lng].present?
  end

  def create
    if write_quota_exceeded_for?(Current.session&.user)
      @listing = Listing.new(listing_params.except(:lat, :lng).merge(source: Listing::SOURCE_USER_SUBMITTED, schema_version: 3, user: Current.session&.user))
      @listing.errors.add(:base, "Bạn đã vượt giới hạn #{daily_write_limit} lượt chỉnh sửa/đăng tin trong hôm nay")
      @lat_value = listing_params[:lat]
      @lng_value = listing_params[:lng]
      return render :new, status: :unprocessable_entity
    end

    attrs = listing_params.except(:lat, :lng)
    attrs = normalize_court_pass_attrs(attrs) if attrs[:listing_type] == "court_pass"
    @listing = Listing.new(attrs.merge(source: Listing::SOURCE_USER_SUBMITTED, schema_version: 3, user: Current.session&.user))
    lat, lng = extract_coordinate_pair(listing_params[:lat], listing_params[:lng])
    @lat_value = listing_params[:lat]
    @lng_value = listing_params[:lng]

    unless valid_coordinate_pair?(lat, lng)
      @listing.errors.add(:base, "Vui lòng chọn địa điểm trên bản đồ")
      return render :new, status: :unprocessable_entity
    end

    if @listing.valid?
      created = Listing.insert_with_point!(
        @listing.attributes.symbolize_keys.slice(
          :sport, :listing_type, :title, :body, :location_name, :start_at, :end_at,
          :slots_needed, :skill_level_min, :skill_level_max, :skill_level_min_pk, :skill_level_max_pk,
          :price_estimate, :contact_info,
          :source, :source_url, :schema_version, :user_id, :gender_requirement, :play_format
        ),
        longitude: lng,
        latitude: lat
      )
      save_detail_record!(created, listing_params)
      increment_daily_write_quota!(Current.session.user)
      GenerateSitemapJob.perform_later
      redirect_to listings_path, notice: "Đăng tin thành công"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @listing = Current.session.user.listings.find(params[:id])
    if write_quota_exceeded_for?(Current.session.user)
      @listing.assign_attributes(listing_params.except(:lat, :lng))
      @listing.errors.add(:base, "Bạn đã vượt giới hạn #{daily_write_limit} lượt chỉnh sửa/đăng tin trong hôm nay")
      @lat_value = listing_params[:lat]
      @lng_value = listing_params[:lng]
      return render :edit, status: :unprocessable_entity
    end

    attrs = listing_params.except(:lat, :lng).merge(
      source: Listing::SOURCE_USER_SUBMITTED,
      schema_version: @listing.schema_version || 3,
      user_id: Current.session.user.id
    )
    attrs = normalize_court_pass_attrs(attrs) if attrs[:listing_type] == "court_pass"
    lat, lng = extract_coordinate_pair(listing_params[:lat], listing_params[:lng])
    @lat_value = listing_params[:lat]
    @lng_value = listing_params[:lng]

    unless valid_coordinate_pair?(lat, lng)
      @listing.assign_attributes(attrs)
      @listing.errors.add(:base, "Vui lòng chọn địa điểm trên bản đồ")
      return render :edit, status: :unprocessable_entity
    end

    @listing.assign_attributes(attrs)
    if @listing.valid?
      Listing.update_with_point!(
        id: @listing.id,
        attributes: attrs.to_h.symbolize_keys.slice(
          :sport, :listing_type, :title, :body, :location_name, :start_at, :end_at,
          :slots_needed, :skill_level_min, :skill_level_max, :skill_level_min_pk, :skill_level_max_pk,
          :price_estimate, :contact_info,
          :source, :source_url, :schema_version, :user_id, :gender_requirement, :play_format
        ),
        longitude: lng,
        latitude: lat
      )
      save_detail_record!(@listing, listing_params)
      increment_daily_write_quota!(Current.session.user)
      redirect_to listing_path(@listing), notice: "Cập nhật tin thành công"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def listing_params
    params.require(:listing).permit(
      :listing_type, :sport, :title, :body, :location_name, :lat, :lng, :start_at, :end_at,
      :slots_needed, :skill_level_min, :skill_level_max, :skill_level_min_pk, :skill_level_max_pk,
      :price_estimate, :contact_info,
      :gender_requirement, :play_format,
      court_pass_detail_attributes: %i[id court_name original_price pass_price booking_proof],
      tournament_detail_attributes: %i[id tournament_name organizer registration_deadline format prize_info registration_link]
    )
  end

  # Khi loại tin là "pass sân", điền giá trị mặc định cho các trường không cần thiết
  # để thoả DB constraint (NOT NULL, CHECK) nhưng không hiển thị với người dùng.
  def normalize_court_pass_attrs(attrs)
    attrs.merge(
      skill_level_min: attrs[:skill_level_min].presence || "trung_binh",
      skill_level_max: attrs[:skill_level_max].presence || "trung_binh",
      slots_needed:    attrs[:slots_needed].presence || 1
    )
  end

  def save_detail_record!(listing, params)
    case listing.listing_type
    when "court_pass"
      detail_attrs = params[:court_pass_detail_attributes]
      return if detail_attrs.blank?
      detail = listing.court_pass_detail || listing.build_court_pass_detail
      detail.update!(detail_attrs.except(:id))
    when "tournament"
      detail_attrs = params[:tournament_detail_attributes]
      return if detail_attrs.blank?
      detail = listing.tournament_detail || listing.build_tournament_detail
      detail.update!(detail_attrs.except(:id))
    end
  end

  def my_listings_params
    params.permit(:status)
  end

  def listing_params_from_request
    raw = params[:listing]
    return ActionController::Parameters.new unless raw.respond_to?(:permit)

    raw.permit(:lat, :lng)
  rescue ActionController::UnfilteredParameters
    ActionController::Parameters.new
  end

  def extract_coordinate_pair(lat_raw, lng_raw)
    [ Float(lat_raw), Float(lng_raw) ]
  rescue ArgumentError, TypeError
    [ nil, nil ]
  end

  def valid_coordinate_pair?(lat, lng)
    lat.present? && lng.present? && lat.between?(-90, 90) && lng.between?(-180, 180)
  end

  def daily_write_limit
    ENV.fetch("LISTING_WRITE_DAILY_LIMIT", "5").to_i
  end

  def write_quota_exceeded_for?(user)
    return false if user.blank?

    current_daily_write_count_for(user) >= daily_write_limit
  end

  def increment_daily_write_quota!(user)
    return if user.blank?

    Rails.cache.increment(daily_write_quota_cache_key(user), 1, initial: 0, expires_in: seconds_until_end_of_day)
  end

  def current_daily_write_count_for(user)
    Rails.cache.fetch(daily_write_quota_cache_key(user), expires_in: seconds_until_end_of_day) { 0 }.to_i
  end

  def daily_write_quota_cache_key(user)
    "listing-write-quota:v1:user:#{user.id}:date:#{Time.zone.today.iso8601}"
  end

  def seconds_until_end_of_day
    [ (Time.zone.now.end_of_day - Time.zone.now).ceil, 60 ].max
  end

  def parse_coordinate(value, default:, range:)
    num = Float(value)
    range.cover?(num) ? num : default
  rescue ArgumentError, TypeError
    default
  end
end
