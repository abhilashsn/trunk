class AddColumnChargesToClaimServiceInformation < ActiveRecord::Migration
  def up
    add_column :claim_service_informations,:charges, :decimal,:precision => 10, :scale => 2
  end

  def down
    remove_column :claim_service_informations,:charges
  end
  def connection
    ClaimServiceInformation.connection
  end
end
