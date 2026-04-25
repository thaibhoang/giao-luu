module SessionTestHelper
  def sign_in_as(user)
    session = user.sessions.create!
    Current.session = session
    # cookies.signed không khả dụng trong Rack::Test; dùng cookie thường.
    # Rails authentication concern đọc cookies.signed[:session_id], nhưng trong
    # integration test ta set trực tiếp bằng cách POST login thật.
    post "/session", params: { email_address: user.email_address, password: "password" }
  end

  def sign_out
    Current.session&.destroy!
    delete "/session"
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
