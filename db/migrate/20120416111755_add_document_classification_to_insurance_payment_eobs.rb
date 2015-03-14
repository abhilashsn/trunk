class AddDocumentClassificationToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :document_classification, :string, :limit => 50
  end
end
