# frozen_string_literal: true

# Thêm 2 cột theo dõi trạng thái check-in vào registrations:
#   - checked_in_at: người tham gia tự xác nhận đã đến (nil = chưa check-in)
#   - owner_confirmed_at: chủ listing xác nhận người đó đã đến (nil = chưa confirm)
#
# Khi cả hai cột đều có giá trị → reward reputation_events +10 cho cả hai bên.
class AddCheckinColumnsToRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registrations, :checked_in_at,      :timestamptz, default: nil
    add_column :registrations, :owner_confirmed_at,  :timestamptz, default: nil
    add_column :registrations, :rewarded_at,         :timestamptz, default: nil
  end
end
