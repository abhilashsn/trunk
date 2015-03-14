class AddParentJobIdToJobsSubJobIdToClientImagesToJobs < ActiveRecord::Migration
  def up
    add_column :jobs,:parent_job_id, :integer
    add_column :client_images_to_jobs,:sub_job_id, :integer
    add_column :insurance_payment_eobs,:sub_job_id, :integer
  end

  def down
    remove_column :jobs,:parent_job_id
    remove_column :client_images_to_jobs,:sub_job_id
    remove_column :insurance_payment_eobs,:sub_job_id
  end
end
