class CreateDataFiles < ActiveRecord::Migration
  def up
    create_table :data_files do |t|
     
      t.timestamps
    end
  end

  def down
    drop_table :data_files
  end
end
