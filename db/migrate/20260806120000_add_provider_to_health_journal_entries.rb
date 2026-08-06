class AddProviderToHealthJournalEntries < ActiveRecord::Migration[8.1]
  def up
    add_reference :health_journal_entries, :provider, foreign_key: true

    # Existing entries predate the column. Attribute each one to the provider
    # its client enrolled with first, which is unambiguous for every client
    # holding a single enrollment and a reasonable guess for the rest.
    execute <<~SQL.squish
      UPDATE health_journal_entries
      SET provider_id = (
        SELECT enrollments.provider_id FROM enrollments
        WHERE enrollments.client_id = health_journal_entries.client_id
        ORDER BY enrollments.id
        LIMIT 1
      )
    SQL

    change_column_null :health_journal_entries, :provider_id, false
  end

  def down
    remove_reference :health_journal_entries, :provider, foreign_key: true
  end
end
