require "test_helper"

class ProviderTest < ActiveSupport::TestCase
  test "has many clients through enrollments" do
    assert_equal [ clients(:client_with_two_providers), clients(:client_with_one_provider) ],
                 providers(:provider_with_two_clients).clients.order(:name)
  end

  test "clients are scoped to the provider" do
    assert_equal [ clients(:client_with_two_providers) ],
                 providers(:provider_with_one_client).clients
  end

  test "has many journal entries, interleaved across its clients" do
    assert_equal [ health_journal_entries(:newest_entry),
                   health_journal_entries(:middle_entry),
                   health_journal_entries(:oldest_entry) ],
                 providers(:provider_with_two_clients).health_journal_entries.newest_first
  end

  test "journal entries exclude those a shared client addressed elsewhere" do
    assert_equal [ health_journal_entries(:cross_provider_entry) ],
                 providers(:provider_with_one_client).health_journal_entries
  end
end
