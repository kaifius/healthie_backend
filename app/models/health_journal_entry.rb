class HealthJournalEntry < ApplicationRecord
  BASIC_PLAN_MONTHLY_ENTRY_LIMIT = 10

  belongs_to :client
  belongs_to :provider

  scope :newest_first, -> { order(created_at: :desc) }
  # Calendar month in the app's time zone, not a rolling 30 days: the allowance
  # resets on the 1st.
  scope :in_month, ->(time = Time.current) { where(created_at: time.all_month) }

  validate :within_plan_entry_limit, on: :create

  private
    # The plan lives on the enrollment, so the allowance belongs to the
    # client-provider pair: the same client can be capped with one provider and
    # unlimited with another, and each pair's entries are counted on their own.
    # A pair with no current enrollment gets the basic limit rather than an
    # unlimited journal.
    def within_plan_entry_limit
      return if client.nil? || provider.nil?
      return if enrollment&.premium?
      return if pair_entries.in_month.count < BASIC_PLAN_MONTHLY_ENTRY_LIMIT

      errors.add(
        :base, "basic plan is limited to #{BASIC_PLAN_MONTHLY_ENTRY_LIMIT} " \
          "health journal entries per provider per calendar month")
    end

    def enrollment
      client.enrollments.current.find_by(provider_id: provider_id)
    end

    def pair_entries
      client.health_journal_entries.where(provider_id: provider_id)
    end
end
