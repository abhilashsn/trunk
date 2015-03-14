class AddCodeTypeRevenueCodeToServicePaymentEobs < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs,:revenue_code, :string
    add_column :service_payment_eobs,:procedure_code_type, :string
  end

  def down
    remove_column :service_payment_eobs,:revenue_code
    remove_column :service_payment_eobs,:procedure_code_type
  end
end
