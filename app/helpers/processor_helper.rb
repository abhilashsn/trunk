module ProcessorHelper
   def save_activity_job(job_id,processor_id,qa_id,activity_name)
    @job_activity=JobActivityLog.new()
        @job_activity.job_id=job_id
        @job_activity.processor_id= processor_id
        @job_activity.qa_id=qa_id
        @job_activity.activity=activity_name
        @job_activity.start_time=Time.now
        @job_activity.save
 end

end
