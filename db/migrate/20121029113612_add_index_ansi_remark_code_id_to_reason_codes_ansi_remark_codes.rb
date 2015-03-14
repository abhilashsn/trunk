class AddIndexAnsiRemarkCodeIdToReasonCodesAnsiRemarkCodes < ActiveRecord::Migration
  def change
    add_index :reason_codes_ansi_remark_codes, :ansi_remark_code_id, :name => "index_ansi_remark_code_id"
  end
end
