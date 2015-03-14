class AddColumnImagesForJobIdToJobs < ActiveRecord::Migration
  def up
    add_column :jobs, :images_for_job_id, :integer
  end

  def down
    remove_column :jobs, :images_for_job_id
  end
end
