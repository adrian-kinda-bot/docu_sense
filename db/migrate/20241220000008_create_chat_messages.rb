class CreateChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :role, null: false
      t.integer :message_type, default: 0, null: false
      t.jsonb :metadata, default: {}
      t.integer :tokens_used
      t.decimal :cost, precision: 10, scale: 4

      t.timestamps
    end

    add_index :chat_messages, :role
    add_index :chat_messages, :message_type
    add_index :chat_messages, :metadata, using: :gin
  end
end
