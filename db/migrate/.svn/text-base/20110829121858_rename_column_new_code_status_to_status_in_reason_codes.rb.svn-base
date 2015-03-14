class RenameColumnNewCodeStatusToStatusInReasonCodes < ActiveRecord::Migration
  def up
    rename_column :reason_codes, :new_code_status, :status
  end

  def down
    rename_column :reason_codes, :status, :new_code_status
  end
end
