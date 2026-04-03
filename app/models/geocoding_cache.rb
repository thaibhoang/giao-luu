# frozen_string_literal: true

class GeocodingCache < ApplicationRecord
  self.table_name = "geocoding_caches"

  validates :location_query, presence: true, uniqueness: true
  validates :provider, presence: true

  def self.insert_with_point!(location_query:, provider: "google", raw_response: nil, longitude:, latitude:)
    now = Time.current
    sql = <<~SQL.squish
      INSERT INTO geocoding_caches (location_query, provider, raw_response, created_at, geom)
      VALUES (?, ?, CAST(? AS jsonb), ?, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)
      RETURNING id
    SQL
    row = connection.exec_query(
      sanitize_sql_array([sql, location_query, provider, raw_response, now, longitude, latitude])
    ).first
    find(row["id"])
  end
end
