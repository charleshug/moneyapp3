class StartingTrxCreator
  def initialize(account, trx_params)
    @account = account
    @budget = @account.budget
    @trx_params = trx_params
    @trx_params[:lines_attributes][0][:amount] = (BigDecimal(@trx_params[:lines_attributes][0][:amount]) * 100).to_s

    ActiveRecord::Base.transaction do
      create_trx
    end
  end

  def create_trx
    @trx = @account.trxes.build(@trx_params)
    set_ledger
    @trx.set_amount
    @trx.save!
  end

  def set_ledger
    @trx.lines.each do |line|
      if line.subcategory_form_id.empty?
        ledger = @budget.ledgers.find_or_create_by(date: @trx.date.end_of_month, subcategory: @budget.subcategories.find(line.subcategory))
      else
        ledger = @budget.ledgers.find_or_create_by(date: @trx.date.end_of_month, subcategory: @budget.subcategories.find(line.subcategory_form_id))
      end
      line.ledger=ledger
    end
  end
end
