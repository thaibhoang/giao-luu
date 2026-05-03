# frozen_string_literal: true

class User < ApplicationRecord
  PASSWORD_RESET_EXPIRES_IN = 15.minutes

  GENDERS = %w[male female other prefer_not_to_say].freeze
  SKILL_LEVELS_BADMINTON = %w[beginner intermediate advanced competitive].freeze
  SKILL_LEVELS_PICKLEBALL = %w[dupr_2_0 dupr_2_5 dupr_3_0 dupr_3_5 dupr_4_0 dupr_4_5 dupr_5_0].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :listings, dependent: :nullify
  has_many :registrations, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_listings, through: :bookmarks, source: :listing
  has_many :reputation_events, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :display_name, length: { maximum: 60 }, allow_blank: true
  validates :phone_number, length: { maximum: 20 }, allow_blank: true
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :gender, inclusion: { in: GENDERS }, allow_blank: true
  validates :skill_level_badminton, inclusion: { in: SKILL_LEVELS_BADMINTON }, allow_blank: true
  validates :skill_level_pickleball, inclusion: { in: SKILL_LEVELS_PICKLEBALL }, allow_blank: true

  def profile_complete?
    display_name.present? && phone_number.present?
  end

  def name_or_email
    display_name.presence || email_address.split("@").first
  end

  # Tổng điểm uy tín — SUM của tất cả reputation_events.
  # Trả về 0 nếu chưa có event nào.
  def reputation_points
    reputation_events.sum(:points_delta)
  end

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_EXPIRES_IN do
    password_digest&.last(10)
  end

  def password_reset_token
    generate_token_for(:password_reset)
  end

  def password_reset_token_expires_in
    self.class::PASSWORD_RESET_EXPIRES_IN
  end

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_EXPIRES_IN do
    password_digest&.last(10)
  end

  def password_reset_token
    generate_token_for(:password_reset)
  end
end
