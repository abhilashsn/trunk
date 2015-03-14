class CreateFacilitiesNpiAndTins < ActiveRecord::Migration
  def up
    create_table :facilities_npi_and_tins do |t|
   t.column :facility_id, :integer
       t.column :npi, :string
       t.column :tin, :string
      t.timestamps
    end
  end

  def down
    drop_table :facilities_npi_and_tins
  end
end
