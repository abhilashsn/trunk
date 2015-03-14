class AddColumnServiceCdtQualifierToServicePaymentEobs < ActiveRecord::Migration
  def change
     add_column :service_payment_eobs, :service_cdt_qualifier, :string
  end
end
