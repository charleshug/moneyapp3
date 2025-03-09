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

ActiveRecord::Schema[7.2].define(version: 2025_03_09_222911) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "balance", default: 0, null: false
    t.boolean "on_budget", default: true, null: false
    t.boolean "closed", default: false, null: false
    t.bigint "budget_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_accounts_on_budget_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "currency"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_budgets_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "hidden", default: false, null: false
    t.string "normal_balance", default: "EXPENSE", null: false
    t.bigint "budget_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_categories_on_budget_id"
  end

  create_table "import_batches", force: :cascade do |t|
    t.bigint "budget_id", null: false
    t.json "parsed_trxes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id"], name: "index_import_batches_on_budget_id"
    t.index ["created_at"], name: "index_import_batches_on_created_at"
  end

  create_table "ledgers", force: :cascade do |t|
    t.date "date", null: false
    t.integer "budget", default: 0, null: false
    t.integer "actual", default: 0, null: false
    t.integer "balance", default: 0, null: false
    t.boolean "carry_forward_negative_balance", default: false, null: false
    t.boolean "user_changed", default: false, null: false
    t.bigint "subcategory_id", null: false
    t.bigint "next_id"
    t.bigint "prev_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rolling_balance", default: 0, null: false
    t.index ["date", "subcategory_id"], name: "index_ledgers_on_date_and_subcategory_id", unique: true, comment: "One ledger per date/category"
    t.index ["next_id"], name: "index_ledgers_on_next_id"
    t.index ["prev_id"], name: "index_ledgers_on_prev_id"
    t.index ["subcategory_id"], name: "index_ledgers_on_subcategory_id"
  end

  create_table "lines", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.string "memo"
    t.bigint "ledger_id", null: false
    t.bigint "trx_id", null: false
    t.bigint "transfer_line_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ledger_id"], name: "index_lines_on_ledger_id"
    t.index ["transfer_line_id"], name: "index_lines_on_transfer_line_id"
    t.index ["trx_id"], name: "index_lines_on_trx_id"
  end

  create_table "scheduled_lines", force: :cascade do |t|
    t.bigint "scheduled_trx_id", null: false
    t.bigint "subcategory_id", null: false
    t.integer "amount", default: 0, null: false
    t.string "memo"
    t.bigint "transfer_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_trx_id"], name: "index_scheduled_lines_on_scheduled_trx_id"
    t.index ["subcategory_id"], name: "index_scheduled_lines_on_subcategory_id"
    t.index ["transfer_account_id"], name: "index_scheduled_lines_on_transfer_account_id"
  end

  create_table "scheduled_trxes", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.bigint "account_id", null: false
    t.bigint "vendor_id"
    t.date "next_date", null: false
    t.string "frequency", null: false
    t.string "memo"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_scheduled_trxes_on_account_id"
    t.index ["vendor_id"], name: "index_scheduled_trxes_on_vendor_id"
  end

  create_table "subcategories", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "hidden", default: false, null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
  end

  create_table "trxes", force: :cascade do |t|
    t.date "date", null: false
    t.integer "amount", default: 0, null: false
    t.string "memo"
    t.bigint "account_id", null: false
    t.bigint "vendor_id", null: false
    t.boolean "cleared", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_trxes_on_account_id"
    t.index ["vendor_id"], name: "index_trxes_on_vendor_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_viewed_budget_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vendors", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "budget_id", null: false
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_vendors_on_account_id"
    t.index ["budget_id"], name: "index_vendors_on_budget_id"
  end

  add_foreign_key "accounts", "budgets"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "budgets"
  add_foreign_key "import_batches", "budgets"
  add_foreign_key "ledgers", "ledgers", column: "next_id"
  add_foreign_key "ledgers", "ledgers", column: "prev_id"
  add_foreign_key "ledgers", "subcategories"
  add_foreign_key "lines", "ledgers"
  add_foreign_key "lines", "lines", column: "transfer_line_id"
  add_foreign_key "lines", "trxes"
  add_foreign_key "scheduled_lines", "accounts", column: "transfer_account_id"
  add_foreign_key "scheduled_lines", "scheduled_trxes"
  add_foreign_key "scheduled_lines", "subcategories"
  add_foreign_key "scheduled_trxes", "accounts"
  add_foreign_key "scheduled_trxes", "vendors"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "trxes", "accounts"
  add_foreign_key "trxes", "vendors"
  add_foreign_key "vendors", "accounts"
  add_foreign_key "vendors", "budgets"
end
