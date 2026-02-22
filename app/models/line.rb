class Line < ApplicationRecord
  belongs_to :trx
  belongs_to :ledger
  delegate :subcategory, to: :ledger
  delegate :category, to: :subcategory
  delegate :vendor, to: :trx
  delegate :account, to: :trx
  delegate :date, to: :trx
  delegate :budget, to: :trx
  belongs_to :transfer_line, class_name: "Line", optional: true

  validates :amount, presence: true

  # has_one :transferee_line, class_name: "Line", foreign_key: "transfer_line_id"
  # has_one :transfer_vendor, through: :transfer_line
  attr_accessor :subcategory_form_id
  attr_accessor :transfer_account_id

  scope :income, -> {
    joins(ledger: { subcategory: :category })
      .merge(Category.income)
  }

  scope :expense, -> {
    joins(ledger: { subcategory: :category })
      .merge(Category.expense)
  }

  # Returns Hash[Date => Numeric] (keys are end-of-month dates) in one query.
  def self.income_sum_by_month_end_dates(lines_relation, month_end_dates)
    return {} if month_end_dates.blank?
    month_ends = month_end_dates.map { |d| d.respond_to?(:end_of_month) ? d.end_of_month : d }.uniq
    range = month_ends.min.beginning_of_month..month_ends.max.end_of_month
    result = lines_relation.income
      .joins(:trx)
      .where(trxes: { date: range })
      .reorder(nil)
      .group("DATE_TRUNC('month', trxes.date)::date")
      .sum(:amount)
    # Keys are first-of-month; convert to end_of_month for lookup
    result.transform_keys { |k| (k.respond_to?(:to_date) ? k.to_date : Date.parse(k.to_s)).end_of_month }
  end

  # This ensures empty parameters generate 0 instead of nil
  def amount=(value)
    if value.present?
      decimal_value = BigDecimal(value.to_s)
      super(decimal_value.round)
    else
      super(value)
    end
  end

  # Initialize transfer_account_id from the transfer line's transaction account
  def transfer_account_id
    # Return the stored value if it's already set
    return @transfer_account_id if defined?(@transfer_account_id) && @transfer_account_id.present?

    # Try to get it from the transfer line
    if transfer_line.present?
      @transfer_account_id = transfer_line.trx.account_id
    end

    @transfer_account_id
  end

  def transfer_account_id=(value)
    @transfer_account_id = value
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "amount", "created_at", "id", "ledger_id", "memo", "transfer_line_id", "trx_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "ledger", "trx", "transfer_line" ]
  end

  def set_ledger
    return unless subcategory_form_id.present?  # Guard clause

    subcategory = Subcategory.find_by(id: subcategory_form_id.to_i)  # More defensive find
    return unless subcategory  # Guard clause

    ledger = Ledger.find_or_create_by(
      date: trx.date.end_of_month,
      subcategory: subcategory
    )
    self.ledger = ledger
  end
end
