class ScheduledTrx < ApplicationRecord
  FREQUENCIES = {
    "once" => "Once",
    "daily" => "Daily",
    "weekly" => "Weekly",
    "biweekly" => "Every Other Week",
    "semiweekly" => "Twice a Week",
    "every_4_weeks" => "Every 4 Weeks",
    "monthly" => "Monthly",
    "bimonthly" => "Every Other Month",
    "quarterly" => "Every 3 Months",
    "triannually" => "Every 4 Months",
    "semiannually" => "Twice a Year",
    "yearly" => "Yearly",
    "biyearly" => "Every Other Year"
  }

  belongs_to :account
  belongs_to :vendor
  has_many :scheduled_lines, dependent: :destroy
  accepts_nested_attributes_for :scheduled_lines, allow_destroy: true

  validates :frequency, inclusion: { in: FREQUENCIES.keys }
  validates :next_date, presence: true
  validates :account, :vendor, presence: true

  before_validation :convert_amounts

  def budget
    account&.budget
  end

  def create_trx!
    trx = nil

    ActiveRecord::Base.transaction do
      accounts_to_update = Set.new
      ledgers_to_update = Set.new
      # Build the transaction first without saving
      trx = account.trxes.build(
        date: next_date,
        memo: memo,
        vendor: vendor
      )

      # Build all lines before saving the transaction
      scheduled_lines.each do |scheduled_line|
        ledger = find_or_create_ledger(scheduled_line.subcategory)

        trx.lines.build(
          amount: scheduled_line.amount,
          memo: scheduled_line.memo,
          ledger: ledger
        )
      end

      # Now save the transaction with its lines
      trx.set_amount
      trx.save!
      accounts_to_update << trx.account
      trx.lines.each { |line| ledgers_to_update << line.ledger }

      # Create transfers after saving the transaction
      trx.lines.each_with_index do |line, index|
        scheduled_line = scheduled_lines[index]
        if scheduled_line.transfer_account
          transfer_trx = create_transfer_from_line(line, scheduled_line.transfer_account)
          line.update_column(:transfer_line_id, transfer_trx.lines.first.id)
          accounts_to_update << scheduled_line.transfer_account
          transfer_trx.lines.each { |line| ledgers_to_update << line.ledger }
        end
      end
      accounts_to_update.each { |account| account.calculate_balance! }
      ledgers_to_update.each { |ledger| LedgerService.recalculate_forward_ledgers(ledger) }

      # Update next_date based on frequency
      if frequency == "once"
        update!(active: false)
      else
        update!(next_date: calculate_next_date)
      end
    end

    trx
  end

  def set_amount
    self.amount = scheduled_lines.map(&:amount).sum  # This will sum the `amount` values from in-memory objects.
  end

  private

  def create_transfer_from_line(line, transfer_account)
    budget = line.budget
    trx = line.trx
    transfer_trx = budget.trxes.build(
      date: trx.date,
      memo: trx.memo,
      account: transfer_account,
      vendor: trx.account.vendor
    )
    transfer_trx.lines.build(
      transfer_line_id: line.id,
      amount: -line.amount,
      ledger: line.ledger
    )
    transfer_trx.set_amount
    transfer_trx.save!
    transfer_trx
  end

  def calculate_next_date
    case frequency
    when "daily"
      next_date + 1.day
    when "weekly"
      next_date + 1.week
    when "biweekly"
      next_date + 2.weeks
    when "semiweekly"
      next_date + 3.days
    when "every_4_weeks"
      next_date + 4.weeks
    when "monthly"
      next_date + 1.month
    when "bimonthly"
      next_date + 2.months
    when "quarterly"
      next_date + 3.months
    when "triannually"
      next_date + 4.months
    when "semiannually"
      next_date + 6.months
    when "yearly"
      next_date + 1.year
    when "biyearly"
      next_date + 2.years
    else
      next_date
    end
  end

  def convert_amounts
    scheduled_lines.each do |line|
      next if line.marked_for_destruction?
      next if line.amount.is_a?(Integer)

      # Convert amount from decimal string to integer cents
      line.amount = (BigDecimal(line.amount.to_s) * 100).to_i if line.amount.present?
    end
  end

  def find_or_create_ledger(subcategory)
    Ledger.find_or_create_by!(
      date: next_date.end_of_month,
      subcategory: subcategory
    ) do |l|
      l.carry_forward_negative_balance = false
    end
  end
end
