class OptimizeDocumentEmbeddings < ActiveRecord::Migration[8.0]
  def change
    # Add embeddings_count to documents for efficient counting
    add_column :documents, :embeddings_count, :integer, default: 0, null: false
    add_index :documents, :embeddings_count

    # Add composite indexes for better query performance
    add_index :document_embeddings, [ :document_id, :chunk_index ], name: 'index_embeddings_on_document_and_chunk'
    add_index :document_embeddings, [ :document_id, :token_count ], name: 'index_embeddings_on_document_and_tokens'

    # Note: Vector similarity index will be added when pgvector is installed
    # For now, embedding_vector is stored as text and GIN indexes require operator classes
    # When pgvector is set up, change column type to vector and add appropriate index (ivfflat/hnsw)

    # Update existing documents with their embedding counts
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE documents
          SET embeddings_count = (
            SELECT COUNT(*)
            FROM document_embeddings
            WHERE document_embeddings.document_id = documents.id
          )
        SQL
      end
    end
  end
end
