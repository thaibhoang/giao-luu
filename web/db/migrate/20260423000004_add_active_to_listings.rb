# frozen_string_literal: true

class AddActiveToListings < ActiveRecord::Migration[8.0]
  def up
    add_column :listings, :active, :boolean, null: false, default: true

    # Drop các index cũ sẽ được thay bằng partial index (WHERE active = true)
    remove_index :listings, name: "index_listings_on_sport_and_start_at"
    remove_index :listings, name: "index_listings_on_start_at"
    remove_index :listings, name: "index_listings_on_listing_type"

    # Composite partial index: lọc sport + thời gian (query phổ biến nhất: home/map)
    # Thứ tự: sport trước (equality filter) → start_at range sau
    add_index :listings,
              %i[sport start_at],
              where: "active = true",
              name: "idx_listings_active_sport_start"

    # Composite partial index: lọc listing_type + thời gian
    add_index :listings,
              %i[listing_type start_at],
              where: "active = true",
              name: "idx_listings_active_type_start"
  end

  def down
    remove_index :listings, name: "idx_listings_active_sport_start"
    remove_index :listings, name: "idx_listings_active_type_start"

    add_index :listings, %i[sport start_at], name: "index_listings_on_sport_and_start_at"
    add_index :listings, :start_at,          name: "index_listings_on_start_at"
    add_index :listings, :listing_type,      name: "index_listings_on_listing_type"

    remove_column :listings, :active
  end
end
