class CreateFacilityPayerRelations < ActiveRecord::Migration
  def up
    create_table :facility_payer_relations do |t|
      t.column :payer_id, :integer
       t.column :facility_id, :integer
    

      t.timestamps
    end
  end

  def down
    drop_table :facility_payer_relations
  end
end
