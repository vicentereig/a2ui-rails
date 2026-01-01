class CreateBriefings < ActiveRecord::Migration[8.1]
  def change
    create_table :briefings do |t|
      t.string :user_id, null: false
      t.date :date, null: false
      t.string :briefing_type, null: false, default: 'daily'

      # Input contexts stored as JSON
      t.json :health_context
      t.json :activity_context
      t.json :performance_context

      # Output stored as JSON
      t.json :output

      # Token tracking
      t.string :model
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0

      # Parent reference for hierarchical briefings (week -> days)
      t.references :parent, foreign_key: { to_table: :briefings }

      t.datetime :generated_at
      t.timestamps
    end

    add_index :briefings, [:user_id, :date, :briefing_type], unique: true
    add_index :briefings, [:user_id, :briefing_type]
  end
end
