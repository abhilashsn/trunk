# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class QaController < ApplicationController
  #TODO: Processor controller and QA controller does almost the same. Clean up...
  require_role "qa"
  layout 'standard'
  
  def my_job

    conditions = ["(jobs.qa_id = ?) AND \
                   (jobs.qa_status = '#{QaStatus::ALLOCATED}' OR \
                    jobs.qa_status = '#{QaStatus::PROCESSING}') AND jobs.is_excluded = 0", @current_user.id]
    
    @jobs = Job.select("jobs.id AS id, \
                        jobs.batch_id AS batch_id,\
                        jobs.parent_job_id AS parent_job_id, \
                        jobs.estimated_eob AS estimated_eob, \
                        jobs.processor_status AS processor_status, \
                        jobs.qa_status AS qa_status, \
                        jobs.job_status AS job_status, \
                        jobs.comment_for_qa AS comment_for_qa, \
                        jobs.processor_comments AS processor_comments, \
                        batches.batchid AS batchid, \
                        facilities.name AS facility_name, \
                        processor_users.name AS processor_name, \
                        CASE WHEN jobs.parent_job_id IS NULL \
                             THEN check_informations.check_number \
                        ELSE jobs.check_number \
                        END \
                        AS check_number, \
                        insurance_payment_eobs.image_page_no as image_page_no"). \
      where(conditions). \
      joins("INNER JOIN batches ON batches.id = jobs.batch_id \
                  INNER JOIN facilities ON facilities.id = batches.facility_id \
                  INNER  JOIN check_informations ON  \
                  CASE WHEN jobs.parent_job_id IS NULL \
                       THEN jobs.id \
                  ELSE jobs.parent_job_id \
                  END = check_informations.job_id \
                  LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id \
                  LEFT OUTER JOIN users processor_users ON processor_users.id = jobs.processor_id"). \
      group("jobs.id"). \
      paginate(:page => params[:page], :per_page => 30)
  end

  def jobs_for_onlineusers
    user=User.find(params[:id])
    @job_pages, @jobs = paginate :jobs, :order => ' id asc', :per_page => 30
  end

  def list_payer
    @payer_pages, @payers = paginate :payers, :per_page => 100
  end

  def online_users
    @user_pages, @users = paginate :users, :conditions => ["users.status = 'Online' and users.role = 'Processor'"], :per_page => 30
  end

  def eob_complete
    job = Job.find(params[:job])

    payer = params[:payer][:id]
    #validating Total fields and Total incorrect fields
    if(params[:eob][:total_fields].to_i < params[:eob][:total_incorrect_fields].to_i or params[:eob][:total_fields].to_i < 0 or params[:eob][:total_incorrect_fields].to_i < 0 )
      flash[:notice]  = '"Total Incorrect fields" count exceeds "Total fields" count'
    else
      #Eob Entry
      eob = EobQa.new(:total_fields => params[:eob][:total_fields], :total_incorrect_fields => params[:eob][:total_incorrect_fields], :eob_error => EobError.find_by_error_type(params[:error][:type]),
        :job => job, :processor => job.processor, :qa => job.qa, :time_of_rejection => Time.now, :account_number => params[:eob][:account_number],
        :comment => params[:eob][:comment], :payer => payer, :accuracy => job.processor.field_accuracy)
      if params[:eob][:status] == 'Verified'
        eob.status = "Accepted"
        eob.prev_status = "new"
      else
        eob.status = "Rejected"
        eob.prev_status = "new"
      end

      unless eob.save
        flash[:notice] = eob.errors.entries[0]
      else
        #User details updating
        user = User.find(job.processor_id)
        user.total_fields = user.total_fields + params[:eob][:total_fields].to_i
        user.total_incorrect_fields = user.total_incorrect_fields + params[:eob][:total_incorrect_fields].to_i
        user.eob_qa_checked = user.eob_qa_checked + 1
        user.save
        user.sampling_rate
      end
    end
    redirect_to :action => 'verify', :job => job.id
  end

  def eob_delete
    job = Job.find(params[:job])
    eob = EobQa.find(params[:eob])

    #User details updating
    user = User.find(job.processor_id)
    user.total_fields = user.total_fields - eob.total_fields
    user.total_incorrect_fields = user.total_incorrect_fields - eob.total_incorrect_fields
    user.eob_qa_checked = user.eob_qa_checked - 1
    user.save
    user.sampling_rate()
    eob.destroy

    redirect_to :action => 'verify', :job => job
  end

  def complete_job
    job = Job.find(params[:job])
    count_for_rejected_eobs = 0
    payer_flag = 0
    #Entry in eob report
    @eobs = job.eob_qas
    #Allow update only when eob info is available
    if @eobs.nil? or @eobs.size == 0
      flash[:notice] = "No verified/rejected EOB found. Add and resubmit."
      redirect_to :action => 'verify', :job => job
    else
      @eobs.each do |eob|
        if eob.prev_status != "old"
          EobReport.create(:verify_time => eob.time_of_rejection, :account_number => eob.account_number, :processor => job.processor.userid, :accuracy => eob.accuracy,
            :qa => job.qa.userid, :batch_id => job.batch.batchid, :batch_date => job.batch.date, :total_fields => eob.total_fields,
            :incorrect_fields => eob.total_incorrect_fields, :error_type => eob.eob_error.error_type, :error_severity => eob.eob_error.severity,
            :error_code => eob.eob_error.code, :status => eob.status, :payer => eob.payer )
          if eob.total_incorrect_fields > 0
            count_for_rejected_eobs += 1
          end
        end
        eob.prev_status = "old"
        eob.save
      end
      
      user = job.processor
      #if job rejections > 0, do not recount the eob count
      if job.rejections == 0
        # job.eob_count will fetch total EOB count for the job based on count of database table records for EOBs
        user.total_eobs = user.total_eobs + job.eob_count
      end
      #rejected_eobs is the count of eobs with incorrect fields >= 1)
      user.rejected_eobs = user.rejected_eobs + count_for_rejected_eobs
      user.save
      
      if count_for_rejected_eobs > 0
        job.rejections += 1
      end
      job.save
      user.compute_eob_accuracy
      
      #Job Status updating
      if @eobs.size > 0
        flag = 0
        comment = ''
        @eobs.each do |eob|
          if comment.nil?
            comment = eob.comment
          else
            if eob.status == 'Rejected'
              comment = eob.comment + '-' + comment
            end
          end
          if eob.status == 'Rejected'
            flag = 1
          end
        end
        if flag == 0
          job.qa_status = QaStatus::COMPLETED
          job.qa_flag_time = Time.now
          if job.processor_status == ProcessorStatus::COMPLETED
            job.job_status = JobStatus::COMPLETED
          end
          if !job.incomplete_count.blank? and job.incomplete_count > 0
            if job.processor_status == ProcessorStatus::COMPLETED
              job.job_status = JobStatus::NEW
            end
          end
        else
          job.qa_status = QaStatus::REJECTED
          job.job_status = QaStatus::REJECTED
          job.comment = comment
        end
      else
        job.qa_status = QaStatus::COMPLETED
        job.qa_flag_time = Time.now
        if job.processor_status == ProcessorStatus::COMPLETED
          job.job_status = JobStatus::COMPLETED
        end
      end
  
      if payer_flag == 1
        flash[:notice] = 'Payer ID invalid! Please reenter.'
        redirect_to :action => 'verify', :job => job
      elsif job.save
        flash[:notice] = 'Job was successfully updated.'
        # Updating the batch status
        batch = Batch.find(job.batch_id)
        batch.update_status
        redirect_to :action => 'my_job', :job => job
      else
        flash[:notice] = 'Job update failed'
        redirect_to :action => 'my_job', :job => job
      end
    end
  end

  def clear_verified_eobs
    job = Job.find(params[:job])
    #EobQa.delete_all(["job_id = ?" , job.id])
    redirect_to :action => 'verify', :job => job

    #TODO: remove when cron task for reset is added
    job.processor.reset_eob_qa_checked()
  end

  def verify
    @job = Job.find(params[:job])
    @user = User.find(@job.processor_id)
    @eobs = @job.eob_qas
    @sample_rate = @user.sampling_rate()
    @error_types = EobError.find(:all)
  end

end
