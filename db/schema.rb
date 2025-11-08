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

ActiveRecord::Schema[8.0].define(version: 2025_10_05_121602) do
  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plan_id", null: false
    t.bigint "subscription_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "paypal_payment_id"
    t.string "paypal_order_id"
    t.string "status", default: "pending", null: false
    t.string "payment_method", null: false
    t.datetime "payment_date", null: false
    t.text "notes"
    t.string "invoice_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["paypal_order_id"], name: "index_payments_on_paypal_order_id"
    t.index ["paypal_payment_id"], name: "index_payments_on_paypal_payment_id"
    t.index ["plan_id"], name: "index_payments_on_plan_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["subscription_id"], name: "index_payments_on_subscription_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "plans", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "duration_months", null: false
    t.string "plan_type", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "paypal_plan_id"
    t.text "description"
    t.boolean "active", default: true
    t.string "billing_cycle_type", default: "monthly"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "paypal_product_id"
    t.index ["duration_months", "plan_type"], name: "index_plans_on_duration_months_and_plan_type", unique: true
    t.index ["paypal_plan_id"], name: "index_plans_on_paypal_plan_id"
  end

  create_table "subscriptions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plan_id", null: false
    t.string "status", default: "active", null: false
    t.string "paypal_subscription_id"
    t.datetime "current_period_start", null: false
    t.datetime "current_period_end", null: false
    t.datetime "canceled_at"
    t.boolean "auto_renew", default: true
    t.datetime "next_payment_attempt"
    t.integer "retry_count", default: 0
    t.string "paypal_payer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_period_end"], name: "index_subscriptions_on_current_period_end"
    t.index ["paypal_subscription_id"], name: "index_subscriptions_on_paypal_subscription_id", unique: true
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "active_subscription_id"
    t.string "subscription_status", default: "inactive"
    t.datetime "trial_ends_at"
    t.text "billing_address"
    t.index ["active_subscription_id"], name: "index_users_on_active_subscription_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["subscription_status"], name: "index_users_on_subscription_status"
  end

  add_foreign_key "payments", "plans"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "payments", "users"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "users", "subscriptions", column: "active_subscription_id"
end
