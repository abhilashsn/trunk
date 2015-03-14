class RenameHipaaGroupCodeInReasonCodeClientsFacilitiesSetNames < ActiveRecord::Migration
  def change
    rename_column :reason_codes_clients_facilities_set_names, :hipaa_group_code, :hipaa_group_code_obsolete
  end
end
