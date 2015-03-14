class CreateProviders < ActiveRecord::Migration
  def up
    create_table :providers do |t|
      t.column :facility_id,:integer,:references => :facilities
      t.column :provider_last_name,:string
      t.column :provider_first_name,:string
      t.column :provider_suffix,:string
      t.column :provider_middle_initial,:string
      t.column :provider_npi_number,:string
      t.column :provider_tin_number,:string
      t.timestamps
    end
    execute "ALTER TABLE providers ADD CONSTRAINT providers_idfk_1 FOREIGN KEY (facility_id)
       REFERENCES facilities(id)"
  end
  
  def down
    execute "ALTER TABLE providers DROP FOREIGN KEY providers_idfk_1"
    drop_table :providers
  end
end
