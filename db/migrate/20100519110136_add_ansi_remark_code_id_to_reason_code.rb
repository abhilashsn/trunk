class AddAnsiRemarkCodeIdToReasonCode < ActiveRecord::Migration
  def up
    add_column :reason_codes, :ansi_remark_code_id, :integer
  end

  def down
    remove_column :reason_codes, :ansi_remark_code_id
  end
end
