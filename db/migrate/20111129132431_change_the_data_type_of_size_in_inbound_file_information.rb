class ChangeTheDataTypeOfSizeInInboundFileInformation < ActiveRecord::Migration
  def up
    change_column :inbound_file_informations, :size, :integer
  end

  def down
    change_column :inbound_file_informations, :size, :string
  end
end
