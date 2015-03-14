class AddDetailsToBatches < ActiveRecord::Migration
   def up
     begin
    add_column :batches, :details, :text
     rescue
     end
  end

  def down
    remove_column :batches, :details
  end
end
