class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.references :subscription, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :paypal_payment_id
      t.string :paypal_order_id
      t.string :status, null: false, default: 'pending'
      t.string :payment_method, null: false
      t.datetime :payment_date, null: false
      t.text :notes
      t.string :invoice_id

      t.timestamps
    end

    add_index :payments, :paypal_payment_id
    add_index :payments, :paypal_order_id
    add_index :payments, :status
    add_index :payments, :payment_date
    add_index :payments, :invoice_id
  end
end
