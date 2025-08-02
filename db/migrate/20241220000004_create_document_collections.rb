class CreateDocumentCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :document_collections do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :category, default: 4, null: false
      t.integer :status, default: 0, null: false
      t.string :color
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :document_collections, :category
    add_index :document_collections, :status
    add_index :document_collections, :sort_order
  end
end
