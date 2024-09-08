class SpendingByVendorReportService
  def self.get_hash_trx_by_vendor_cat(trxes_input)
    trx_amounts = SpendingByVendorReportService.get_hash_trx_by_vendor(trxes_input)
    trx_amounts.sort_by { |_, amount| amount }.to_h
    # Use the following line for descending order:
    # trx_amounts.sort_by { |_, amount| -amount }.to_h
  end

  def self.get_hash_trx_by_vendor(trxes_input)
    trx_amounts =     trxes_input.joins(:vendor, subcategory: :category)
    .where.not(vendor: { account_id: nil })  # Exclude trx where vendor's account is nil
    .where.not(categories: { normal_balance: "INCOME" })  # Exclude trx where category is INCOME
    .group("vendor.id", "vendor.name")  # Group by vendor_id and vendor name
    .order("SUM(amount) DESC")  # Order by the total sum of amounts for each vendor
    .sum(:amount)  # Sum the amounts for each vendor
    trx_amounts
  end

  def self.get_hash_trx_by_vendor_all
    SpendingByVendorReportService.get_hash_trx_by_vendor(@current_budget.trxes)
  end
end
