class SpendingByVendorReportService
  def self.get_hash_trx_by_vendor_cat(trxes_input)
    return {} if trxes_input.empty?
    trx_amounts = SpendingByVendorReportService.get_hash_trx_by_vendor(trxes_input)
    trx_amounts.sort_by { |_, amount| amount }.to_h
    # Use the following line for descending order:
    # trx_amounts.sort_by { |_, amount| -amount }.to_h
  end

  def self.get_hash_trx_by_vendor(trxes_input)
    # return {} if trxes_input.empty?
    # trx_amounts =     trxes_input
    # .joins(lines: { ledger: { subcategory: :category }, trx: :vendor })
    # .where(lines: { line_transfer_id: nil })  # Exclude trx whose lines have a value in line_transfer_id
    # # .where.not(vendor: { account_id: nil })  # Exclude trx where vendor's account is nil
    # # .where.not(categories: { normal_balance: "INCOME" })  # Exclude trx where category is INCOME
    # .group("vendors.id", "vendors.name")  # Group by vendor_id and vendor name
    # # .order("SUM(lines.amount) DESC")  # Order by the total sum of amounts for each vendor
    # .sum("trxes.amount")  # Sum the amounts for each vendor
    # trx_amounts

    return {} if trxes_input.empty?
    trx_amounts = trxes_input
      .joins(lines: { ledger: { subcategory: :category }, trx: :vendor })
      .where(lines: { transfer_line_id: nil })  # Exclude trx whose lines have a value in line_transfer_id
      .group("vendors.id", "vendors.name")  # Group by vendors.id and vendors.name
      .sum("trxes.amount")  # Sum the amounts for each vendor
    trx_amounts
  end

  def self.get_hash_trx_by_vendor_all
    SpendingByVendorReportService.get_hash_trx_by_vendor(@current_budget.trxes)
  end
end
