require "test_helper"

class VendorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "test@example.com", password: "password123")
    @budget = Budget.create!(name: "Test Budget", user: @user)
    @vendor = Vendor.create!(name: "Test Vendor", budget: @budget)
    login_as(@user)
  end

  test "modal frame is preserved after successful vendor creation" do
    post vendors_path, params: { vendor: { name: "New Vendor" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # Check that the response contains an empty modal frame (not completely removed)
    assert_match /<turbo-frame id="modal"><\/turbo-frame>/, response.body
  end

  test "modal frame is preserved after successful vendor update" do
    patch vendor_path(@vendor), params: { vendor: { name: "Updated Vendor" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # Check that the response contains an empty modal frame (not completely removed)
    assert_match /<turbo-frame id="modal"><\/turbo-frame>/, response.body
  end

  test "modal frame is preserved after vendor deletion" do
    delete vendor_path(@vendor),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # Check that the response contains an empty modal frame (not completely removed)
    assert_match /<turbo-frame id="modal"><\/turbo-frame>/, response.body
  end
end
