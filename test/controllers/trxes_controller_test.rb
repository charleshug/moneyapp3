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

  test "should update trx via JSON" do
    patch trx_url(@trx),
          params: { trx: { memo: "Updated memo", date: "2024-01-15" } },
          headers: { "Accept" => "application/json" }

    assert_response :success
    @trx.reload
    assert_equal "Updated memo", @trx.memo
    assert_equal Date.parse("2024-01-15"), @trx.date

    response_data = JSON.parse(response.body)
    assert_equal true, response_data["success"]
    assert_equal @trx.id, response_data["trx_id"]
  end

  test "should destroy trx" do
    assert_difference("Trx.count", -1) do
      delete trx_url(@trx)
    end

    assert_redirected_to trxes_url
  end

  test "should toggle cleared status" do
    initial_cleared = @trx.cleared

    post toggle_cleared_trx_url(@trx), headers: { "Accept" => "application/json" }

    assert_response :success
    @trx.reload
    assert_not_equal initial_cleared, @trx.cleared

    response_data = JSON.parse(response.body)
    assert_equal @trx.cleared, response_data["cleared"]
  end

  test "should get balance info" do
    get balance_info_trxes_url, headers: { "Accept" => "application/json" }

    assert_response :success

    response_data = JSON.parse(response.body)
    assert_includes response_data.keys, "cleared_balance"
    assert_includes response_data.keys, "cleared_count"
    assert_includes response_data.keys, "uncleared_balance"
    assert_includes response_data.keys, "uncleared_count"
    assert_includes response_data.keys, "working_balance"
    assert_includes response_data.keys, "total_count"
  end
end
