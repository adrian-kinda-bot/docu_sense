class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :document_collection, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content
      t.integer :file_type, null: false
      t.bigint :file_size, null: false
      t.integer :status, default: 0, null: false
      t.datetime :processed_at
      t.integer :page_count
      t.string :checksum
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :documents, :file_type
    add_index :documents, :status
    add_index :documents, :processed_at
    add_index :documents, :metadata, using: :gin
  end
end
