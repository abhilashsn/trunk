class AlterPayerIdStartDatetimeEndDatetime < ActiveRecord::Migration
  def up
    change_column :error_popups, :payer_id, :integer
    rename_column "error_popups", "start_datetime", "start_date"
    rename_column "error_popups", "end_datetime", "end_date"
  end

  def down
    change_column :error_popups, :payer_id, :string 
    rename_column "error_popups", "start_date", "start_datetime"
    rename_column "error_popups", "end_date", "end_datetime"
  end
end
