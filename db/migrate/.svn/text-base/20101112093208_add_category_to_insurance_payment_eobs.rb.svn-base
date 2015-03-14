class AddCategoryToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs,  :category,  :string,  :default=>"service"
  end

  def down
    remove_column :insurance_payment_eobs, :category
  end
end
