class AddColumnImagePageToNumberToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :image_page_to_number, :integer
  end

  def down
    remove_column :insurance_payment_eobs, :image_page_to_number
  end
end
