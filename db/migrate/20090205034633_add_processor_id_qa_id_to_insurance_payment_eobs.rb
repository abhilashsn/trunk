class AddProcessorIdQaIdToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs,:processor_id,:integer
    add_column :insurance_payment_eobs,:qa_id,:integer
    add_column :insurance_payment_eobs,:processing_completed,:date
  end

  def down
    remove_column :insurance_payment_eobs,:processor_id
    remove_column :insurance_payment_eobs,:qa_id
    remove_column :insurance_payment_eobs,:processing_completed
  end
end
