class AddHcraToInsuranceEob < ActiveRecord::Migration
  def up
       add_column :insurance_payment_eobs,:hcra, :string
  end

  def down
    remove_column :insurance_payment_eobs,:hcra, :string
  end
end
