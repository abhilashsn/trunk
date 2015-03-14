class AddPatientMedistreamsIdToClaimInformations < ActiveRecord::Migration
  def up
    begin
     add_column :claim_informations, :patient_medistreams_id, :string
    rescue
    end
  end

  def down
     remove_column :claim_informations, :patient_medistreams_id
  end
  def connection
    ClaimInformation.connection
  end
end
