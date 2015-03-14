class CreateFacilityAliases < ActiveRecord::Migration
  def change
    create_table :facility_aliases do |t|
      t.string :name
      t.integer :facility_id

      t.timestamps
    end
  end
end
