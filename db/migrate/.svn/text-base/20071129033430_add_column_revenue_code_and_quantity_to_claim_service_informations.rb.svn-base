class AddColumnRevenueCodeAndQuantityToClaimServiceInformations < ActiveRecord::Migration
  def up
    add_column :claim_service_informations, :quantity, :decimal,:precision => 8, :scale => 2
    add_column :claim_service_informations, :non_covered_charge, :decimal,:precision => 8, :scale => 2
    add_column :claim_service_informations, :revenue_code, :string,:limit =>6
  end

  def down
    remove_column :claim_service_informations, :quantity
    remove_column :claim_service_informations, :non_covered_charge
    remove_column :claim_service_informations, :revenue_code
  end
  def connection
    ClaimServiceInformation.connection
  end
end
