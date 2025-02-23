class ImportTrxesController < ApplicationController
  def import_preview
    @categories = @current_budget.categories.includes(:subcategories)
    @accounts = @current_budget.accounts

    @parsed_trxes = TrxImportService.parse(preview_import_trxes_params[:file], @current_budget)
    if @parsed_trxes
      session[:parsed_trxes] = @parsed_trxes
    else
      redirect_to accounts_path, alert: "Error in CSV file."
    end

    @trxes = @parsed_trxes
    if @trxes.nil?
      redirect_to new_trx_path, alert: "No trxes to import"
    end
  end

  def submit_import
    ledgers_to_update = Set.new
    accounts_to_update = Set.new


    imported_trxes = import_trxes_params.values.select { |trx| trx["include"] == "1" }

    if imported_trxes.empty?
      redirect_to new_trx_path, notice: "No transactions selected for import" and return
    end
    ActiveRecord::Base.transaction do
      imported_trxes.each do |trx_params|
        trx = @current_budget.trxes.build(
          date: trx_params["date"],
          account_id: trx_params["account_id"],
          vendor_id: trx_params["vendor_id"],
          memo: trx_params["memo"]
        )

        trx_params["lines_attributes"].each do |_, line_params|
          line = trx.lines.build(
            subcategory_form_id: line_params["subcategory_id"],
            amount: convert_amount_to_cents(line_params["amount"])
          )
          line.set_ledger
          ledgers_to_update << line.ledger
        end


        trx.set_amount
        trx.save!
        accounts_to_update << trx.account
        trx.lines.each { |line| ledgers_to_update << line.ledger }
      end

      accounts_to_update.each { |account| account.calculate_balance! }
      ledgers_to_update.each { |ledger| LedgerService.new.recalculate_forward_ledgers(ledger) }
    end

    redirect_to trxes_path, notice: "Transactions imported successfully."
  end

  private

  # # Only allow a list of trusted parameters through.
  def preview_import_trxes_params
    params.permit(:file, :authenticity_token, :commit)
  end

  def import_trxes_params
    params.require(:trx).permit(
      {}.tap do |hash|
        params[:trx].each_key do |key|
          hash[key] = [ :date, :memo, :account_id, :vendor_id, :include,
                       { lines_attributes: [ :subcategory_id, :amount ] } ]
        end
      end
    )
  end

  def convert_amount_to_cents(amount)
    (amount.to_d * 100).to_i
  end
end
