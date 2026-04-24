# frozen_string_literal: true

module My
  class BookmarksController < ApplicationController
    def index
      @bookmarks = Current.session.user
                          .bookmarks
                          .includes(:listing)
                          .order(created_at: :desc)
      @listings = @bookmarks.map(&:listing)
    end
  end
end
