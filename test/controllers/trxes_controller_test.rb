require "test_helper"

class TrxesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trx = trxes(:one)
  end

  test "should get index" do
    get trxes_url
    assert_response :success
  end

  test "should get new" do
    get new_trx_url
    assert_response :success
  end

  test "should create trx" do
    assert_difference("Trx.count") do
      post trxes_url, params: { trx: { account_id: @trx.account_id, amount: @trx.amount, cleared: @trx.cleared, date: @trx.date, ledger_id: @trx.ledger_id, memo: @trx.memo, subcategory_id: @trx.subcategory_id, transfer_id: @trx.transfer_id, vendor_id: @trx.vendor_id } }
    end

    assert_redirected_to trx_url(Trx.last)
  end

  test "should show trx" do
    get trx_url(@trx)
    assert_response :success
  end

  test "should get edit" do
    get edit_trx_url(@trx)
    assert_response :success
  end

  test "should update trx" do
    patch trx_url(@trx), params: { trx: { account_id: @trx.account_id, amount: @trx.amount, cleared: @trx.cleared, date: @trx.date, ledger_id: @trx.ledger_id, memo: @trx.memo, subcategory_id: @trx.subcategory_id, transfer_id: @trx.transfer_id, vendor_id: @trx.vendor_id } }
    assert_redirected_to trx_url(@trx)
  end

  test "should destroy trx" do
    assert_difference("Trx.count", -1) do
      delete trx_url(@trx)
    end

    assert_redirected_to trxes_url
  end
end
