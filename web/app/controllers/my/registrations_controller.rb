# frozen_string_literal: true

module My
  class RegistrationsController < ApplicationController
    def index
      @registrations = Current.session.user
                              .registrations
                              .includes(:listing)
                              .order(created_at: :desc)
    end
  end
end
