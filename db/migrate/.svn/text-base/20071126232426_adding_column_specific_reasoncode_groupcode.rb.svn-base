class AddingColumnSpecificReasoncodeGroupcode < ActiveRecord::Migration
  def up
     add_column :service_payment_eobs,:charges_code, :string
     add_column :service_payment_eobs,:charges_groupcode, :string
     add_column :service_payment_eobs,:noncovered_code, :string
     add_column :service_payment_eobs,:noncovered_groupcode, :string
     add_column :service_payment_eobs,:discount_code, :string
     add_column :service_payment_eobs,:discount_groupcode, :string
     add_column :service_payment_eobs,:coinsurance_code, :string
     add_column :service_payment_eobs,:coinsurance_groupcode, :string
     add_column :service_payment_eobs,:deductuble_code, :string
      add_column :service_payment_eobs,:deductuble_groupcode, :string
     add_column :service_payment_eobs,:copay_code, :string
     add_column :service_payment_eobs,:copay_groupcode, :string
     add_column :service_payment_eobs,:payment_code, :string
     add_column :service_payment_eobs,:payment_groupcode, :string
     add_column :service_payment_eobs,:primary_payment_code, :string
     add_column :service_payment_eobs,:primary_payment_groupcode, :string
     add_column :service_payment_eobs,:charges_code_description, :string
     add_column :service_payment_eobs,:noncovered_code_description, :string
     add_column :service_payment_eobs,:discount_code_description, :string
     add_column :service_payment_eobs,:coinsurance_code_description, :string
     add_column :service_payment_eobs,:deductuble_code_description, :string
     add_column :service_payment_eobs,:copay_code_description, :string
     add_column :service_payment_eobs,:payment_code_description, :string
     add_column :service_payment_eobs,:primary_payment_code_description, :string
  end

  def down
    remove_column :service_payment_eobs,:charges_code
    remove_column :service_payment_eobs,:noncovered_code
    remove_column :service_payment_eobs,:discount_code
    remove_column :service_payment_eobs,:coinsurance_code
    remove_column :service_payment_eobs,:deductuble_code
    remove_column :service_payment_eobs,:copay_code
    remove_column :service_payment_eobs,:payment_code
    remove_column :service_payment_eobs,:primary_payment_code
     remove_column :service_payment_eobs,:charges_groupcode
     remove_column :service_payment_eobs,:noncovered_groupcode
    remove_column :service_payment_eobs,:discount_groupcode
    remove_column :service_payment_eobs,:coinsurance_groupcode
    remove_column :service_payment_eobs,:deductuble_groupcode
     remove_column :service_payment_eobs,:copay_groupcode
     remove_column :service_payment_eobs,:payment_groupcode
     remove_column :service_payment_eobs,:primary_payment_groupcode
     remove_column :service_payment_eobs,:charges_code_description
     remove_column :service_payment_eobs,:noncovered_code_description
     remove_column :service_payment_eobs,:discount_code_description
     remove_column :service_payment_eobs,:coinsurance_code_description
      remove_column :service_payment_eobs,:deductuble_code_description
      remove_column :service_payment_eobs,:copay_code_description
      remove_column :service_payment_eobs,:payment_code_description
      remove_column :service_payment_eobs,:primary_payment_code_description
  end
end
