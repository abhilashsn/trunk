class AddDateReceivedByInsurerToInsurancePaymentEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :date_received_by_insurer, :date
  end

  def down
    remove_column :insurance_payment_eobs, :date_received_by_insurer
  end
end
