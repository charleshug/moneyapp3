class NetWorthReportService
  def self.get_hash_net_worth(trxes)
    transactions_by_month = trxes.group_by { |trx| trx.date.strftime("%Y-%m") }
    net_worth_hash = {}

    running_balance = 0
    transactions_by_month.each do |month, transactions|
      amount_for_month = transactions.sum(&:amount)
      running_balance += amount_for_month

      # Construct entry with Date, Amount, and Running Balance
      date = Date.parse(month + "-01")
      net_worth_hash[date] = { amount: amount_for_month, running_balance: running_balance }
    end

    net_worth_hash
  end
end
