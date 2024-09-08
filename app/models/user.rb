class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :budgets, dependent: :destroy

  # has_one :last_viewed_budget, class_name: "Budget", optional: true

  def set_current_budget(budget = nil)
    if budget.nil?
      budget = self.budgets.first
    end
    debugger
    self.update(last_viewed_budget_id: budget)
  end
end
