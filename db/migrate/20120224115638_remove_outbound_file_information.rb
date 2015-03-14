class RemoveOutboundFileInformation < ActiveRecord::Migration
  def up
    drop_table :outbound_file_informations
  end

  def down
  end
end
