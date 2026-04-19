# frozen_string_literal: true

module Admin
  module FacebookImportsHelper
    # Parse ISO 8601 string → "YYYY-MM-DDTHH:MM" cho input datetime-local.
    # Trả về chuỗi rỗng nếu không parse được.
    def format_datetime_local(value)
      return "" if value.blank?
      Time.parse(value.to_s).strftime("%Y-%m-%dT%H:%M")
    rescue ArgumentError, TypeError
      ""
    end
  end
end
