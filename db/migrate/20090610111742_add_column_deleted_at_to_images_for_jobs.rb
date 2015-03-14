class AddColumnDeletedAtToImagesForJobs < ActiveRecord::Migration
  def up
    begin
     add_column :images_for_jobs, :deleted_at,  :datetime
    rescue
    end
  end

  def down
     remove_column :images_for_jobs, :deleted_at
  end
end
