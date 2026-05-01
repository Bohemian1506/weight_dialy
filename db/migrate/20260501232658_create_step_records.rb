class CreateStepRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :step_records do |t|
      t.references :user, null: false, foreign_key: true
      t.date    :recorded_on,     null: false
      t.integer :steps,           null: false, default: 0
      t.integer :distance_meters, null: false, default: 0
      t.integer :flights_climbed, null: false, default: 0
      t.timestamps
    end

    add_index :step_records, [ :user_id, :recorded_on ], unique: true
  end
end
