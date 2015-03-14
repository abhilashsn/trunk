class RenameFlieLocationToSftpLocation < ActiveRecord::Migration
  def up
    rename_column :eras, :file_location, :sftp_location
  end

  def down
    rename_column :eras,:sftp_location, :file_location
  end
end
