# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  default_scope { order(created_at: :asc) }
end
