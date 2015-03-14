class AddProcessingCompletedToPatientPay < ActiveRecord::Migration
  def up
    add_column :patient_pay_eobs,:processing_completed,:date
  end

  def down
    remove_column :patient_pay_eobs,:processing_completed
  end
end
