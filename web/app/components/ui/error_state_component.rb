# frozen_string_literal: true

module Ui
  class ErrorStateComponent < ApplicationComponent
    def initialize(
      title:,
      headline:,
      description:,
      status_badge: "Lỗi",
      primary_label: nil,
      primary_href: nil,
      primary_icon: "map",
      **html_options
    )
      @title = title
      @headline = headline
      @description = description
      @status_badge = status_badge
      @primary_label = primary_label
      @primary_href = primary_href
      @primary_icon = primary_icon
      @html_options = html_options
    end

    attr_reader :title, :headline, :description, :status_badge, :primary_label, :primary_href, :primary_icon
  end
end
