class CreateOneTimeLoginTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :one_time_login_tokens do |t|
      t.string :token, null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end
    add_index :one_time_login_tokens, :token, unique: true
  end
end
