class AddPayerIdAndSubscriptionIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :payer_id, :string
    add_column :users, :subscription_id, :string
  end
end
