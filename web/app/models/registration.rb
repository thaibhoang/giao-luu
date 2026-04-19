# frozen_string_literal: true

class Registration < ApplicationRecord
  belongs_to :listing
  belongs_to :user

  validates :listing_id, uniqueness: { scope: :user_id, message: "Bạn đã đăng ký tham gia bài này rồi" }
  validate :cannot_register_own_listing
  validate :listing_must_be_user_submitted

  default_scope { order(created_at: :asc) }

  private

    def cannot_register_own_listing
      return unless listing && user
      return unless listing.user_id == user_id

      errors.add(:base, "Bạn không thể đăng ký tham gia bài đăng của chính mình")
    end

    def listing_must_be_user_submitted
      return unless listing

      unless listing.source == Listing::SOURCE_USER_SUBMITTED
        errors.add(:base, "Bài đăng này không hỗ trợ đăng ký trực tiếp, vui lòng liên hệ qua thông tin bên dưới")
      end
    end
end
