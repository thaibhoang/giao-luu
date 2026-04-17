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
      sanitize_sql_array([ sql, location_query, provider, raw_response, now, longitude, latitude ])
    ).first
    find(row["id"])
  end

  def self.lookup(query)
    normalized = normalize_query(query)
    return nil if normalized.blank?

    row = where(location_query: normalized).pick(
      :location_query,
      :provider,
      Arel.sql("ST_Y(geom::geometry)"),
      Arel.sql("ST_X(geom::geometry)")
    )
    return nil if row.blank?

    {
      query: row[0],
      provider: row[1],
      lat: row[2].to_f,
      lng: row[3].to_f
    }
  end

  def self.upsert_with_point!(location_query:, provider:, raw_response:, longitude:, latitude:)
    normalized = normalize_query(location_query)
    raise ArgumentError, "location_query is required" if normalized.blank?

    now = Time.current
    sql = <<~SQL.squish
      INSERT INTO geocoding_caches (location_query, provider, raw_response, created_at, geom)
      VALUES (?, ?, CAST(? AS jsonb), ?, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)
      ON CONFLICT (location_query)
      DO UPDATE SET
        provider = EXCLUDED.provider,
        raw_response = EXCLUDED.raw_response,
        created_at = EXCLUDED.created_at,
        geom = EXCLUDED.geom
      RETURNING id
    SQL
    raw_payload = raw_response.is_a?(String) ? raw_response : raw_response.to_json
    row = connection.exec_query(
      sanitize_sql_array([ sql, normalized, provider, raw_payload, now, longitude, latitude ])
    ).first
    find(row["id"])
  end

  def self.normalize_query(query)
    query.to_s.strip.downcase.gsub(/\s+/, " ")
  end
end
