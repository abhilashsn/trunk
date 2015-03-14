class CreateServicePaymentEras < ActiveRecord::Migration
  def change
    create_table :service_payment_eras do |t|
      t.references :insurance_payment_era, :null => false
      t.string :service_product_qualifier, :limit => 2, :null => false
      t.string :service_procedure_code, :limit => 48
      t.string :service_modifier1, :limit => 2
      t.string :service_modifier2, :limit => 2
      t.string :service_modifier3, :limit => 2
      t.string :service_modifier4, :limit => 2
      t.decimal :service_procedure_charge_amount, :precision => 18, :scale => 2
      t.decimal :service_paid_amount, :precision => 18, :scale => 2
      t.string :revenue_code, :limit => 48
      t.column :service_quantity, :bigint
      t.string :original_service_product_qualifier, :limit => 2
      t.string :original_service_procedure_code, :limit => 48
      t.string :original_service_modifier1, :limit => 2
      t.string :original_service_modifier2, :limit => 2
      t.string :original_service_modifier3, :limit => 2
      t.string :original_service_modifier4, :limit => 2
      t.string :original_procedure_description, :limit => 80
      t.column :original_service_quantity, :bigint
      t.date :date_of_service_from
      t.date :date_of_service_to
      t.string :line_item_number, :limit => 50
      t.string :service_policy_identification, :limit => 50
      t.string :service_identification_qualifier, :limit => 3
      t.string :service_identifier, :limit => 50
      t.string :service_amount_qualifier_code, :limit => 3
      t.decimal :service_amount, :precision => 18, :scale => 2
      t.decimal :service_supp_quantity, :precision => 15, :scale => 2
      t.string :service_supp_quantity_qualifier, :limit => 3
      t.string :service_remark_code_qualifier, :limit => 3
      t.string :service_remark_code, :limit => 30
      t.decimal :primary_payment, :precision => 18, :scale => 2
      t.decimal :service_co_insurance, :precision => 18, :scale => 2
      t.decimal :service_deductible, :precision => 18, :scale => 2
      t.decimal :service_co_pay, :precision => 18, :scale => 2
      t.decimal :service_no_covered, :precision => 18, :scale => 2
      t.decimal :service_discount, :precision => 18, :scale => 2
      t.decimal :contractual_amount, :precision => 18, :scale => 2
      t.decimal :denied, :precision => 18, :scale => 2
      t.string :noncovered_code, :limit => 5
      t.string :noncovered_groupcode, :limit => 2
      t.string :discount_code, :limit => 5
      t.string :discount_groupcode, :limit => 2
      t.string :coinsurance_code, :limit => 5
      t.string :coinsurance_groupcode, :limit => 2
      t.string :deductuble_code, :limit => 5
      t.string :deductuble_groupcode, :limit => 2
      t.string :copay_code, :limit => 5
      t.string :copay_groupcode, :limit => 2
      t.string :primary_payment_code, :limit => 5
      t.string :primary_payment_groupcode, :limit => 2
      t.string :contractual_groupcode, :limit => 5
      t.string :contractual_code, :limit => 2
      t.string :denied_code, :limit => 5
      t.string :denied_groupcode, :limit => 2
      t.string :era_misc_svc_segments
      t.timestamps
    end
  end
end
