require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "has many providers through enrollments" do
    assert_equal [ providers(:provider_with_one_client), providers(:provider_with_two_clients) ],
                 clients(:client_with_two_providers).providers.order(:name)
  end

  test "a client can be signed up with a single provider" do
    assert_equal [ providers(:provider_with_two_clients) ],
                 clients(:client_with_one_provider).providers
  end

  test "has many journal entries" do
    assert_equal [ health_journal_entries(:oldest_entry), health_journal_entries(:newest_entry) ],
                 clients(:client_with_one_provider).health_journal_entries.order(:created_at)
  end

  test "journal entries are scoped to the client but span its providers" do
    assert_equal [ health_journal_entries(:middle_entry),
                   health_journal_entries(:cross_provider_entry) ],
                 clients(:client_with_two_providers).health_journal_entries.order(:created_at)
  end
end
