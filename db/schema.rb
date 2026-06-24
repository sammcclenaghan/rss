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

ActiveRecord::Schema[8.1].define(version: 2026_06_23_120003) do
  create_table "feeds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "last_accessed_at", default: 0, null: false
    t.bigint "last_fetched_at", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 250, null: false
    t.index ["last_accessed_at"], name: "index_feeds_on_last_accessed_at"
    t.index ["last_fetched_at"], name: "index_feeds_on_last_fetched_at"
    t.index ["url"], name: "index_feeds_on_url", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.integer "feed_id", null: false
    t.string "guid", limit: 250, null: false
    t.bigint "published_at", null: false
    t.string "thumbnail", default: "", null: false
    t.string "title", limit: 250, null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 250, null: false
    t.index ["feed_id", "guid"], name: "index_posts_on_feed_id_and_guid", unique: true
    t.index ["feed_id"], name: "index_posts_on_feed_id"
    t.index ["published_at"], name: "index_posts_on_published_at"
  end

  create_table "read_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_read_posts_on_post_id", unique: true
  end

  add_foreign_key "posts", "feeds"
  add_foreign_key "read_posts", "posts", on_delete: :cascade
end
