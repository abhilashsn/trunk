module Admin::BatchHelper

  # Returns the color for the legend for work list
  def legend_color_for_work_list
    time = (@batch.contracted_time.blank? ? 1 : (Time.now.utc.in_time_zone("Eastern Time (US & Canada)") <=> @batch.contracted_time))
    processor_completed_job_count = @batch.processor_completed.to_i
    processor_incompleted_job_count = @batch.processor_incompleted.to_i
    processor_completed_plus_incompleted_job_count = processor_completed_job_count + processor_incompleted_job_count
    admin_incompleted_job_count = @batch.admin_incompleted.to_i
    job_count = @batch.job_count.to_i
    allocated_job_count = @batch.allocated.to_i
    
    if time == 1
      color = "orangered"
    elsif (@batch.status == "#{BatchStatus::OUTPUT_READY}" ||
          (@batch.status == "#{BatchStatus::PROCESSING}" && 
            admin_incompleted_job_count == job_count))
      color = "palered"
    elsif (@batch.status == "#{BatchStatus::COMPLETED}" && processor_completed_plus_incompleted_job_count == job_count && allocated_job_count > 0)
      color = "grey"
    elsif @batch.status == "#{BatchStatus::COMPLETED}"
      color = "green"
    elsif (@batch.status == "#{BatchStatus::PROCESSING}" && processor_completed_job_count == job_count && allocated_job_count > 0)
      color = "grey"
    elsif @batch.status == "#{BatchStatus::PROCESSING}" && job_count > allocated_job_count && ((job_count - allocated_job_count) != @batch.excluded_job_count)
      color = "orange"
    elsif @batch.status == "#{BatchStatus::PROCESSING}" && job_count == allocated_job_count
      color = "blue"
    elsif @batch.status == "#{BatchStatus::PROCESSING}"
      color = "blue"
    
    else
      color = "white"
    end
    
    color
  end
  
  def batch_status_details
    batch_status = [BatchStatus::NEW, BatchStatus::PROCESSING, BatchStatus::COMPLETED, BatchStatus::OUTPUT_READY,
      BatchStatus::OUTPUT_GENERATING, BatchStatus::OUTPUT_GENERATED,BatchStatus::OUTPUT_EXCEPTION,BatchStatus::ARCHIVED, BatchStatus::DEALLOCATED]
  end

end
