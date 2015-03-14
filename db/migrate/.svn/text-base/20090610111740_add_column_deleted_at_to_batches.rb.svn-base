class AddColumnDeletedAtToBatches < ActiveRecord::Migration
  def up
    begin
     add_column :batches, :deleted_at,  :datetime 
   rescue
   end
  end

  def down
    remove_column :batches, :deleted_at
  end
end
