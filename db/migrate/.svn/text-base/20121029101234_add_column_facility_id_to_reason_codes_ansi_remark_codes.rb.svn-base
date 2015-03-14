class AddColumnFacilityIdToReasonCodesAnsiRemarkCodes < ActiveRecord::Migration
  def change
    add_column :reason_codes_ansi_remark_codes, :facility_id, :integer
    add_index :reason_codes_ansi_remark_codes, :facility_id, :name => "index_facility_id"
  end
end
