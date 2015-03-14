class AddImagePageNoToPatientPays < ActiveRecord::Migration
  def up
     add_column :patient_pay_eobs,:image_page_no,:integer
  end

  def down
     remove_column :patient_pay_eobs,:image_page_no
  end
end
