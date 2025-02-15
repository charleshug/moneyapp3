class AccountCreator
  def initialize(account, account_params)
    @account = account
    @account_params = account_params

    ActiveRecord::Base.transaction do
      create_account
      create_vendor_from_account
      create_starting_transaction
    end
  end

  def create_account
    @account.assign_attributes(@account_params.except(:starting_balance, :starting_date))
    @account.save
  end

  def create_vendor_from_account
    @account.budget.vendors.create!(name: "Transfer: " + @account.name, account: @account)
  end

  def create_starting_transaction
    starting_balance = @account_params[:starting_balance]
    return if starting_balance.empty?

    starting_date = @account_params[:starting_date].presence || Date.today
    vendor = @account.budget.vendors.find_or_create_by(name: "Starting Balance")
    category = @account.budget.categories.find_or_create_by(name: "Income Parent")
    subcategory = category.subcategories.find_or_create_by(name: "Income")

    trx_params = {
      date: starting_date,
      memo: "Starting Balance",
      vendor_id: vendor.id,
      lines_attributes: [
        {
          amount: starting_balance,
          subcategory_form_id: subcategory.id.to_s
        }
      ]
    }

    # trx = @account.trxes.build(trx_params)
    StartingTrxCreator.new(@account, trx_params)
    # TrxCreatorService.new.create_trx(trx, trx_params)

    @account.calculate_balance!
  end
end
