class RemoveColumnFacilityLockboxMappingsIdFromThroughputReports < ActiveRecord::Migration
  def up
    remove_column :throughput_reports, :facility_lockbox_mappings_id
  end

  def down
    add_column :throughput_reports, :facility_lockbox_mappings_id, :integer
  end
end
