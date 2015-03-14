class AddDetailsToInsurancePaymentEobs < ActiveRecord::Migration
   def up
     begin
    add_column :insurance_payment_eobs, :details, :text
     rescue
     end
  end

  def down
    remove_column :insurance_payment_eobs, :details
  end
end

