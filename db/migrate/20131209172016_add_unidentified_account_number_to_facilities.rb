class AddUnidentifiedAccountNumberToFacilities < ActiveRecord::Migration
  def change
    add_column :facilities, :unidentified_account_number, :string
  end
end
