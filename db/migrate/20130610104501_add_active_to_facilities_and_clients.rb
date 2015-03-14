class AddActiveToFacilitiesAndClients < ActiveRecord::Migration
  def change
    add_column :facilities, :active, :boolean, :default => true
    add_column :clients, :active, :boolean, :default => true
  end
end
