require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "should get check" do
    get "/health"
    assert_response :success
    response_data = JSON.parse(response.body)
    assert_equal "ok", response_data["status"]
    assert_not_nil response_data["timestamp"]
  end
end
