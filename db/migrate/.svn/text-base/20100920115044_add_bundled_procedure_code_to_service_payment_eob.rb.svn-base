class AddBundledProcedureCodeToServicePaymentEob < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :bundled_procedure_code, :string, :limit =>5
  end

  def down
    remove_column :service_payment_eobs, :bundled_procedure_code
  end
end
