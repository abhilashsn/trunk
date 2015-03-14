class RemoveOutputPayidFromFacilitiesMicrInformations < ActiveRecord::Migration
  def up
    remove_column :facilities_micr_informations, :output_payid
  end

  def down
    add_column :facilities_micr_informations, :output_payid, :integer
  end
end
