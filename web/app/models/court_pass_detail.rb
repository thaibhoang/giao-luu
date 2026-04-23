# frozen_string_literal: true

class CourtPassDetail < ApplicationRecord
  FORMATS = [].freeze # không dùng format cho loại này

  belongs_to :listing

  validates :court_name,    presence: true
  validates :original_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :pass_price,    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
