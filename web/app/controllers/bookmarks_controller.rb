# frozen_string_literal: true

class BookmarksController < ApplicationController
  before_action :set_listing

  # POST /listings/:listing_id/bookmark
  def create
    @bookmark = @listing.bookmarks.find_or_initialize_by(user: Current.session.user)
    @bookmark.save unless @bookmark.persisted?
    @bookmarked = true

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @listing }
    end
  end

  # DELETE /listings/:listing_id/bookmark
  def destroy
    @listing.bookmarks.find_by(user: Current.session.user)&.destroy
    @bookmarked = false

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: @listing }
    end
  end

  private

    def set_listing
      @listing = Listing.find(params[:listing_id])
    end
end
