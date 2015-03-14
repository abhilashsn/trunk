class AddPatientIdToClaimInformations < ActiveRecord::Migration
  def up
    begin
     add_column :claim_informations, :patient_identification_number,  :string
    rescue
    end
  end

  def down
     remove_column :claim_informations, :patient_identification_number
  end
  def connection
    ClaimInformation.connection
  end
end
