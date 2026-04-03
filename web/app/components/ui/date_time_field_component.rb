# frozen_string_literal: true

module Ui
  class DateTimeFieldComponent < ApplicationComponent
    BASE_INPUT_CLASS = "w-full h-14 px-4 bg-surface-container-low border-none rounded-xl focus:ring-0 focus:bg-surface-container-lowest transition-all text-sm font-medium text-on-surface"

    def initialize(form:, attribute:, id: nil, error: nil, input_class: nil, **html_options)
      @form = form
      @attribute = attribute
      @id = id
      @error = error
      @input_class = input_class
      @html_options = html_options
    end

    attr_reader :error

    def field_id
      @id || "#{@form.object_name}_#{@attribute}"
    end

    def input_classes
      class_names(BASE_INPUT_CLASS, @input_class, @html_options[:class])
    end
  end
end
