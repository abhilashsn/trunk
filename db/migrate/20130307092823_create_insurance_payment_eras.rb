class CreateInsurancePaymentEras < ActiveRecord::Migration
  def change
    create_table :insurance_payment_eras do |t|

      t.timestamps
      t.integer  :era_check_id	
      t.string   :patient_account_number, :limit => 38
      t.string   :claim_status_code
      t.decimal  :total_submitted_charge_for_claim	, :precision => 18, :scale => 2
      t.decimal  :total_amount_paid_for_claim	, :precision => 18, :scale => 2
      t.decimal  :total_patient_responsibility	, :precision => 18, :scale => 2
      t.string   :claim_indicator_code, :limit => 2
      t.string   :claim_number, :limit => 50
      t.string   :facility_type_code, :limit => 2
      t.string   :claim_frequency_code, :limit => 1
      t.string   :drg_code, :limit => 4
      t.integer  :drg_weight
      t.decimal  :discharge_fraction	, :precision => 10, :scale => 2
      t.string   :patient_entity_qualifier, :limit => 1
      t.string   :patient_last_name, :limit => 60
      t.string   :patient_first_name, :limit => 35
      t.string   :patient_middle_initial, :limit => 25
      t.string   :patient_suffix, :limit => 10
      t.string   :patient_identification_code_qualifier, :limit => 2
      t.string   :patient_identification_code, :limit => 80
      t.string   :subscriber_entity_qualifier, :limit => 1
      t.string   :subscriber_last_name, :limit => 60
      t.string   :subscriber_first_name, :limit => 35
      t.string   :subscriber_middle_initial, :limit => 25
      t.string   :subscriber_suffix, :limit => 10
      t.string   :subscriber_identification_code_qualifier, :limit => 2
      t.string   :subscriber_identification_code, :limit => 80
      t.string   :rendering_provider_entity_qualifier, :limit => 1
      t.string   :rendering_provider_last_name, :limit => 60
      t.string   :rendering_provider_first_name, :limit => 35
      t.string   :rendering_provider_middle_initial, :limit => 25
      t.string   :rendering_provider_suffix, :limit => 10
      t.string   :rendering_provider_code_qualifier, :limit => 2
      t.string   :rendering_provider_identification_number, :limit => 80
      t.string   :other_claim_identification_qualifier, :limit => 3
      t.string   :other_claim_identifier, :limit => 50
      t.date     :claim_from_date
      t.date     :claim_to_date
      t.date     :date_received_by_insurer
      t.string   :amt_qualifier, :limit => 3
      t.decimal  :amt_amount	, :precision => 18, :scale => 2
      t.string   :archived_claim_hash
      t.decimal  :claim_adjustment_primary_pay_payment, :precision => 18, :scale => 2
      t.string   :claim_primary_payment_reasoncode, :limit => 5
      t.string   :claim_primary_payment_groupcode, :limit => 2
      t.decimal  :claim_adjustment_co_insurance	, :precision => 18, :scale => 2
      t.string   :claim_coinsurance_reasoncode	, :limit => 5
      t.string   :claim_coinsurance_groupcode, :limit => 2
      t.decimal  :claim_adjustment_deductable	, :precision => 18, :scale => 2
      t.string   :claim_deductable_reasoncode, :limit => 5
      t.string   :claim_deductuble_groupcode, :limit => 2
      t.decimal  :claim_adjustment_copay	, :precision => 18, :scale => 2
      t.string   :claim_copay_reasoncode, :limit => 5
      t.string   :claim_copay_groupcode, :limit => 2
      t.decimal  :claim_adjustment_non_covered	, :precision => 18, :scale => 2
      t.string   :claim_noncovered_reasoncode, :limit => 5
      t.string   :claim_noncovered_groupcode, :limit => 2
      t.decimal  :claim_adjustment_discount	, :precision => 18, :scale => 2
      t.string   :claim_discount_reasoncode, :limit => 5
      t.string   :claim_discount_groupcode, :limit =>2
      t.decimal  :claim_adjustment_contractual_amount, :precision => 18, :scale => 2
      t.string   :claim_contractual_reasoncode, :limit => 5
      t.string   :claim_contractual_groupcode, :limit => 2
      t.decimal  :total_denied	, :precision => 18, :scale => 2
      t.string   :claim_denied_reasoncode, :limit => 5
      t.string   :claim_denied_groupcode, :limit => 2
      t.integer  :lx_number
      t.string   :ts3_provider_number	, :limit => 60
      t.integer  :ts3_facility_type_code
      t.date     :ts3_date
      t.integer  :ts3_quantity
      t.decimal  :ts3_amount	, :precision => 18, :scale => 2
      t.string   :era_misc_claim_segments

    end
  end
end
