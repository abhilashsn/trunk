class ChangeStatusForJobsAndBatches < ActiveRecord::Migration
  def up
    Job.update_all("job_status = 'NEW'", "job_status = 'New'")
    Job.update_all("qa_status = 'NEW'", "qa_status = 'New'")
    Job.update_all("processor_status = 'NEW'", "processor_status = 'New'")
    Batch.update_all("status = 'NEW'", "status = 'New'")
    change_column :jobs, :job_status, :string, :default => JobStatus::NEW
    change_column :jobs, :qa_status, :string, :default => QaStatus::NEW
    change_column :jobs, :processor_status, :string, :default => ProcessorStatus::NEW
    change_column :batches, :status, :string, :default => BatchStatus::NEW
  end

  def down
    Job.update_all("job_status = 'New'", "job_status = 'NEW'")
    Job.update_all("qa_status = 'New'", "qa_status = 'NEW'")
    Job.update_all("processor_status = 'New'", "processor_status = 'NEW'")
    Batch.update_all("status = 'New'", "status = 'NEW'")
    change_column :jobs, :job_status, :string, :default => 'New'
    change_column :jobs, :qa_status, :string, :default => 'New'
    change_column :jobs, :processor_status, :string, :default => 'New'
    change_column :batches, :status, :string, :default => 'New'
  end
end
