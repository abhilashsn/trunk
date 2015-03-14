class AddDetailsToPayers < ActiveRecord::Migration
   def up
     begin
    add_column :payers, :details, :text
     rescue
     end
  end

  def down
    remove_column :payers, :details
  end
end
