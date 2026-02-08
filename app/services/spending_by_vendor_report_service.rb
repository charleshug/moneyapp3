class SpendingByVendorReportService
  # Returns hash of (vendor_id, vendor_name) => amount (cents), sorted ascending by amount.
  # For expenses (negative amounts), ascending means biggest spenders first (e.g. Landlord, then Trader Joe's, ...).
  def self.get_hash_trx_by_vendor_cat(trxes_input)
    return {} if trxes_input.empty?
    trx_amounts = SpendingByVendorReportService.get_hash_trx_by_vendor(trxes_input)
    trx_amounts.sort_by { |_, amount| amount }.to_h
  end

  # Returns array of { label:, value: } for pie chart: top 9 vendors + "Others" (value in dollars).
  # Pass the result of get_hash_trx_by_vendor_cat (already sorted ascending = biggest expenses first).
  def self.chart_data_top9_plus_others(vendor_amount_hash)
    return [] if vendor_amount_hash.blank?
    sorted = vendor_amount_hash.to_a
    top9 = sorted.first(9).map { |(_, name), amount| { label: name.presence || 'N/A', value: amount / 100.0 } }
    others_sum = sorted.drop(9).sum(&:last)
    # Add "Others" when there are vendors beyond top 9 (amounts may be negative for expenses)
    top9 << { label: 'Others', value: others_sum / 100.0 } if sorted.size > 9
    top9
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
