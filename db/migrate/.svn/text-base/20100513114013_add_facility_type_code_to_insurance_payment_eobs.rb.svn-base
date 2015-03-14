class AddFacilityTypeCodeToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    begin
     add_column :insurance_payment_eobs, :facility_type_code, :string
    rescue
    end
  end

  def down
    remove_column :insurance_payment_eobs, :facility_type_code
  end
end
