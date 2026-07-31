class Client < ApplicationRecord
  has_many :enrollments
  has_many :providers, through: :enrollments
  has_many :health_journal_entries
end
