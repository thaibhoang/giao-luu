class ApplicationController < ActionController::Base
  include Authentication

  # Mặc định yêu cầu đăng nhập (before_action :require_authentication).
  # Controller công khai (home, session, password reset) gọi allow_unauthenticated_access.
  # API/map xem tin: thêm allow_unauthenticated_access khi implement controller.

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
