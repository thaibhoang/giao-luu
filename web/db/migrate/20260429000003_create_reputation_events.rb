# frozen_string_literal: true

# Bảng reputation_events lưu lịch sử thay đổi điểm uy tín của user.
#
# - source_type / source_id: polymorphic FK — hiện tại "Registration" nhưng
#   có thể mở rộng sau (vd. "Listing" khi bị hủy không báo trước → trừ điểm)
# - points_delta: số điểm thay đổi (dương = cộng, âm = trừ)
# - reason: slug ngắn mô tả lý do (vd. "checkin_confirmed", "listing_cancelled")
#
# User#reputation_points = SUM(points_delta) WHERE user_id = ?
class CreateReputationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reputation_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :source_type, null: false
      t.bigint  :source_id,   null: false
      t.integer :points_delta, null: false
      t.string  :reason,       null: false

      t.timestamps
    end

    add_index :reputation_events, %i[source_type source_id]

    add_check_constraint :reputation_events,
      "points_delta != 0",
      name: "reputation_events_points_delta_nonzero"
  end
end
