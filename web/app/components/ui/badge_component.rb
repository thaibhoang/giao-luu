# frozen_string_literal: true

module Ui
  class BadgeComponent < ApplicationComponent
    def initialize(text, tone: :neutral, **html_options)
      @text = text
      @tone = tone.to_sym
      @html_options = html_options
    end

    attr_reader :text

    def tone_classes
      case @tone
      when :draft
        "text-on-surface-variant bg-surface-container px-3 py-1 rounded-full"
      when :required
        "text-[10px] font-medium text-on-surface-variant/60 uppercase tracking-wide px-0 py-0 bg-transparent"
      when :optional
        "text-[10px] font-medium text-on-surface-variant/40 italic px-0 py-0 bg-transparent"
      else
        "text-on-surface-variant bg-surface-container-low px-3 py-1 rounded-full"
      end
    end
  end
end
