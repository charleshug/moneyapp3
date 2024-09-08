require "application_system_test_case"

class TrxesTest < ApplicationSystemTestCase
  setup do
    @trx = trxes(:one)
  end

  test "visiting the index" do
    visit trxes_url
    assert_selector "h1", text: "Trxes"
  end

  test "should create trx" do
    visit trxes_url
    click_on "New trx"

    fill_in "Account", with: @trx.account_id
    fill_in "Amount", with: @trx.amount
    check "Cleared" if @trx.cleared
    fill_in "Date", with: @trx.date
    fill_in "Ledger", with: @trx.ledger_id
    fill_in "Memo", with: @trx.memo
    fill_in "Subcategory", with: @trx.subcategory_id
    fill_in "Transfer", with: @trx.transfer_id
    fill_in "Vendor", with: @trx.vendor_id
    click_on "Create Trx"

    assert_text "Trx was successfully created"
    click_on "Back"
  end

  test "should update Trx" do
    visit trx_url(@trx)
    click_on "Edit this trx", match: :first

    fill_in "Account", with: @trx.account_id
    fill_in "Amount", with: @trx.amount
    check "Cleared" if @trx.cleared
    fill_in "Date", with: @trx.date
    fill_in "Ledger", with: @trx.ledger_id
    fill_in "Memo", with: @trx.memo
    fill_in "Subcategory", with: @trx.subcategory_id
    fill_in "Transfer", with: @trx.transfer_id
    fill_in "Vendor", with: @trx.vendor_id
    click_on "Update Trx"

    assert_text "Trx was successfully updated"
    click_on "Back"
  end

  test "should destroy Trx" do
    visit trx_url(@trx)
    click_on "Destroy this trx", match: :first

    assert_text "Trx was successfully destroyed"
  end
end
