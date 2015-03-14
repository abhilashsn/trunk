class RemoveImageTypeFromImagesForJobs < ActiveRecord::Migration
  def up
    remove_column :images_for_jobs, :image_type
  end

  def down
    add_column :images_for_jobs, :image_type
  end
end
