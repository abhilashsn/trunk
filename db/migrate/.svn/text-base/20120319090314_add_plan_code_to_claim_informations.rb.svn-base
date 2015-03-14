class AddPlanCodeToClaimInformations < ActiveRecord::Migration
  def change
    add_column :claim_informations, :plan_code, :string
  end

  def connection
    ClaimInformation.connection
  end
end
