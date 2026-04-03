# frozen_string_literal: true

module Ui
  class FixedBottomBarComponent < ApplicationComponent
    def initialize(blurred: true, with_border: false, inner_class: "max-w-2xl mx-auto", **html_options)
      @blurred = blurred
      @with_border = with_border
      @inner_class = inner_class
      @html_options = html_options
    end

    def call
      content_tag(
        :div,
        content_tag(:div, content, class: @inner_class),
        **bar_attributes
      )
    end

    private

    def bar_attributes
      @html_options.merge(
        class: class_names(
          "fixed bottom-0 left-0 right-0 p-5 z-50",
          @blurred ? "bg-surface/90 backdrop-blur-md" : "bg-surface",
          @with_border ? "border-t border-surface-container-high" : nil,
          @html_options[:class]
        )
      )
    end
  end
end
