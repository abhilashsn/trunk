class CreateClaimValidationExceptions < ActiveRecord::Migration
  def change
    create_table :claim_validation_exceptions do |t|
      t.integer :insurance_payment_eob_id
      t.integer :claim_information_id
      t.string :action

      t.timestamps
    end
  end
end