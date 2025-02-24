class Ledger < ApplicationRecord
  attr_readonly :category_id
  attr_readonly :date

  belongs_to :subcategory
  delegate :category, to: :subcategory
  belongs_to :prev, class_name: "Ledger", optional: true
  belongs_to :next, class_name: "Ledger", optional: true
  has_many :lines
  # has_many :trxes

  def self.ransackable_attributes(auth_object = nil)
    [ "subcategory_id", "date", "id", "prev_id", "user_changed", "budget", "actual", "balance", "carry_forward_negative_balance" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # note: these match belongs_to (no plurals)
    [ "subcategory" ]
  end

  validates :date, presence: true
  validates :subcategory, presence: true
  validate :last_day_of_month
  validate :unique_date_and_category, on: :create

  before_save :calculate_balance

  # #unused - delete if no issues arise
  # def trx_entries
  #   Trx.where(category_id: category_id)
  #      .where(date: (date.beginning_of_month..date.end_of_month))
  # end

  def change_carry_forward_negative_balance
    newValue = !carry_forward_negative_balance
    self.carry_forward_negative_balance = newValue
    self.user_changed = true unless self.user_changed
    save
    # update all next ledgers until user_changed = true
    find_next_ledgers.each do |ledger|
      return if ledger.user_changed
      if ledger.carry_forward_negative_balance != newValue
        ledger.update(carry_forward_negative_balance: newValue)
      end
    end
  end

  def calculate_balance
    # update actual figure first
    calculate_actual

    self.balance= (prev_balance + budget + actual)
  end

  def prev_balance
    if prev.nil?
      return 0
    end

    prev_balance = prev.balance || 0

    if prev.carry_forward_negative_balance == false
      prev_balance = [ prev_balance, 0 ].max
    end
    prev_balance
  end

  def calculate_actual
    self.actual = lines.sum(:amount)
  end

  def find_prev_ledgers
    Ledger.where("date < ?", date)
                          .where(subcategory_id: subcategory_id)
                          .order(date: :desc)
  end

  def find_next_ledgers
    Ledger.where("date > ?", date)
                        .where(subcategory_id: subcategory_id)
                        .order(date: :asc)
  end

  def last_day_of_month
    if date && date != date.end_of_month
      errors.add(:date, "must be the last day of the month")
    end
  end

  def unique_date_and_category
    if Ledger.exists?(date: date, subcategory_id: subcategory_id)
      errors.add(:base, "Record with this date and category already exists")
    end
  end

  def self.get_overspent_in_date_range(start_date, end_date)
    Ledger.where(carry_forward_negative_balance: false)
          .where(date: start_date.end_of_month .. end_date.end_of_month)
          .where("balance < ?", 0)
          .sum(:balance)
  end

  def self.get_overspent_before_month(date)
    date = date.prev_month.end_of_month
    Ledger.where(date: ..date)
        .where("balance < ?", 0)
        .sum do |ledger|
          if ledger.carry_forward_negative_balance
            0
          else
            ledger.balance
          end
        end
  end


  def self.get_budget_in_date_range(start_date, end_date)
    Ledger.where(date: start_date.end_of_month .. end_date.end_of_month)
          .sum(:budget)
  end

  def self.get_budget_sum_before_month(date)
    Ledger.where(date: .. date.prev_month.end_of_month)
          .sum(:budget)
  end

  def self.get_budget_sum_current_month(date)
    Ledger.where(date: date.end_of_month)
          .sum(:budget)
  end

  def self.rebuild_chain_for_subcategory(subcategory_id)
    ledgers = where(subcategory_id: subcategory_id)
              .order(:date, :id)
              .to_a

    # Clear existing relationships
    ledgers.each do |ledger|
      ledger.update_columns(prev_id: nil, next_id: nil)
    end

    # Build new chain
    ledgers.each_cons(2) do |current, next_ledger|
      current.update_columns(next_id: next_ledger.id)
      next_ledger.update_columns(prev_id: current.id)
    end
  end

  def toggle_carry_forward_and_propagate!
    # Toggle current ledger's carry_forward and mark as user changed
    self.carry_forward_negative_balance = !carry_forward_negative_balance
    self.user_changed = true
    save!

    # Propagate the new carry_forward value to future ledgers
    propagate_carry_forward_to_future_ledgers
  end

  private

  def propagate_carry_forward_to_future_ledgers
    current_ledger = self.next
    new_state = self.carry_forward_negative_balance

    while current_ledger.present? && !current_ledger.user_changed
      current_ledger.update!(
        carry_forward_negative_balance: new_state
      )
      current_ledger = current_ledger.next
    end
  end
end
