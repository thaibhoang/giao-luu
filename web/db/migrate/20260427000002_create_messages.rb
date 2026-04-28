class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamptz :created_at, null: false, default: -> { "now()" }
    end

    add_index :messages, %i[chat_room_id created_at], name: "index_messages_on_chat_room_id_and_created_at"

    # Max 2000 ký tự theo ADR-005
    add_check_constraint :messages, "char_length(body) <= 2000", name: "messages_body_max_length"
    # Không cho phép body rỗng
    add_check_constraint :messages, "char_length(trim(body)) > 0", name: "messages_body_not_blank"
  end
end
