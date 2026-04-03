# frozen_string_literal: true

module Ui
  class EmptyStateComponent < ApplicationComponent
    def initialize(title:, description:, primary_label:, primary_href: nil, secondary_label: nil, secondary_href: nil, **html_options)
      @title = title
      @description = description
      @primary_label = primary_label
      @primary_href = primary_href
      @secondary_label = secondary_label
      @secondary_href = secondary_href
      @html_options = html_options
    end

    attr_reader :title, :description, :primary_label, :primary_href, :secondary_label, :secondary_href
  end
end
