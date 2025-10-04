class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.integer :duration_months, null: false
      t.string :plan_type, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :paypal_plan_id
      t.text :description
      t.boolean :active, default: true
      t.string :billing_cycle_type, default: 'monthly'

      t.timestamps
    end

    add_index :plans, [:duration_months, :plan_type], unique: true
    add_index :plans, :paypal_plan_id
  end
end
