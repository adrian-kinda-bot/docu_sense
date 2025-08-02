class CreateDocumentEmbeddings < ActiveRecord::Migration[8.0]
  def change
    create_table :document_embeddings do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content_chunk, null: false
      t.text :embedding_vector, null: false
      t.integer :chunk_index, null: false
      t.integer :token_count, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :document_embeddings, :chunk_index
    add_index :document_embeddings, :token_count
    add_index :document_embeddings, :metadata, using: :gin
  end
end
