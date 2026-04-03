module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!
    cookies.signed.permanent[:session_id] = {
      value: Current.session.id,
      httponly: true,
      same_site: :lax
    }
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("session_id")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
