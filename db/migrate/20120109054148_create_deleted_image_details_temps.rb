class CreateDeletedImageDetailsTemps < ActiveRecord::Migration
  def change
    create_table :deleted_image_details_temps do |t|
      t.integer :batch_id
      t.integer :folder_name
      t.string :image_file_name
      t.string :image_folder_path
      t.timestamps
    end
    
    create_table :batch_temps do |t|
    	t.integer :batch_id
        t.datetime :batch_date
    end
    
    add_index :batch_temps, :batch_id, :name => "idx_batch_temps_lookup"
    
  end
end
