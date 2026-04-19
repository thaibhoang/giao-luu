# frozen_string_literal: true

module Admin
  class SessionsController < Admin::ApplicationController
    skip_before_action :require_admin_authentication, only: %i[new create]
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to admin_new_session_path, alert: "Thử lại sau." }

    def new
    end

    def create
      if admin = AdminUser.authenticate_by(params.permit(:email_address, :password))
        start_new_admin_session_for(admin)
        redirect_to admin_dashboard_path
      else
        redirect_to admin_new_session_path, alert: "Email hoặc mật khẩu không đúng."
      end
    end

    def destroy
      terminate_admin_session
      redirect_to admin_new_session_path, status: :see_other
    end
  end
end
