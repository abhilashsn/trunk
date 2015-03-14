class AddIsNullfileToInboundFileInformation < ActiveRecord::Migration
  def change
    add_column :inbound_file_informations, :is_nullfile, :tinyint, :default => 0
  end
end
