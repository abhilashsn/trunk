class CreateImagesForJobs < ActiveRecord::Migration
  def up
    create_table :images_for_jobs do |t|
      t.column :content_type, :string
      t.column :filename, :string    
      t.column :size, :integer
      t.column :width, :integer
      t.column :height, :integer
      t.column :image_type, :string ,:limit=>"2"
      t.column :eob_status, :string,:default=>"New"
      t.column :batch_id, :integer
      t.column  :deleted_at,  :datetime
      t.column :details, :text
    end
    execute "ALTER TABLE images_for_jobs
            ADD CONSTRAINT images_for_jobs_idfk_1 FOREIGN KEY (batch_id)
            REFERENCES batches(id)"
  end

  def down
    execute "ALTER TABLE images_for_jobs DROP FOREIGN KEY images_for_jobs_idfk_1"
    drop_table :images_for_jobs
  end
end
