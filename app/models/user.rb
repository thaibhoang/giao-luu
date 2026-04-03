# frozen_string_literal: true

class User < ApplicationRecord
  PASSWORD_RESET_EXPIRES_IN = 15.minutes

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :listings, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_EXPIRES_IN do
    password_digest&.last(10)
  end

  def password_reset_token
    generate_token_for(:password_reset)
  end

  def password_reset_token_expires_in
    self.class::PASSWORD_RESET_EXPIRES_IN
  end
end
