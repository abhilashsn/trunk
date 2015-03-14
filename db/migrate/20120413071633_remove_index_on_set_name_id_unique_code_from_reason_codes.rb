class RemoveIndexOnSetNameIdUniqueCodeFromReasonCodes < ActiveRecord::Migration
  def change
    if index_exists?(:reason_codes, [:set_name_id, :unique_code], :name => "index_on_set_name_id_unique_code")
      remove_index(:reason_codes, :name => :index_on_set_name_id_unique_code)
    end
    if index_exists?(:reason_codes, [:set_name_id, :unique_code], :name => "index_set_name_id_unique_code")
      remove_index(:reason_codes, :name => :index_set_name_id_unique_code)
    end
  end
end
