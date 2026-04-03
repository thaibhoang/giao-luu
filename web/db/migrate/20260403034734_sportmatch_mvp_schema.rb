# frozen_string_literal: true

class SportmatchMvpSchema < ActiveRecord::Migration[8.1]
  def up
    enable_extension "postgis" unless extension_enabled?("postgis")

    create_table :listings do |t|
      t.string :sport, null: false
      t.string :title, null: false
      t.text :body
      t.string :location_name, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.integer :slots_needed, null: false
      t.string :skill_level, null: false
      t.integer :price_estimate
      t.string :contact_info, null: false
      t.string :source, null: false
      t.string :source_url
      t.integer :schema_version, null: false, default: 1

      t.timestamps
    end

    add_check_constraint :listings, "sport IN ('badminton', 'pickleball')", name: "listings_sport_valid"
    # Khớp Listing::SKILL_LEVELS / docs/DATA_MODEL — tránh lệch CHECK so với validation trong cửa sổ migrate.
    add_check_constraint :listings,
                         "skill_level IN ('yeu', 'trung_binh_yeu', 'trung_binh_minus', 'trung_binh', 'trung_binh_plus', 'trung_binh_plus_plus', 'trung_binh_kha', 'kha', 'ban_chuyen', 'chuyen_nghiep')",
                         name: "listings_skill_level_valid"
    add_check_constraint :listings, "slots_needed >= 1", name: "listings_slots_needed_positive"
    add_check_constraint :listings, "end_at >= start_at", name: "listings_time_range_valid"

    execute "ALTER TABLE listings ADD COLUMN geom geography(Point,4326)"
    execute "CREATE INDEX index_listings_on_geom ON listings USING GIST (geom)"

    add_index :listings, :start_at
    add_index :listings, %i[sport start_at]

    execute <<-SQL.squish
      CREATE UNIQUE INDEX index_listings_on_source_url_nonnull
      ON listings (source_url)
      WHERE source_url IS NOT NULL
    SQL

    create_table :geocoding_caches do |t|
      t.string :location_query, null: false
      t.string :provider, null: false, default: "google"
      t.jsonb :raw_response
      t.datetime :created_at, null: false
    end

    add_index :geocoding_caches, :location_query, unique: true

    execute "ALTER TABLE geocoding_caches ADD COLUMN geom geography(Point,4326) NOT NULL"
    execute "CREATE INDEX index_geocoding_caches_on_geom ON geocoding_caches USING GIST (geom)"
  end

  def down
    drop_table :geocoding_caches, if_exists: true
    drop_table :listings, if_exists: true
  end
end
