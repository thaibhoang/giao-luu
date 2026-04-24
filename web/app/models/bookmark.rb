# frozen_string_literal: true

class Bookmark < ApplicationRecord
  belongs_to :listing
  belongs_to :user

  validates :listing_id, uniqueness: { scope: :user_id, message: "đã được lưu" }
end
