class AddIndexToOneTimeLoginTokensExpiresAt < ActiveRecord::Migration[8.1]
  def change
    add_index :one_time_login_tokens, :expires_at
  end
end
