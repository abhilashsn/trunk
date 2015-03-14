class AddColumnClientGroupToFacilities < ActiveRecord::Migration
  def change
  	add_column :facilities, :client_group, :string
  end
end
