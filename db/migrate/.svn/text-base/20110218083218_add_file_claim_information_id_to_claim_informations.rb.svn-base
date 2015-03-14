class AddFileClaimInformationIdToClaimInformations < ActiveRecord::Migration
  def up
    if !ClaimInformation.column_names.include?"claim_file_information_id"
     add_column :claim_informations, :claim_file_information_id, :int
    end
  end

  def down
    remove_column :claim_informations, :claim_file_information_id
  end
  def connection
    ClaimInformation.connection
  end
end
