class CreateFacilitiesCodes < ActiveRecord::Migration
  def change
    create_table :facilities_codes do |t|
      t.integer :facility_id
      t.string :code

      t.timestamps
    end
  end
end
