class Account < ApplicationRecord
  validates :balance, presence: true
  validates :name, presence: true
  validates :on_budget, inclusion: { in: [ true, false ] }
  validates :closed, inclusion: { in: [ true, false ] }

  belongs_to :budget
  has_many :trxes
  has_one :vendor, dependent: :destroy

  attr_accessor :starting_balance, :starting_date
  before_destroy :ensure_no_trxes

  def self.ransackable_attributes(auth_object = nil)
    [ "name", "balance", "on_budget", "closed" ]
  end

  def calculate_balance
    self.balance = self.trxes.sum(:amount)
  end

  def calculate_balance!
    calculate_balance
    self.save!
  end

  def self.calculate_balances!
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
end
