class RenameCheckNumberInReasonCodes < ActiveRecord::Migration
  def change
    rename_column :reason_codes, :check_number, :check_number_obsolete
  end
end
