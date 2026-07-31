class CreateHealthJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :health_journal_entries do |t|
      t.references :client, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
