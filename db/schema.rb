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

ActiveRecord::Schema[8.1].define(version: 2026_08_25_174000) do
  create_table "expenses", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.string "category", default: "", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.text "notes", default: "", null: false
    t.date "spent_on", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "spent_on"], name: "index_expenses_on_user_id_and_spent_on"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "payment_days", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "due_day", null: false
    t.text "notes", default: "", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "due_day"], name: "index_payment_days_on_user_id_and_due_day"
    t.index ["user_id"], name: "index_payment_days_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "amount_cents", null: false
    t.integer "billing_month"
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.integer "due_day"
    t.string "interval", default: "monthly", null: false
    t.text "notes", default: "", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "title"], name: "index_subscriptions_on_user_id_and_title"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "auto_lock", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "fx", default: "{}", null: false
    t.string "home_currency", default: "BRL", null: false
    t.string "income_currency", default: "BRL", null: false
    t.integer "monthly_income_cents", default: 0, null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "expenses", "users"
  add_foreign_key "payment_days", "users"
  add_foreign_key "subscriptions", "users"
end
