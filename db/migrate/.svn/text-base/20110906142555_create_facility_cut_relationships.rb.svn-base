class CreateFacilityCutRelationships < ActiveRecord::Migration
  def up
    create_table :facility_cut_relationships do |t|
      t.references :facility
      t.string :cut
      t.string :day
      t.time :time
      t.timestamps
    end
  end

  def down
    drop_table :facility_cut_relationships
  end
end
