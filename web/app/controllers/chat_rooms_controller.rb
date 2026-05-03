# frozen_string_literal: true

# ChatRoomsController — upsert room cho listing, load lịch sử messages.
# GET /listings/:listing_id/chat_room
# Chỉ chủ listing và người đã được accepted mới vào được.
class ChatRoomsController < ApplicationController
  before_action :require_authentication
  before_action :set_listing
  before_action :require_access

  def show
    @room = ChatRoom.find_or_create_for_listing!(@listing)
    @messages = @room.recent_messages(limit: 50)
  end

  private

    def set_listing
      @listing = Listing.find(params[:listing_id])
    end

    def require_access
      user = Current.session.user
      is_owner    = @listing.user_id == user.id
      is_accepted = @listing.registrations.accepted.exists?(user: user)

      unless is_owner || is_accepted
        redirect_to @listing, alert: "Chat room chỉ dành cho người đã được chấp nhận tham gia."
      end
    end
end
