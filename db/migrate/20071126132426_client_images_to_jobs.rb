class ClientImagesToJobs < ActiveRecord::Migration
  def up
    create_table :client_images_to_jobs do |t|
      t.column :job_id, :integer
      t.column :images_for_job_id, :integer
      t.column :deleted_at,  :datetime
    end
    execute "ALTER TABLE client_images_to_jobs ADD CONSTRAINT client_images_to_jobs_idfk_1 FOREIGN KEY (job_id)
        REFERENCES jobs(id)"
    execute "ALTER TABLE client_images_to_jobs ADD CONSTRAINT client_images_to_jobs_idfk_2 FOREIGN KEY (images_for_job_id)
        REFERENCES images_for_jobs(id)"
  end

  def down
    execute "ALTER TABLE client_images_to_jobs DROP FOREIGN KEY client_images_to_jobs_idfk_1"
    execute "ALTER TABLE client_images_to_jobs DROP FOREIGN KEY client_images_to_jobs_idfk_2"
    drop_table :client_images_to_jobs
  end
end
