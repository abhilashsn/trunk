class CreateServicePaymentEobs < ActiveRecord::Migration
  def up
    create_table :service_payment_eobs do |t|
      t.column :insurance_payment_eob_id, :integer,:references=>:insurance_payment_eobs
      t.column :service_procedure_code, :string ,:limit =>5
      t.column :service_modifier1, :string ,:limit =>2
      t.column :service_modifier2, :string ,:limit =>2
      t.column :service_modifier3, :string ,:limit =>2
      t.column :service_modifier4, :string ,:limit =>2
      t.column :service_procedure_charge_amount,:decimal,:precision => 10, :scale => 2
      t.column :service_paid_amount,:decimal,:precision => 10, :scale => 2
      t.column :service_quantity, :string ,:limit => 20
      t.column :primary_payment,:decimal,:precision => 10, :scale => 2
      t.column :service_co_insurance,:decimal,:precision => 10, :scale => 2
      t.column :service_deductible,:decimal,:precision => 10, :scale => 2
      t.column :service_co_pay,:decimal,:precision => 10, :scale => 2
      t.column :service_no_covered,:decimal,:precision => 10, :scale => 2
      t.column :service_discount,:decimal,:precision => 10, :scale => 2
      t.column :service_balance,:decimal,:precision => 10, :scale => 2
      t.column :service_allowable,:decimal,:precision => 10, :scale => 2
      t.column :service_claim_adjustment_group_code,:integer ,:limit =>2
      t.column :service_claim_adjustment_reason_code,:string ,:limit =>5
      t.column :service_claim_adjustment_reason_code_description,:string ,:limit =>50
      t.column :service_units_of_service_being_adjusted,:integer ,:limit =>15
      t.column :date_of_service_from, :date
      t.column :date_of_service_to, :date
      t.column :service_provider_control_number,:string ,:limit =>30
      t.column :service_reference_identification_number,:string ,:limit =>30
      t.column :service_amount_qualifier_code,:string ,:limit =>30
      t.column :service_amount,:decimal,:precision => 10, :scale => 2
      t.column :service_code_list_qualifier,:string ,:limit =>3
      t.column :service_industry_code,:string ,:limit =>30
      t.column :service_provider_number,:string ,:limit =>30
      t.column :created_at,:datetime
      t.column :updated_at,:datetime
      t.column :details, :text
    end
    execute "ALTER TABLE service_payment_eobs ADD CONSTRAINT service_payment_eobs_idfk_1 FOREIGN KEY (insurance_payment_eob_id)
               REFERENCES insurance_payment_eobs(id)"
  end

  def down
    execute "ALTER TABLE service_payment_eobs DROP FOREIGN KEY service_payment_eobs_idfk_1"
    drop_table :service_payment_eobs
  end
end
