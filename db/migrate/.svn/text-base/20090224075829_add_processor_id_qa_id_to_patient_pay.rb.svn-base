class AddProcessorIdQaIdToPatientPay < ActiveRecord::Migration
  def up
    add_column :patient_pay_eobs,:processor_id,:integer
    add_column :patient_pay_eobs,:qa_id,:integer
  end

  def down
    remove_column :patient_pay_eobs,:processor_id
    remove_column :patient_pay_eobs,:qa_id
  end
end
