class AddDeniedAndDeniedCodeAndDeniedGroupcodeAndDeniedCodeDescriptionToServicePaymentEob < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :denied, :decimal,:precision => 10, :scale => 2
    add_column :service_payment_eobs, :denied_code, :string
    add_column :service_payment_eobs, :denied_groupcode, :string
    add_column :service_payment_eobs, :denied_code_description, :string    
  end

  def down
    remove_column :service_payment_eobs, :denied,:precision => 10, :scale => 2
    remove_column :service_payment_eobs, :denied_code, :string
    remove_column :service_payment_eobs, :denied_groupcode, :string
    remove_column :service_payment_eobs, :denied_code_description, :string    
  end
end
