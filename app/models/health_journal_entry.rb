class HealthJournalEntry < ApplicationRecord
  belongs_to :client

  scope :newest_first, -> { order(created_at: :desc) }
end
