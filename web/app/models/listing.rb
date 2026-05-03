# frozen_string_literal: true

class Listing < ApplicationRecord
  SPORTS = %w[badminton pickleball].freeze

  # ── Cầu lông — thang điểm nội bộ ────────────────────────
  # Slug lưu DB / API / LLM; nhãn hiển thị — SKILL_LEVEL_LABELS
  SKILL_LEVELS = %w[
    yeu
    trung_binh_yeu
    trung_binh_minus
    trung_binh
    trung_binh_plus
    trung_binh_plus_plus
    trung_binh_kha
    kha
    ban_chuyen
    chuyen_nghiep
  ].freeze

  SKILL_LEVEL_LABELS = {
    "yeu" => "Yếu",
    "trung_binh_yeu" => "Trung bình yếu",
    "trung_binh_minus" => "Trung bình -",
    "trung_binh" => "Trung bình",
    "trung_binh_plus" => "Trung bình +",
    "trung_binh_plus_plus" => "Trung bình ++",
    "trung_binh_kha" => "Trung bình khá",
    "kha" => "Khá",
    "ban_chuyen" => "Bán chuyên",
    "chuyen_nghiep" => "Chuyên nghiệp"
  }.freeze
  SKILL_LEVEL_INDEX = SKILL_LEVELS.each_with_index.to_h.freeze

  # ── Pickleball — thang DUPR ───────────────────────────
  SKILL_LEVELS_PK = %w[
    dupr_2_0
    dupr_2_5
    dupr_3_0
    dupr_3_5
    dupr_4_0
    dupr_4_5
    dupr_5_0
  ].freeze

  SKILL_LEVEL_PK_LABELS = {
    "dupr_2_0" => "2.0–2.5 · Mới bắt đầu",
    "dupr_2_5" => "2.5–3.0 · Cơ bản",
    "dupr_3_0" => "3.0–3.5 · Trung cấp thấp",
    "dupr_3_5" => "3.5–4.0 · Trung cấp",
    "dupr_4_0" => "4.0–4.5 · Trung cấp cao",
    "dupr_4_5" => "4.5–5.0 · Nâng cao",
    "dupr_5_0" => "5.0+ · Chuyên nghiệp"
  }.freeze
  SKILL_LEVEL_PK_INDEX = SKILL_LEVELS_PK.each_with_index.to_h.freeze

  SOURCE_USER_SUBMITTED = "user_submitted"
  SOURCE_FACEBOOK_SCRAPE = "facebook_scrape"

  LISTING_TYPES = %w[match_finding court_pass tournament].freeze
  LISTING_TYPE_LABELS = {
    "match_finding" => "Tuyển giao lưu",
    "court_pass"    => "Pass sân",
    "tournament"    => "Tuyển giải đấu"
  }.freeze
  LISTING_TYPE_BADGES = {
    "match_finding" => "green",
    "court_pass"    => "orange",
    "tournament"    => "purple"
  }.freeze

  GENDER_REQUIREMENTS = %w[any male female mixed].freeze
  GENDER_REQUIREMENT_LABELS = {
    "any"    => "Không giới hạn",
    "male"   => "Nam",
    "female" => "Nữ",
    "mixed"  => "Nam & Nữ"
  }.freeze

  PLAY_FORMATS = %w[singles doubles both].freeze
  PLAY_FORMAT_LABELS = {
    "singles" => "Đánh đơn",
    "doubles" => "Đánh đôi",
    "both"    => "Đơn & Đôi"
  }.freeze

  belongs_to :user, optional: true
  has_many :registrations, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_one  :court_pass_detail, dependent: :destroy
  has_one  :tournament_detail, dependent: :destroy

  accepts_nested_attributes_for :court_pass_detail, update_only: true, reject_if: :all_blank
  accepts_nested_attributes_for :tournament_detail, update_only: true, reject_if: :all_blank

  validates :sport, inclusion: { in: SPORTS }
  validates :skill_level_min, :skill_level_max, inclusion: { in: SKILL_LEVELS }, unless: -> { court_pass? || pickleball? }
  validates :skill_level_min_pk, :skill_level_max_pk, inclusion: { in: SKILL_LEVELS_PK }, unless: -> { court_pass? || !pickleball? }, allow_nil: true
  validates :title, :location_name, :contact_info, :source, presence: true
  validates :listing_type, inclusion: { in: LISTING_TYPES }
  validates :gender_requirement, inclusion: { in: GENDER_REQUIREMENTS }, allow_nil: true
  validates :play_format, inclusion: { in: PLAY_FORMATS }, allow_nil: true
  validate  :play_format_not_for_court_pass
  validates :slots_needed, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, unless: :court_pass?
  validates :schema_version, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :end_at_not_before_start_at
  validate :user_present_for_user_submitted
  validate :skill_level_range_order
  validate :detail_record_present

  def match_finding? = listing_type == "match_finding"
  def court_pass?    = listing_type == "court_pass"
  def tournament?    = listing_type == "tournament"
  def pickleball?    = sport == "pickleball"

  def listing_type_label
    LISTING_TYPE_LABELS.fetch(listing_type, listing_type)
  end

  def gender_requirement_label
    GENDER_REQUIREMENT_LABELS.fetch(gender_requirement, gender_requirement)
  end

  def play_format_label
    PLAY_FORMAT_LABELS.fetch(play_format, play_format)
  end

  # Tin đang active và thời điểm bắt đầu >= hiện tại — scope mặc định cho trang chủ/bản đồ
  scope :upcoming, -> { where(active: true).where("start_at >= ?", Time.current) }
  scope :with_geom, -> { where.not(geom: nil) }
  scope :by_sport, ->(sport) { sport.present? ? where(sport:) : all }
  scope :by_listing_type, ->(type) { type.present? ? where(listing_type: type) : all }
  scope :from_time, ->(from) { from.present? ? where("start_at >= ?", from) : all }
  scope :to_time, ->(to) { to.present? ? where("start_at <= ?", to) : all }
  scope :by_keyword, ->(q) {
    return all if q.blank?
    pattern = "%#{sanitize_sql_like(q)}%"
    where("title ILIKE ? OR location_name ILIKE ?", pattern, pattern)
  }
  scope :by_gender, ->(g) { g.present? ? where(gender_requirement: g) : all }
  scope :by_play_format, ->(pf) { pf.present? ? where(play_format: pf) : all }
  # Tìm listing có skill_level_max >= slug (listing chấp nhận trình độ tối thiểu slug)
  scope :skill_min_filter, ->(slug) {
    return all if slug.blank? || !SKILL_LEVEL_INDEX.key?(slug)
    where(skill_level_max: SKILL_LEVELS[SKILL_LEVEL_INDEX[slug]..])
  }
  # Tìm listing có skill_level_min <= slug (listing chấp nhận trình độ tối đa slug)
  scope :skill_max_filter, ->(slug) {
    return all if slug.blank? || !SKILL_LEVEL_INDEX.key?(slug)
    where(skill_level_min: SKILL_LEVELS[0..SKILL_LEVEL_INDEX[slug]])
  }
  # Pickleball DUPR — tương tự nhưng dùng cột skill_level_min/max_pk
  scope :skill_min_filter_pk, ->(slug) {
    return all if slug.blank? || !SKILL_LEVEL_PK_INDEX.key?(slug)
    where(skill_level_max_pk: SKILL_LEVELS_PK[SKILL_LEVEL_PK_INDEX[slug]..])
  }
  scope :skill_max_filter_pk, ->(slug) {
    return all if slug.blank? || !SKILL_LEVEL_PK_INDEX.key?(slug)
    where(skill_level_min_pk: SKILL_LEVELS_PK[0..SKILL_LEVEL_PK_INDEX[slug]])
  }
  # Tìm listing trong bán kính radius_meters (mét) tính từ tọa độ (lat, lng).
  # Dùng ST_DWithin trên cột geography — chính xác theo khoảng cách mặt đất.
  # ST_MakePoint nhận (longitude, latitude).
  scope :near_point, ->(lat, lng, radius_meters) {
    where(
      "ST_DWithin(geom, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
      lng, lat, radius_meters
    )
  }

  def self.skill_label_for(slug)
    SKILL_LEVEL_LABELS.fetch(slug, SKILL_LEVEL_PK_LABELS.fetch(slug, slug))
  end

  def self.skill_label_for_sport(slug, sport)
    if sport == "pickleball"
      SKILL_LEVEL_PK_LABELS.fetch(slug, slug)
    else
      SKILL_LEVEL_LABELS.fetch(slug, slug)
    end
  end

  def self.skill_range_label_for(min_slug, max_slug, sport = "badminton")
    return "" if min_slug.blank? || max_slug.blank?
    min_label = skill_label_for_sport(min_slug, sport)
    max_label = skill_label_for_sport(max_slug, sport)
    return min_label if min_slug == max_slug

    "#{min_label} - #{max_label}"
  end

  def skill_range_label
    if pickleball?
      self.class.skill_range_label_for(skill_level_min_pk, skill_level_max_pk, "pickleball")
    else
      self.class.skill_range_label_for(skill_level_min, skill_level_max, "badminton")
    end
  end

  def self.within_radius(lat:, lng:, radius_meters:)
    where(
      sanitize_sql_array(
        [
          "geom IS NOT NULL AND ST_DWithin(geom, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
          lng, lat, radius_meters
        ]
      )
    )
  end

  def self.map_rows_for(sport: nil, listing_type: nil, from: nil, to: nil, q: nil, skill_min: nil, skill_max: nil, lat: nil, lng: nil, radius_meters: nil, gender: nil, play_format: nil)
    is_pickleball = sport == "pickleball"
    rel = with_geom
            .where(active: true)
            .by_sport(sport)
            .by_listing_type(listing_type)
            .from_time(from || Time.current)
            .to_time(to)
            .by_keyword(q)
            .by_gender(gender)
            .by_play_format(play_format)
    rel = if is_pickleball
            rel.skill_min_filter_pk(skill_min).skill_max_filter_pk(skill_max)
    else
            rel.skill_min_filter(skill_min).skill_max_filter(skill_max)
    end
    rel = rel.within_radius(lat:, lng:, radius_meters:) if lat && lng && radius_meters
    rel.select(
      "id, sport, listing_type, title, location_name, start_at, end_at, " \
      "skill_level_min, skill_level_max, skill_level_min_pk, skill_level_max_pk, " \
      "price_estimate, source, gender_requirement, play_format, " \
      "ST_Y(geom::geometry) AS lat, ST_X(geom::geometry) AS lng"
    )
  end

  # geography(Point,4326) is not mapped by ActiveRecord (ADR-004); use SQL for writes.
  def self.insert_with_point!(attributes, longitude:, latitude:)
    cols = %i[
      sport listing_type title body location_name start_at end_at slots_needed skill_level_min skill_level_max
      skill_level_min_pk skill_level_max_pk
      price_estimate contact_info source source_url schema_version user_id gender_requirement play_format
      active created_at updated_at
    ]
    now = Time.current
    h = attributes.symbolize_keys.reverse_merge(created_at: now, updated_at: now, user_id: nil, active: true)
    values = cols.map { |c| h[c] }
    placeholders = ([ "?" ] * cols.size).join(", ")
    sql = <<~SQL.squish
      INSERT INTO listings (#{cols.join(", ")}, geom)
      VALUES (#{placeholders}, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)
      RETURNING id
    SQL
    binds = values + [ longitude, latitude ]
    row = connection.exec_query(sanitize_sql_array([ sql, *binds ])).first
    find(row["id"])
  end

  def self.update_with_point!(id:, attributes:, longitude:, latitude:)
    cols = %i[
      sport listing_type title body location_name start_at end_at slots_needed skill_level_min skill_level_max
      skill_level_min_pk skill_level_max_pk
      price_estimate contact_info source source_url schema_version user_id gender_requirement play_format
      active updated_at
    ]
    now = Time.current
    h = attributes.symbolize_keys.merge(updated_at: now)
    assignments = cols.map { |c| "#{c} = ?" }.join(", ")
    sql = <<~SQL.squish
      UPDATE listings
      SET #{assignments}, geom = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
      WHERE id = ?
    SQL
    binds = cols.map { |c| h[c] } + [ longitude, latitude, id ]
    connection.exec_update(sanitize_sql_array([ sql, *binds ]), "Listing Update", [])
    find(id)
  end

  private

  def end_at_not_before_start_at
    return if start_at.blank? || end_at.blank?

    errors.add(:end_at, :invalid) if end_at < start_at
  end

  def user_present_for_user_submitted
    return unless source == SOURCE_USER_SUBMITTED

    errors.add(:user, :blank) if user_id.blank?
  end

  def skill_level_range_order
    return if court_pass?

    if pickleball?
      return if skill_level_min_pk.blank? || skill_level_max_pk.blank?

      min_index = SKILL_LEVEL_PK_INDEX[skill_level_min_pk]
      max_index = SKILL_LEVEL_PK_INDEX[skill_level_max_pk]
      return if min_index.nil? || max_index.nil?
      return if min_index <= max_index

      errors.add(:skill_level_max_pk, "phải lớn hơn hoặc bằng mức bắt đầu")
    else
      return if skill_level_min.blank? || skill_level_max.blank?

      min_index = SKILL_LEVEL_INDEX[skill_level_min]
      max_index = SKILL_LEVEL_INDEX[skill_level_max]
      return if min_index.nil? || max_index.nil?
      return if min_index <= max_index

      errors.add(:skill_level_max, "phải lớn hơn hoặc bằng mức bắt đầu")
    end
  end

  def detail_record_present
    case listing_type
    when "court_pass"
      if court_pass_detail.nil? || court_pass_detail.marked_for_destruction?
        errors.add(:base, "Vui lòng điền thông tin Pass sân")
      end
    when "tournament"
      if tournament_detail.nil? || tournament_detail.marked_for_destruction?
        errors.add(:base, "Vui lòng điền thông tin giải đấu")
      end
    end
  end

  def play_format_not_for_court_pass
    return unless court_pass?
    return if play_format.blank?

    errors.add(:play_format, "không áp dụng cho loại tin Pass sân")
  end
end
