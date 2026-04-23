# frozen_string_literal: true

# Job chạy cuối ngày để deactivate các listing đã qua thời gian bắt đầu.
# Khi active = false, tin sẽ tự động bị lọc khỏi trang chủ/bản đồ và
# partial index (WHERE active = true) sẽ không còn cover các row này.
class ExpireListingsJob < ApplicationJob
  queue_as :default

  def perform
    expired_count = Listing.where(active: true)
                            .where("start_at < ?", Time.current)
                            .update_all(active: false, updated_at: Time.current)

    Rails.logger.info("ExpireListingsJob: deactivated #{expired_count} listings")
    expired_count
  end
end
