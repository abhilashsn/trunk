class CreateReasonCodesAnsiRemarkCodes < ActiveRecord::Migration
  def up
    create_table :reason_codes_ansi_remark_codes do |t|
       t.column "reason_code_id", :integer, :null => false
       t.column "ansi_remark_code_id",  :integer, :null => false
       t.timestamps
    end
  end

  def down
    drop_table :reason_codes_ansi_remark_codes
  end
end
