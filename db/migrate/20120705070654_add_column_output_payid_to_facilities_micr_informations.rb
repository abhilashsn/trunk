class AddColumnOutputPayidToFacilitiesMicrInformations < ActiveRecord::Migration
  def up
    add_column :facilities_micr_informations, :output_payid, :integer
  end

  def down
    remove_column :facilities_micr_informations, :output_payid
  end
end
  