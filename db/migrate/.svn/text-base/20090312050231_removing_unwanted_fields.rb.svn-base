class RemovingUnwantedFields < ActiveRecord::Migration
  def up

    execute "ALTER TABLE eob_reports DROP FOREIGN KEY fk_eob_report_payer_id"
     
    remove_column :batches, :batch_amount
    remove_column :batches, :manual_override
    remove_column :batches, :source
    remove_column :batches, :system_issue
    remove_column :batches, :policy_issue
    remove_column :eob_reports, :payer_id
    remove_column :eob_reports, :account_number 
    remove_column :jobs, :time_taken
    remove_column :jobs, :hlsc_id
    remove_column :payers, :date_added
    remove_column :payers, :navicurepayid
    remove_column :check_informations, :payer_name
    remove_column :check_informations, :payer_city
    remove_column :check_informations, :payer_state_code
    remove_column :check_informations, :payer_zip
    remove_column :check_informations, :payer_address_line1
    remove_column :check_informations, :payer_address_line2
    remove_column :check_informations, :payer_tin
    remove_column :check_informations, :payee_tin
    remove_column :check_informations, :payee_name
    remove_column :check_informations, :payee_city
    remove_column :check_informations, :payee_state_code
    remove_column :check_informations, :payee_zip
    remove_column :check_informations, :payee_address_line1
    remove_column :check_informations, :payee_address_line2
    remove_column :check_informations, :payee_reference_identification
    remove_column :check_informations, :payee_identification_number
    remove_column :check_informations, :payee_npi_number
    remove_column :check_informations, :payid
    remove_column :check_informations, :navicure_payid
  end

  def down
  end
end
