class AddCompositeIndexToReasonCodesOnUniqueCodeAndReasonCodeSetNameId < ActiveRecord::Migration
  def up    
    add_index(:reason_codes, [:reason_code_set_name_id, :unique_code], :unique => true, :name => "index_set_name_id_unique_code")
  end

  def down
    remove_index :reason_codes, :name => "index_on_set_name_id_unique_code"
  end
end
