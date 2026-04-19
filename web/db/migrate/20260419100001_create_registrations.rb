# frozen_string_literal: true

class CreateRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :registrations do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :note
      t.string :phone

      t.timestamps
    end

    add_index :registrations, %i[listing_id user_id], unique: true
  end
end
