class AddEstimatedLoadEndTimeToInboundFileInformations < ActiveRecord::Migration
  def up
    add_column :inbound_file_informations, :estimated_load_end_time, :datetime
    remove_column :inbound_file_informations, :estimated_time
  end

  def down
    remove_column :inbound_file_informations, :estimated_load_end_time
    add_column :output_activity_logs, :estimated_time, :string, :limit=>64
  end
end
