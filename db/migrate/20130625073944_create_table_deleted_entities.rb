class CreateTableDeletedEntities < ActiveRecord::Migration
  def change
    create_table :deleted_entities do |t|
      t.string :entity
      t.integer :entity_id
      t.integer :client_id
      t.integer :facility_id
      t.datetime :created_at
    end

    add_index :deleted_entities, :client_id, :name => 'by_client_id'
  end
end
