class AddXpeditorDocumentNumberToClaimInformations < ActiveRecord::Migration
  def change
    if !ClaimInformation.column_names.include?"xpeditor_document_number"
     add_column :claim_informations, :xpeditor_document_number, :string
    end
  end
  def connection
    ClaimInformation.connection
  end
end
