class AddPatientMedistreamsIdToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    begin
     add_column :insurance_payment_eobs, :patient_medistreams_id, :string
    rescue
    end
  end

  def down
    remove_column :insurance_payment_eobs, :patient_medistreams_id
  end
end
