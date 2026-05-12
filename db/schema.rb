# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_12_015038) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "one_time_login_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_one_time_login_tokens_on_expires_at"
    t.index ["token"], name: "index_one_time_login_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_one_time_login_tokens_on_user_id"
  end

  create_table "step_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "distance_meters", default: 0, null: false
    t.integer "flights_climbed", default: 0, null: false
    t.date "recorded_on", null: false
    t.integer "steps", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "recorded_on"], name: "index_step_records_on_user_id_and_recorded_on", unique: true
    t.index ["user_id"], name: "index_step_records_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "image_url"
    t.string "name", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_token"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["webhook_token"], name: "index_users_on_webhook_token", unique: true
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "accepted_count"
    t.string "error_message"
    t.jsonb "payload", default: {}, null: false
    t.datetime "received_at", null: false
    t.string "status", null: false
    t.bigint "user_id"
    t.index ["received_at"], name: "index_webhook_deliveries_on_received_at"
    t.index ["user_id"], name: "index_webhook_deliveries_on_user_id"
  end

  add_foreign_key "one_time_login_tokens", "users", on_delete: :cascade
  add_foreign_key "step_records", "users", on_delete: :cascade
  add_foreign_key "webhook_deliveries", "users", on_delete: :cascade
end
