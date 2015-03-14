class AddClientIdToClaimInformation < ActiveRecord::Migration
  def up
    if !ClaimInformation.column_names.include?"client_id"
      add_column :claim_informations, :client_id, :integer
    end
  end

  def down
    remove_column :claim_informations, :client_id
  end

  def connection
    ClaimInformation.connection
  end
end
