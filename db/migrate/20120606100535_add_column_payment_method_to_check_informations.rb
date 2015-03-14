class AddColumnPaymentMethodToCheckInformations < ActiveRecord::Migration
  def change
    add_column :check_informations, :payment_method, :string, :limit => 10
  end
end
