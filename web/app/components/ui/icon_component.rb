# frozen_string_literal: true

module Ui
  class IconComponent < ApplicationComponent
    attr_reader :name, :data_icon

    def initialize(name:, filled: false, size_class: "text-2xl", data_icon: nil, **system_arguments)
      @name = name
      @filled = filled
      @size_class = size_class
      @data_icon = data_icon || name
      @system_arguments = system_arguments
    end

    def icon_classes
      class_names(
        "material-symbols-outlined",
        @size_class,
        @system_arguments[:class],
        "material-symbols-outlined--filled" => @filled
      )
    end

    def extra_attributes
      @system_arguments.except(:class)
    end
  end
end
