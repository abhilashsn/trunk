class AddOutputPayidToFacilitiesPayersInformations < ActiveRecord::Migration
  def change
    add_column :facilities_payers_informations, :output_payid, :string
  end
end
