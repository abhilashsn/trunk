class AddIndexReplacementReasonCodeIdInReasonCodes < ActiveRecord::Migration
  def change
    add_index :reason_codes, :replacement_reason_code_id
  end
end



