class AddColumnsToClaimInformations < ActiveRecord::Migration
  def up
    attributes = ["claim_id_hash", "active", "status", "reason_for_duplication",
      "bill_print_date", "retained_claim_id","billing_provider_hierarchical_level_code",
      "billing_provider_additional_identifier",
      "subscriber_hierarchical_level_code","individual_relationship_code",
      "subscriber_name_suffix","subscriber_address_line","subscriber_city_name",
      "subscriber_state_code","subscriber_zip_code", "payer_identifier",
      "patient_hierarchical_level_code","patient_identification_code_qualifier",
      "patient_primary_identifier","patient_address_line","patient_city_name","patient_state_code",
      "patient_zip_code",
      "claim_original_reference_number",
      "payer_paid_amount",
      "individual_relationship_code"]
    if !(attributes - ClaimInformation.column_names).empty?
      execute "ALTER TABLE claim_informations
     ADD (claim_id_hash  VARCHAR(255),
          active  TINYINT(1),
          STATUS VARCHAR(255),
          reason_for_duplication VARCHAR(255),
          bill_print_date DATE,
          retained_claim_id INT(11),
          billing_provider_hierarchical_level_code INT(2) NOT NULL DEFAULT 20,
          billing_provider_additional_identifier VARCHAR(50),
          subscriber_hierarchical_level_code INT(2) NOT NULL DEFAULT 22,
          individual_relationship_code INT(2) NOT NULL DEFAULT 18,
          subscriber_name_suffix VARCHAR(10),
          subscriber_address_line VARCHAR(55),
          subscriber_city_name VARCHAR(30),
          subscriber_state_code VARCHAR(2),
          subscriber_zip_code VARCHAR(15),
          payer_identifier VARCHAR(80),
          patient_hierarchical_level_code INT(2) NOT NULL DEFAULT 23,
          patient_identification_code_qualifier VARCHAR(2),
          patient_primary_identifier VARCHAR(80),
          patient_address_line VARCHAR(55),
          patient_city_name VARCHAR(30),
          patient_state_code VARCHAR(2),
          patient_zip_code VARCHAR(15),
          claim_original_reference_number INT(50),
          payer_paid_amount DECIMAL(18)),
      ADD INDEX (claim_id_hash),
      ADD INDEX (active),
      ADD INDEX (retained_claim_id);"
    end
  end

  def down
    execute "ALTER TABLE claim_informations
      DROP INDEX claim_id_hash, DROP INDEX active, DROP INDEX retained_claim_id,
      DROP COLUMN claim_id_hash, DROP COLUMN active, DROP COLUMN status,
      DROP COLUMN reason_for_duplication, DROP COLUMN bill_print_date,
      DROP COLUMN retained_claim_id,
      DROP COLUMN billing_provider_hierarchical_level_code,
      DROP COLUMN billing_provider_additional_identifier,
      DROP COLUMN subscriber_hierarchical_level_code,
      DROP COLUMN individual_relationship_code,
      DROP COLUMN subscriber_name_suffix,
      DROP COLUMN subscriber_address_line,
      DROP COLUMN subscriber_city_name,
      DROP COLUMN subscriber_state_code,
      DROP COLUMN subscriber_zip_code,
      DROP COLUMN  payer_identifier,
      DROP COLUMN patient_hierarchical_level_code,
      DROP COLUMN patient_identification_code_qualifier,
      DROP COLUMN patient_primary_identifier,
      DROP COLUMN patient_address_line,
      DROP COLUMN patient_city_name,
      DROP COLUMN patient_state_code,
      DROP COLUMN patient_zip_code,
      DROP COLUMN claim_original_reference_number,
      DROP COLUMN payer_paid_amount;"
  end

 def connection
    ClaimInformation.connection
  end
end
