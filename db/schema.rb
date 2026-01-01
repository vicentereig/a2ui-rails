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

ActiveRecord::Schema[8.1].define(version: 2026_01_01_215910) do
  create_table "briefings", force: :cascade do |t|
    t.json "activity_context"
    t.string "briefing_type", default: "daily", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.datetime "generated_at"
    t.json "health_context"
    t.integer "input_tokens", default: 0
    t.string "model"
    t.json "output"
    t.integer "output_tokens", default: 0
    t.integer "parent_id"
    t.json "performance_context"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["parent_id"], name: "index_briefings_on_parent_id"
    t.index ["user_id", "briefing_type"], name: "index_briefings_on_user_id_and_briefing_type"
    t.index ["user_id", "date", "briefing_type"], name: "index_briefings_on_user_id_and_date_and_briefing_type", unique: true
  end

  add_foreign_key "briefings", "briefings", column: "parent_id"
end
