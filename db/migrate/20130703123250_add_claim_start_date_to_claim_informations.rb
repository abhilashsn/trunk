class AddClaimStartDateToClaimInformations < ActiveRecord::Migration
  def change
    add_column :claim_informations, :claim_start_date, :date
  end

  def connection
    ClaimInformation.connection
  end
end
