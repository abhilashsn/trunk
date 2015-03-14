class AddImageColumnsToImagesForJob < ActiveRecord::Migration
  def up
    rename_column :images_for_jobs, :filename, :image_file_name
    rename_column :images_for_jobs, :content_type, :image_content_type
    rename_column :images_for_jobs, :size, :image_file_size
    add_column :images_for_jobs, :image_updated_at,   :datetime
  end

  def down
    rename_column :images_for_jobs, :image_file_name, :filename
    rename_column :images_for_jobs, :image_content_type, :content_type
    rename_column :images_for_jobs, :image_file_size, :size
    remove_column :images_for_jobs, :image_updated_at,   :datetime
  end
end
