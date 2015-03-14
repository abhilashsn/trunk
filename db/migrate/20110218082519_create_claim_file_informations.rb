class CreateClaimFileInformations < ActiveRecord::Migration
  def up
    create_table :claim_file_informations do |t|
      t.column :zip_file_name, :string
      t.column :facility_id, :integer 
      t.column :file_837_name, :string
      t.column :arrival_time, :timestamp
      t.column :size, :float
      t.column :load_start_time, :timestamp
      t.column :load_end_time, :timestamp
      t.column :status,:string
      t.column :total_claim_count, :integer, :limit => 25
      t.column :loaded_claim_count, :integer, :limit => 25
      t.column :total_svcline_count, :integer, :limit => 25
      t.column :loaded_svcline_count, :integer, :limit => 25
      t.timestamps
    end
  end

  def down
    drop_table :claim_file_informations
  end
end
