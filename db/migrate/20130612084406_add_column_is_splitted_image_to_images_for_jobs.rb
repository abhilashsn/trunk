class AddColumnIsSplittedImageToImagesForJobs < ActiveRecord::Migration
  def change
    add_column :images_for_jobs, :is_splitted_image, :boolean, :default => false
  end
end
