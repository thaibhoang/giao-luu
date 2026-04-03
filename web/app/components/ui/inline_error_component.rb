# frozen_string_literal: true

module Ui
  class InlineErrorComponent < ApplicationComponent
    def initialize(message, **html_options)
      @message = message
      @html_options = html_options
    end

    attr_reader :message
  end
end
