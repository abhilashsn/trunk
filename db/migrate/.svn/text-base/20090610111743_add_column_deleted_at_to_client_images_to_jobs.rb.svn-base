class AddColumnDeletedAtToClientImagesToJobs < ActiveRecord::Migration
  def up
    begin
      add_column :client_images_to_jobs, :deleted_at,  :datetime
    rescue
    end
  end

  def down
    remove_column :client_images_to_jobs, :deleted_at
  end
end
