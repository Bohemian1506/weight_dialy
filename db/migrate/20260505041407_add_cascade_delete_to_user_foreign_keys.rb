class AddCascadeDeleteToUserForeignKeys < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :step_records, :users
    add_foreign_key :step_records, :users, on_delete: :cascade

    remove_foreign_key :webhook_deliveries, :users
    add_foreign_key :webhook_deliveries, :users, on_delete: :cascade
  end
end
