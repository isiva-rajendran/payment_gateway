class AddPaypalProductIdToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :paypal_product_id, :string
  end
end
