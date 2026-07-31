class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :client, null: false, foreign_key: true, index: false
      t.references :provider, null: false, foreign_key: true
      t.string :plan_type, null: false

      t.timestamps
    end

    add_index :enrollments, [ :client_id, :provider_id ], unique: true
  end
end
