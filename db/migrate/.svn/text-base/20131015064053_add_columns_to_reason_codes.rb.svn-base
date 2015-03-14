class AddColumnsToReasonCodes < ActiveRecord::Migration
  def change
    add_column :reason_codes, :facility_name, :string, :limit => 100
    add_column :reason_codes, :batchid, :string, :limit => 100
    add_column :reason_codes, :batch_date, :date
  end
end
