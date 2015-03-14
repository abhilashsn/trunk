class AddDateOfBirthToClaimInformations < ActiveRecord::Migration
  def up
    if !ClaimInformation.column_names.include?"date_of_birth"
      add_column :claim_informations, :date_of_birth, :date
    end
  end
  def down
    remove_column :claim_informations, :date_of_birth
  end

  def connection
    ClaimInformation.connection
  end
end
