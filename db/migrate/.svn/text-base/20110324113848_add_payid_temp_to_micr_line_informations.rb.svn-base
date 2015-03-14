class AddPayidTempToMicrLineInformations < ActiveRecord::Migration
  def up
    add_column :micr_line_informations, :payid_temp, :string, :limit => 10
  end

  def down
    remove_column :micr_line_informations, :payid_temp
  end
end
