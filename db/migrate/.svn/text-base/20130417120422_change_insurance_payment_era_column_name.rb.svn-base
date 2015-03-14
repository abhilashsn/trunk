class ChangeInsurancePaymentEraColumnName < ActiveRecord::Migration
  def up
    rename_column :insurance_payment_eras, :claim_adjustment_deductable, :claim_adjustment_deductible
    rename_column :insurance_payment_eras, :claim_deductable_reasoncode, :claim_deductible_reasoncode
    rename_column :insurance_payment_eras, :claim_deductuble_groupcode, :claim_deductible_groupcode
  end

  def down
    rename_column :insurance_payment_eras, :claim_adjustment_deductible, :claim_adjustment_deductable
    rename_column :insurance_payment_eras, :claim_deductible_reasoncode, :claim_deductable_reasoncode
    rename_column :insurance_payment_eras, :claim_deductible_groupcode, :claim_deductuble_groupcode
  end
end
