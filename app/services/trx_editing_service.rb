class TrxEditingService
  def initialize(trx, trx_params)
    @trx = trx
    @trx_params = trx_params.dup
    @ledgers_to_update = Set.new
    @accounts_to_update = Set.new
  end

  def edit_trx
    ActiveRecord::Base.transaction do
      convert_amount_to_cents
      handle_vendor_custom_text
      save_trx_state

      update_trx_state
      handle_deleted_lines
      @trx.set_amount
      @trx.save
      unless @trx.valid?
        # trx failed, do something
      end

      # Process each line for transfer logic
      @trx.lines.each do |line|
        handle_transfer_logic(line)
      end

      update_impacted_ledgers_and_accounts
      @trx
    end
  end

  private

  def handle_transfer_logic(line)
    if line.transfer_line_id.present?
      if line.ledger.subcategory.name != "Transfer"
        delete_transfer(line)
      else
        update_transfer(line)
      end
    elsif line.transfer_account_id.present?
      create_transfer(line)
    end
    # No action needed if transfer_line_id == nil and subcategory is not Transfer
  end


  def delete_transfer(line)
    transfer_trx = line.transfer_line.trx
    @accounts_to_update << transfer_trx.account
    @ledgers_to_update << transfer_trx.lines.first.ledger


    # Update the original line
    subcategory = line.ledger.subcategory
    case subcategory.name
    when "Transfer"
      subcategory = line.budget.subcategories.find_or_create_by(name: "Uncategorized")
    when "" # empty
      subcategory = line.budget.subcategories.find_or_create_by(name: "Uncategorized")
    else
      # no action
    end

    ledger = Ledger.find_or_create_by(date: line.date.end_of_month, subcategory: subcategory)
    line.update_columns(
      transfer_line_id: nil,
      ledger_id: ledger.id
    )
    @ledgers_to_update << line.ledger

    # Update the original transaction if needed
    if @trx.lines.count == 1
      vendor = line.budget.vendors.find_or_create_by(name: "Other")
      @trx.update_column(:vendor_id, vendor.id)
    end

    # Delete the transfer transaction
    transfer_trx.destroy
  end

  def update_transfer(line)
    transfer_trx = line.transfer_line.trx
    # Update transfer transaction attributes
    transfer_trx.account = line.budget.accounts.find_by(id: line.transfer_account_id)
    transfer_trx.date = @trx.date
    transfer_trx.vendor = @trx.account.vendor
    transfer_trx.memo = @trx.memo

    # Update transfer line attributes
    transfer_line = transfer_trx.lines.first
    transfer_line.update_columns(amount: -line.amount, ledger_id: line.ledger_id)

    @accounts_to_update << transfer_trx.account
    @ledgers_to_update << line.ledger
    transfer_trx.set_amount
    transfer_trx.save!

    # Update the original transaction vendor if single line
    if @trx.lines.count == 1
      vendor = line.budget.vendors.find_by(account: transfer_line.trx.account)
      @trx.update_column(:vendor_id, vendor.id)
    end
  end

  def create_transfer(line)
    budget = line.budget
    transfer_trx = budget.trxes.build(
      account: budget.accounts.find_by(id: line.transfer_account_id),
      date: @trx.date,
      vendor: @trx.account.vendor,
      memo: @trx.memo
    )

    transfer_line = transfer_trx.lines.build(
      amount: -line.amount,
      ledger: line.ledger,
      transfer_line_id: line.id
    )

    @accounts_to_update << transfer_trx.account
    @ledgers_to_update << line.ledger
    transfer_trx.set_amount
    transfer_trx.save!

    # Update original line with transfer reference
    line.update_column(:transfer_line_id, transfer_line.id)

    # Update original transaction vendor if single line
    if @trx.lines.count == 1
      @trx.update_column(:vendor_id, transfer_trx.account.vendor.id)
    end
  end

  def update_trx_state
    @trx.assign_attributes(@trx_params)
    set_ledger
    set_amount
  end

  def save_trx_state
    save_impacted_ledgers
    save_impacted_accounts
  end

  def update_impacted_ledgers_and_accounts
    update_impacted_ledgers
    update_impacted_accounts
  end

  def update_impacted_accounts
    @accounts_to_update.each do |account|
      account.calculate_balance!
    end
  end

  def save_impacted_accounts
    @trx.lines.each { |line| @accounts_to_update << line.account }
  end

  def update_impacted_ledgers
    @ledgers_to_update.each do |ledger|
      LedgerService.recalculate_forward_ledgers(ledger)
    end
  end

  def set_amount
    @trx.amount = @trx.lines.sum(&:amount)
  end

  def save_impacted_ledgers
    @trx.lines.each { |line| @ledgers_to_update << line.ledger }
  end

  def set_ledger
    budget = @trx.budget
    @trx.lines.each do |line|
      subcategory = if line.subcategory_form_id.present?
        budget.subcategories.find(line.subcategory_form_id)
      else
        line.ledger&.subcategory
      end

      next unless subcategory  # Skip if no subcategory found

      ledger = Ledger.find_or_create_by(
        date: @trx.date.end_of_month,
        subcategory: subcategory
      )
      line.ledger = ledger
    end
  end

  def handle_vendor_custom_text
    unless @trx_params[:vendor_custom_text].blank?
      vendor = @budget.vendors.find_or_create_by(name: @trx_params[:vendor_custom_text])
      @trx_params[:vendor_id] = vendor.id
    end
    @trx_params.delete(:vendor_custom_text)
  end

  def convert_amount_to_cents
    return unless @trx_params[:lines_attributes].present?

    @trx_params[:lines_attributes].each do |_, line_params|  # Keep index key (_ ignored)
      if line_params[:amount].present?
        line_params[:amount] = (line_params[:amount].to_d * 100).to_i
      end
    end
  end

  def handle_deleted_lines
    return unless @trx_params[:lines_attributes]

    @trx_params[:lines_attributes].each do |_, line_params|
      if line_params[:_destroy] == "1" && line_params[:id].present?
        line = @trx.lines.find(line_params[:id])
        if line.transfer_line_id.present?
          transfer_trx = line.transfer_line.trx
          @accounts_to_update << transfer_trx.account
          line.update_column(:transfer_line_id, nil)
          transfer_trx.destroy
        end
      end
    end
  end
end
