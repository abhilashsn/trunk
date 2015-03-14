class AddClientCodeToProviderAdjustments < ActiveRecord::Migration
  def change
     add_column :provider_adjustments, :client_code, :string, :limit => 20
  end
end
