require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)
  end


  test "should create account" do
    visit trxes_url
    click_on "Add Account"

    fill_in "Balance", with: @account.balance
    fill_in "Budget", with: @account.budget_id
    check "Closed" if @account.closed
    fill_in "Name", with: @account.name
    check "On budget" if @account.on_budget
    click_on "Create Account"

    assert_text "Account was successfully created"
    click_on "Back"
  end

  test "should update Account" do
    visit account_url(@account)
    click_on "Edit this account", match: :first

    fill_in "Balance", with: @account.balance
    fill_in "Budget", with: @account.budget_id
    check "Closed" if @account.closed
    fill_in "Name", with: @account.name
    check "On budget" if @account.on_budget
    click_on "Update Account"

    assert_text "Account was successfully updated"
    click_on "Back"
  end

  test "should destroy Account" do
    visit account_url(@account)
    click_on "Destroy this account", match: :first

    assert_text "Account was successfully destroyed"
  end
end
