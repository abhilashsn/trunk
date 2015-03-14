class AddDocumentClassificationToPatientPayEobs < ActiveRecord::Migration
  def change
    add_column :patient_pay_eobs, :document_classification, :string, :limit => 50
  end
end
