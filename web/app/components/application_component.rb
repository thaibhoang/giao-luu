# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include Turbo::FramesHelper

  private

  # Rails no longer exposes sanitize_to_id publicly via helpers.
  # Keep id generation consistent for component inputs.
  def sanitize_to_id(value)
    value.to_s.delete("]").tr("^a-zA-Z0-9:.-", "_")
  end
end
