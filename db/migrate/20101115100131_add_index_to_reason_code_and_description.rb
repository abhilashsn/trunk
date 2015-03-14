class AddIndexToReasonCodeAndDescription < ActiveRecord::Migration
  def up
    add_index :reason_codes, :reason_code
    add_index :reason_codes, :reason_code_description
  end

  def down
    remove_index :reason_codes, :reason_code
    remove_index :reason_codes, :reason_code_description
  end
end
