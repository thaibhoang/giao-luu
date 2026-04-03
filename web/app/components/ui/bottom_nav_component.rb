# frozen_string_literal: true

module Ui
  class BottomNavComponent < ApplicationComponent
    def initialize(items:, **html_options)
      @items = items
      @html_options = html_options
    end

    attr_reader :items
  end
end
