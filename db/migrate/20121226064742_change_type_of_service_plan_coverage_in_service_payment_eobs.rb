class ChangeTypeOfServicePlanCoverageInServicePaymentEobs < ActiveRecord::Migration
  def up
    change_column :service_payment_eobs, :service_plan_coverage,  :string, :limit => 5
  end

  def down
    change_column :service_payment_eobs, :service_plan_coverage, :decimal, :precision => 10, :scale => 2
  end
end
