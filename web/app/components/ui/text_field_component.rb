# frozen_string_literal: true

module Ui
  class TextFieldComponent < ApplicationComponent
    BASE_INPUT_CLASS = "w-full h-14 px-5 bg-surface-container-low border-none rounded-xl focus:ring-0 focus:bg-surface-container-lowest transition-all text-on-surface font-medium placeholder:text-outline-variant"

    def initialize(form: nil, attribute: nil, name: nil, value: nil, type: "text", placeholder: nil, id: nil, icon: nil, icon_position: :leading, error: nil, input_class: nil, **html_options)
      @form = form
      @attribute = attribute
      @name = name
      @value = value
      @type = type
      @placeholder = placeholder
      @explicit_id = id
      @icon = icon
      @icon_position = icon_position.to_sym
      @error = error
      @input_class = input_class
      @html_options = html_options
    end

    attr_reader :form, :attribute, :placeholder, :icon, :icon_position, :error

    def field_id
      @explicit_id.presence || generate_field_id
    end

    def input_classes
      class_names(
        BASE_INPUT_CLASS,
        ("pl-12" if @icon.present? && @icon_position == :leading),
        ("pr-12" if @icon.present? && @icon_position == :trailing),
        @input_class,
        @html_options[:class]
      )
    end

    private

    def generate_field_id
      if @form && @attribute
        "#{@form.object_name}_#{@attribute}"
      elsif @name.present?
        helpers.sanitize_to_id(@name)
      end
    end
  end
end
