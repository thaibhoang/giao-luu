# frozen_string_literal: true

module Ui
  class ListingCardComponent < ApplicationComponent
    def initialize(listing:, show_actions: false, compact: false)
      @listing = listing
      @show_actions = show_actions
      @compact = compact
    end

    attr_reader :listing, :show_actions, :compact
  end
end
