class AddXeroCustomerIdToSpreeUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_users, :xero_customer_id, :string
  end
end
