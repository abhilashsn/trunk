class AddRmsGridFieldsToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :over_payment_recovery, :decimal, :precision => 10, :scale => 2
    add_column :insurance_payment_eobs, :total_prepaid, :decimal, :precision => 10, :scale => 2
    add_column :insurance_payment_eobs, :total_plan_coverage, :decimal, :precision => 10, :scale => 2
  end
end
