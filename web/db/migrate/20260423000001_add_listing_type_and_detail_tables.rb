# frozen_string_literal: true

class AddListingTypeAndDetailTables < ActiveRecord::Migration[8.0]
  def change
    # Thêm cột listing_type vào bảng listings
    add_column :listings, :listing_type, :string, null: false, default: "match_finding"
    add_index  :listings, :listing_type

    # Bảng chi tiết cho loại "Pass sân"
    create_table :court_pass_details do |t|
      t.references :listing, null: false, foreign_key: true, index: { unique: true }
      t.string  :court_name,    null: false
      t.integer :original_price, null: false
      t.integer :pass_price,    null: false
      t.string  :booking_proof  # link / ảnh xác nhận (optional)
      t.timestamps
    end

    # Bảng chi tiết cho loại "Tuyển giải đấu"
    create_table :tournament_details do |t|
      t.references :listing, null: false, foreign_key: true, index: { unique: true }
      t.string   :tournament_name,        null: false
      t.string   :organizer
      t.datetime :registration_deadline,  null: false
      t.string   :format,                 null: false
      t.string   :prize_info
      t.string   :registration_link
      t.timestamps
    end
  end
end
