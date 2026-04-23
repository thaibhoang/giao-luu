# frozen_string_literal: true

class TournamentDetail < ApplicationRecord
  FORMATS = %w[singles mens_doubles womens_doubles mixed_doubles team].freeze
  FORMAT_LABELS = {
    "singles"         => "Đơn",
    "mens_doubles"    => "Đôi nam",
    "womens_doubles"  => "Đôi nữ",
    "mixed_doubles"   => "Đôi nam nữ",
    "team"            => "Đồng đội"
  }.freeze

  belongs_to :listing

  validates :tournament_name,       presence: true
  validates :registration_deadline, presence: true
  validates :format, inclusion: { in: FORMATS }
end
