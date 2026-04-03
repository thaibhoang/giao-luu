# frozen_string_literal: true

module Ui
  class NumberStepperComponent < ApplicationComponent
    def initialize(form: nil, attribute: nil, name: nil, value: 0, min: 0, max: 99, step: 1, **html_options)
      @form = form
      @attribute = attribute
      @name = name
      @value = value
      @min = min
      @max = max
      @step = step
      @html_options = html_options
    end

    attr_reader :form, :attribute, :name, :value, :min, :max, :step

    def field_id
      if @form && @attribute
        "#{@form.object_name}_#{@attribute}"
      elsif @name.present?
        helpers.sanitize_to_id(@name)
      end
    end
  end
end
