class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :active_subscription, foreign_key: { to_table: :subscriptions }
    add_column :users, :subscription_status, :string, default: 'inactive'
    add_column :users, :trial_ends_at, :datetime
    add_column :users, :billing_address, :text

    add_index :users, :subscription_status
  end
end
