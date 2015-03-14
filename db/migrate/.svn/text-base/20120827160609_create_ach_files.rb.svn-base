class CreateAchFiles < ActiveRecord::Migration
  def change
    create_table :ach_files do |t|
      t.string :file_name
      t.integer :file_size
      t.string :file_creation_date
      t.string :file_creation_time
      t.string :file_hash
      t.string :file_arrival_date
      t.string :file_arrival_time
      t.datetime :file_load_start_time
      t.datetime :file_load_end_time

      t.timestamps
    end
  end
end
