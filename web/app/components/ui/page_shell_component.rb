# frozen_string_literal: true

module Ui
  class PageShellComponent < ApplicationComponent
    def initialize(tag: :div, padding_top: "pt-20", padding_bottom: "pb-24", max_width: "max-w-2xl", horizontal_padding: "px-5", extra_class: nil, **html_options)
      @tag = tag
      @padding_top = padding_top
      @padding_bottom = padding_bottom
      @max_width = max_width
      @horizontal_padding = horizontal_padding
      @extra_class = extra_class
      @html_options = html_options
    end

    def call
      content_tag(@tag, content, **main_attributes)
    end

    private

    def main_attributes
      @html_options.merge(
        class: class_names(
          @padding_top,
          @padding_bottom,
          @horizontal_padding,
          @max_width,
          "mx-auto",
          "w-full",
          @extra_class,
          @html_options[:class]
        )
      )
    end
  end
end
