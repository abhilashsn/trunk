class AddAdditionalFieldsToInboundFileInformations < ActiveRecord::Migration
  def change    
    add_column :inbound_file_informations, :cut, :string, :limit => 64
    add_column :inbound_file_informations, :total_charge, :decimal, :precision=>10, :scale =>2
    add_column :inbound_file_informations, :total_excluded_charge, :decimal, :precision=>10, :scale =>2
    add_column :inbound_file_informations, :batchdate, :date
    add_column :inbound_file_informations, :expected_arrival_date , :date
    add_column :inbound_file_informations, :expected_start_time, :datetime
    add_column :inbound_file_informations, :expected_end_time, :datetime
    add_column :inbound_file_informations, :revremit_exception_id, :integer    
    remove_column :inbound_file_informations, :facility_cut_relationship_id
  end
end
