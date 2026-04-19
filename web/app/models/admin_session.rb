# frozen_string_literal: true

class AdminSession < ApplicationRecord
  belongs_to :admin_user
end
