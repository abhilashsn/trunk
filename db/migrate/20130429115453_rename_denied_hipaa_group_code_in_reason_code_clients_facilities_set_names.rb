class RenameDeniedHipaaGroupCodeInReasonCodeClientsFacilitiesSetNames < ActiveRecord::Migration
  def change
    rename_column :reason_codes_clients_facilities_set_names, :denied_hipaa_group_code, :denied_hipaa_group_code_obsolete
  end
end
