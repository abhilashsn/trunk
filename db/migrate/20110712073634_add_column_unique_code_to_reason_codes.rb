class AddColumnUniqueCodeToReasonCodes < ActiveRecord::Migration
  def up
    add_column :reason_codes, :unique_code, :string, :limit => 11
  end

  def down
    remove_column :reason_codes, :unique_code
  end
end
