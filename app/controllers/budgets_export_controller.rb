class BudgetsExportController < ApplicationController
  def create
    base_query = @current_budget.ledgers
                               .includes(subcategory: :category)
                               .order(:date, :id)

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    budget_name = @current_budget.name.gsub(/[^0-9A-Za-z]/, "_")

    csv_data = CSV.generate do |csv|
      csv << [ "Date", "Category Name", "Subcategory Name", "Budgeted", "Actual", "Balance",
              "Rolling Balance", "Carry Forward Negative Balance", "User Changed", "ID", "Next ID", "Prev ID" ]

      base_query.each do |ledger|
        csv << [
          ledger.date,
          ledger.subcategory.category.name,
          ledger.subcategory.name,
          ledger.budget.to_f / 100,
          ledger.actual.to_f / 100,
          ledger.balance.to_f / 100,
          ledger.rolling_balance.to_f / 100,
          ledger.carry_forward_negative_balance,
          ledger.user_changed,
          ledger.id,
          ledger.next_id,
          ledger.prev_id
        ]
      end
    end

    respond_to do |format|
      format.csv do
        send_data csv_data,
                 filename: "MoneyApp_#{budget_name}_budget-#{timestamp}.csv",
                 type: "text/csv",
                 disposition: "attachment"
      end
      format.any { head :not_acceptable }
    end
  end
end
