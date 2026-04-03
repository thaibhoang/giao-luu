# frozen_string_literal: true

module Ui
  class ButtonComponent < ApplicationComponent
    VALID_VARIANTS = %i[primary secondary ghost dashed link].freeze

    def initialize(label = nil, variant: :primary, type: "button", href: nil, icon: nil, icon_position: :trailing,
                   full_width: false, size_class: "h-14 px-5 text-base", **system_arguments, &block)
      @label = label
      @variant = VALID_VARIANTS.include?(variant.to_sym) ? variant.to_sym : :primary
      @button_type = type
      @href = href
      @icon = icon
      @icon_position = icon_position.to_sym
      @full_width = full_width
      @size_class = size_class
      @system_arguments = system_arguments
      @block = block
    end

    def call
      inner = @block ? capture(&@block) : default_content
      if @href.present?
        link_to inner, @href, **link_attributes
      else
        content_tag(:button, inner, **button_attributes)
      end
    end

    private

    def default_content
      parts = []
      if @icon.present? && @icon_position == :leading
        parts << render(Ui::IconComponent.new(name: @icon, size_class: "text-xl"))
      end
      parts << @label if @label.present?
      if @icon.present? && @icon_position == :trailing
        parts << render(Ui::IconComponent.new(name: @icon, size_class: "text-xl"))
      end
      safe_join(parts.compact)
    end

    def variant_classes
      case @variant
      when :primary
        "bg-primary text-on-primary-container font-lexend font-bold rounded-xl hover:opacity-90 active:scale-[0.98] shadow-xl shadow-black/10"
      when :secondary
        "bg-surface-container-high text-on-surface font-semibold rounded-xl hover:bg-surface-container-highest border border-outline-variant"
      when :ghost
        "bg-transparent text-on-surface-variant font-medium rounded-xl hover:bg-surface-container-low"
      when :dashed
        "bg-surface-container-low border border-dashed border-outline-variant rounded-xl text-sm font-bold text-primary-fixed-dim hover:bg-surface-container"
      when :link
        "bg-transparent text-on-surface-variant font-medium underline-offset-2 hover:text-primary"
      end
    end

    def base_classes
      class_names(
        "inline-flex items-center justify-center gap-2 transition-all",
        @size_class,
        variant_classes,
        @system_arguments[:class],
        "w-full" => @full_width
      )
    end

    def button_attributes
      @system_arguments.except(:class).merge(
        type: @button_type,
        class: base_classes
      )
    end

    def link_attributes
      @system_arguments.except(:class).merge(class: base_classes, role: "button")
    end
  end
end
