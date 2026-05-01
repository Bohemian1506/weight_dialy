class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      # user is nullable: unauthorized requests have no associated user
      t.references :user, null: true, foreign_key: true
      t.jsonb   :payload,       null: false, default: {}
      t.string  :status,        null: false  # success / unauthorized / invalid
      t.string  :error_message
      t.datetime :received_at,  null: false
    end

    add_index :webhook_deliveries, :received_at
  end
end
