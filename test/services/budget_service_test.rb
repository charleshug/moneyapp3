# frozen_string_literal: true

require "test_helper"

# BudgetService tests use a real User + Budget (with default categories) created in setup
# so behavior does not depend on fixture data or load order.
class BudgetServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "budget_service_test@example.com", password: "password123")
    @budget = Budget.new(name: "Test Budget", description: "D", currency: "USD", user: @user)
    @budget.save!
    # Budget has default expense categories + Income Parent > Income
    @expense_category = @budget.categories.expense.first
    @income_category = @budget.categories.income.first
    @expense_sub = @expense_category.subcategories.first
    @income_sub = @income_category.subcategories.first
  end

  teardown do
    @user&.destroy
  end

  # --- get_budget_available ---

  test "get_budget_available returns income minus budgeted when no overspend" do
    month = Date.new(2024, 10, 31)
    Ledger.create!(
      subcategory: @income_sub,
      date: month,
      budget: 0,
      actual: 50_00, # 5000 cents
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @expense_sub,
      date: month,
      budget: 30_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    available = BudgetService.get_budget_available(@budget, month)
    assert_equal 50_00 - 30_00, available, "available = income - budgeted"
  end

  test "get_budget_available includes overspent from prior months when carry_forward is false" do
    aug = Date.new(2024, 8, 31)
    sep = Date.new(2024, 9, 30)
    Ledger.create!(
      subcategory: @expense_sub,
      date: aug,
      budget: 100,
      actual: 0,
      carry_forward_negative_balance: false
    )
    # Force negative balance (overspent)
    Ledger.where(subcategory: @expense_sub, date: aug).update_all(balance: -20_00, rolling_balance: -20_00)
    Ledger.create!(
      subcategory: @income_sub,
      date: sep,
      budget: 0,
      actual: 100_00,
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @expense_sub,
      date: sep,
      budget: 50_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    available = BudgetService.get_budget_available(@budget, sep)
    # overspent -20_00 + income 100_00 - budgeted 50_00 = 30_00
    assert_equal(-20_00 + 100_00 - 50_00, available)
  end

  test "get_budget_available ignores negative balance when carry_forward_negative_balance is true" do
    aug = Date.new(2024, 8, 31)
    sep = Date.new(2024, 9, 30)
    l = Ledger.create!(
      subcategory: @expense_sub,
      date: aug,
      budget: 100,
      actual: 0,
      carry_forward_negative_balance: true
    )
    Ledger.where(id: l.id).update_all(balance: -20_00, rolling_balance: -20_00)
    Ledger.create!(
      subcategory: @income_sub,
      date: sep,
      budget: 0,
      actual: 100_00,
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @expense_sub,
      date: sep,
      budget: 50_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    available = BudgetService.get_budget_available(@budget, sep)
    # no overspent (carry forward) + 100_00 - 50_00 = 50_00
    assert_equal 100_00 - 50_00, available
  end

  # --- get_budget_available_for_dates ---

  test "get_budget_available_for_dates returns hash keyed by end_of_month dates" do
    sep = Date.new(2024, 9, 30)
    oct = Date.new(2024, 10, 31)
    Ledger.create!(
      subcategory: @income_sub,
      date: sep,
      budget: 0,
      actual: 100_00,
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @expense_sub,
      date: sep,
      budget: 40_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @income_sub,
      date: oct,
      budget: 0,
      actual: 100_00,
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @expense_sub,
      date: oct,
      budget: 30_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    dates = [sep, oct]
    result = BudgetService.get_budget_available_for_dates(@budget, dates)
    assert_equal 2, result.size
    assert_equal 100_00 - 40_00, result[sep]
    assert_equal 100_00 - 30_00, result[oct]
  end

  test "get_budget_available_for_dates returns empty hash for empty dates" do
    assert_equal({}, BudgetService.get_budget_available_for_dates(@budget, []))
  end

  test "get_budget_available_for_dates normalizes input to end_of_month" do
    sep = Date.new(2024, 9, 30)
    Ledger.create!(
      subcategory: @income_sub,
      date: sep,
      budget: 0,
      actual: 50_00,
      carry_forward_negative_balance: false
    )
    Ledger.create!(
      subcategory: @expense_sub,
      date: sep,
      budget: 10_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    result = BudgetService.get_budget_available_for_dates(@budget, [Date.new(2024, 9, 15)])
    assert_equal 1, result.size
    assert_equal 50_00 - 10_00, result[sep]
  end

  # --- generate_budget_table_data ---

  test "generate_budget_table_data returns expense categories with subcategories and ledger data" do
    month = Date.new(2024, 10, 31)
    Ledger.create!(
      subcategory: @expense_sub,
      date: month,
      budget: 100_00,
      actual: 30_00,
      carry_forward_negative_balance: false
    )
    data = BudgetService.generate_budget_table_data(@budget, month)
    assert data.is_a?(Array), "returns array of categories"
    assert data.any? { |c| c[:id] == @expense_category.id }, "includes expense category"
    cat = data.find { |c| c[:id] == @expense_category.id }
    assert_equal @expense_category.name, cat[:name]
    assert_equal 100_00, cat[:budget]
    assert_equal 30_00, cat[:actual]
    assert cat[:subcategories].is_a?(Array)
    sub = cat[:subcategories].find { |s| s[:id] == @expense_sub.id }
    assert sub, "subcategory present"
    assert_equal 100_00, sub[:budget]
    assert_equal 30_00, sub[:actual]
    assert sub.key?(:balance)
    assert sub.key?(:carry_forward)
    assert sub.key?(:ledger)
  end

  test "generate_budget_table_data does not include income categories" do
    month = Date.new(2024, 10, 31)
    data = BudgetService.generate_budget_table_data(@budget, month)
    category_ids = data.map { |c| c[:id] }
    assert_not_includes category_ids, @income_category.id
  end

  test "generate_budget_table_data uses previous ledger balance when no ledger for selected month" do
    aug = Date.new(2024, 8, 31)
    oct = Date.new(2024, 10, 31)
    Ledger.create!(
      subcategory: @expense_sub,
      date: aug,
      budget: 50_00,
      actual: 0,
      carry_forward_negative_balance: false
    )
    Ledger.rebuild_chain_for_subcategory(@expense_sub.id)
    data = BudgetService.generate_budget_table_data(@budget, oct)
    cat = data.find { |c| c[:id] == @expense_category.id }
    sub = cat[:subcategories].find { |s| s[:id] == @expense_sub.id }
    assert_nil sub[:ledger], "no ledger for October"
    assert_equal 0, sub[:budget], "no budget for October"
    assert sub[:balance].present? || sub[:balance] == 0, "balance from previous or zero"
  end

  test "generate_budget_table_data sums category budget and actual from subcategories" do
    second_sub = @expense_category.subcategories.create!(name: "Second", order: 10)
    month = Date.new(2024, 10, 31)
    Ledger.create!(subcategory: @expense_sub, date: month, budget: 100, actual: 20, carry_forward_negative_balance: false)
    Ledger.create!(subcategory: second_sub, date: month, budget: 200, actual: 50, carry_forward_negative_balance: false)
    data = BudgetService.generate_budget_table_data(@budget, month)
    cat = data.find { |c| c[:id] == @expense_category.id }
    assert_equal 300, cat[:budget]
    assert_equal 70, cat[:actual]
  end
end
