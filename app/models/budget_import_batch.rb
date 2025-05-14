class BudgetImportBatch < ApplicationRecord
  belongs_to :budget
  # serialize :parsed_ledgers

  validates :parsed_ledgers, presence: true
  validates :budget, presence: true

  # Clean up old import batches to prevent DB bloat
  def self.cleanup_old_batches
    where("created_at < ?", 1.hour.ago).destroy_all
  end

  # Ensure parsed_ledgers is always an array
  def parsed_ledgers=(value)
    super(Array.wrap(value))
  end

  def parsed_ledgers
    super || []
  end
end
