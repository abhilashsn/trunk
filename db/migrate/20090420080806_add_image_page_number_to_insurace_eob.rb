class AddImagePageNumberToInsuraceEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs,:image_page_no,:integer
  end
  
  def down
    remove_column :insurance_payment_eobs,:image_page_no
  end
end
