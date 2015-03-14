class RemoveUnusedFieldsFromClaimInformations < ActiveRecord::Migration
    def up
    remove_column :claim_informations, :billing_provider_hierarchical_level_code  if column_exists? :claim_informations, :billing_provider_hierarchical_level_code
    remove_column :claim_informations, :billing_provider_additional_identifier  if column_exists? :claim_informations, :billing_provider_additional_identifier
    remove_column :claim_informations, :subscriber_hierarchical_level_code  if column_exists? :claim_informations, :subscriber_hierarchical_level_code
    remove_column :claim_informations, :patient_hierarchical_level_code  if column_exists? :claim_informations, :patient_hierarchical_level_code
    remove_column :claim_informations, :patient_identification_code_qualifier  if column_exists? :claim_informations, :patient_identification_code_qualifier
    remove_column :claim_informations, :patient_primary_identifier  if column_exists? :claim_informations, :patient_primary_identifier
    remove_column :claim_informations, :subscriber_name_suffix  if column_exists? :claim_informations, :subscriber_name_suffix
  end
 

  def down
    execute "ALTER TABLE claim_informations
     ADD (billing_provider_hierarchical_level_code INT(2) NOT NULL DEFAULT 20,
          billing_provider_additional_identifier VARCHAR(50),
          subscriber_hierarchical_level_code INT(2) NOT NULL DEFAULT 22,
          patient_hierarchical_level_code INT(2) NOT NULL DEFAULT 23,
          patient_identification_code_qualifier VARCHAR(2),
          patient_primary_identifier VARCHAR(80),
          subscriber_name_suffix VARCHAR(10));"
  end
  
  def connection
    ClaimInformation.connection
  end
end
