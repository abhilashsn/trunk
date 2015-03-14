class CreateReferencesToOutboundFilesInOutputActivityLogs < ActiveRecord::Migration
  def up
    add_column :output_activity_logs, :outbound_file_information_id, :int, :limit=>11
  end

  def down
    remove_column :output_activity_logs, :outbound_file_information_id
  end
end
