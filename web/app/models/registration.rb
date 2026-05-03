# frozen_string_literal: true

class Registration < ApplicationRecord
  CHECKIN_POINTS = 10  # điểm cộng cho mỗi bên khi cả hai confirm

  belongs_to :listing
  belongs_to :user

  validates :listing_id, uniqueness: { scope: :user_id, message: "Bạn đã đăng ký tham gia bài này rồi" }
  validate :cannot_register_own_listing
  validate :listing_must_be_user_submitted

  default_scope { order(created_at: :asc) }

  # ── Check-in helpers ────────────────────────────────────

  # Người tham gia tự xác nhận đã đến (chỉ sau end_at)
  def checkin!
    return false if checked_in_at.present?
    return false unless listing.end_at <= Time.current

    update!(checked_in_at: Time.current)
    try_reward!
    true
  end

  # Chủ listing xác nhận người tham gia đã đến (chỉ sau end_at)
  def owner_confirm!
    return false if owner_confirmed_at.present?
    return false unless listing.end_at <= Time.current

    update!(owner_confirmed_at: Time.current)
    try_reward!
    true
  end

  # Cả hai bên đã confirm chưa?
  def both_confirmed?
    checked_in_at.present? && owner_confirmed_at.present?
  end

  # Đã reward chưa?
  def rewarded?
    rewarded_at.present?
  end

  private

    # Trao +10 điểm cho cả hai bên nếu cả hai đã confirm và chưa từng reward.
    # Dùng transaction để đảm bảo atomic.
    def try_reward!
      return unless both_confirmed?
      return if rewarded?

      ActiveRecord::Base.transaction do
        # +10 cho người tham gia
        ReputationEvent.create!(
          user: user,
          source_type: "Registration",
          source_id: id,
          points_delta: CHECKIN_POINTS,
          reason: ReputationEvent::REASON_CHECKIN_CONFIRMED
        )

        # +10 cho chủ listing
        if listing.user.present? && listing.user_id != user_id
          ReputationEvent.create!(
            user: listing.user,
            source_type: "Registration",
            source_id: id,
            points_delta: CHECKIN_POINTS,
            reason: ReputationEvent::REASON_CHECKIN_CONFIRMED
          )
        end

        update_column(:rewarded_at, Time.current)
      end
    end

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
