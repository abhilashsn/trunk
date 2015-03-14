class ChangeProcessingCompletedDataTypeInInsurancePaymentEobs < ActiveRecord::Migration
  def change
    change_column(:insurance_payment_eobs, :processing_completed, :datetime)
  end
end
