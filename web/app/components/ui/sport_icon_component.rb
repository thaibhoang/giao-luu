# frozen_string_literal: true

module Ui
  class SportIconComponent < ApplicationComponent
    def initialize(sport:, **system_arguments)
      @sport = sport.to_s.downcase
      @system_arguments = system_arguments
    end

    def call
      css = @system_arguments.delete(:class) || "w-5 h-5"
      image_tag asset_path("#{sport_slug}.svg"), class: css, alt: sport_alt
    end

    private

    def sport_slug
      @sport == "pickleball" ? "pickleball" : "badminton"
    end

    def sport_alt
      @sport == "pickleball" ? "Pickleball" : "Cầu lông"
    end
  end
end
