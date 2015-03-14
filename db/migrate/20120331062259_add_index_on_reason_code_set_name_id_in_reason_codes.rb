class AddIndexOnReasonCodeSetNameIdInReasonCodes < ActiveRecord::Migration
  def change
    add_index :reason_codes, :reason_code_set_name_id
  end
end
