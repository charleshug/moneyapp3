class AccountEditingService

  def edit_account(account, account_params)
    account.update(account_params)
    if account.valid?
      #do something
    end

    update_vendor_from_account(account)

    account
  end

  def update_vendor_from_account(account)
    v = account.vendor
    v.update!(name: "Transfer: " + account.name)
  end

end