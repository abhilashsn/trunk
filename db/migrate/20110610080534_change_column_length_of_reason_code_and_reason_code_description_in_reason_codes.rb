class ChangeColumnLengthOfReasonCodeAndReasonCodeDescriptionInReasonCodes < ActiveRecord::Migration
  def up
    # change_column :reason_codes, :reason_code, :string, :limit => 15
    change_column :reason_codes, :reason_code_description, :string, :limit => 2500    
  end

  def down
    change_column :reason_codes, :reason_code, :string
    change_column :reason_codes, :reason_code_description, :string    
  end
end
