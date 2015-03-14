class CreateInsurancePaymentEobsReasonCodes < ActiveRecord::Migration
  def up
    create_table :insurance_payment_eobs_reason_codes do |t|
      t.integer :insurance_payment_eob_id
      t.integer :reason_code_id
      t.string :adjustment_reason

      t.timestamps
    end
  end

  def down
    drop_table :insurance_payment_eobs_reason_codes
  end
end
