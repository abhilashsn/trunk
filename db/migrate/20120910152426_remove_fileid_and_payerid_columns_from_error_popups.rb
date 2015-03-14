class RemoveFileidAndPayeridColumnsFromErrorPopups < ActiveRecord::Migration
  def up
    remove_column :error_popups,:file_id
    remove_column :error_popups,:payer_id
  end

  def down
    
    add_column :error_popups,:file_id,:integer 
    add_column :error_popups,:payer_id,:integer 
    
  end
end



