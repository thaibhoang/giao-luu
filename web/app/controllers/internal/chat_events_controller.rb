# frozen_string_literal: true

module Internal
  # POST /internal/chat_events
  # Nhận webhook từ Go Chat Service, verify HMAC (ADR-002 pattern), enqueue job.
  class ChatEventsController < ApplicationController
    allow_unauthenticated_access
    skip_forgery_protection

    def create
      return render_unauthorized unless valid_signature?

      payload = JSON.parse(request.raw_post)

      ChatNotificationJob.perform_later(
        event:          payload["event"],
        chat_room_id:   payload["chat_room_id"]&.to_i,
        listing_id:     payload["listing_id"]&.to_i,
        sender_user_id: payload["sender_user_id"]&.to_i,
        message_id:     payload["message_id"]&.to_i
      )

      head :no_content
    rescue JSON::ParserError => e
      Rails.logger.warn("internal/chat_events: invalid JSON — #{e.message}")
      render json: { error: "invalid json" }, status: :bad_request
    end

    private

      def valid_signature?
        secret = ENV["CHAT_HMAC_SECRET"].to_s
        return false if secret.blank?

        timestamp = request.headers["X-SportMatch-Timestamp"].to_s
        signature = request.headers["X-SportMatch-Signature"].to_s
        return false if timestamp.blank? || signature.blank?
        return false if (Time.now.to_i - timestamp.to_i).abs > 300

        raw_body = request.raw_post
        digest   = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{raw_body}")
        ActiveSupport::SecurityUtils.secure_compare(digest, signature)
      end

      def render_unauthorized
        render json: { errors: [ { field: "signature", message: "invalid" } ] },
               status: :unauthorized
      end
  end
end
