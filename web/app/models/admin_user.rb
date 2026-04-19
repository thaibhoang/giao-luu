# frozen_string_literal: true

class AdminUser < ApplicationRecord
  has_secure_password
  has_many :admin_sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
end
