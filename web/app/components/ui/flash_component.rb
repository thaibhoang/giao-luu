# frozen_string_literal: true

module Ui
  class FlashComponent < ApplicationComponent
    def initialize(type:, message:)
      @raw_type = type.to_s
      @message = message
    end

    attr_reader :message

    def variant
      case @raw_type
      when "notice", "success", "alert"
        @raw_type == "alert" ? :alert : :notice
      else
        :neutral
      end
    end

    def box_classes
      case variant
      when :notice
        "bg-secondary-container/90 text-on-secondary-container border border-secondary-fixed-dim/40"
      when :alert
        "bg-error-container text-on-error-container border border-error/30"
      else
        "bg-surface-container-high text-on-surface border border-outline-variant"
      end
    end
  end
end
