# frozen_string_literal: true

class ReputationEvent < ApplicationRecord
  REASON_CHECKIN_CONFIRMED = "checkin_confirmed"

  belongs_to :user

  validates :points_delta, numericality: { other_than: 0 }
  validates :reason, presence: true
  validates :source_type, :source_id, presence: true

  scope :for_source, ->(source) {
    where(source_type: source.class.name, source_id: source.id)
  }
end
