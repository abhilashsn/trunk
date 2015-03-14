class AddCompositeIndexToReasonCodesJobsOnParentJobIdAndReasonCodeId < ActiveRecord::Migration
  def up
    add_index(:reason_codes_jobs, [:parent_job_id, :reason_code_id], :unique => true, :name => "index_on_parent_job_id_reason_code_id")
  end

  def down
    remove_index :reason_codes_jobs, :name => "index_on_parent_job_id_reason_code_id"
  end
end
