require "test_helper"

class VendorsModalTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    # Create test data without fixtures
    @user = User.create!(email: "test@example.com", password: "password123")
    @budget = Budget.create!(name: "Test Budget", user: @user)
    @vendor = Vendor.create!(name: "Test Vendor", budget: @budget)
    login_as(@user)
  end

  test "modal HTML remains present after closing" do
    visit vendors_path

    # Verify modal frame exists initially
    assert_selector "turbo-frame#modal", visible: false

    # Open new vendor modal
    click_on "New Vendor"
    assert_selector "turbo-frame#modal", visible: true

    # Close modal by clicking outside
    find("body").click
    assert_selector "turbo-frame#modal", visible: false

    # Verify modal frame still exists in DOM
    assert_selector "turbo-frame#modal", visible: false

    # Open modal again to verify it still works
    click_on "New Vendor"
    assert_selector "turbo-frame#modal", visible: true
  end

  test "modal HTML remains present after successful vendor creation" do
    visit vendors_path

    # Open new vendor modal
    click_on "New Vendor"
    assert_selector "turbo-frame#modal", visible: true

    # Fill and submit form
    fill_in "Name", with: "Test Vendor"
    click_on "Create Vendor"

    # Wait for form submission to complete
    assert_no_selector "turbo-frame#modal", visible: true

    # Verify modal frame still exists in DOM (even though not visible)
    assert_selector "turbo-frame#modal", visible: false

    # Verify we can open modal again
    click_on "New Vendor"
    assert_selector "turbo-frame#modal", visible: true
  end

  test "modal HTML remains present after successful vendor update" do
    visit vendors_path

    # Open edit vendor modal
    click_on @vendor.name
    assert_selector "turbo-frame#modal", visible: true

    # Update vendor name
    fill_in "Name", with: "Updated Vendor Name"
    click_on "Update Vendor"

    # Wait for form submission to complete
    assert_no_selector "turbo-frame#modal", visible: true

    # Verify modal frame still exists in DOM (even though not visible)
    assert_selector "turbo-frame#modal", visible: false

    # Verify we can open modal again
    click_on "Updated Vendor Name"
    assert_selector "turbo-frame#modal", visible: true
  end
end
