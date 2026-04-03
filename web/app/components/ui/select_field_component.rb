# frozen_string_literal: true

module Ui
  class SelectFieldComponent < ApplicationComponent
    BASE_SELECT_CLASS = "w-full h-14 pl-12 pr-10 bg-surface-container-low border-none rounded-xl focus:ring-0 text-sm font-semibold ui-select-native text-on-surface"

    def initialize(form: nil, attribute: nil, name: nil, choices: [], selected: nil, include_blank: nil, id: nil, icon: "trending_up", **html_options)
      @form = form
      @attribute = attribute
      @name = name
      @choices = choices
      @selected = selected
      @include_blank = include_blank
      @id = id
      @icon = icon
      @html_options = html_options
    end

    attr_reader :form, :attribute, :choices, :icon, :selected, :include_blank

    def field_id
      @id || (@form && @attribute ? "#{@form.object_name}_#{@attribute}" : nil)
    end

    def select_classes
      class_names(BASE_SELECT_CLASS, @html_options[:class])
    end
  end
end
