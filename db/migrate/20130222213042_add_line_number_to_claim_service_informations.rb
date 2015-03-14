class AddLineNumberToClaimServiceInformations < ActiveRecord::Migration
  def change
    add_column :claim_service_informations, :line_number, :integer, {null: false, default: 0}
  end
  
  def connection
        ClaimInformation.connection
  end
  
end
