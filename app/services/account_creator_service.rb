class AccountCreatorService

  def create_account(account)
    account.save
    if account.invalid?
      #do something when account fails
      return account
    end

    create_vendor_from_account(account)

    if account.starting_balance != 0
      create_starting_transaction(account)
      account.calculate_balance!
    end

    account
  end

  def create_starting_transaction(account)
    vendor = account.budget.vendors.find_or_create_by(name: "Starting Balance")

    category = account.budget.categories.find_or_create_by(name: "Income Parent")
    subcategory = category.subcategories.find_or_create_by(name: "Income")

    trx = account.trxes.build(
      date: account.starting_date,
      amount: account.starting_balance,
      memo: "Starting Balance",
      vendor: vendor,
      subcategory: subcategory
    )
    TrxCreatorService.new.create_trx(trx)
  end

  def create_vendor_from_account(account)
    account.budget.vendors.create!(name: "Transfer: " + account.name, account: account)
    #Vendor.create!(name: "Transfer: " + account.name, account_id: account.id )
  end

end