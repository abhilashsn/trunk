class RemoveReasonCodeSetNameIdObsoleteFromReasonCodesClientsFacilitiesSetNames < ActiveRecord::Migration
  def up
    remove_column :reason_codes_clients_facilities_set_names, :reason_code_set_name_id_obsolete
  end

  def down
    add_column :reason_codes_clients_facilities_set_names, :reason_code_set_name_id_obsolete, :integer
  end
end
