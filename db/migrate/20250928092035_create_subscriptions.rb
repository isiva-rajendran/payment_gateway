class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :status, null: false, default: 'active'
      t.string :paypal_subscription_id
      t.datetime :current_period_start, null: false
      t.datetime :current_period_end, null: false
      t.datetime :canceled_at
      t.boolean :auto_renew, default: true
      t.datetime :next_payment_attempt
      t.integer :retry_count, default: 0
      t.string :paypal_payer_id

      t.timestamps
    end

    add_index :subscriptions, :paypal_subscription_id, unique: true
    add_index :subscriptions, :status
    add_index :subscriptions, :current_period_end
  end
end
