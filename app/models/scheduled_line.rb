class ScheduledLine < ApplicationRecord
  belongs_to :scheduled_trx
  belongs_to :subcategory
  belongs_to :transfer_account, class_name: "Account", optional: true
end
