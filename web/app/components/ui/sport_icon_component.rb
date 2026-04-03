# frozen_string_literal: true

module Ui
  class SportIconComponent < ApplicationComponent
    BADMINTON_ICON = "sports_tennis"
    PICKLEBALL_ICON = "sports_handball"

    def initialize(sport:, **system_arguments)
      @sport = sport
      @system_arguments = system_arguments
    end

    def call
      render Ui::IconComponent.new(name: icon_name, **@system_arguments)
    end

    private

    def icon_name
      case @sport.to_s.downcase
      when "pickleball"
        PICKLEBALL_ICON
      else
        BADMINTON_ICON
      end
    end
  end
end
