class TransferService
  attr_reader :trx

  def initialize(trx)
    @trx = trx
  end

  def process
    return if trx.is_transfer # Prevent recursive transfers

    transfer_account = determine_transfer_account
    return unless transfer_account

    create_transfer_trx(transfer_account)
  end

  private

  def determine_transfer_account
    return trx.vendor.account if vendor_transfer?

    line_with_transfer = trx.lines.find { |line| line.transfer_account.present? }
    line_with_transfer&.transfer_account
  end

  def vendor_transfer?
    trx.vendor&.account?
  end

  def create_transfer_trx(transfer_account)
    transfer_trx_params = {
      account_id: transfer_account.id,
      vendor_id: trx.vendor_id,
      date: trx.date,
      lines_attributes: build_transfer_lines,
      is_transfer: true # Flag to prevent infinite recursion
    }

    TrxCreatorService.new(trx.budget, transfer_trx_params).create_trx
  end

  def build_transfer_lines
    trx.lines.map do |line|
      {
        subcategory_id: line.subcategory_id,
        amount: -line.amount, # Reverse the amount
        transfer_account_id: trx.account_id # Set original account as the counter transfer
      }
    end
  end
end
