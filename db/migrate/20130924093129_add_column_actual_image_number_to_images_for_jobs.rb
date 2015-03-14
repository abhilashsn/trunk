class AddColumnActualImageNumberToImagesForJobs < ActiveRecord::Migration
  def change
     add_column :images_for_jobs, :actual_image_number, :integer
  end
end
