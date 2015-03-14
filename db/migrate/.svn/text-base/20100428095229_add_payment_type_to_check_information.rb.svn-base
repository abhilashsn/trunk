class AddPaymentTypeToCheckInformation < ActiveRecord::Migration
  def up
    add_column :check_informations, :payment_type, :string,:limit =>30
  end

  def down
    remove_column :check_informations, :payment_type
  end
end
