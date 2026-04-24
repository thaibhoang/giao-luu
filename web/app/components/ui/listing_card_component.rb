# frozen_string_literal: true

module Ui
  class ListingCardComponent < ApplicationComponent
    def initialize(listing:, show_actions: false, compact: false, bookmarked: false, current_user: nil)
      @listing = listing
      @show_actions = show_actions
      @compact = compact
      @bookmarked = bookmarked
      @current_user = current_user
    end

    attr_reader :listing, :show_actions, :compact, :bookmarked, :current_user
  end
end
