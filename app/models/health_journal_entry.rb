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
    # The plan lives on the enrollment, so a client can be basic with one
    # provider and premium with another. The allowance is counted per client
    # across every provider they write to, and a single premium enrollment lifts
    # it — the entry's own provider is deliberately not consulted. A client with
    # no enrollment at all gets the basic limit rather than an unlimited journal.
    def within_plan_entry_limit
      return if client.nil?
      return if client.enrollments.premium.exists?
      return if client.health_journal_entries.in_month.count < BASIC_PLAN_MONTHLY_ENTRY_LIMIT

      errors.add(
        :base, "basic plan is limited to #{BASIC_PLAN_MONTHLY_ENTRY_LIMIT} " \
          "health journal entries per calendar month")
    end
end
