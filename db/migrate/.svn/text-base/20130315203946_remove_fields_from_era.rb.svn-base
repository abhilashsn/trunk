class RemoveFieldsFromEra < ActiveRecord::Migration
  def change
    add_column :eras, :inbound_file_information_id, :integer
    remove_column :eras, :file_name
    remove_column :eras, :file_size
    remove_column :eras, :file_arrival_time
    remove_column :eras, :status
    remove_column :eras, :file_path
  end
end
