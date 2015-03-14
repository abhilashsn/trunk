class AddClaimSpecificGroupcodeReasoncode < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs,:contractual_amount, :decimal,:precision => 10, :scale => 2
    add_column :service_payment_eobs,:contractual_groupcode, :string
    add_column :service_payment_eobs,:contractual_code, :string
    add_column :service_payment_eobs,:contractual_code_description, :string
    add_column :insurance_payment_eobs,:claim_adjustment_charges, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_charges_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_charge_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_non_covered, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_noncovered_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_noncovered_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_discount, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_discount_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_discount_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_contractual_amount, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_contractual_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_contractual_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_co_insurance, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_coinsurance_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_coinsurance_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_deductable, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_deductable_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_deductuble_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_copay, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_copay_reasoncode, :string
     
    add_column :insurance_payment_eobs,:claim_copay_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_payment, :decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_payment_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_payment_groupcode, :string
    add_column :insurance_payment_eobs,:claim_adjustment_primary_pay_payment ,:decimal,:precision => 10, :scale => 2
    add_column :insurance_payment_eobs,:claim_primary_payment_reasoncode, :string
    add_column :insurance_payment_eobs,:claim_primary_payment_groupcode, :string
    add_column :insurance_payment_eobs,:claim_charges_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_noncovered_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_discount_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_contractual_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_coinsurance_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_deductable_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_copay_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_payment_reasoncode_description, :string
    add_column :insurance_payment_eobs,:claim_primary_payment_reasoncode_description, :string
    add_column :insurance_payment_eobs,:total_contractual_amount, :decimal,:precision => 10, :scale => 2
  end

  def down
    
    remove_column :service_payment_eobs,:contractual_amount
    remove_column :service_payment_eobs,:contractual_groupcode
    remove_column :service_payment_eobs,:contractual_code
    remove_column :insurance_payment_eobs,:claim_adjustment_charges, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_charges_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_charge_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_non_covered, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_noncovered_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_noncovered_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_discount, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_discount_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_discount_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_contractual_amount, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_contractual_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_contractual_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_co_insurance, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_coinsurance_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_coinsurance_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_deductable, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_deductable_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_deductuble_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_copay, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_copay_reasoncode, :string
     
    remove_column :insurance_payment_eobs,:claim_copay_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_payment, :decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_payment_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_payment_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_adjustment_primary_pay_payment ,:decimal,:precision => 10, :scale => 2
    remove_column :insurance_payment_eobs,:claim_primary_payment_reasoncode, :string
    remove_column :insurance_payment_eobs,:claim_primary_payment_groupcode, :string
    remove_column :insurance_payment_eobs,:claim_charges_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_noncovered_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_discount_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_contractual_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_coinsurance_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_deductable_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_copay_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_payment_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:claim_primary_payment_reasoncode_description, :string
    remove_column :insurance_payment_eobs,:total_contractual_amount, :decimal,:precision => 10, :scale => 2
    
  end
end
