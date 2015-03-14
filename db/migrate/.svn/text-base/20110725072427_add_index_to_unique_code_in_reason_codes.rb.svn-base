class AddIndexToUniqueCodeInReasonCodes < ActiveRecord::Migration
  def up
    add_index :reason_codes, :unique_code
  end

  def down
    remove_index :reason_codes, :unique_code
  end
end
