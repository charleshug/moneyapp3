require "csv"

class ImportBudgetsController < ApplicationController
  def import_preview
    if request.get?
      redirect_to import_import_budgets_path and return
    end

    Rails.logger.info "=== Starting Budget Import Preview ==="
    Rails.logger.info "Params: #{preview_import_budgets_params.inspect}"

    unless preview_import_budgets_params[:file]
      Rails.logger.info "No file provided"
      flash[:alert] = "Please select a file to import"
      redirect_to import_import_budgets_path and return
    end

    begin
      Rails.logger.info "Parsing file: #{preview_import_budgets_params[:file].original_filename}"
      result = BudgetImportService.parse(preview_import_budgets_params[:file], @current_budget)
      # Rails.logger.info "Parse result: #{result.inspect}"

      if result[:ledgers].any?
        Rails.logger.info "Clean up old batches"
        BudgetImportBatch.cleanup_old_batches

        Rails.logger.info "Create new BudgetImportBatch"
        @import_batch = BudgetImportBatch.new(
          budget: @current_budget,
          parsed_ledgers: result[:ledgers]
        )

        if @import_batch.save
          Rails.logger.info "Created BudgetImportBatch ID: #{@import_batch.id}"
          session[:budget_import_batch_id] = @import_batch.id
          @ledgers = result[:ledgers]

          if result[:warnings].any?
            Rails.logger.info "Import warnings: #{result[:warnings]}"
            flash.now[:warning] = truncate_warnings(result[:warnings])
          end

          Rails.logger.info "Rendering preview template"
          render template: "import_budgets/preview", layout: "application"
        else
          Rails.logger.error "Failed to create BudgetImportBatch: #{@import_batch.errors.full_messages}"
          flash[:alert] = "Failed to create import batch"
          redirect_to import_import_budgets_path
        end
      else
        Rails.logger.info "No valid budget entries found"
        flash[:alert] = "No valid budget entries found in file. #{truncate_warnings(result[:warnings])}"
        redirect_to import_import_budgets_path
      end
    rescue BudgetImportService::ImportError => e
      Rails.logger.error "Import error: #{e.message}"
      flash[:alert] = "Import failed: #{truncate_error_message(e.message)}"
      redirect_to import_import_budgets_path
    rescue StandardError => e
      Rails.logger.error "Unexpected error during import: #{e.message}\n#{e.backtrace.join("\n")}"
      flash[:alert] = "An unexpected error occurred during import. Please check your file format and try again."
      redirect_to import_import_budgets_path
    ensure
      Rails.logger.info "=== End Budget Import Preview ==="
    end
  end

  def submit_import
    @import_batch = BudgetImportBatch.find_by(id: session[:budget_import_batch_id])

    unless @import_batch
      redirect_to import_import_budgets_path, alert: "Import session expired. Please try again." and return
    end

    imported_ledgers = import_budgets_params.select { |_, ledger| ledger["include"] == "1" }

    if imported_ledgers.empty?
      redirect_to import_import_budgets_path, notice: "No budget entries selected for import" and return
    end

    ledgers_to_update = Set.new

    ActiveRecord::Base.transaction do
      imported_ledgers.each do |_, ledger_params|
        date = Date.parse(ledger_params["date"])
        subcategory = @current_budget.subcategories.find(ledger_params["subcategory_id"])
        budget = (BigDecimal(ledger_params["budget"]) * 100).to_i

        ledger = Ledger.find_or_initialize_by(
          date: date.end_of_month,
          subcategory_id: subcategory.id
        ) do |l|
          l.budget = 0
          l.actual = 0
          l.balance = 0
          l.rolling_balance = 0
          l.carry_forward_negative_balance = false
          l.user_changed = false
        end

        ledger.budget = budget
        if ledger_params["carry_forward_negative_balance"].present?
          ledger.carry_forward_negative_balance = ledger_params["carry_forward_negative_balance"] == "true"
        end
        ledger.user_changed = true
        ledger.save!

        ledgers_to_update << ledger
      end

      ledgers_to_update.each do |ledger|
        LedgerService.recalculate_balance_chain(ledger)
      end
    end

    @import_batch.destroy
    session.delete(:budget_import_batch_id)
    redirect_to trxes_path, notice: "Budget entries imported successfully."
  end

  def import
    # This will render the initial import form
    render template: "import_budgets/import", layout: "application"
  end

  private

  def preview_import_budgets_params
    params.permit(:file, :authenticity_token, :commit)
  end

  def import_budgets_params
    params.require(:ledger).permit!
  end

  def truncate_warnings(warnings)
    return "" if warnings.blank?
    warnings.map { |w| truncate_error_message(w) }.join(", ")
  end

  def truncate_error_message(message)
    return "" if message.blank?
    message = message.split("\n").first
    message = message.split("ERROR:").last if message.include?("ERROR:")
    message.strip
  end
end
