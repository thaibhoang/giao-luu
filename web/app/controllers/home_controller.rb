# frozen_string_literal: true

class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    redirect_to listings_path
  end
end
