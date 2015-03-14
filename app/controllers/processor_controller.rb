# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class ProcessorController < ApplicationController
  #TODO: Processor controller and QA controller does almost the same. Clean up ...
  require_role "processor"
  layout 'standard'

  def my_job
    if !params[:location].blank? && params[:location] == 'dashboard'
      if @current_user.auto_allocation_enabled == false
        @current_user.auto_allocation_enabled = true
        @current_user.save
      end
    end
    JobAllocator::allocate_facility_wise([@current_user.id])
    conditions = ["(jobs.processor_id = ?) AND \
                   (jobs.processor_status = '#{ProcessorStatus::ALLOCATED}' OR \
                   jobs.qa_status = '#{QaStatus::REJECTED}') AND jobs.is_excluded = 0", @current_user.id]
    @jobs = Job.select("jobs.id AS id, \
                        jobs.batch_id AS batch_id, \
                        jobs.estimated_eob AS estimated_eob, \
                        jobs.job_status AS job_status, \
                        jobs.incomplete_count AS incomplete_eob_count, \
                        jobs.processor_status AS processor_status, \
                        jobs.qa_status AS qa_status, \
                        jobs.pages_from AS pages_from, \
                        jobs.pages_to AS pages_to, \
                        jobs.parent_job_id AS parent_job_id, \
                        jobs.rejected_comment AS rejected_comment, \
jobs.is_ocr as is_ocr_flag,\
                        CASE WHEN jobs.parent_job_id IS NULL \
                          THEN check_informations.check_number \
                          ELSE jobs.check_number \
                          END \
                        AS check_number, \
                        facilities.name AS facility_name, \
                        facilities.details AS facility_details, \
                        batches.batchid AS batchid, \
                        batches.date AS batch_date, \
                        batches.arrival_time AS arrival_time, \
                        batches.target_time AS target_time, \
                        batches.expected_completion_time AS expected_completion_time, \
                        check_informations.details AS check_details_column, \
                        (CASE WHEN payers.payer IS NOT NULL
                            THEN payers.payer
                            ELSE
                              CASE WHEN micr_payers.payer IS NOT NULL
                                THEN micr_payers.payer
                                ELSE 'UNKNOWN'
                              END
                         END) AS name_payer, \
                        insurance_payment_eobs.details AS eob_details_column, \
                        qa_users.name AS qa_name, \
                        qa_users.id AS qa_id ,GROUP_CONCAT(eob_errors.error_type) AS error_type").\
      where(conditions). \
      joins("LEFT OUTER JOIN eob_qas ON eob_qas.job_id = jobs.id LEFT OUTER JOIN eob_errors ON eob_qas.eob_error_id = eob_errors.id
