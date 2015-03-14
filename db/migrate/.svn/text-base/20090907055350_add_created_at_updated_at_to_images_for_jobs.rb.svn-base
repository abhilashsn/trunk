class AddCreatedAtUpdatedAtToImagesForJobs < ActiveRecord::Migration
  def up
    add_column :images_for_jobs, :created_at, :datetime
    add_column :images_for_jobs, :updated_at, :datetime
  end

  def down
    remove_column :images_for_jobs, :created_at
    remove_column :images_for_jobs, :updated_at
  end
end
