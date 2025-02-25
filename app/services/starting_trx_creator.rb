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

  private
  def set_ledger
    @trx.lines.each do |line|
      subcategory = @budget.subcategories.find(line.subcategory_form_id)

      date = @trx.date.end_of_month
      ledger = Ledger.find_by(
        date: date,
        subcategory: subcategory
      )

      if ledger.nil?
        # Only set carry_forward for new ledgers
        prev_ledger = Ledger.where(subcategory: subcategory)
                           .where("date < ?", date)
                           .order(date: :desc)
                           .first

        ledger = Ledger.create!(
          date: date,
          subcategory: subcategory,
          carry_forward_negative_balance: prev_ledger&.carry_forward_negative_balance || false
        )
      end

      line.ledger = ledger
    end
  end
end
