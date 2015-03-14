class AddIndexPayerAndReasonCodesClientsFacilitiesSetNamesHipaaCodes < ActiveRecord::Migration
  def up
    execute "ALTER TABLE payers ADD INDEX (reason_code_set_name_id);"
    execute "ALTER TABLE reason_codes_clients_facilities_set_names_hipaa_codes
            ADD INDEX(reason_codes_clients_facilities_set_name_id),
            ADD INDEX(hipaa_code_id);"
  end

  def down

    execute "ALTER TABLE payers DROP INDEX (reason_code_set_name_id);"
    execute "ALTER TABLE reason_codes_clients_facilities_set_names_hipaa_codes
            DROP INDEX(reason_codes_clients_facilities_set_name_id),
            DROP INDEX(hipaa_code_id);"
    
  end
end



