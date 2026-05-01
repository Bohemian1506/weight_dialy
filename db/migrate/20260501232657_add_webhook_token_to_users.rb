class AddWebhookTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :webhook_token, :string
    add_index :users, :webhook_token, unique: true

    # Backfill existing users so they can authenticate immediately.
    # has_secure_token auto-generates on create; existing rows would remain nil
    # without this step, making their webhook endpoints unusable.
    reversible do |dir|
      dir.up { User.find_each(&:regenerate_webhook_token) }
    end
  end
end
