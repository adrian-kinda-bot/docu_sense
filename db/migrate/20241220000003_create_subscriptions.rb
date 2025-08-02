class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :customer, null: false, foreign_key: true
      t.integer :plan_type, null: false
      t.integer :status, default: 0, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :monthly_price, precision: 10, scale: 2, null: false
      t.text :notes
      t.string :stripe_subscription_id
      t.string :stripe_customer_id

      t.timestamps
    end

    add_index :subscriptions, :plan_type
    add_index :subscriptions, :status
    add_index :subscriptions, :start_date
    add_index :subscriptions, :end_date
  end
end
