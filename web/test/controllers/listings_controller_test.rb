# frozen_string_literal: true

require "test_helper"

class ListingsControllerTest < ActionDispatch::IntegrationTest
  test "index is public" do
    get "/listings"
    assert_response :success
  end

  test "new requires login" do
    get "/listings/new"
    assert_redirected_to new_session_path
  end
end
