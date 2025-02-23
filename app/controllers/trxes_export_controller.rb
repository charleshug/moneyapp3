class TrxesExportController < ApplicationController
  def create
    @trxes = @current_budget.trxes.all
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    budget_name = @current_budget.name.gsub(/[^0-9A-Za-z]/, "_") # sanitize name

    csv_data = TrxCsvExporter.new(@trxes).generate_csv

    respond_to do |format|
      format.csv do
        send_data csv_data, filename: "MoneyApp_#{budget_name}_trxes-#{timestamp}.csv"
      end
    end
  end
end
