class AddMarkToEobAndChekinformation < ActiveRecord::Migration
  def up
    add_column :check_informations,:check_regenerate,:string
    add_column :check_informations,:check_regenerate_comment,:string
    add_column :insurance_payment_eobs,:eob_regenerate,:string
    add_column :patient_pay_eobs,:patient_pay_eob_regenerate,:string
  end

  def down
    remove_column :check_informations,:check_regenerate
    remove_column :insurance_payment_eobs,:eob_regenerate
    remove_column :patient_pay_eobs,:patient_pay_eob_regenerate
  end
end
