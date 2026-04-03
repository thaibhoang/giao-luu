module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      session = Session.find_by(id: cookies.signed[:session_id])
      verified_user = session&.user
      if verified_user
        self.current_user = verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
