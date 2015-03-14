class ChangeServiceClaimAdjustmentGroupCodeInServicePaymentEobToString < ActiveRecord::Migration
  def up
    change_column :service_payment_eobs,:service_claim_adjustment_group_code,:string,:limit=>4
  end

  def down
    change_column :service_payment_eobs,:service_claim_adjustment_group_code,:integer,:limit=>2
  end
end
