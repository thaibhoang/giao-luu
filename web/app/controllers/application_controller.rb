class ApplicationController < ActionController::Base
  include Authentication

  # Mặc định yêu cầu đăng nhập (before_action :require_authentication).
  # Controller công khai (home, session, password reset) gọi allow_unauthenticated_access.
  # API/map xem tin: thêm allow_unauthenticated_access khi implement controller.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

    # Trả về Set các listing_id đã được bookmark bởi user hiện tại.
    # Truyền vào danh sách listings để chỉ query trong scope đó (tránh N+1).
    def current_user_bookmark_ids(listings = [])
      return Set.new unless authenticated?

      listing_ids = listings.map(&:id)
      return Set.new if listing_ids.empty?

      Current.session.user
             .bookmarks
             .where(listing_id: listing_ids)
             .pluck(:listing_id)
             .to_set
    end
end
