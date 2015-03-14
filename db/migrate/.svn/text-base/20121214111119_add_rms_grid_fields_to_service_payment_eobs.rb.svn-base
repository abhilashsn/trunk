class AddRmsGridFieldsToServicePaymentEobs < ActiveRecord::Migration
  def change
    add_column :service_payment_eobs, :service_prepaid, :decimal, :precision => 10, :scale => 2
    add_column :service_payment_eobs, :service_plan_coverage, :decimal, :precision => 10, :scale => 2
  end
end
