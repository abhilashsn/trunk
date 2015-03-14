class AddMultipleInvoiceRelatedColumnsToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :statement_applied, :boolean
    add_column :insurance_payment_eobs, :multiple_invoice_applied, :boolean
    add_column :insurance_payment_eobs, :multiple_statement_applied, :boolean
    add_column :insurance_payment_eobs, :statement_receiver, :string, :limit => 15
  end
end
