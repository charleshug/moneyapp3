class TrxDeleteService
  def initialize(trx)
    @trx = trx
    @accounts = Set.new
    @ledgers = Set.new
  end

  def delete_trx
    collect_accounts_and_ledgers
    delete_transactions
    update_accounts
    update_ledgers
  end

  private

  def collect_accounts_and_ledgers
    @accounts << @trx.account
    @ledgers << @trx.ledger
    if @trx.transfer
      @accounts << @trx.transfer.account
      @ledgers << @trx.transfer.ledger
    end
  end

  def delete_transactions
    @trx.destroy!
    @trx.transfer&.destroy!
  end

  def update_accounts
    @accounts.each { |account| account.calculate_balance! }
  end

  def update_ledgers
    @ledgers.each do |ledger|
      LedgerService.new.recalculate_forward_ledgers(ledger)
    end
  end
end
