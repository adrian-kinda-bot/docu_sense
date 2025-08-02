class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :domain, null: false
      t.integer :status, default: 0, null: false
      t.text :description
      t.string :phone
      t.string :address
      t.string :website

      t.timestamps
    end

    add_index :customers, :email, unique: true
    add_index :customers, :domain, unique: true
    add_index :customers, :status
  end
end
