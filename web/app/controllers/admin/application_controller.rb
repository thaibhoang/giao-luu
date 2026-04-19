# frozen_string_literal: true

module Admin
  class ApplicationController < ActionController::Base
    layout "admin"

    # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
    allow_browser versions: :modern unless Rails.env.test?

    before_action :require_admin_authentication
    helper_method :current_admin, :admin_authenticated?

    private

      def current_admin
        Current.admin_user
      end

      def admin_authenticated?
        resume_admin_session
      end

      def require_admin_authentication
        resume_admin_session || request_admin_authentication
      end

      def resume_admin_session
        Current.admin_session ||= find_admin_session_by_cookie
      end

      def find_admin_session_by_cookie
        AdminSession.find_by(id: cookies.signed[:admin_session_id]) if cookies.signed[:admin_session_id]
      end

      def request_admin_authentication
        redirect_to admin_new_session_path, alert: "Vui lòng đăng nhập để tiếp tục."
      end

      def start_new_admin_session_for(admin_user)
        admin_user.admin_sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |admin_session|
          Current.admin_session = admin_session
          cookies.signed.permanent[:admin_session_id] = { value: admin_session.id, httponly: true, same_site: :lax }
        end
      end

      def terminate_admin_session
        Current.admin_session&.destroy
        cookies.delete(:admin_session_id)
      end
  end
end
