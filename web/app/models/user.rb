# frozen_string_literal: true

class User < ApplicationRecord
  PASSWORD_RESET_EXPIRES_IN = 15.minutes

  GENDERS = %w[male female other prefer_not_to_say].freeze
  SKILL_LEVELS_BADMINTON = %w[beginner intermediate advanced competitive].freeze
  SKILL_LEVELS_PICKLEBALL = %w[2.0-2.5 2.5-3.0 3.0-3.5 3.5-4.0 4.0-4.5 4.5-5.0 5.0+].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :listings, dependent: :nullify
  has_many :registrations, dependent: :destroy

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
