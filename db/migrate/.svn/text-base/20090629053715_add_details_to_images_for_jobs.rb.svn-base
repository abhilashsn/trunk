class AddDetailsToImagesForJobs < ActiveRecord::Migration
 def up
   begin
    add_column :images_for_jobs, :details, :text
   rescue
   end
  end

  def down
    remove_column :images_for_jobs, :details
  end
end
