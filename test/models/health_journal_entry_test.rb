require "test_helper"

class HealthJournalEntryTest < ActiveSupport::TestCase
  test "belongs to a client" do
    assert_equal clients(:client_with_one_provider),
                 health_journal_entries(:oldest_entry).client
  end

  test "newest_first orders by most recent" do
    assert_equal [ health_journal_entries(:newest_entry), health_journal_entries(:oldest_entry) ],
                 clients(:client_with_one_provider).health_journal_entries.newest_first
  end
end
