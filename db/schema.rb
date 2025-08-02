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

ActiveRecord::Schema[8.0].define(version: 2025_08_02_072646) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.integer "role", null: false
    t.integer "message_type", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.integer "tokens_used"
    t.decimal "cost", precision: 10, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
    t.index ["message_type"], name: "index_chat_messages_on_message_type"
    t.index ["metadata"], name: "index_chat_messages_on_metadata", using: :gin
    t.index ["role"], name: "index_chat_messages_on_role"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "document_collection_id", null: false
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "settings", default: {}
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_collection_id"], name: "index_chat_sessions_on_document_collection_id"
    t.index ["last_activity_at"], name: "index_chat_sessions_on_last_activity_at"
    t.index ["settings"], name: "index_chat_sessions_on_settings", using: :gin
    t.index ["status"], name: "index_chat_sessions_on_status"
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "domain", null: false
    t.integer "status", default: 0, null: false
    t.text "description"
    t.string "phone"
    t.string "address"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_customers_on_domain", unique: true
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["status"], name: "index_customers_on_status"
  end

  create_table "document_collections", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "category", default: 4, null: false
    t.integer "status", default: 0, null: false
    t.string "color"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_document_collections_on_category"
    t.index ["customer_id"], name: "index_document_collections_on_customer_id"
    t.index ["sort_order"], name: "index_document_collections_on_sort_order"
    t.index ["status"], name: "index_document_collections_on_status"
  end

  create_table "document_embeddings", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.text "content_chunk", null: false
    t.text "embedding_vector", null: false
    t.integer "chunk_index", null: false
    t.integer "token_count", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chunk_index"], name: "index_document_embeddings_on_chunk_index"
    t.index ["document_id"], name: "index_document_embeddings_on_document_id"
    t.index ["metadata"], name: "index_document_embeddings_on_metadata", using: :gin
    t.index ["token_count"], name: "index_document_embeddings_on_token_count"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "document_collection_id", null: false
    t.string "title", null: false
    t.text "content"
    t.integer "file_type", null: false
    t.bigint "file_size", null: false
    t.integer "status", default: 0, null: false
    t.datetime "processed_at"
    t.integer "page_count"
    t.string "checksum"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_collection_id"], name: "index_documents_on_document_collection_id"
    t.index ["file_type"], name: "index_documents_on_file_type"
    t.index ["metadata"], name: "index_documents_on_metadata", using: :gin
    t.index ["processed_at"], name: "index_documents_on_processed_at"
    t.index ["status"], name: "index_documents_on_status"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.integer "plan_type", null: false
    t.integer "status", default: 0, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.decimal "monthly_price", precision: 10, scale: 2, null: false
    t.text "notes"
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["end_date"], name: "index_subscriptions_on_end_date"
    t.index ["plan_type"], name: "index_subscriptions_on_plan_type"
    t.index ["start_date"], name: "index_subscriptions_on_start_date"
    t.index ["status"], name: "index_subscriptions_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "first_name", null: false
    t.string "last_name"
    t.integer "role", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.bigint "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["customer_id"], name: "index_users_on_customer_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "chat_sessions", "document_collections"
  add_foreign_key "chat_sessions", "users"
  add_foreign_key "document_collections", "customers"
  add_foreign_key "document_embeddings", "documents"
  add_foreign_key "documents", "document_collections"
  add_foreign_key "subscriptions", "customers"
  add_foreign_key "users", "customers"
end
