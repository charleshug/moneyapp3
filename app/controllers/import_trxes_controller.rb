class ImportTrxesController < ApplicationController
  def import_preview
    if request.get?
      redirect_to trxes_import_path and return
    end

    Rails.logger.info "=== Starting Import Preview ==="
    Rails.logger.info "Params: #{preview_import_trxes_params.inspect}"

    @current_budget = Budget.includes(:accounts, :vendors, :categories, :subcategories)
                           .find(@current_budget.id)

    unless preview_import_trxes_params[:file]
      Rails.logger.info "No file provided"
      flash[:alert] = "Please select a file to import"
      redirect_to trxes_import_path and return
    end

    begin
      Rails.logger.info "Parsing file: #{preview_import_trxes_params[:file].original_filename}"
      result = TrxImportService.parse(preview_import_trxes_params[:file], @current_budget)
      Rails.logger.info "Parse result: #{result.inspect}"

      if result[:trxes].any?
        ImportBatch.cleanup_old_batches
        @import_batch = ImportBatch.create!(
          budget: @current_budget,
          parsed_trxes: result[:trxes]
        )
        Rails.logger.info "Created ImportBatch ID: #{@import_batch.id}"

        session[:import_batch_id] = @import_batch.id
        @trxes = result[:trxes]

        if result[:warnings].any?
          Rails.logger.info "Import warnings: #{result[:warnings]}"
          flash.now[:warning] = truncate_warnings(result[:warnings])
        end

        Rails.logger.info "Rendering preview template"
        render template: "import_trxes/preview", layout: "application"
      else
        Rails.logger.info "No valid transactions found"
        flash[:alert] = "No valid transactions found in file. #{truncate_warnings(result[:warnings])}"
        redirect_to trxes_import_path
      end
    rescue TrxImportService::ImportError => e
      Rails.logger.error "Import error: #{e.message}"
      flash[:alert] = "Import failed: #{truncate_error_message(e.message)}"
      redirect_to trxes_import_path
    rescue StandardError => e
      Rails.logger.error "Unexpected error during import: #{e.message}\n#{e.backtrace.join("\n")}"
      flash[:alert] = "An unexpected error occurred during import. Please check your file format and try again."
      redirect_to trxes_import_path
    ensure
      Rails.logger.info "=== End Import Preview ==="
    end
  end

  def submit_import
    @import_batch = ImportBatch.find_by(id: session[:import_batch_id])

    unless @import_batch
      redirect_to trxes_import_path, alert: "Import session expired. Please try again." and return
    end

    imported_trxes = import_trxes_params.select { |_, trx| trx["include"] == "1" }

    if imported_trxes.empty?
      redirect_to trxes_import_path, notice: "No transactions selected for import" and return
    end

    ledgers_to_update = Set.new
    accounts_to_update = Set.new

    ActiveRecord::Base.transaction do
      imported_trxes.each do |_, trx_params|
        trx = @current_budget.trxes.build(
          date: trx_params["date"],
          account_id: trx_params["account_id"],
          vendor_id: trx_params["vendor_id"],
          memo: trx_params["memo"]
        )

        trx_params["lines_attributes"].each do |_, line_params|
          amount = (BigDecimal(line_params["amount"]) * BigDecimal("100")).to_i
          line = trx.lines.build(
            subcategory_form_id: line_params["subcategory_id"],
            amount: amount
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

    @import_batch.destroy
    session.delete(:import_batch_id)
    redirect_to trxes_path, notice: "Transactions imported successfully."
  end

  private

  # # Only allow a list of trusted parameters through.
  def preview_import_trxes_params
    params.permit(:file, :authenticity_token, :commit)
  end

  def import_trxes_params
    params.require(:trx).permit!
  end

  def convert_amount_to_cents(amount)
    (amount.to_d * 100).to_i
  end

  def truncate_warnings(warnings)
    return "" if warnings.blank?

    warnings.map { |w| truncate_error_message(w) }.join(", ")
  end

  def truncate_error_message(message)
    return "" if message.blank?

    # Extract just the user-friendly part of the error message
    message = message.split("\n").first
    message = message.split("ERROR:").last if message.include?("ERROR:")
    message.strip
  end
end
