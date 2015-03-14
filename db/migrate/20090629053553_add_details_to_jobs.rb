class AddDetailsToJobs < ActiveRecord::Migration
 def up
   begin
    add_column :jobs, :details, :text
   rescue
   end
  end

  def down
    remove_column :jobs, :details
  end
end
