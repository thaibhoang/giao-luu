# frozen_string_literal: true

# Thêm cột status vào registrations để implement owner approval workflow:
#   - pending:  mới đăng ký, chờ chủ listing duyệt (default)
#   - accepted: chủ listing đã chấp nhận
#   - rejected: chủ listing từ chối
#
# Dữ liệu cũ (trước feature này) được migrate sang accepted để không mất tương thích.
class AddStatusToRegistrations < ActiveRecord::Migration[8.0]
  def up
    add_column :registrations, :status, :string, default: "pending", null: false

    # Dữ liệu cũ: tất cả registration hiện tại đều coi là accepted
    execute "UPDATE registrations SET status = 'accepted'"
  end

  def down
    remove_column :registrations, :status
  end
end
