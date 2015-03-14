class CreatePayerOnbaseRelations < ActiveRecord::Migration
  def up
    create_table :payer_onbase_relations do |t|
      t.column :facility_id, :integer
      t.column :onbase_name, :string
      t.column :payer_id, :integer
      t.timestamps
    end
  end

  def down
    drop_table :payer_onbase_relations
  end
end
