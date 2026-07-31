class Enrollment < ApplicationRecord
  belongs_to :client
  belongs_to :provider

  str_enum :plan_type, %w[basic premium], default: nil
end
