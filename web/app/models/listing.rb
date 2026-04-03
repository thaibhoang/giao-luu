# frozen_string_literal: true

class Listing < ApplicationRecord
  SPORTS = %w[badminton pickleball].freeze

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

  SOURCE_USER_SUBMITTED = "user_submitted"
  SOURCE_FACEBOOK_SCRAPE = "facebook_scrape"

  belongs_to :user, optional: true

  validates :sport, inclusion: { in: SPORTS }
  validates :skill_level, inclusion: { in: SKILL_LEVELS }
  validates :title, :location_name, :contact_info, :source, presence: true
  validates :slots_needed, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :schema_version, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validate :end_at_not_before_start_at
  validate :user_present_for_user_submitted

  scope :with_geom, -> { where.not(geom: nil) }
  scope :by_sport, ->(sport) { sport.present? ? where(sport:) : all }
  scope :from_time, ->(from) { from.present? ? where("start_at >= ?", from) : all }
  scope :to_time, ->(to) { to.present? ? where("start_at <= ?", to) : all }

  def self.skill_label_for(slug)
    SKILL_LEVEL_LABELS.fetch(slug, slug)
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

  def self.map_rows_for(lat:, lng:, radius_meters:, sport: nil, from: nil, to: nil)
    rel = within_radius(lat:, lng:, radius_meters:).by_sport(sport).from_time(from).to_time(to)
    rel.select(
      "id, sport, title, location_name, start_at, end_at, skill_level, price_estimate, source, "\
      "ST_Y(geom::geometry) AS lat, ST_X(geom::geometry) AS lng"
    )
  end

  # geography(Point,4326) is not mapped by ActiveRecord (ADR-004); use SQL for writes.
  def self.insert_with_point!(attributes, longitude:, latitude:)
    cols = %i[
      sport title body location_name start_at end_at slots_needed skill_level
      price_estimate contact_info source source_url schema_version user_id
      created_at updated_at
    ]
    now = Time.current
    h = attributes.symbolize_keys.reverse_merge(created_at: now, updated_at: now, user_id: nil)
    values = cols.map { |c| h[c] }
    placeholders = (["?"] * cols.size).join(", ")
    sql = <<~SQL.squish
      INSERT INTO listings (#{cols.join(", ")}, geom)
      VALUES (#{placeholders}, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)
      RETURNING id
    SQL
    binds = values + [longitude, latitude]
    row = connection.exec_query(sanitize_sql_array([sql, *binds])).first
    find(row["id"])
  end

  def self.update_with_point!(id:, attributes:, longitude:, latitude:)
    cols = %i[
      sport title body location_name start_at end_at slots_needed skill_level
      price_estimate contact_info source source_url schema_version user_id
      updated_at
    ]
    now = Time.current
    h = attributes.symbolize_keys.merge(updated_at: now)
    assignments = cols.map { |c| "#{c} = ?" }.join(", ")
    sql = <<~SQL.squish
      UPDATE listings
      SET #{assignments}, geom = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
      WHERE id = ?
    SQL
    binds = cols.map { |c| h[c] } + [longitude, latitude, id]
    connection.exec_update(sanitize_sql_array([sql, *binds]), "Listing Update", [])
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
end
