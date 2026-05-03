# frozen_string_literal: true

# ChatNotificationJob — xử lý event từ Go Chat Service (webhook POST /internal/chat_events).
# Hiện tại: log event. Sprint 4 sẽ mở rộng thành gửi email / push notification.
class ChatNotificationJob < ApplicationJob
  queue_as :default

  # @param event [String] loại event, hiện chỉ "new_message"
  # @param chat_room_id [Integer]
  # @param listing_id [Integer]
  # @param sender_user_id [Integer]
  # @param message_id [Integer]
  def perform(event:, chat_room_id:, listing_id:, sender_user_id:, message_id:)
    Rails.logger.info(
      "[ChatNotificationJob] event=#{event} room=#{chat_room_id} " \
      "listing=#{listing_id} sender=#{sender_user_id} message=#{message_id}"
    )

    nil unless event == "new_message"

    # TODO Sprint 4: notify các thành viên đã đăng ký listing qua email
    # listing = Listing.find_by(id: listing_id)
    # return unless listing
    # recipients = listing.registrations.includes(:user).map(&:user)
    #              .reject { |u| u.id == sender_user_id }
    # recipients.each { |u| ChatMailer.new_message(u, listing, message_id).deliver_later }
  end
end
