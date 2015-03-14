class RemoveEraColumns < ActiveRecord::Migration
  def up
    remove_column :insurance_payment_eras, :claim_adjustment_primary_pay_payment
    remove_column :insurance_payment_eras, :claim_primary_payment_reasoncode
    remove_column :insurance_payment_eras, :claim_primary_payment_groupcode
    remove_column :insurance_payment_eras, :claim_adjustment_co_insurance
    remove_column :insurance_payment_eras, :claim_coinsurance_reasoncode
    remove_column :insurance_payment_eras, :claim_coinsurance_groupcode
    remove_column :insurance_payment_eras, :claim_adjustment_deductible
    remove_column :insurance_payment_eras, :claim_deductible_reasoncode
    remove_column :insurance_payment_eras, :claim_deductible_groupcode
    remove_column :insurance_payment_eras, :claim_adjustment_copay
    remove_column :insurance_payment_eras, :claim_copay_reasoncode
    remove_column :insurance_payment_eras, :claim_copay_groupcode
    remove_column :insurance_payment_eras, :claim_adjustment_non_covered
    remove_column :insurance_payment_eras, :claim_noncovered_reasoncode
    remove_column :insurance_payment_eras, :claim_noncovered_groupcode
    remove_column :insurance_payment_eras, :claim_adjustment_discount
    remove_column :insurance_payment_eras, :claim_discount_reasoncode
    remove_column :insurance_payment_eras, :claim_discount_groupcode
    remove_column :insurance_payment_eras, :claim_adjustment_contractual_amount
    remove_column :insurance_payment_eras, :claim_contractual_reasoncode
    remove_column :insurance_payment_eras, :claim_contractual_groupcode
    remove_column :insurance_payment_eras, :total_denied
    remove_column :insurance_payment_eras, :claim_denied_reasoncode
    remove_column :insurance_payment_eras, :claim_denied_groupcode
    
    remove_column :service_payment_eras, :primary_payment
    remove_column :service_payment_eras, :service_co_insurance
    remove_column :service_payment_eras, :service_deductible
    remove_column :service_payment_eras, :service_co_pay
    remove_column :service_payment_eras, :service_no_covered
    remove_column :service_payment_eras, :service_discount
    remove_column :service_payment_eras, :contractual_amount
    remove_column :service_payment_eras, :denied
    remove_column :service_payment_eras, :noncovered_code
    remove_column :service_payment_eras, :noncovered_groupcode
    remove_column :service_payment_eras, :discount_code
    remove_column :service_payment_eras, :discount_groupcode
    remove_column :service_payment_eras, :coinsurance_code
    remove_column :service_payment_eras, :coinsurance_groupcode
    remove_column :service_payment_eras, :deductuble_code
    remove_column :service_payment_eras, :deductuble_groupcode
    remove_column :service_payment_eras, :copay_code
    remove_column :service_payment_eras, :copay_groupcode
    remove_column :service_payment_eras, :primary_payment_code
    remove_column :service_payment_eras, :primary_payment_groupcode
    remove_column :service_payment_eras, :contractual_groupcode
    remove_column :service_payment_eras, :contractual_code
    remove_column :service_payment_eras, :denied_code
    remove_column :service_payment_eras, :denied_groupcode
  end

  def down
    add_column :insurance_payment_eras, :claim_adjustment_primary_pay_payment, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_primary_payment_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_primary_payment_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_adjustment_co_insurance, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_coinsurance_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_coinsurance_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_adjustment_deductible, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_deductible_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_deductible_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_adjustment_copay, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_copay_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_copay_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_adjustment_non_covered, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_noncovered_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_noncovered_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_adjustment_discount, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_discount_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_discount_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :claim_adjustment_contractual_amount, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_contractual_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_contractual_groupcode, :string, :limit => 2
    add_column :insurance_payment_eras, :total_denied, :decimal, :precision => 18, :scale => 2
    add_column :insurance_payment_eras, :claim_denied_reasoncode, :string, :limit => 5
    add_column :insurance_payment_eras, :claim_denied_groupcode, :string, :limit => 2
    
    add_column :service_payment_eras, :primary_payment, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :service_co_insurance, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :service_deductible, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :service_co_pay, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :service_no_covered, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :service_discount, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :contractual_amount, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :denied, :decimal, :precision => 18, :scale => 2
    add_column :service_payment_eras, :noncovered_code, :string, :limit => 5
    add_column :service_payment_eras, :noncovered_groupcode, :string, :limit => 2
    add_column :service_payment_eras, :discount_code, :string, :limit => 5
    add_column :service_payment_eras, :discount_groupcode, :string, :limit => 2
    add_column :service_payment_eras, :coinsurance_code, :string, :limit => 5
    add_column :service_payment_eras, :coinsurance_groupcode, :string, :limit => 2
    add_column :service_payment_eras, :deductuble_code, :string, :limit => 5
    add_column :service_payment_eras, :deductuble_groupcode, :string, :limit => 2
    add_column :service_payment_eras, :copay_code, :string, :limit => 5
    add_column :service_payment_eras, :copay_groupcode, :string, :limit => 2
    add_column :service_payment_eras, :primary_payment_code, :string, :limit => 5
    add_column :service_payment_eras, :primary_payment_groupcode, :string, :limit => 2
    add_column :service_payment_eras, :contractual_groupcode, :string, :limit => 5
    add_column :service_payment_eras, :contractual_code, :string, :limit => 2
    add_column :service_payment_eras, :denied_code, :string, :limit => 5
    add_column :service_payment_eras, :denied_groupcode, :string, :limit => 2
  end
end
