class RenameColumnOfInboundFileInformations < ActiveRecord::Migration
  def up
    rename_column :inbound_file_informations, :type, :file_type
  end

  def down
    rename_column :inbound_file_informations, :file_type, :type
  end
end
