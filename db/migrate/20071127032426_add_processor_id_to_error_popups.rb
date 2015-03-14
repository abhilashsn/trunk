class AddProcessorIdToErrorPopups < ActiveRecord::Migration
  def up
    add_column :error_popups,:processor_id,:integer 
  end

  def down
    remove_column :error_popups,:processor_id,:integer
  end
end
