class Enrollment < ApplicationRecord
  belongs_to :client
  belongs_to :provider

  str_enum :plan_type, %w[basic premium], default: nil

  # An open-ended enrollment is the one in force; the partial unique index
  # allows only one of them per client-provider pair.
  scope :current, -> { where(end_date: nil) }
end
