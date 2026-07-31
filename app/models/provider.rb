class Provider < ApplicationRecord
  has_many :enrollments
  has_many :clients, through: :enrollments
  has_many :health_journal_entries, through: :clients
end
