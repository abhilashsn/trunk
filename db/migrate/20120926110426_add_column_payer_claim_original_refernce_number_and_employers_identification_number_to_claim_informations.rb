class AddColumnPayerClaimOriginalRefernceNumberAndEmployersIdentificationNumberToClaimInformations < ActiveRecord::Migration
  def up
    #add_column :claim_informations, :employers_identification_number, :string,  :limit=>50
    #add_column :claim_informations, :payer_claim_original_reference_number, :string,  :limit=>50
    #change_column :claim_informations, :claim_original_reference_number,:string, :limit=>50
  end

  def down
    remove_column :claim_informations,:employers_identification_number
    remove_column :claim_informations,:payer_claim_original_reference_number
    change_column :claim_informations, :claim_original_reference_number,:integer
  end

  def connection
    ClaimInformation.connection
  end
  
end