INNER JOIN batches ON batches.id = jobs.batch_id INNER JOIN facilities ON facilities.id = batches.facility_id
INNER JOIN check_informations ON CASE WHEN jobs.parent_job_id IS NULL THEN jobs.id ELSE jobs.parent_job_id END = check_informations.job_id
LEFT OUTER JOIN micr_line_informations ON micr_line_informations.id = check_informations.micr_line_information_id
LEFT OUTER JOIN payers micr_payers ON micr_payers.id = micr_line_informations.payer_id
LEFT OUTER JOIN payers ON payers.id = check_informations.payer_id
LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id
LEFT OUTER JOIN users qa_users ON qa_users.id = jobs.qa_id  "). \
      includes({:check_informations => :insurance_payment_eobs}). \
      group("jobs.id").paginate(:page => params[:page], :per_page => 30)

  end

  def list_payer
    @payer_pages, @payers = paginate :payers, :per_page => 100
  end

  def complete_job
    job = Job.find(params[:id])
    use=params[:job][:count].to_i + params[:job][:incomplete_count].to_i
     
    
      
    if params[:job][:count].blank?
      flash[:notice] = "EOB Count Incorrect"
      redirect_to :action => 'my_job'
    elsif params[:job][:count].to_i > 200
      flash[:notice] = "You have exceeded maximum Eobs!"
      redirect_to :action => 'my_job'
    elsif params[:payerid].blank?
      flash[:notice] = "Please Enter PayerId"
      redirect_to :action => 'my_job'
    elsif params[:job][:incomplete_count].blank?
      flash[:notice] = "Please Enter remaining Eobs"
      redirect_to :action => 'my_job'
    else
      job.incomplete_count = params[:job][:incomplete_count]
      job.processor_flag_time = Time.now
      job.processor_status = ProcessorStatus::COMPLETED
      if job.qa_id != nil
        if job.qa_status == QaStatus::COMPLETED
          job.job_status = JobStatus::COMPLETED
        elsif job.qa_status == QaStatus::REJECTED
          job.qa_status = QaStatus::ALLOCATED
        end
      else
        job.job_status = JobStatus::COMPLETED
      end
    
      if UserPayerJobHistory.find_by_payer_id_and_user_id(job.payer.id, job.processor.id).nil?
        new_job_history = UserPayerJobHistory.new
        new_job_history.job_count = 1
        new_job_history.user = job.processor
        new_job_history.payer = job.payer
        new_job_history.save
      else
        job_history = UserPayerJobHistory.find_by_payer_id_and_user_id(job.payer.id, job.processor.id)
        job_history.job_count += 1
        job_history.save
      end
      
      if UserClientJobHistory.find_by_client_id_and_user_id(job.batch.facility.client.id, job.processor.id).nil?
        new_client_history = UserClientJobHistory.new
        new_client_history.job_count = 1
        new_client_history.user = job.processor
        new_client_history.client = job.batch.facility.client
        new_client_history.save
      else
        client_history = UserClientJobHistory.find_by_client_id_and_user_id(job.batch.facility.client.id, job.processor.id)
        client_history.job_count += 1
        client_history.save
      end
      
      if !job.incomplete_count.nil? and job.incomplete_count > 0
        if not params[:payerid].blank?
          payer = Payer.find_by_payid(params[:payerid])
          @payergroup=Payer.find_by_payid(params[:payerid]).payer_group_id
          unless payer.nil?
            new_job = Job.new(:check_number => job.check_number, :batch => job.batch,
              :estimated_eob => job.incomplete_count, :payer => payer)
            new_job.save!
            update_jobs(job)
          else
            flash[:notice] = "PayerID is invalid"
            redirect_to :action => 'my_job'
          end
        end
      elsif 
        payer = Payer.find_by_payid(params[:payerid])
        if !payer.nil?
          update_jobs(job)
        else
          flash[:notice] = "PayerID is invalid. Enter Correct PayerID (or) Please Create New Payer."
          redirect_to :action => 'my_job'
        end
      else
        flash[:notice] = 'PayerID is invalid. Enter Correct PayerID (or) Please Create New Payer.'
        redirect_to :action => 'my_job'
      end
    end
  end
  
  def update_jobs(job)
    job.update_attributes(params[:job])
    flash[:notice] = 'Job was sucessfully updated'
    # Updating the batch status
    batch = job.batch
    batch.update_status
    redirect_to :action => 'my_job'
  end
  
  def productivity_report
    @total_ins_eobs=0
    @total_service_lines=0
    @total_pat_eobs=0

    today_date = Date.today.strftime('%Y-%m-%d')

    @ins_eobs = InsurancePaymentEob.find(:all \
        , :select => "batches.batchid as batchid \
                    , batches.date as date \
                    , insurance_payment_eobs.created_at as created_at \
                    , insurance_payment_eobs.patient_account_number as patient_account_number \
                    , check_informations.check_number as check_number \
                    , facilities.name as facility_name \
                    , count(service_payment_eobs.id) as service_payment_eobs_count" \
        , :joins => "LEFT OUTER JOIN service_payment_eobs ON service_payment_eobs.insurance_payment_eob_id = insurance_payment_eobs.id \
                    LEFT OUTER JOIN check_informations ON check_informations.id = insurance_payment_eobs.check_information_id \
                    LEFT OUTER JOIN jobs ON jobs.id = check_informations.job_id \
                    LEFT OUTER JOIN batches ON batches.id = jobs.batch_id \
                    LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id" \
        , :group => "insurance_payment_eobs.id" \
        , :conditions => ["insurance_payment_eobs.processor_id=? and insurance_payment_eobs.processing_completed like ?", @current_user.id,"#{today_date}%"])
    @total_ins_eobs=@ins_eobs.length

    @pat_eobs = PatientPayEob.find(:all \
        , :select => "batches.batchid as batchid \
                    , batches.date as date \
                    , patient_pay_eobs.end_time as end_time \
                    , patient_pay_eobs.account_number as account_number \
                    , check_informations.check_number as check_number \
                    , facilities.name as facility_name" \
        , :joins => "LEFT OUTER JOIN check_informations ON check_informations.id = patient_pay_eobs.check_information_id \
                    LEFT OUTER JOIN jobs ON jobs.id = check_informations.job_id \
                    LEFT OUTER JOIN batches ON batches.id = jobs.batch_id \
                    LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id" \
        , :group => "patient_pay_eobs.id" \
        , :conditions => ["patient_pay_eobs.processor_id=? and patient_pay_eobs.processing_completed like ?", @current_user.id, "#{today_date}%"])
    @total_pat_eobs=@pat_eobs.length
  end
  
  def monthly_productivity_report
    @ins_eobs = nil
    @pat_eobs = nil
    flash[:notice] = nil
    if params[:commit].eql?('View')
      flash[:notice] = nil
      if (!(params[:date_from].blank?) and !(params[:date_to].blank?))
        from_date_time = Date.rr_parse(params[:date_from], true).to_s + ' 00:00:00'
        to_date_time = Date.rr_parse(params[:date_to], true).to_s + ' 23:59:59'
        @ins_eobs = InsurancePaymentEob.find(:all \
            , :select => "  insurance_payment_eobs.processing_completed as user_date, \
                        COUNT(DISTINCT insurance_payment_eobs.id) as completed_eobs, \
                        COUNT(DISTINCT service_payment_eobs.id) as completed_sv_count, \
                        COUNT(DISTINCT eob_total.id) AS eob_total, \
                        COUNT(DISTINCT eob_incorrect.total_incorrect_fields) AS eob_incorrect" \
            , :joins =>  "  LEFT OUTER JOIN \
                          eob_qas AS eob_total ON eob_total.eob_id = insurance_payment_eobs.id \
                        LEFT OUTER JOIN \
                          eob_qas AS eob_incorrect ON eob_incorrect.eob_id = insurance_payment_eobs.id AND eob_incorrect.total_incorrect_fields > 0 \
                        LEFT OUTER JOIN \
                          service_payment_eobs ON service_payment_eobs.insurance_payment_eob_id = insurance_payment_eobs.id" \
            , :conditions => [ " insurance_payment_eobs.processing_completed between ? AND ? \
                             AND insurance_payment_eobs.processor_id = ?", from_date_time, to_date_time, @current_user.id] \
            , :group => "insurance_payment_eobs.processing_completed")

        @pat_eobs = PatientPayEob.find(:all \
            , :select => "  patient_pay_eobs.processing_completed as user_date, \
                        COUNT(DISTINCT patient_pay_eobs.id) as completed_eobs, \
                        COUNT(DISTINCT eob_total.id) AS eob_total, \
                        COUNT(DISTINCT eob_incorrect.total_incorrect_fields) AS eob_incorrect" \
            , :joins =>  "  LEFT OUTER JOIN \
                          eob_qas AS eob_total ON eob_total.eob_id = patient_pay_eobs.id \
                        LEFT OUTER JOIN \
                          eob_qas AS eob_incorrect ON eob_incorrect.eob_id = patient_pay_eobs.id AND eob_incorrect.total_incorrect_fields > 0" \
            , :conditions => [" patient_pay_eobs.processing_completed between ? AND ? \
                            AND patient_pay_eobs.processor_id = ?", from_date_time, to_date_time, @current_user.id] \
            , :group => "patient_pay_eobs.processing_completed")

      elsif ((params[:date_from].blank?) and (not params[:date_to].blank?))
        flash[:notice] = "From Date Mandatory"
      elsif ((not params[:date_from].blank?) and (params[:date_to].blank?))
        flash[:notice] = "To Date Mandatory"
      else
        if (( params[:date_from].blank?) and (params[:date_to].blank?))
          flash[:notice] = "Dates are Mandatory"
        end
      end
    end
  end
end
