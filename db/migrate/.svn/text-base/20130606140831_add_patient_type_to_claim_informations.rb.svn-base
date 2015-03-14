class AddPatientTypeToClaimInformations < ActiveRecord::Migration
  def change
    add_column :claim_informations, :patient_type, :string, {limit: 30}
  end

  def connection
    ClaimInformation.connection
  end
end
