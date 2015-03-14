class AddDefaultPatpayPayerTinToFacilities < ActiveRecord::Migration
  def up
    add_column :facilities, :default_patpay_payer_tin, :string
  end

  def down
    remove_column :facilities, :default_patpay_payer_tin
  end
end
