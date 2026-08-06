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

  test "a basic pair may write up to the monthly limit" do
    fill_month(*basic_pair, MONTHLY_LIMIT - 1)

    assert_predicate build_entry(*basic_pair), :valid?
  end

  test "a basic pair is rejected once the month is full" do
    fill_month(*basic_pair, MONTHLY_LIMIT)
    entry = build_entry(*basic_pair)

    assert_not entry.valid?
    assert_includes entry.errors[:base],
                    "basic plan is limited to #{MONTHLY_LIMIT} health journal entries " \
                    "per provider per calendar month"
  end

  test "entries from earlier months do not count against the allowance" do
    fill_month(*basic_pair, MONTHLY_LIMIT, at: 1.month.ago)

    assert_predicate build_entry(*basic_pair), :valid?
  end

  test "the allowance resets on the first of the month" do
    fill_month(*basic_pair, MONTHLY_LIMIT)

    travel_to Time.current.next_month.beginning_of_month do
      assert_predicate build_entry(*basic_pair), :valid?
    end
  end

  test "a premium pair is not capped" do
    fill_month(*premium_pair, MONTHLY_LIMIT)

    assert_predicate build_entry(*premium_pair), :valid?
  end

  test "the allowance is per pair, so another provider's entries do not count" do
    client, = shared_basic_pair
    fill_month(client, providers(:provider_with_two_clients), MONTHLY_LIMIT)

    assert_predicate build_entry(*shared_basic_pair), :valid?
  end

  test "a premium enrollment elsewhere does not lift a basic pair's cap" do
    fill_month(*shared_basic_pair, MONTHLY_LIMIT)
    assert_predicate clients(:client_with_two_providers).enrollments.premium, :exists?

    assert_not build_entry(*shared_basic_pair).valid?
  end

  test "a pair with no enrollment falls back to the basic limit" do
    fill_month(*unenrolled_pair, MONTHLY_LIMIT)

    assert_not build_entry(*unenrolled_pair).valid?
  end

  test "a full month can still be edited" do
    client, provider = basic_pair
    fill_month(client, provider, MONTHLY_LIMIT)
    entry = client.health_journal_entries.where(provider: provider).newest_first.first

    assert entry.update(body: "Corrected the entry.")
  end

  private
    MONTHLY_LIMIT = HealthJournalEntry::BASIC_PLAN_MONTHLY_ENTRY_LIMIT

    def basic_pair
      [ clients(:client_with_one_provider), providers(:provider_with_two_clients) ]
    end

    def premium_pair
      [ clients(:client_with_two_providers), providers(:provider_with_two_clients) ]
    end

    # The same client as premium_pair, basic with its other provider — the pair
    # that shows the allowance does not follow the client around.
    def shared_basic_pair
      [ clients(:client_with_two_providers), providers(:provider_with_one_client) ]
    end

    def unenrolled_pair
      [ clients(:client_with_one_provider), providers(:provider_with_one_client) ]
    end

    def build_entry(client, provider)
      client.health_journal_entries.build(body: "One more entry.", provider: provider)
    end

    # Tops the pair's month up to the given size so the assertions read in terms
    # of the limit rather than the fixture count. The fixture entries are all
    # dated in the past, so they never land in the month being filled.
    def fill_month(client, provider, size, at: Time.current)
      written = client.health_journal_entries.where(provider: provider).in_month(at).count

      (size - written).times do |i|
        client.health_journal_entries.create!(body: "Filler entry #{i}.",
                                              provider: provider,
                                              created_at: at)
      end
    end
end
