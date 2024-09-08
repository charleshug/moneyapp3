require "application_system_test_case"

class LedgersTest < ApplicationSystemTestCase
  setup do
    @ledger = ledgers(:one)
  end

  test "visiting the index" do
    visit ledgers_url
    assert_selector "h1", text: "Ledgers"
  end

  test "should create ledger" do
    visit ledgers_url
    click_on "New ledger"

    fill_in "Actual", with: @ledger.actual
    fill_in "Balance", with: @ledger.balance
    fill_in "Budget", with: @ledger.budget
    check "Carry forward negative balance" if @ledger.carry_forward_negative_balance
    fill_in "Date", with: @ledger.date
    fill_in "Next", with: @ledger.next_id
    fill_in "Prev", with: @ledger.prev_id
    fill_in "Subcategory", with: @ledger.subcategory_id
    check "User changed" if @ledger.user_changed
    click_on "Create Ledger"

    assert_text "Ledger was successfully created"
    click_on "Back"
  end

  test "should update Ledger" do
    visit ledger_url(@ledger)
    click_on "Edit this ledger", match: :first

    fill_in "Actual", with: @ledger.actual
    fill_in "Balance", with: @ledger.balance
    fill_in "Budget", with: @ledger.budget
    check "Carry forward negative balance" if @ledger.carry_forward_negative_balance
    fill_in "Date", with: @ledger.date
    fill_in "Next", with: @ledger.next_id
    fill_in "Prev", with: @ledger.prev_id
    fill_in "Subcategory", with: @ledger.subcategory_id
    check "User changed" if @ledger.user_changed
    click_on "Update Ledger"

    assert_text "Ledger was successfully updated"
    click_on "Back"
  end

  test "should destroy Ledger" do
    visit ledger_url(@ledger)
    click_on "Destroy this ledger", match: :first

    assert_text "Ledger was successfully destroyed"
  end
end
