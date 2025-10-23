class Account < ApplicationRecord
  validates :balance, presence: true
  validates :name, presence: true
  validates :on_budget, inclusion: { in: [ true, false ] }
  validates :closed, inclusion: { in: [ true, false ] }

  belongs_to :budget
  has_many :trxes
  has_many :scheduled_trxes
  has_one :vendor, dependent: :destroy

  # attr_accessor :starting_balance, :starting_date
  before_destroy :ensure_no_trxes
  after_create :create_transfer_vendor
  after_update :update_transfer_vendor_name, if: :saved_change_to_name?

  def self.ransackable_attributes(auth_object = nil)
    [ "balance", "budget_id", "closed", "created_at", "id", "name", "on_budget", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "budget", "trxes", "vendors" ]
  end

  def calculate_balance
    self.balance = self.trxes.sum(:amount)
  end

  def calculate_balance!
    calculate_balance
    self.save!
  end

  def self.calculate_balances!
    # TODO - limit this to current budget
    Account.all.each do |account|
      account.calculate_balance!
    end
  end

  def self.for_select
    {
    "On-Budget"    => where(on_budget: true).map     { |p| [ p.name, p.id ] },
    "Off-Budget"   => where.not(on_budget: true).map { |p| [ p.name, p.id ] }
    }
  end

  def ensure_no_trxes
    if trxes.any?
      errors.add(:base, "Cannot delete account with associated trxes")
      throw :abort
    end
  end

  private

  def create_transfer_vendor
    budget.vendors.create!(name: "Transfer: #{name}", account: self)
  end

  def update_transfer_vendor_name
    vendor&.update!(name: "Transfer: #{name}")
  end
end
