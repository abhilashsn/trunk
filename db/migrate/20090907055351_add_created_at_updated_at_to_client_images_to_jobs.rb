class AddCreatedAtUpdatedAtToClientImagesToJobs < ActiveRecord::Migration
  def up
     add_column :client_images_to_jobs, :created_at, :datetime
     add_column :client_images_to_jobs, :updated_at, :datetime
  end

  def down
     remove_column :client_images_to_jobs, :created_at
     remove_column :client_images_to_jobs, :updated_at
  end
end
