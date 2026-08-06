require "test_helper"

class HealthJournalEntryTest < ActiveSupport::TestCase
  test "belongs to a client" do
    assert_equal clients(:client_with_one_provider),
                 health_journal_entries(:oldest_entry).client
  end

  test "belongs to the provider it was written for" do
    assert_equal providers(:provider_with_one_client),
                 health_journal_entries(:cross_provider_entry).provider
  end

  test "requires a provider" do
    entry = HealthJournalEntry.new(client: clients(:client_with_one_provider), body: "No provider.")

    assert_not entry.valid?
    assert_includes entry.errors[:provider], "must exist"
  end

  test "newest_first orders by most recent" do
    assert_equal [ health_journal_entries(:newest_entry), health_journal_entries(:oldest_entry) ],
                 clients(:client_with_one_provider).health_journal_entries.newest_first
  end

  test "a basic client may write up to the monthly limit" do
    client = clients(:client_with_one_provider)
    fill_month(client, MONTHLY_LIMIT - 1)

    assert_predicate build_entry(client), :valid?
  end

  test "a basic client is rejected once the month is full" do
    client = clients(:client_with_one_provider)
    fill_month(client, MONTHLY_LIMIT)
    entry = build_entry(client)

    assert_not entry.valid?
    assert_includes entry.errors[:base],
                    "basic plan is limited to #{MONTHLY_LIMIT} health journal entries per calendar month"
  end

  test "entries from earlier months do not count against the allowance" do
    client = clients(:client_with_one_provider)
    fill_month(client, MONTHLY_LIMIT, at: 1.month.ago)

    assert_predicate build_entry(client), :valid?
  end

  test "the allowance resets on the first of the month" do
    client = clients(:client_with_one_provider)
    fill_month(client, MONTHLY_LIMIT)

    travel_to Time.current.next_month.beginning_of_month do
      assert_predicate build_entry(client), :valid?
    end
  end

  test "a single premium enrollment lifts the limit even alongside a basic one" do
    client = clients(:client_with_two_providers)
    assert_predicate client.enrollments.basic, :exists?
    fill_month(client, MONTHLY_LIMIT)

    assert_predicate build_entry(client), :valid?
  end

  test "a full month can still be edited" do
    client = clients(:client_with_one_provider)
    fill_month(client, MONTHLY_LIMIT)
    entry = client.health_journal_entries.newest_first.first

    assert entry.update(body: "Corrected the entry.")
  end

  private
    MONTHLY_LIMIT = HealthJournalEntry::BASIC_PLAN_MONTHLY_ENTRY_LIMIT

    def build_entry(client)
      client.health_journal_entries.build(body: "One more entry.", provider: client.providers.first)
    end

    # Tops the client's month up to the given size so the assertions read in
    # terms of the limit rather than the fixture count. The fixture entries are
    # all dated in the past, so they never land in the month being filled.
    def fill_month(client, size, at: Time.current)
      (size - client.health_journal_entries.in_month(at).count).times do |i|
        client.health_journal_entries.create!(body: "Filler entry #{i}.",
                                              provider: client.providers.first,
                                              created_at: at)
      end
    end
end
