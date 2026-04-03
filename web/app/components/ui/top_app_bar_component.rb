# frozen_string_literal: true

module Ui
  class TopAppBarComponent < ApplicationComponent
    renders_one :trailing

    def initialize(title:, back_href: nil, back_icon: "arrow_back", html_class: nil, **html_options)
      @title = title
      @back_href = back_href
      @back_icon = back_icon
      @html_class = html_class
      @html_options = html_options
    end

    attr_reader :title, :back_href, :back_icon, :html_class, :html_options
  end
end
