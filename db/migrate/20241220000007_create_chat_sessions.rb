class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :document_collection, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :settings, default: {}
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :chat_sessions, :status
    add_index :chat_sessions, :last_activity_at
    add_index :chat_sessions, :settings, using: :gin
  end
end
