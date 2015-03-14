class ChangeBillPrintDateToClaimInformations < ActiveRecord::Migration
  def change
    change_column :claim_informations, :bill_print_date, :datetime
  end

  def connection
    ClaimInformation.connection
  end
end