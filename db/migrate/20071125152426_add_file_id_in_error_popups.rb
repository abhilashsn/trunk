class AddFileIdInErrorPopups < ActiveRecord::Migration
  def up
    add_column :error_popups,:file_id,:integer 
  end

  def down
    remove_column :error_popups,:file_id
  end
end
