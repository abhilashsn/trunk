class CreateReasonCodesJobs < ActiveRecord::Migration
  def up
    create_table :reason_codes_jobs do |t|
      t.integer :reason_code_id, :limit => 11
      t.integer :parent_job_id, :limit => 11
      t.integer :sub_job_id, :limit => 11
      t.timestamps
    end
  end

  def down
    drop_table :reason_codes_jobs
  end
end
