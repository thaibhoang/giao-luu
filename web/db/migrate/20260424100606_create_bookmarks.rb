class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamptz :created_at, null: false, default: -> { "now()" }
    end

    add_index :bookmarks, %i[listing_id user_id], unique: true
  end
end
