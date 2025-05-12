class TrxesExportController < ApplicationController
  def create
    # Get the same filtered results as the index page
    base_query = @current_budget.trxes
                               .select("trxes.*, accounts.name as account_name, vendors.name as vendor_name")
                               .joins(:account, :vendor)
                               .includes(:account, :vendor, lines: { ledger: { subcategory: :category } })

    # Parse the JSON filter parameters
    filter_params = JSON.parse(params[:q]) if params[:q].present?
    @q = base_query.ransack(filter_params)
    @q.sorts = [ "date desc", "id desc" ] if @q.sorts.empty?
    @trxes = @q.result

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    budget_name = @current_budget.name.gsub(/[^0-9A-Za-z]/, "_") # sanitize name

    csv_data = TrxCsvExporter.new(@trxes).generate_csv

    respond_to do |format|
      format.csv do
        send_data csv_data,
                 filename: "MoneyApp_#{budget_name}_trxes-#{timestamp}.csv",
                 type: "text/csv",
                 disposition: "attachment"
      end
      format.any { head :not_acceptable }
    end
  end
end
