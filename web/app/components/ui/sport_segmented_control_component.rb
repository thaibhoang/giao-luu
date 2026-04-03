# frozen_string_literal: true

module Ui
  class SportSegmentedControlComponent < ApplicationComponent
    def initialize(name:, value:, value_badminton: "badminton", value_pickleball: "pickleball", **html_options)
      @name = name
      @value = value.to_s
      @value_badminton = value_badminton
      @value_pickleball = value_pickleball
      @html_options = html_options
    end

    attr_reader :name, :value, :value_badminton, :value_pickleball
  end
end
