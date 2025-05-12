require "csv"

class ImportBudgetsController < ApplicationController
  def import_preview
    if request.post?
      if params[:file].blank?
        flash[:error] = "Please select a file to import"
        redirect_to import_preview_import_budgets_path and return
      end

      begin
        file_content = params[:file].read
        @csv_data = CSV.parse(file_content, headers: true)
        @headers = @csv_data.headers
        @preview_rows = @csv_data.first(5)

        # Validate headers
        required_headers = [ "Date", "Subcategory", "Budget" ]
        missing_headers = required_headers - @headers
        if missing_headers.any?
          flash[:error] = "Missing required headers: #{missing_headers.join(', ')}"
          redirect_to import_preview_import_budgets_path and return
        end

        # Validate subcategories
        subcategory_names = @csv_data.map { |row| row["Subcategory"] }.uniq
        existing_subcategories = @current_budget.subcategories.where(name: subcategory_names)
        missing_subcategories = subcategory_names - existing_subcategories.pluck(:name)

        if missing_subcategories.any?
          flash[:error] = "The following subcategories do not exist in your budget: #{missing_subcategories.join(', ')}"
          redirect_to import_preview_import_budgets_path and return
        end

        # Store the file content for processing
        session[:budget_import_file] = file_content

        respond_to do |format|
          format.html { render :import_preview }
          format.turbo_stream { render :import_preview }
        end
      rescue CSV::MalformedCSVError
        flash[:error] = "Invalid CSV file format"
        redirect_to import_preview_import_budgets_path
      end
    end
  end

  def submit_import
    if session[:budget_import_file].blank?
      flash[:error] = "No import file found"
      redirect_to import_preview_import_budgets_path and return
    end

    begin
      ActiveRecord::Base.transaction do
        csv_data = CSV.parse(session[:budget_import_file], headers: true)
        subcategories = @current_budget.subcategories.where(name: csv_data.map { |row| row["Subcategory"] }.uniq)
        subcategory_map = subcategories.index_by(&:name)

        csv_data.each do |row|
          date = Date.parse(row["Date"])
          subcategory = subcategory_map[row["Subcategory"]]
          budget = (BigDecimal(row["Budget"]) * 100).to_i

          # This will create a new ledger if one doesn't exist for this date/subcategory
          ledger = Ledger.find_or_initialize_by(
            date: date.end_of_month,
            subcategory_id: subcategory.id
          ) do |l|
            # These values will only be set for new ledgers
            l.budget = 0
            l.actual = 0
            l.balance = 0
            l.rolling_balance = 0
            l.carry_forward_negative_balance = false
            l.user_changed = false
          end

          # Update the budget amount
          ledger.budget = budget

          # Only update carry_forward if the field exists and has a value
          if row["Carry Forward Negative Balance"].present?
            ledger.carry_forward_negative_balance = row["Carry Forward Negative Balance"].downcase == "true"
          end

          ledger.user_changed = true
          ledger.save!

          # Recalculate affected ledgers
          LedgerService.recalculate_balance_chain(ledger)
        end

        session.delete(:budget_import_file)
        flash[:success] = "Budget import completed successfully"
        redirect_to trxes_path
      end
    rescue => e
      flash[:error] = "Error during import: #{e.message}"
      redirect_to import_preview_import_budgets_path
    end
  end
end
