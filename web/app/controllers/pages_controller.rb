# frozen_string_literal: true

class PagesController < ApplicationController
  allow_unauthenticated_access

  def empty_map; end

  def error_page; end

  def policy; end
end
