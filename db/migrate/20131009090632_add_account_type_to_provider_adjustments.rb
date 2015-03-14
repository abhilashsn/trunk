class AddAccountTypeToProviderAdjustments < ActiveRecord::Migration
  def change
    add_column :provider_adjustments, :account_type, :string
  end
end
