class CreateInsurancePaymentEobs < ActiveRecord::Migration
  def up
    create_table :insurance_payment_eobs do |t|
      t.column :check_information_id,:integer,:references=>:check_informations
      t.column :patient_account_number, :string ,:limit =>30
      t.column :claim_number, :string ,:limit =>30
      t.column :claim_status_code, :string ,:limit =>2
      t.column :total_submitted_charge_for_claim,:decimal,:precision => 10, :scale => 2
      t.column :total_amount_paid_for_claim,:decimal,:precision => 10, :scale => 2
      t.column :total_primary_payer_amount,:decimal,:precision => 10, :scale => 2
      t.column :total_co_insurance,:decimal,:precision => 10, :scale => 2
      t.column :total_deductible,:decimal,:precision => 10, :scale => 2
      t.column :total_co_pay,:decimal,:precision => 10, :scale => 2
      t.column :total_non_covered,:decimal,:precision => 10, :scale => 2
      t.column :total_discount,:decimal,:precision => 10, :scale => 2
      t.column :total_allowable,:decimal,:precision => 10, :scale => 2
      t.column :total_service_balance,:decimal,:precision => 10, :scale => 2
      t.column :claim_indicator_code, :integer ,:limit =>2
      t.column :claim_interest,:decimal,:precision => 10, :scale => 2
      t.column :transaction_reference_identification_number, :string ,:limit =>30
      t.column :drg_code, :integer ,:limit =>2
      t.column :drg_weight,:decimal,:precision => 10, :scale => 2
      t.column :percent,:decimal,:precision => 10, :scale => 2
      t.column :claim_adjustment_group_code, :string ,:limit =>2
      t.column :claim_adjustment_reason_code, :string ,:limit =>5
      t.column :claim_adjustment_reason_code_description, :string ,:limit =>50
      t.column :claim_reason_code_number, :string ,:limit =>5
      t.column :claim_reason_code_description, :string ,:limit =>50
      t.column :units_of_service_being_adjusted, :integer ,:limit =>15
      t.column :patient_last_name, :string ,:limit =>35
      t.column :patient_first_name, :string ,:limit =>35
      t.column :patient_middle_initial, :string ,:limit =>4
      t.column :patient_suffix, :string ,:limit =>4
      t.column :patient_identification_code_qualifier, :integer ,:limit =>2
      t.column :patient_identification_code, :string ,:limit =>80
      t.column :subscriber_last_name, :string ,:limit =>35
      t.column :subscriber_first_name, :string ,:limit =>35
      t.column :subscriber_middle_initial, :string ,:limit =>4
      t.column :subscriber_suffix, :string ,:limit =>4
      t.column :subscriber_identification_code_qualifier, :integer ,:limit =>2
      t.column :subscriber_identification_code, :string ,:limit =>80
      t.column :rendering_provider_last_name, :string ,:limit =>35
      t.column :rendering_provider_first_name, :string ,:limit =>35
      t.column :rendering_provider_suffix, :string ,:limit =>5
      t.column :rendering_provider_middle_initial, :string ,:limit =>4
      t.column :rendering_provider_identification_number, :string ,:limit =>20
      t.column :rendering_provider_code_qualifier, :integer ,:limit =>20
      t.column :provider_date, :date
      t.column :provider_adjustment_reason_code, :string ,:limit =>20
      t.column :provider_adjustment_amount, :string ,:limit =>20
      t.column :provider_tin, :string ,:limit =>20
      t.column :claim_type, :string 
      t.column :plan_type, :string ,:limit =>20
      t.column :provider_npi, :string ,:limit =>20
      t.column :created_at,:datetime
      t.column :updated_at,:datetime
      t.column :details, :text
    end
    execute "ALTER TABLE insurance_payment_eobs ADD CONSTRAINT insurance_payment_eobs_idfk_1 FOREIGN KEY (check_information_id)
             REFERENCES check_informations(id)"
  end

  def down
    execute "ALTER TABLE insurance_payment_eobs DROP FOREIGN KEY insurance_payment_eobs_idfk_1"
    drop_table :insurance_payment_eobs
  end
end
