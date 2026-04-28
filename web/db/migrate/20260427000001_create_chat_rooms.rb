class CreateChatRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_rooms do |t|
      t.references :listing, null: false, foreign_key: true
      t.timestamptz :created_at, null: false, default: -> { "now()" }
    end

    add_index :chat_rooms, :listing_id, unique: true, name: "index_chat_rooms_on_listing_id_unique"
  end
end
