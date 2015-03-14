class AddPayIdToClaimInformationInMpiData < ActiveRecord::Migration
  def up
   if !ClaimInformation.column_names.include?"payid"
    add_column :claim_informations, :payid, :string, :limit => 60
   end
  end

  def down
    remove_column :claim_informations, :payid 
  end

  def connection
    ClaimInformation.connection
  end
end
