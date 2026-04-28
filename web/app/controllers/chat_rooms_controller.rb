# frozen_string_literal: true

# ChatRoomsController — upsert room cho listing, load lịch sử messages.
# GET /listings/:listing_id/chat_room
class ChatRoomsController < ApplicationController
  before_action :require_authentication
  before_action :set_listing

  def show
    @room = ChatRoom.find_or_create_for_listing!(@listing)
    @messages = @room.recent_messages(limit: 50)
  end

  private

    def set_listing
      @listing = Listing.find(params[:listing_id])
    end
end
