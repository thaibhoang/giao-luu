# frozen_string_literal: true

module Ui
  class TextAreaFieldComponent < ApplicationComponent
    BASE_TEXTAREA_CLASS = "w-full px-5 py-4 bg-surface-container-low border-none rounded-xl focus:ring-0 focus:bg-surface-container-lowest transition-all text-on-surface font-medium placeholder:text-outline-variant"

    def initialize(form:, attribute:, rows: 4, placeholder: nil, id: nil, error: nil, input_class: nil, **html_options)
      @form = form
      @attribute = attribute
      @rows = rows
      @placeholder = placeholder
      @id = id
      @error = error
      @input_class = input_class
      @html_options = html_options
    end

    attr_reader :rows, :error

    def field_id
      @id || "#{@form.object_name}_#{@attribute}"
    end

    def input_classes
      class_names(BASE_TEXTAREA_CLASS, @input_class, @html_options[:class])
    end
  end
end
