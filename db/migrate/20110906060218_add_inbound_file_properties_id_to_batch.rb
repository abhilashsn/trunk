class AddInboundFilePropertiesIdToBatch < ActiveRecord::Migration
  def up
    add_column :batches, :inbound_file_information_id, :integer
  end

  def down
    remove_column :batches, :inbound_file_information_id
  end
end
