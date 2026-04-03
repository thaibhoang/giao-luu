# frozen_string_literal: true

module Ui
  class FieldLabelComponent < ApplicationComponent
    def initialize(text, for_id: nil, required_badge: false, optional_badge: false, uppercase: true, wrapper_class: nil, **html_options)
      @text = text
      @for_id = for_id
      @required_badge = required_badge
      @optional_badge = optional_badge
      @uppercase = uppercase
      @wrapper_class = wrapper_class
      @html_options = html_options
    end

    attr_reader :text, :for_id, :wrapper_class
  end
end
