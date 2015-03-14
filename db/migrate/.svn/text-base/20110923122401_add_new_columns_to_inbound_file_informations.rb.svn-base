class AddNewColumnsToInboundFileInformations < ActiveRecord::Migration
  def up
   add_column :inbound_file_informations, :type, :string
   add_column :inbound_file_informations, :status, :string
   add_column :inbound_file_informations, :facility_id, :integer
   add_column :inbound_file_informations, :count, :integer
  end

  def down
    remove_column :inbound_file_informations, :type
    remove_column :inbound_file_informations, :status
    remove_column :inbound_file_informations, :facility_id
    remove_column :inbound_file_informations, :count
  end
end
