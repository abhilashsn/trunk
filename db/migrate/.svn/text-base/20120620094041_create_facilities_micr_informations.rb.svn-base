class CreateFacilitiesMicrInformations < ActiveRecord::Migration
  def change
    create_table :facilities_micr_informations do |t|
      t.references :facility
      t.references :micr_line_information
      t.string :onbase_name, :limit => 255
      t.timestamps
    end
  end
end
