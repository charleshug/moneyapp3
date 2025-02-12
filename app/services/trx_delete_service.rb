class TrxDeleteService
  def initialize(trx)
    @trx = trx
    @trxes = Set.new
    @accounts = Set.new
    @ledgers = Set.new
  end

  def delete_trx
    collect_trxes
    collect_accounts
    collect_ledgers
    delete_transactions
    update_accounts
    update_ledgers
  end

  private

  def collect_trxes
    @trxes << @trx
    @trx.lines.each do |line|
      @trxes << line.transfer_line.trx if line.transfer_line&.trx
    end
  end

  def collect_accounts
    @trxes.each do |trx|
      @accounts << trx.account if trx.account
    end
  end

  def collect_ledgers
    @trxes.each do |trx|
      trx.lines.each do |line|
        @ledgers << line.ledger if line.ledger
      end
    end
  end

  def delete_transactions
    @trxes.each { |trx| trx.destroy! }
  end

  def update_accounts
    @accounts.each { |account| account.calculate_balance! }
  end

  def update_ledgers
    @ledgers.each { |ledger| LedgerService.new.recalculate_forward_ledgers(ledger) }
  end
end
