class ImportBatch < ApplicationRecord
  belongs_to :budget

  validates :parsed_trxes, presence: true
  validates :budget, presence: true

  # Clean up old import batches to prevent DB bloat
  def self.cleanup_old_batches
    where("created_at < ?", 1.hour.ago).destroy_all
  end

  # Ensure parsed_trxes is always an array
  def parsed_trxes=(value)
    super(Array.wrap(value))
  end

  def parsed_trxes
    super || []
  end
end
