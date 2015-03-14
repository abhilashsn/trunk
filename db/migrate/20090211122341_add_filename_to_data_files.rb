class AddFilenameToDataFiles < ActiveRecord::Migration
  def up
    add_column :data_files,:file_name, :string
  end

  def down
    remove_column :data_files,:file_name
  end
end
