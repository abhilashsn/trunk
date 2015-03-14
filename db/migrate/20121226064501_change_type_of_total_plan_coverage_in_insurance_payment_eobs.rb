class ChangeTypeOfTotalPlanCoverageInInsurancePaymentEobs < ActiveRecord::Migration
  def up
    change_column :insurance_payment_eobs, :total_plan_coverage,  :string, :limit => 5
  end

  def down
    change_column :insurance_payment_eobs, :total_plan_coverage,  :decimal, :precision => 10, :scale => 2
  end
end
