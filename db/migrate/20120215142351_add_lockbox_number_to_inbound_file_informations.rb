class AddLockboxNumberToInboundFileInformations < ActiveRecord::Migration
  def change
    add_column :inbound_file_informations, :lockbox_number, :string, :limit => 50
  end
end
