# frozen_string_literal: true

module Ui
  class FormErrorSummaryComponent < ApplicationComponent
    def initialize(record:, title: "Không thể lưu biểu mẫu")
      @record = record
      @title = title
    end

    attr_reader :record, :title
  end
end
