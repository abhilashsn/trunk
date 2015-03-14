class AddClientIdToInboundFileInformation < ActiveRecord::Migration
  def change
    add_column :inbound_file_informations, :client_id, :integer
  end
end
