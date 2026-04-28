# frozen_string_literal: true

class ChatRoom < ApplicationRecord
  belongs_to :listing
  has_many :messages, dependent: :destroy

  validates :listing_id, uniqueness: true

  # Tạo room nếu chưa có, trả về room hiện tại nếu đã tồn tại.
  def self.find_or_create_for_listing!(listing)
    find_or_create_by!(listing: listing)
  end

  # 50 messages gần nhất, cũ → mới (dùng cho history UI)
  def recent_messages(limit: 50)
    messages.order(created_at: :asc).last(limit)
  end
end
