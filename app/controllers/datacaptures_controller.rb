require 'adjustment_reason'
require 'utils/rr_logger'
class DatacapturesController < ApplicationController
  include InsurancePaymentEobsHelper
  include AdjustmentReason
  require 'csv'
  protect_from_forgery :only => [:create, :update, :destroy]
  layout 'datacapture',:except => [:mpisearch]
  require_role ["supervisor","admin", "processor","qa","partner","client","facility"]
  before_filter :prepare, :except => [:capitation_account, :export_to_csv]
  before_filter :supervisor_processor_validate, :only => [:capitation_account]

  def correct_answer
  
    @popup = ErrorPopup.find(params[:error_popup_id])
    comment_id = params[:id_pop]
    if(!(@popup.Question).blank?)
      if params[:choice]
        if @popup.answer==params[:choice]
          comment_id = comment_id.split("-").reject{ |e| e.empty? }
          comment_id.delete("#{params[:error_popup_id]}")
          if(comment_id.length == 0)
            cont = "<script>window.opener.document.getElementById('insurance').value=1</script>
            <font color='blue'>You have answered all the questions correctly. Now you can close the window and proceed.</font>"

            cont = cont.html_safe
            render :text=> cont
          else
            alert_id = comment_id[0]
            comment_id = comment_id.join('-')
            flash[:message]="entered answer is correct. Please answer next questions."
            redirect_to :action=>"popup",:payer=>params[:payer] ,:popup_id => comment_id ,:error_popup_id => alert_id
          end
        else
          flash[:message]="That is a wrong answer. Please try again."
          redirect_to :action=>"popup",:payer=>params[:payer] ,:error_popup_id => params[:error_popup_id],:popup_id => comment_id
        end
      else
        flash[:message]="Please answer the question and hit submit."
        redirect_to :action=>"popup",:payer=>params[:payer] ,:error_popup_id => params[:error_popup_id],:popup_id => comment_id
      end
    else
      comment_id = comment_id.split("-").reject{ |e| e.empty? }
      comment_id.delete("#{params[:error_popup_id]}")
      if(comment_id.length == 0)
        cont = "<script>window.opener.document.getElementById('insurance').value=1</script>
            <font color='blue'> Now you can close the window and proceed.</font>"

        cont = cont.html_safe
        render :text=> cont
      else
        alert_id = comment_id[0]
        comment_id = comment_id.join('-')
        redirect_to :action=>"popup",:payer=>params[:payer] ,:popup_id => comment_id ,:error_popup_id => alert_id
      end
    end
  end
    
  def popup
    if(params[:error_popup_id].nil?)
      alerts = ErrorPopup.find(:all,
        :conditions => ["(processor_id is null or processor_id = ?)
       and (facility_id is null or facility_id = ?)
       and (reason_code_set_name_id is null or reason_code_set_name_id = ? )
       and client_id = ? and start_date <= ? and end_date > ?
       and field_id = ?",
          "#{session[:user_id]}", "#{params[:facility_id]}", "#{params[:rc_set_name_id]}", "#{params[:client_id]}",
          "#{(Time.now).strftime("%y/%m/%d")}", "#{Time.now.strftime("%y/%m/%d")}","#{params[:field_id]}"],:order => "Question")
      @question = alerts.last
      @alert_ids = alerts.collect{|alert| alert.id}.reverse.join("-")
    else
      @question = ErrorPopup.find( params[:popup_id])
      @alert_ids = params[:popup_id]
    end
  end

  def show
    send_file File.join(Rails.root,"public","/documents/#{params[:filename]}"),:type => 'text/html',:disposition => 'attachment'
  end

  # Method for displaying the values for Patient Pay tab - Nextgen format
  def patient_pay
    processor_report
    claim_id = cookies[:patpay_patient_id] unless cookies[:patpay_patient_id].blank?
    params[:tab_type] = "Patient Pay Nextgen Format"
    @job = @check_information.job
    @patpay_837_information = ClaimInformation.find(claim_id) if claim_id
    @total_amount = PatientPayEob.total_amount(@check_information.id)
    @balance =(@check_information.check_amount.to_f - @total_amount.to_f).to_f
    @processor_view = true
    @grid_type = 'nextgen'
    @page = params[:page] || 1
    if (@client_name == 'ORBOGRAPH' || @client_name == 'ORB TEST FACILITY')
      @date = @batch.date.strftime("%m/%d/%y") if @batch.date
    end
    @date ||= 'MM/DD/YY'
  end


  def orbo_correspondance_eob_save
    if (params[:option1] == 'SAVE EOB' || params[:option1] == 'Save Eob' || params[:submit_button][:flag] == 'true')
      orbo_correspondance_eob_insert
      update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
      if !@error_message.blank?
        flash[:notice] = @error_message
        redirect_when_invalid_data_exists
      else
        if(@current_user.has_role?(:processor))
          redirect_to :controller => 'insurance_payment_eobs',:action => 'show_orbograph_correspondance_grid',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber], :tab => 'correspondance'
        else
          render :inline=>"EOB Saved"
          return nil
        end
      end
    elsif(params[:option1] == 'COMPLETE')
      if !params[:complete_processor_comment].blank? && params[:complete_processor_comment] != '--'
        save_processor_comments_for_job(params[:complete_processor_comment], params[:complete_proc_comment_other])
      end     
      @job.rejected_comment = nil
      complete_job_and_update_user( JobStatus::COMPLETED)
      @batch.update_status
      JobAllocator::allocate_facility_wise([@current_user.id])
      #This for getting next job of this processor.We need next job after his current job is Completed.
      processor_next_job = Job.find(:first,
        :conditions => "processor_id = #{@current_user.id} and
         processor_status = '#{ProcessorStatus::ALLOCATED}' and is_excluded = 0",
        :select => "id id ,batch_id batchid,check_number checknumber")
      if !@current_user.has_role?(:qa)
        save_job_activity(@job.id, nil, @current_user.id, nil, "Job Completed", Time.now, nil, nil, true)
        if not processor_next_job.blank?
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => processor_next_job.batchid,:job_id => processor_next_job.id,:checknumber => processor_next_job.checknumber
        else
          redirect_to :controller => 'processor', :action => 'my_job', :location => 'grid'
        end
      else
        save_job_activity(@job.id, nil, nil, @current_user.id, "Job Completed", Time.now, nil, nil, true)
        render :inline=>"EOB Saved"
        return nil
      end
    end


  end

  def orbo_correspondance_eob_insert
    eob_exists = params[:orbo_correspondance][:eob_id]
    params[:insurancepaymenteob][:patient_first_name] = format_ui_param(params[:insurancepaymenteob][:patient_first_name])
    params[:insurancepaymenteob][:patient_last_name] = format_ui_param(params[:insurancepaymenteob][:patient_last_name])
    if(!eob_exists.blank?)
      orbo_correspondance_data = InsurancePaymentEob.find_by_id(params[:orbo_correspondance][:eob_id])
    else     
      orbo_correspondance_data = InsurancePaymentEob.new(params[:insurancepaymenteob])
    end
    orbo_correspondance_data.start_time = Time.zone.parse(params[:orbo_correspondance][:start_time])
    orbo_correspondance_data.end_time = Time.now
    unless params[:checkinformation].blank?
      unless params[:checkinformation][:payee_name].blank?
        @check_information.payee_name = params[:checkinformation][:payee_name]
        @check_information.save
      end
    end
    if @current_user.has_role?(:qa)
      orbo_correspondance_data.processor_id = @job.processor_id
      orbo_correspondance_data.qa_id = @current_user.id
    else
      if orbo_correspondance_data.processor_id.present? && @current_user.has_role?(:processor) &&
          @current_user.id != orbo_correspondance_data.processor_id          
        eob_rekeyed_by_another_processor = true
      end
      orbo_correspondance_data.processor_id = @current_user.id
    end 
    orbo_correspondance_data.sub_job_id = session[:job_id]
    orbo_correspondance_data.processing_completed = Time.now
    orbo_correspondance_data.check_information_id = @check_information.id
    orbo_correspondance_data.processor_input_fields = '11'
    details = params[:details]
    orbo_correspondance_data.details_will_change!  if !params[:details].blank? && @current_user.has_role?(:qa) && !eob_exists.blank?
    details.each do |key, value|
      value = Time.zone.parse(format_date(value).to_s) if(key == 'letter_date')
      orbo_correspondance_data.details[key] = value
      end
    reason = (params[:reason][:description] == "Other")?  params[:reason][:comment_area]: params[:reason][:description]
    orbo_correspondance_data.details['reason'] = reason
    orbo_correspondance_data.client_code = @facility.sitecode
    if(params[:view] == 'qa' || params[:view] == 'CompletedEOB' || params[:verify_grid] == '1')
      orbo_correspondance_data.update_attributes(params[:insurancepaymenteob])
    end
    orbo_correspondance_data.save
    job_activities = []
    if !@current_user.has_role?(:qa)      
      if eob_rekeyed_by_another_processor
        job_activities << save_job_activity(@job.id, orbo_correspondance_data.id, @job.processor_id, nil, "EOB Re-keyed", Time.now, nil, 1, false)
      end
      job_activities << save_job_activity(@job.id, orbo_correspondance_data.id, @current_user.id, nil, "EOB Saved by processor", Time.now, nil, 1, false)
      job_activities << save_job_activity(@job.id,orbo_correspondance_data.id,@job.processor_id,nil,"Processing Started",Time.zone.parse(params[:orbo_correspondance][:start_time]),orbo_correspondance_data.end_time, 1, false)
      job_activities << save_job_activity(@job.id,orbo_correspondance_data.id,@job.processor_id,nil,"Processing Completed",orbo_correspondance_data.end_time,nil, 1, false)
    elsif @current_user.has_role?(:qa)
      job_activities << save_job_activity(@job.id, orbo_correspondance_data.id, nil,  @current_user.id, "EOB Saved by QA", Time.now, nil, 1, false)
    end
    # Bulk saving of all JobActivityLogs table entries
    JobActivityLog.import job_activities unless job_activities.blank?
    job_count = @job.count
    @job.count = job_count + 1
    @job.save
  end


  #'Patient Pay eob save' function is used for saving the patient pay eob details from grid.
  #There are three buttons used for this.They are 'INCOMPLETE','COMPLETE' and 'SAVE'.
  #The button 'COMPLETE' is used for marking the job status as complete.
  #The button 'INCOMPLETE' is used for marking the job status as incomplete.
  #The button 'SAVE' is used for saving the eob in 'patient_payment_eobs' table.
  #The check information corresponding to that job is also saved in the check_informations table.
  def patient_pay_eob_save()
    job = @job
    @batch = job.batch
    if (params[:option1] == 'SAVE')
      to_save,statement_to_alert = validate_insurance_eob_saved_already(@check_information)
      if not to_save
        flash[:notice] = statement_to_alert
        redirect_when_invalid_data_exists
      else
        patient_pay_eob_insert()
        if !@error_message.blank?
          flash[:notice] = @error_message
          redirect_when_invalid_data_exists
        else
          update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
          if !@current_user.has_role?(:qa)
            redirect_to :action => 'patient_pay',:batch_id => @batch.id,:job_id => job.id,:checknumber => params[:checknumber]
          else
            render :inline=>"EOB Saved"
            return nil
          end
        end
      end
    elsif(params[:option1] == 'COMPLETE')
      EobReasonCode.destroy_all(:insurance_payment_eob_id => nil, :job_id => @job.id)
      if !params[:complete_processor_comment].blank? && params[:complete_processor_comment] != '--'
        save_processor_comments_for_job(params[:complete_processor_comment], params[:complete_proc_comment_other])
      end
      @job.rejected_comment = nil
      complete_job_and_update_user(job, JobStatus::COMPLETED)
      save_job_activity(@job.id, nil, @current_user.id, nil, "Job Completed", Time.now, nil, nil, true)
      @batch.update_status
      JobAllocator::allocate_facility_wise([@current_user.id])
      #This for getting next job of this processor.We need next job after his current job is Completed.
      processor_next_job = Job.find(:first,
        :conditions => "processor_id = #{@current_user.id} and processor_status = '#{ProcessorStatus::ALLOCATED}' and is_excluded = 0",
        :select => "id id ,batch_id batchid,check_number checknumber")
      if !@current_user.has_role?(:qa)
        if not processor_next_job.blank?
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => processor_next_job.batchid,:job_id => processor_next_job.id,:checknumber => processor_next_job.checknumber
        else
          redirect_to :controller => 'processor', :action => 'my_job', :location => 'grid'
        end
      else
        save_job_activity(@job.id, nil, nil, @current_user.id, "Job Completed", Time.now, nil, nil, true)
        render :inline=>"EOB Saved"
        return nil
      end
    elsif(params[:option1] == 'INCOMPLETE')
      unless params[:incomplete_processor_comment].blank?
        save_processor_comments_for_job(params[:incomplete_processor_comment], params[:incomplete_proc_comment_other])
        @job.rejected_comment = get_qa_comments(params[:incomplete_processor_comment], params[:incomplete_proc_comment_other])

      end
      complete_job_and_update_user(job, JobStatus::INCOMPLETED)
      patient_pay_eob_insert()
      if !@error_message.blank?
        flash[:notice] = @error_message
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => @batch.id,:job_id => params[:job_id],:checknumber => params[:checknumber]
      else
        @batch.update_status
        JobAllocator::allocate_facility_wise([@current_user.id])
        processor_next_job = Job.find(:first,
          :conditions => "processor_id = #{@current_user.id} and processor_status = '#{ProcessorStatus::ALLOCATED}' and is_excluded = 0",
          :select => "id id ,batch_id batchid,check_number checknumber")
        job.processor_status = ProcessorStatus::INCOMPLETED
        if !@current_user.has_role?(:qa)
          save_job_activity(@job.id, nil, @current_user.id, nil, "Job Incompleted", Time.now, nil, nil, true)
          if not processor_next_job.blank?
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => processor_next_job.batchid,:job_id => processor_next_job.id,:checknumber => processor_next_job.checknumber
          else
            redirect_to :controller => 'processor', :action => 'my_job', :location => 'grid'
          end
        else
          save_job_activity(@job.id, nil, nil, @current_user.id, "Job Incompleted", Time.now, nil, nil, true)
          render :inline=>"EOB Saved"
          return nil
        end
      end
    end
  end

  #This method is used as a sub-routine to save the 'patient_pay_eob' details from the pat pay grid
  #The 'PatientPayEob' Model is instantiated in this method.
  #The check information is also created in this if check information object is null.
  #if current_user's role is qa,a method named 'save_job_activity' is called.

  def patient_pay_eob_insert()
    check_information = @check_information
    if check_information.blank?
      check_information = CheckInformation.new(params[:checkinforamation])
      check_information.job_id = params[:job_id]
      check_information.save
    else
      check_information.update_attributes(params[:checkinforamation])
    end
    patient_data = PatientPayEob.new(params[:patientpayeob])
    transaction_date = ""
    if !params[:patient_pay_eob].blank? && !params[:patient_pay_eob][:transaction_date].blank?
      transaction_date = Date.rr_parse(params[:patient_pay_eob][:transaction_date], true)
    end
    patient_data.transaction_date = transaction_date
    patient_data.check_information_id = check_information.id
    patient_data.start_time = Time.zone.parse(params[:patientpayeob][:start_time])
    patient_data.end_time = Time.now
    if patient_data.processor_id.present? && @current_user.id != patient_data.processor_id &&
        @current_user.has_role?(:processor)
      eob_rekeyed_by_another_processor = true
    end
    patient_data.client_code = @facility.sitecode
    patient_data.processor_id = @current_user.id
    patient_data.job_id = params[:job_id]
    patient_data.processing_completed = Time.now
    job = @job
    account_number_length =  patient_data.account_number.length
    is_client_orbograph = Client.is_client_orbograph?(@client_name)
    if !is_client_orbograph && (account_number_length == 0 || account_number_length > 12)
      @error_message = "Account Number digit length should be != 0 and less than or equal to 12 digits."
      return @error_message
    end
    if !is_client_orbograph
      patient_data.account_number = patient_data.normalize_account_number(@facility.details[:practice_id])
    end
    account_number_length =  patient_data.account_number.length
    patient_data.save
    # Gets the total field count for the nextgen patpay grid
    get_total_nextgen_field_count(check_information, patient_data)
    job_activities = []
    if !@current_user.has_role?(:qa)      
      if eob_rekeyed_by_another_processor
        job_activities << save_job_activity(job.id, patient_data.id, job.processor_id, nil, "EOB Re-keyed", Time.now, nil, 2, false)
      end
      job_activities << save_job_activity(job.id, patient_data.id, @current_user.id, nil, "EOB Saved by processor", Time.now, nil, 2, false)
      job_activities << save_job_activity(job.id,patient_data.id,job.processor_id,nil,"Processing Started",Time.zone.parse(params[:patientpayeob][:start_time]),patient_data.end_time, 2, false)
      patpay_mpi_search_conditions = []
      patpay_mpi_search_conditions_list = []
      if !params[:mpi_search][:patpay_mpi_start_time].blank?
        job_activities << save_job_activity(job.id,patient_data.id,job.processor_id,nil,"MPI Search Started",Time.zone.parse(params[:mpi_search][:patpay_mpi_start_time]),nil, 2, false)
      end
      if !params[:mpi_search][:patpay_mpi_found_time].blank?
        job_activities << save_job_activity(job.id,patient_data.id,job.processor_id,nil,"MPI Match Found",Time.zone.parse(params[:mpi_search][:patpay_mpi_found_time]),nil, 2, false)
      end
      if !params[:mpi_search][:patpay_mpi_used_time].blank?
        job_activities << save_job_activity(job.id,patient_data.id,job.processor_id,nil,"MPI Match Used",Time.zone.parse(params[:mpi_search][:patpay_mpi_used_time]),nil, 2, false)
        # Saving all milestone events occured during MPI Search in mpi_statistics_reports table
        patpay_mpi_search_conditions << "PACNO" unless params[:mpi_search][:patpay_account_number].blank?
        patpay_mpi_search_conditions_list = patpay_mpi_search_conditions.join(",")
        save_mpi_statistics(params[:batch_id],@current_user.id,patient_data,"Success",patpay_mpi_search_conditions_list,params[:mpi_search][:patpay_mpi_used_time])
      else
        if (cookies[:patpay_mpi_start_time].blank? and cookies[:patpay_account_number].blank?)
          save_mpi_statistics(params[:batch_id],@current_user.id,patient_data,"MPI Not Used",nil,nil)
          job_activities << save_job_activity(job.id, patient_data.id, job.processor_id, nil, "MPI Not Used", Time.now, nil, 2, false)
        else
          patpay_mpi_search_conditions << "PACNO" unless cookies[:patpay_account_number].blank?
          patpay_mpi_search_conditions_list = patpay_mpi_search_conditions.join(",")
          save_mpi_statistics(params[:batch_id],@current_user.id,patient_data,"Failure",patpay_mpi_search_conditions_list,cookies[:patpay_mpi_start_time])
          job_activities << save_job_activity(job.id, patient_data.id, @current_user.id, nil, "MPI Failed", Time.now, nil, 2, false)
        end
      end
      job_activities << save_job_activity(job.id,patient_data.id,job.processor_id,nil,"Processing Completed",patient_data.end_time,nil, 2, false)
    else
      job_activities << save_job_activity(job.id, patient_data.id, nil,  @current_user.id, "EOB Saved by QA", Time.now, nil, 2, false)
    end
    # Bulk saving of all JobActivityLogs table entries
    JobActivityLog.import job_activities unless job_activities.blank?
    job_count = job.count
    job.count = job_count + 1
    job.save
  end

  #  calculation of total nextgen fields
  def get_total_nextgen_field_count(check_information, patpay_eob)
    total_nextgen_fields = 0
    eob_type = 'nextgen'
    #    Calculating processor_input_field_count for nextgen eob
    #    using the model level method processor_input_field_count()
    total_nextgen_fields += check_information.processor_input_field_count(@facility, eob_type) +
      patpay_eob.processor_input_field_count
    #    Storing the processor input field count in processor_input_fields column of patient_pay_eobs table
    patpay_eob.processor_input_fields = total_nextgen_fields
    patpay_eob.save
  end

  # Returns if the current EOB under processing is type Insurance EOB
  # based on the payer for the check
  def insurance_eob?
    @eob_type = !@check_information.does_check_have_patient_payer?(@facility, @payer)
  end

  def create_interest_eob(insurance_eobs)
    if (!(@multiple_eob.nil?) && @multiple_eob == "true")
      # For mutliple EOB
      interest  = @check_information.get_total_claim_interest
      doc_classification = nil
      check = @check_information
      doc_classification = insurance_eobs.first.document_classification unless insurance_eobs.first.document_classification.nil?
      svc_line_array = ServicePaymentEob.find_by_sql("SELECT MIN(date_of_service_from) as min_date,\
  MAX(date_of_service_to)  as max_date \
  FROM service_payment_eobs \
  INNER JOIN insurance_payment_eobs ON insurance_payment_eobs.id = service_payment_eobs.insurance_payment_eob_id \
  INNER JOIN check_informations ON  check_informations.id = insurance_payment_eobs.check_information_id
  WHERE insurance_payment_eobs.check_information_id = #{check.id}")
      if !svc_line_array.blank?
        svc = svc_line_array[0]
        least_date = svc.min_date
        highest_date = svc.max_date
      end
      eob_attributes = {
        :check_information_id => check.id,
        :patient_account_number => '000000000',
        :patient_first_name =>'INTEREST',
        :patient_last_name => 'PAYMENT',
        :subscriber_first_name => 'INTEREST',
        :subscriber_last_name => 'PAYMENT',
        :sub_job_id => params[:job_id],
        :balance_record_type => 'INTEREST ONLY',
        :total_amount_paid_for_claim => interest,
        :total_submitted_charge_for_claim => interest,
        :total_allowable => '0.00',
        :document_classification => doc_classification,
        :image_page_no => @last_eob_page_number,
        :image_page_to_number => @last_eob_page_number,
        :alternate_payer_name => @alternate_payer_name,
        :claim_type => 'Primary',
        :total_service_balance => 0.00,
        :client_code => @facility.sitecode
      }
      if @current_user.has_role?(:processor)
        eob_attributes[:processor_id] = @current_user.id
      elsif @current_user.has_role?(:qa)
        eob_attributes[:qa_id] = @current_user.id
      end
      interest_eob = InsurancePaymentEob.where(:check_information_id => check.id, :balance_record_type => 'INTEREST ONLY').first
      #interest_eob = interest_eobs.first unless interest_eobs.blank?
      if !interest_eob.blank?
        interest_eob.total_amount_paid_for_claim = interest
        interest_eob.total_submitted_charge_for_claim = interest
        svc_line = interest_eob.service_payment_eobs.first
        #svc_line = svc_lines.first
      else
        interest_eob = InsurancePaymentEob.new
        interest_eob.assign_attributes(eob_attributes, :without_protection => true)
      end
      if !interest_eob.blank?
        if interest_eob.valid?
          interest_eob.save
          interest_eob.reload
          params[:insurancepaymenteob] = {
            :image_page_no => @last_eob_page_number,
            :image_type => 'EOB'
          }
          save_image_type(interest_eob)
        else
          flash[:notice] = "#{interest_eob.errors.messages[:base]}"
        end
        if svc_line.blank?
          svc_line = ServicePaymentEob.new
          svc_line.insurance_payment_eob_id = interest_eob.id
          svc_line.service_procedure_code = '99999'
          svc_line.service_allowable = 0.00
          svc_line.date_of_service_from = least_date
          svc_line.date_of_service_to = highest_date
        end
        if !svc_line.blank?
          svc_line.service_procedure_charge_amount = interest
          svc_line.service_paid_amount = interest
        end
        if !svc_line.blank? && svc_line.valid?
          svc_line.save
        else
          flash[:notice] = "#{interest_eob.errors.messages[:base]}"
        end
      end
    end
    interest_eob
  end

  def update_interest_eob_with_interest_amount
    interest_eob = InsurancePaymentEob.where(:check_information_id => @check_information.id, :balance_record_type => 'INTEREST ONLY').first
    #interest_eob = interest_eobs.first unless interest_eobs.blank?
    if !interest_eob.blank?
      insurance_payment_eobs = InsurancePaymentEob.select("count(*) as eob_count,
        sum(claim_interest) as total_claim_interest").where("check_information_id = ? ", @check_information.id).first
      count_of_eobs = insurance_payment_eobs.eob_count
      if count_of_eobs > 1
        total_interest_amount = insurance_payment_eobs.total_claim_interest
      elsif count_of_eobs == 1
        total_interest_amount = @check_information.check_amount
      end
      if !((interest_eob.total_amount_paid_for_claim.to_f).eql?(total_interest_amount.to_f))
        interest_amount = total_interest_amount
      end
      if !interest_amount.blank?
        interest_eob.total_amount_paid_for_claim = interest_amount
        interest_eob.total_submitted_charge_for_claim = interest_amount
        svc_line = interest_eob.service_payment_eobs.first
        #svc_line = svc_lines.first
        if !svc_line.blank?
          svc_line.service_procedure_charge_amount = interest_amount
          svc_line.service_paid_amount = interest_amount
          svc_line.save
        end
      end
      if count_of_eobs == 1
        interest_eob.claim_interest = nil
      end
      interest_eob.save
    end
  end

  def create_interest_only_eob
    amount =  params[:insurancepaymenteob][:claim_interest]
    default_service_date = params[:lineinformation][:dateofservice_from]

    if (default_service_date.blank?) || (default_service_date == 'mm/dd/yy')
      default_service_date = ServicePaymentEob.default_service_date(@facility.default_service_date, @batch.date, @check_information.check_date)
      if default_service_date.blank?
        default_service_date = @batch.date
      end
    end

    if !default_service_date.blank? && !default_service_date.is_a?(String)
      default_service_date = default_service_date.strftime("%m/%d/%y")
    end
    params[:insurancepaymenteob][:patient_account_number] = '000000000'
    params[:insurancepaymenteob][:patient_first_name] = 'INTEREST'
    params[:insurancepaymenteob][:patient_last_name] = 'PAYMENT'
    params[:insurancepaymenteob][:sub_job_id] = params[:job_id]
    params[:insurancepaymenteob][:subscriber_first_name] = 'INTEREST'
    params[:insurancepaymenteob][:subscriber_last_name] = 'PAYMENT'
    params[:insurancepaymenteob][:balance_record_type] = 'INTEREST ONLY'
    params[:insurancepaymenteob][:total_amount_paid_for_claim] = amount
    params[:insurancepaymenteob][:total_submitted_charge_for_claim] = amount
    params[:insurancepaymenteob][:total_allowable] = '0.00'
    params[:insurancepaymenteob][:image_page_no] = '1'
    params[:insurancepaymenteob][:image_page_to_number] = '1'
    params[:insurancepaymenteob][:claim_interest] = nil
    params[:insurancepaymenteob][:claim_type] = 'Primary'

    params[:service_line] = {
      :serial_numbers => '1'
    }
    params[:lineinformation] = {} if params[:lineinformation].blank?
    params[:lineinformation]["procedure_code1"] = '99999'
    params[:lineinformation]["dateofservice_from1"] = default_service_date
    params[:lineinformation]["dateofservice_to1"] = default_service_date
    params[:lineinformation]["charges1"] = amount
    params[:lineinformation]["payment1"] = amount
    params[:lineinformation]["allowable1"] = '0.00'
  end

  def create_offset_eob
    total_amount =  InsurancePaymentEob.amount_so_far(@check_information, @facility)
    total_amount = total_amount.abs
    check = @check_information
    eob_attributes = {
      :check_information_id => check.id,
      :patient_account_number => '999999999',
      :patient_first_name =>'NEGATIVE',
      :patient_last_name => 'OFFSET',
      :subscriber_first_name => 'NEGATIVE',
      :subscriber_last_name => 'OFFSET',
      :sub_job_id => params[:job_id],
      :total_amount_paid_for_claim => total_amount,
      :total_submitted_charge_for_claim => total_amount,
      :total_allowable => 0.00,
      :image_page_no => @last_eob_page_number,
      :image_page_to_number => @last_eob_page_number,
      :alternate_payer_name => @alternate_payer_name,
      :claim_type => 'Primary',
      :total_service_balance => 0.00,
      :processor_input_fields => 0,
      :client_code => @facility.sitecode
    }
    if @current_user.has_role?(:processor)
      eob_attributes[:processor_id] = @current_user.id
    elsif @current_user.has_role?(:qa)
      eob_attributes[:qa_id] = @current_user.id
    end
    offset_eob = InsurancePaymentEob.new
    offset_eob.assign_attributes(eob_attributes, :without_protection => true)
    if !offset_eob.blank?
      if offset_eob.valid?
        offset_eob.save
        offset_eob.reload
        params[:insurancepaymenteob] = {
          :image_page_no => @last_eob_page_number,
          :image_type => 'EOB'
        }
        save_image_type(offset_eob)
      else
        flash[:notice] = "#{offset_eob.errors.messages[:base]}"
      end

      svc_line = ServicePaymentEob.new
      svc_line.insurance_payment_eob_id = offset_eob.id
      svc_line.service_procedure_code = '99999'
      svc_line.service_allowable = 0.00
      svc_line.date_of_service_from = @batch.date
      svc_line.date_of_service_to = @batch.date

      if !svc_line.blank?
        svc_line.service_procedure_charge_amount = total_amount
        svc_line.service_paid_amount = total_amount
      end
      if !svc_line.blank? && svc_line.valid?
        svc_line.save
      else
        flash[:notice] = "#{offset_eob.errors.messages[:base]}"
      end
    end
    offset_eob
  end
  #'Insurance eob save' is using save insurance eob from processor side.There are three buttons for this.
  # If button  'INCOMPLETE' clicked, marked that job as incomplete.
  # processor comment and processor id saved in bot insurance and job table,ie save processor status and job status  as INCOMPLETED
  # If button 'COMPLETE' clicked, save that job as complete,ie change processor and job status as complete.
  # processor comment and processor id saved in bot insurance and job table,ie save processor status and job satatus  as COMPLETED .
  #After job complete ,next job will automatically comes in the processor view.
  # If button 'SAVE EOB' clicked save that eob in the  'insurance_payment_eobs' table.
  # processor comment and processor id saved in  insurance payment eob  table.
  # It also saves check level information,i.e. if provider adjustment amout present, that  will be saved

  def insurance_eob_save()
    @parent_job_id = @parent_job_id_or_id
    is_parent_job_id_present = !@job.parent_job_id.blank?
    params[:mode] = nil
    @payer = @check_information.payer
    if (params[:option1] == 'SAVE EOB')
      if !(params[:insurancepaymenteob]).blank?
        invoice_by = params[:insurancepaymenteob][:statement_receiver]  unless (params[:insurancepaymenteob][:statement_receiver]).blank?
      end
      if !params[:payer].blank?
        payer_address_fields = {
          :address_one => params[:payer][:pay_address_one].to_s,
          :city => params[:payer][:payer_city].to_s,
          :state => params[:payer][:payer_state].to_s,
          :zip_code => params[:payer][:payer_zip].to_s
        }
      end
      to_save,eob_releated_to_check_alert = validate_netgen_eob_saved_already(@check_information)
      to_proceed, statement_to_alert = validate_payer_address(payer_address_fields)
      validate_patient_address_flag, patient_address_alert = validate_patient_address(params[:patient], @facility_name)
      validate_check_date_flag , validate_check_date_alert = validate_check_date
      if not to_save
        flash[:notice] = eob_releated_to_check_alert
        redirect_to :action => 'patient_pay',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
      elsif not validate_check_date_flag
        flash[:notice] = validate_check_date_alert
        redirect_when_invalid_data_exists
      elsif not to_proceed
        flash[:notice] = statement_to_alert
        redirect_when_invalid_data_exists
      elsif not validate_patient_address_flag
        flash[:notice] = patient_address_alert
        redirect_when_invalid_data_exists
      else
        invalid_reason_codes = validate_adjustment_codes
        if !invalid_reason_codes.blank?
          flash[:notice] = "The following unique codes are not associated with this job : #{invalid_reason_codes.join('; ')}"
          redirect_when_invalid_data_exists
        else
          to_proceed, statement_to_alert = validate_payment_method
          if not to_proceed
            flash[:notice] = statement_to_alert
            redirect_when_invalid_data_exists
          else
            insertdata(0)     
            
            if !@error_message.blank?
              flash[:notice] = @error_message
              redirect_when_invalid_data_exists
            else              
              params[:view] = ""
              @job.apply_to_all_claims = params[:apply_to_all_claims_hidden_field]
              job_count = @job.count
              @job.count = job_count + 1
              @job.save
              Batch.where(:id => @batch.id).update_all(:associated_entity_updated_at => Time.now)
              if !@current_user.has_role?(:qa)
                # Redirect to Patient Pay tab if save eob button is clicked on Patient Pay tab
                if not insurance_eob?
                  redirect_to :controller => 'insurance_payment_eobs',:action => 'show_eob_grid', :tab => 'patient_pay', :batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
                else
                  redirect_to :controller => 'insurance_payment_eobs',:action => 'show_eob_grid', :tab => 'insurance_pay', :batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber],:mode => params[:mode]
                end
                
              else
                render :inline=>"EOB Saved"
                return nil
              end
            end
          end
        end
      end
    elsif(params[:option1] == 'INCOMPLETE')
      insurance_eobs = @check_information.insurance_payment_eobs unless @check_information.blank?
      @job.set_total_edited_fields(insurance_eobs)
      @job.rejected_comment = get_qa_comments(params[:incomplete_processor_comment], params[:incomplete_proc_comment_other])
      unless insurance_eobs.blank?
        last_eob = insurance_eobs.last
        @first_eob = insurance_eobs.first
        save_eob_id_in_provider_adjustment
      end
      save_user_id_for_eobs

      unless params[:incomplete_processor_comment].blank?
        save_processor_comments_for_job(params[:incomplete_processor_comment], params[:incomplete_proc_comment_other])

        unless last_eob.blank?
          unless (last_eob.processor_input_fields.blank?)
            last_eob.processor_input_fields += 1
            last_eob.save
          else
            last_eob.processor_input_fields = 1
            last_eob.save
          end
        end
      end
      complete_job_and_update_user(JobStatus::INCOMPLETED)

      @batch.update_status
      JobAllocator::allocate_facility_wise([@current_user.id])
      processor_next_job = Job.find(:first, :conditions => "processor_id = #{@current_user.id} and processor_status = '#{ProcessorStatus::ALLOCATED}' and is_excluded = 0",
        :select => "id id ,batch_id batchid,check_number checknumber")

      unless is_parent_job_id_present
        @check_information.auto_generate_check_number(@batch) if (@client_name == "ASCEND CLINICAL LLC")
      end

      if !@current_user.has_role?(:qa)
        save_job_activity(@job.id, nil, @current_user.id, nil, "Job Incompleted", Time.now, nil, nil, true)
        if not processor_next_job.blank?
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => processor_next_job.batchid,:job_id => processor_next_job.id,:checknumber => processor_next_job.checknumber
        else
          redirect_to :controller => 'processor', :action => 'my_job', :location => 'grid'
        end
      else
        save_job_activity(@job.id, nil, nil, @current_user.id, "Job Incompleted", Time.now, nil, nil, true)
        render :inline=>"EOB Saved "
        return nil
      end

    elsif(params[:option1] == 'COMPLETE')
      @offset_eob_flag = params[:flag_for_offset_eob]
      @interest_eob = params[:interest_eob]
      @multiple_eob = params[:complete_button_flag]
      validate_image_type_for_pages_flag = true
      validate_doc_classification_flag = true
      insurance_eobs = @check_information.insurance_payment_eobs unless @check_information.blank?
      @job.rejected_comment = nil
      validate_upmc_payeename_and_tin_message = validate_payee_name_and_tin_upmc(params[:checkinforamation])
      if validate_upmc_payeename_and_tin_message == ''
        if @facility.details[:interest_only_835] &&
            !params[:checkinforamation][:interest_only_check].blank? &&
            params[:checkinforamation][:interest_only_check] == "true"
          save_interest_only_check_details
        end
      
        @job.set_total_edited_fields(insurance_eobs)
        unless insurance_eobs.blank?
          last_eob = insurance_eobs.last
          @first_eob = insurance_eobs.first
          save_eob_id_in_provider_adjustment
        end
        @last_eob_page_number = last_eob.image_page_no unless last_eob.blank?
        # Bypassing image type validations for non bank and for NextGen checks.
        if @is_partner_bac && !@check_information.nextgen_check?
          validate_image_type_for_pages_flag = validate_image_type_for_pages
          validate_image_type_for_pages_flag &&= validate_eob_image_types(insurance_eobs.count)
        end
        if insurance_eobs.blank?
          patient_pay_eob = @check_information.patient_pay_eobs unless @check_information.blank?
        end
        if @facility.details[:document_classification] &&
            @facility.details[:same_document_classification_within_a_job]
          if !insurance_eobs.blank?
            validate_doc_classification_flag = validate_doc_classification(insurance_eobs)
          else
            if !patient_pay_eob.blank?
              validate_doc_classification_flag = validate_doc_classification(patient_pay_eob)
            end
          end
        end
        #Dummy EOB creation
        unless is_parent_job_id_present
          interest_only_eob = create_interest_eob(insurance_eobs) unless insurance_eobs.blank?
          insurance_eobs << interest_only_eob if !interest_only_eob.blank?
        end
        if(@offset_eob_flag == 'true' && is_parent_job_id_present == false )
          offset_eob = create_offset_eob
          insurance_eobs << offset_eob unless offset_eob.blank?
        end

        if @check_information.is_transaction_type_missing_check_or_check_only? || @check_information.is_check_balanced?(@job, @facility)

          if validate_image_type_for_pages_flag && validate_doc_classification_flag
            save_user_id_for_eobs
            if insurance_eobs.blank? && patient_pay_eob.blank? # this is true for all normal jobs. Only a real parent job may not have eobs associated
              jobcount = Job.count(:all,:conditions=>"parent_job_id=#{@job.id}")
            end
          
            #Deleting EOBs which populate in VERIFICATION mode(OCR mode) that do not have Pt Acc No
            eobs_deleted = InsurancePaymentEob.where(:patient_account_number => nil, :check_information_id => @check_information.id).destroy_all
          
            if eobs_deleted.present?
              deleted_entity_records = []
              job_activity_records = []
              eobs_deleted.each do |eob|
                job_activity_records << JobActivityLog.create_activity({:job_id => @job.id, :processor_id => @current_user.id,
                    :activity => 'EOB Deleted', :start_time => Time.now, :eob_type_id => 1,
                    :object_name => 'insurance_payment_eobs', :field_name => 'patient_account_number',
                    :old_value => eob.patient_account_number }, false)
                parameters = { :entity => 'insurance_payment_eobs', :entity_id => eob.id,
                  :client_id => @client.id, :facility_id => @facility.id }
                deleted_entity_records << DeletedEntity.create_records(parameters)
              end
            end
          
            DeletedEntity.import(deleted_entity_records) if deleted_entity_records.present?
            JobActivityLog.import(job_activity_records) if job_activity_records.present?
          
            if ((!insurance_eobs.blank? || !patient_pay_eob.blank?) ||
                  (insurance_eobs.blank? && patient_pay_eob.blank? && jobcount > 0) ||
                  (insurance_eobs.blank? && patient_pay_eob.blank? && @facility.details[:interest_only_835] && @check_information.interest_only_check))
              if !params[:complete_processor_comment].blank? && params[:complete_processor_comment] != '--'
                save_processor_comments_for_job(params[:complete_processor_comment], params[:complete_proc_comment_other])
              end
              complete_job_and_update_user(JobStatus::COMPLETED)
            
              if(@parent_job_id && insurance_eobs.blank? && patient_pay_eob.blank? && jobcount > 0)
                @job.update_parent_job_status(@parent_job_id)
              end

              @batch.update_status

              JobAllocator::allocate_facility_wise([@current_user.id])
              processor_next_job = Job.find(:first, :conditions => "processor_id = #{@current_user.id} and processor_status = '#{ProcessorStatus::ALLOCATED}' and is_excluded = 0",
                :select => "id id ,batch_id batchid,check_number checknumber")
              #This is to delete reason_code_jobs records which are not associated
              # to any of the eobs.
              unless is_parent_job_id_present
                delete_reason_code_jobs_records(insurance_eobs, @parent_job_id)
                #This is to delete unused reason_code_setname_records
                dummy_reason_code_set_name = ReasonCodeSetName.find_by_name("JOB_#{@parent_job_id}_SET")
                delete_reason_code_set_name(@parent_job_id, dummy_reason_code_set_name.id) unless dummy_reason_code_set_name.blank?
                if (@client_name == "QUADAX")
                  is_system_generated_check_number = @check_information.is_check_number_in_auto_generated_format?(@check_information.check_number, @batch, false, true, false)
                  @check_information.auto_generate_check_number(@batch) if (!is_system_generated_check_number)
                elsif (@client_name == "BARNABAS" || @client_name == "ASCEND CLINICAL LLC" || @client_name == "PACIFIC DENTAL SERVICES")
                  @check_information.auto_generate_check_number(@batch)
                end
                recalculate_transaction_type("complete_job") if @facility.details[:transaction_type] == true
              end
              unless @current_user.has_role?(:qa)
                save_job_activity(@job.id, nil, @current_user.id, nil, "Job Completed", Time.now, nil, nil, true)
                unless processor_next_job.blank?
                  redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => processor_next_job.batchid,:job_id => processor_next_job.id,:checknumber => processor_next_job.checknumber
                else
                  redirect_to :controller => 'processor', :action => 'my_job', :location => 'grid'
                end
              else
                save_job_activity(@job.id, nil, nil, @current_user.id, "Job Completed", Time.now, nil, nil, true)
                render :inline=>"EOB Saved "
                return nil
              end
            else
              unless @current_user.has_role?(:qa)
                flash[:notice] = "Please Save Atleast one EOB"
                redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
              else
                render :inline=>"EOB Saved "
                return nil
              end
            end
          else
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
          end
        else
          flash[:notice] = "Check is not balanced."
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
        end
      else
        flash[:notice] = validate_upmc_payeename_and_tin_message
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',
          :batch_id => params[:batch_id], :job_id => params[:job_id],
          :checknumber => params[:checknumber]
      end
    elsif(params[:option1] == 'Additional Job Request')
      if params[:additional_job_request] && params[:additional_job_request][:comment]
        @job.job_status = JobStatus::ADDITIONAL_JOB_REQUESTED
        @job.processor_status = ProcessorStatus::ADDITIONAL_JOB_REQUESTED
        @job.processor_comments = params[:additional_job_request][:comment]
        @job.save
        @batch.update_status
        job_count = Job.where("processor_status = '#{ProcessorStatus::ALLOCATED}' AND processor_id = #{@job.processor_id}").count
        if job_count.zero?
          User.where(:id => @job.processor_id).update_all(:allocation_status => 0, :updated_at => Time.now)
        end
        save_job_activity(@job.id, nil, @current_user.id, nil, "Additional Job Creation Requested", Time.now, nil, nil, true)
        JobAllocator::allocate_facility_wise([@current_user.id])
        processor_next_job = Job.find(:first, :conditions => "processor_id = #{@current_user.id} and processor_status = '#{ProcessorStatus::ALLOCATED}' and is_excluded = 0",
          :select => "id id ,batch_id batchid,check_number checknumber")
        unless processor_next_job.blank?
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => processor_next_job.batchid,:job_id => processor_next_job.id,:checknumber => processor_next_job.checknumber
        else
          redirect_to :controller => 'processor', :action => 'my_job', :location => 'grid'
        end
      else
        flash[:notice] = "Please enter comment for requesting additional jobs"
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',
          :batch_id => params[:batch_id], :job_id => params[:job_id],
          :checknumber => params[:checknumber]
      end
    elsif (params[:option1] == 'Delete EOB' || params[:option1] == 'DELETE EOB')
      if (params[:option1] == 'Delete EOB')
        eobs = InsurancePaymentEob.select("id, patient_account_number").where(:id => params[:insurance_id])
        eob = eobs.first
        if !eob.blank?
          JobActivityLog.delete_all(:eob_id => eob.id, :eob_type_id => '1')
          JobActivityLog.create_activity({:job_id => @job.id, :processor_id => @current_user.id,
              :activity => 'EOB Deleted', :start_time => Time.now, :eob_type_id => 1,
              :object_name => 'insurance_payment_eobs', :field_name => 'patient_account_number',
              :old_value => eob.patient_account_number })
          parameters = { :entity => 'insurance_payment_eobs', :entity_id => eob.id,
            :client_id => @client.id, :facility_id => @facility.id }
          DeletedEntity.create_records(parameters, true)
          eob.destroy
          update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
        end
        @check_information.populate_report_check_informations(insurance_eob?)
        recalculate_transaction_type("delete_eob") if @facility.details[:transaction_type] == true && @client_name == "MEDISTREAMS"
      elsif (params[:option1] == 'DELETE EOB')
        eobs = PatientPayEob.select("id, account_number").where(:id => params[:patient_pay_eob][:eob_id])
        eob = eobs.first
        if !eob.blank?
          JobActivityLog.delete_all(:eob_id => eob.id, :eob_type_id => '1')
          JobActivityLog.create_activity({:job_id => @job.id, :processor_id => @current_user.id,
              :activity => 'EOB Deleted', :start_time => Time.now, :eob_type_id => 2,
              :object_name => 'patient_pay_eobs', :field_name => 'patient_account_number',
              :old_value => eob.account_number })
          parameters = { :entity => 'patient_pay_eobs', :entity_id => eob.id,
            :client_id => @client.id, :facility_id => @facility.id }
          DeletedEntity.create_records(parameters, true)
          eob.destroy
          update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
        end

      end
      if @check_information.any_eob_processed? == false
        @check_information.payment_method = nil
        @check_information.save!
      end
      job_count = @job.count
      job_co = job_count - 1
      if(job_co == 0)
        @job.apply_to_all_claims = "0"
      end
      @job.count = job_count - 1
      @job.save
      if @current_user.has_role?(:qa)  #This occurs when QA adds an EOB in 'AddEOB view'
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id]
      else    # This occurs when Processor deletes a record in 'Processor view' or 'CompletedEOB view'
        if(@current_user.has_role?(:processor) &&  view !="qa" &&  view !="CompletedEOB")   # This occurs when Processor deletes a record in 'Processor view'
          page = Integer(params[:page])
          page = page+1
          redirect_to :controller => 'insurance_payment_eobs',:action => 'show_eob_grid',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber], :page => page
          # for qa s and processors in CompletedEOB view, redirect to claimqa page
        else  # This occurs when Processor deletes a record in 'CompletedEOB view'
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :view => view
        end
      end
    end    
  end

  def save_processor_comments_for_job(processor_comment, processor_comment_other)
    if processor_comment == "Other"
      @job.processor_comments = processor_comment_other
    else
      @job.processor_comments = processor_comment
    end
  end

  def get_qa_comments(qa_comment, qa_comment_other)
    if qa_comment == "Other"
      qa_comm = qa_comment_other
    else
      qa_comm = qa_comment
    end
    return qa_comm
  end

  # image type validations starts here
  def validate_image_type_for_pages
    page_from = 1
    page_count = @job.get_total_image_page_count
    image_page_array = []
    image_type_obj_array = @job.get_all_image_type_obj_for_job
    partial_eob_image_type_obj_array = @job.get_all_partial_eob_image_type_obj_for_job
    image_page_numbers_for_job = @job.get_all_image_page_numbers_for_job(image_type_obj_array)
    image_types_for_job = @job.get_all_image_types_for_job(image_type_obj_array)
    page_from.upto(page_count) { |i|
      if image_page_numbers_for_job.index(i) == nil
        image_page_array << i
      end
    }
    image_page_array = image_page_array.join(",")
    unless image_page_array.blank?
      flash[:notice] = "All pages must have at least one image type record. Please classify pages : #{image_page_array}"
      return false
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
    else
      validate_classified_image_type(image_types_for_job, page_count, partial_eob_image_type_obj_array)
    end
  end

  def validate_classified_image_type(image_types_for_job, page_count, partial_eob_image_type_obj_array)
    is_correspondence_batch = @check_information.correspondence?(@batch, @facility)
    unless image_types_for_job.blank?
      if image_types_for_job.index("EOB") == nil
        flash[:notice] = "In a complete job, at least one EOB image type should be present"
        return false
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
      else
        unless is_correspondence_batch
          if image_types_for_job.count("CHK") != 1
            flash[:notice] = "In a payment check, exactly one CHK should exist"
            return false
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
          else
            validate_image_types_per_page(page_count, partial_eob_image_type_obj_array)
          end
        else
          validate_image_types_per_page(page_count, partial_eob_image_type_obj_array)
        end
      end
    end
  end

  def validate_image_types_per_page(page_count, partial_eob_image_type_obj_array)

    partial_eob_image_page_numbers = @job.get_partial_eob_image_page_nos_for_job(partial_eob_image_type_obj_array)
    partial_eob_image_types = @job.get_partial_eob_image_types_for_job(partial_eob_image_type_obj_array)
    page_from = 1
    image_type_array = []
    image_page_no_array =[]
    page_index_array  = []
    jobs_partial_eob_image_types = []
    partial_eob_image_type_array = ["OTH", "NOT", "TIC", "HDR", "BOP"]
    # If any of the image types like CHK,OTH,NOT,TIC,HDR,BOP,ENV appears more than once in the same page
    # then that page number is pushed into image_page_no_array and
    # index of that page number in partial_eob_image_page_numbers array is pushed into page_index_array.
    partial_eob_image_page_numbers.each_with_index do |image_page_number, index|
      if partial_eob_image_page_numbers.count(image_page_number).to_i > 1
        image_page_no_array << image_page_number
        page_index_array << index
      end
    end
    # For each page for that job we will get the indexes of that page number if its
    # more than one, from page_index_array and pushed to each_page_indexes. Thus we will
    # get all the image types in the corresponding repeated page numbers in
    # image_type_array
    page_from.upto(page_count) { |page_no|
      each_page_indexes = []
      if partial_eob_image_page_numbers.count(page_no).to_i > 1
        if image_page_no_array.include?(page_no)
          image_page_no_array.each_with_index do |image_page_no, index|
            if image_page_no == page_no
              each_page_indexes << page_index_array[index]
            end
          end
        end
      end

      unless each_page_indexes.blank?
        each_page_indexes.each do |page_index|
          image_type_array << partial_eob_image_types[page_index]
        end
      end
    }
    # With the image type_array , we will check whether this array contains
    # image types in ["OTH", "NOT", "TIC", "HDR", "BOP"] for validating.
    # If present displays an alert.
    partial_eob_image_type_array.each do |partial_eob_image_type|
      if image_type_array.include?(partial_eob_image_type)
        jobs_partial_eob_image_types << partial_eob_image_type
      end
    end

    unless jobs_partial_eob_image_types.blank?
      flash[:notice] = "All image types other than EOB, OTH with full EOB ,CHK & ENV should have only one record/page"
      return false
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
    else
      return true
    end
  end

  def validate_eob_image_types(insurance_eobs_count)
    image_types = @job.get_all_image_type_obj_for_job
    eob_image_types = image_types.select{|i| i.image_type == 'EOB' || i.image_type == 'OTH' unless i.insurance_payment_eob_id.blank?}
    if eob_image_types.length == insurance_eobs_count
      return true
    else
      flash[:notice] = "Each EOB should have an Image Type record"
      return false
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
    end
  end
  # image type validations ends here.

  def validate_doc_classification(eobs)
    doc_classification = []
    eob_index = []
    eobs.each_with_index do |eob, index|
      doc_classification << eob.document_classification
      eob_index << index + 1
    end
    unique_doc_classification = doc_classification.uniq
    if unique_doc_classification.length == 1
      return true
    else
      flash[:notice] = "A unique document classification should be used for all EOBs within a job. Please verify #{doc_classification} used for eobs #{eob_index}"
      return false
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claim',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber]
    end
  end

  # Associating reason codes to jobs and set names.
  def associate_rcs_to_jobs_and_set_names(job, payer)
    set_name = payer.reason_code_set_name
    set_name_id = set_name.id
    parent_job_exists = !job.parent_job_id.blank?
    if parent_job_exists
      job = Job.find(job.parent_job_id)
    end
    reason_code_records = job.reason_codes
    default_unique_codes = ["1", "2", "3", "4", "5"]
    @hash_for_replacing_unique_code = {}
    reason_code_records.each do |reason_code_record|
      unique_code = reason_code_record.get_unique_code #.upcase
      if default_unique_codes.include?(unique_code)
        reason_code = ReasonCode.find(:first, :conditions => ["unique_code = ? and reason_code_set_name_id = ?",
            unique_code, set_name])
        if reason_code.blank?
          reason_code_record.update_attributes(:reason_code_set_name_id => set_name_id)
        else
          update_reason_code_jobs(reason_code_record.id, reason_code.id, job.id)
        end
      elsif reason_code_record.reason_code_set_name_id != set_name_id
        saved_rc_record = ReasonCode.get_reason_code(reason_code_record.reason_code, reason_code_record.reason_code_description, set_name, payer)
        if saved_rc_record.blank?
          reason_code_record.update_attributes(:reason_code_set_name_id => set_name_id, :payer_name => payer.payer)
        else
          @hash_for_replacing_unique_code[unique_code.to_sym] = saved_rc_record.get_unique_code #.upcase
          update_reason_code_jobs(reason_code_record.id, saved_rc_record.id, job.id)
        end

      end
    end
  end

  def update_reason_code_jobs(old_reason_code_id, new_reason_code_id, job_id)
    reason_codes_job_old = ReasonCodesJob.find_by_reason_code_id_and_parent_job_id(old_reason_code_id, job_id)
    reason_codes_job_new = ReasonCodesJob.find_by_reason_code_id_and_parent_job_id(new_reason_code_id, job_id)
    reason_codes_job_old.update_attributes(:reason_code_id => new_reason_code_id) if reason_codes_job_new.blank?
  end

  # This method inserts all the information captured through the grid into check_informations, payers, insurance_payment_eobs tables
  # - flag : indicates whether an eob ahs been inserted by QA (0)
  # this method delegates service_payment_eob save to process_service_lines
  # First the payer type is checked. If its a normal payer then we check whether the payer already exists, if yes update else insert.
  # This method is also called during the qa insert/update of an EOB. If QA is inserting a new eob then flag = 0 else flag = 1
  # Different ativities performed on an EOB along its life cycle are saved in the table job_activity_logs
  # Navicure and Medistream clients have specialized logic to compute claim type, the same has been coded for in this method
  # Finally, we are converting the claim_from and to dates from mm/dd/yy format to mm/dd/yyyy format and save them
  # this method delegates claim level reason code population to another method called navicure_claim_based_information, if the client is Navicure
  # calls process_service_lines to save details of service_payment_eob
  def insertdata(flag)
    job_activities = []
    insurance_eob = nil
    @reason_code_for_image_aggregate = []
    facility_payids = {:commercial_payid => @facility.commercial_payerid, :patient_payid => @facility.patient_payerid}
    @payer = save_payer(@check_information, facility_payids)
    if @client.name.upcase == 'GOODMAN CAMPBELL'
      tab_type_condition =  (params[:payer_type].upcase != 'PATPAY')
    else
      tab_type_condition = true;
    end
    if params[:tab_type].upcase == 'INSURANCE' && @payer.payer_type.upcase == 'PATPAY' && tab_type_condition
      @error_message = "Payer is PatPay, Please process in PatPay Grid"
      return @error_message
    end unless params[:tab_type].blank?
    if @client_name == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' && !(params[:checkinforamation][:payee_name].blank?)
      payee_name_flag = UpmcFacility.exists?(:name => "#{params[:checkinforamation][:payee_name]}")
      payee_tin_flag = UpmcFacility.exists?(:name => "#{params[:checkinforamation][:payee_name]}", :tin => "#{params[:checkinforamation][:payee_tin]}") if payee_name_flag == true
      if payee_name_flag != true
        @error_message = "Invalid Payee Name, Please Recheck"
        return @error_message
      elsif payee_tin_flag != true
        @error_message = "Invalid Payee Name and Payee Tin Combination, Please Recheck"
        return @error_message
      end
    end

    #    if (params[:insurancepaymenteob][:image_page_no].blank? || params[:insurancepaymenteob][:image_page_no] == "" || params[:insurancepaymenteob][:image_page_no] == "NaN")
    #      @error_message = "Page from is missing Please ReSave"
    #      return @error_messag
    #    end
    #    if (params[:insurancepaymenteob][:image_page_to_number] == "" || params[:insurancepaymenteob][:image_page_to_number]== "NaN" ||  params[:insurancepaymenteob][:image_page_to_number].blank?)
    #      @error_message = "Page To  is missing Please ReSave"
    #      return @error_messag
    #    end
    @check_information = save_check(@check_information,facility_payids)
    @job ||= Job.find(params[:job_id])
    if !@job.parent_job_id.blank?
      jobs_for_chk_no_update = Job.find(:all, :conditions => "parent_job_id = #{@job.parent_job_id}")
    else
      jobs_for_chk_no_update = Job.find(:all, :conditions => "parent_job_id = #{@job.id}")
    end
    jobs_for_chk_no_update.each do |job_for_chk_no_update|
      old_job_chk_no = job_for_chk_no_update.check_number
      sequence_no_of_split_job = old_job_chk_no.split("_")[1]
      job_for_chk_no_update.check_number = "#{params[:checkinforamation][:check_number]}_#{sequence_no_of_split_job}"
      job_for_chk_no_update.save
    end
    if !@job.blank? && !@check_information.blank? && !@payer.blank?
      # reason_code_set_name_id updation for  default reason codes
      associate_rcs_to_jobs_and_set_names(@job, @payer)

      insurance_eob_exist = params[:insurance_id]
      if params[:interest_eob].to_s == 'true'
        create_interest_only_eob
      end
      is_balance_record_object_created = create_balance_record
      validation_for_eob_balance = true
      formatted_date_received_by_insurer = format_date(params[:insurancepaymenteob][:date_received_by_insurer])
      InsurancePaymentEob.transaction do
        if(!insurance_eob_exist.blank?)
          job_count = @job.count
          insurance_eob = InsurancePaymentEob.find(params[:insurance_id])
          insurance_eob.check_information_id = @check_information.id
          @previous_claim_interest = insurance_eob.claim_interest
          insurance_eob.assign_attributes(params[:insurancepaymenteob], :without_protection => true)
          set_provider_npi_and_tin insurance_eob
          insurance_eob.rendering_provider_last_name = params[:provider][:provider_last_name] if params[:provider]
          @job.apply_to_all_claims = params[:apply_to_all_claims_hidden_field] if @job.apply_to_all_claims != params[:apply_to_all_claims_hidden_field]
          if((insurance_eob.processor_id != @current_user.id) && @current_user.has_role?(:processor))
            eob_rekeyed_by_another_processor = true if insurance_eob.processor_id.present?
            @job.count = job_count + 1
          end
          @job.save if @job.changed?
          if @current_user.has_role?(:processor)
            insurance_eob.processor_id = @current_user.id
            insurance_eob.processing_completed = Time.now
            insurance_eob.end_time = Time.now
          end
          insurance_eob.patient_identification_code = nil if set_patient_identification_code_to_blank(params[:insurancepaymenteob][:patient_identification_code_qualifier], params[:insurancepaymenteob][:patient_identification_code])
          insurance_eob.date_received_by_insurer = formatted_date_received_by_insurer
          if(params[:mode_value]== "VERIFICATION")
            save_job_activity_flag = true
          end
        else
          insurance_eob = InsurancePaymentEob.new
          insurance_eob.assign_attributes(params[:insurancepaymenteob], :without_protection => true)
          set_provider_npi_and_tin insurance_eob
          insurance_eob.patient_identification_code = nil if set_patient_identification_code_to_blank(params[:insurancepaymenteob][:patient_identification_code_qualifier], params[:insurancepaymenteob][:patient_identification_code])
          insurance_eob.check_information_id = @check_information.id
          if params[:provider]
            insurance_eob.rendering_provider_last_name = params[:provider][:provider_last_name]
          end
          if @current_user.has_role?(:qa)
            insurance_eob.processor_id = @job.processor_id
          else
            if insurance_eob.processor_id.present? && @current_user.has_role?(:processor) &&
                @current_user.id != insurance_eob.processor_id
              eob_rekeyed_by_another_processor = true
            end
            insurance_eob.processor_id = @current_user.id
          end
          save_job_activity_flag = true
          insurance_eob.processing_completed = Time.now
          insurance_eob.end_time = Time.now
          insurance_eob.svc_start_time = Time.zone.parse(params[:service_start_time])
          insurance_eob.date_received_by_insurer = formatted_date_received_by_insurer
          set_total_amounts(insurance_eob) if params[:claimleveleob] == "true"
          insurance_eob.save
          @error_message = insurance_eob.validate_patient_name(@facility)
          if !@error_message.blank?
            return @error_message
          end
          # Navicure and Medistreams client have special requirements to fill claim level reason codes and other related info
          # Delegate to navicure_claim_based_information method
          if (@client.name == 'Navicure' or @client.name == 'Medistreams')
            navicure_claim_based_information(insurance_eob)
          end
        end
        if eob_rekeyed_by_another_processor
          job_activities << save_job_activity(@job.id, insurance_eob.id, @job.processor_id, nil, "EOB Re-keyed", Time.now, nil, 1, false)
        end
        if (!params[:payer][:payer_tin].blank?)
          @job.payer_tin = params[:payer][:payer_tin].to_s.strip
        end
        if(save_job_activity_flag)
          # Save all milestone events occured during processing in job_activity_logs table
          if !@current_user.has_role?(:qa)
            if is_balance_record_object_created && insurance_eob.balance_record_type.present?
              job_activities << save_job_activity(@job.id, insurance_eob.id, @current_user.id, nil, "Balance Record created", Time.now, nil, 1, false)
            end
            job_activities << save_job_activity(@job.id, insurance_eob.id, @current_user.id, nil, "EOB Saved by processor", Time.now, nil, 1, false)
            job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"Processing Started",Time.zone.parse(params[:insurancepaymenteob][:start_time]),insurance_eob.end_time,1,false)
            mpi_search_conditions = []
            mpi_search_conditions_list = []
            if !params[:mpi_search][:mpi_start_time].blank?
              job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"MPI Search Started",Time.zone.parse(params[:mpi_search][:mpi_start_time]),nil, 1, false)
            end
            if !params[:mpi_search][:mpi_found_time].blank?
              job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"MPI Match Found",Time.zone.parse(params[:mpi_search][:mpi_found_time]),nil, 1, false)
            end
            if (!params[:mpi_search][:mpi_used_time].blank? && !params[:claim_information_id].blank?)
              job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"MPI Match Used",Time.zone.parse(params[:mpi_search][:mpi_used_time]),nil, 1, false)
              # Saving all milestone events occured during MPI Search in mpi_statistics_reports table
              mpi_search_conditions << "PACNO" unless params[:mpi_search][:account_number].blank?
              mpi_search_conditions << "PLN" unless params[:mpi_search][:patient_last_name].blank?
              mpi_search_conditions << "PFN" unless params[:mpi_search][:patient_first_name].blank?
              mpi_search_conditions << "DOS" unless (params[:mpi_search][:date_of_service_from].blank? or params[:mpi_search][:date_of_service_from] == "MM/DD/YY")
              mpi_search_conditions_list = mpi_search_conditions.join(",")
              save_mpi_statistics(params[:batch_id],@current_user.id,insurance_eob,"Success",mpi_search_conditions_list,params[:mpi_search][:mpi_used_time])
            else
              if (params[:mpi_search_start_time].blank? and params[:account_number].blank? and params[:patient_last_name].blank? and params[:patient_first_name].blank? and params[:claim_information_id].blank? and (params[:date_of_service_from].blank? or params[:date_of_service_from] == "MM/DD/YY" ))
                save_mpi_statistics(params[:batch_id], @current_user.id, insurance_eob, "MPI Not Used", nil, params[:acc_no_captured_time])
                job_activities << save_job_activity(@job.id, insurance_eob.id, @job.processor_id, nil, "MPI Not Used", Time.now, nil, 1, false)
              else
                mpi_search_conditions << "PACNO" unless params[:mpi_search][:account_number].blank?
                mpi_search_conditions << "PLN" unless params[:mpi_search][:patient_last_name].blank?
                mpi_search_conditions << "PFN" unless params[:mpi_search][:patient_first_name].blank?
                mpi_search_conditions << "DOS" unless (params[:mpi_search][:date_of_service_from].blank? or params[:mpi_search][:date_of_service_from] == "MM/DD/YY")
                mpi_search_conditions_list = mpi_search_conditions.join(",")
                save_mpi_statistics(params[:batch_id],@current_user.id,insurance_eob,"Failure",mpi_search_conditions_list,Time.zone.parse(params[:mpi_search_start_time]))
                job_activities << save_job_activity(@job.id, insurance_eob.id, @current_user.id, nil, "MPI Failed", Time.now, nil, 1, false)
              end
            end
            job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"Processing Completed",insurance_eob.end_time,nil,1,false)

          elsif @current_user.has_role?(:qa)
            mpi_search_conditions = []
            mpi_search_conditions_list = []
            job_activities << save_job_activity(@job.id, insurance_eob.id, nil,  @current_user.id, "EOB Saved by QA", Time.now, nil, 1, false)
            if is_balance_record_object_created && insurance_eob.balance_record_type.present?
              job_activities << save_job_activity(@job.id, insurance_eob.id, nil, @current_user.id, "Balance Record created", Time.now, nil, 1, false)
            end
            job_activities << save_job_activity(@job.id,insurance_eob.id,nil,@job.qa_id,"QA Verification Started",Time.zone.parse(params[:insurancepaymenteob][:start_time]),insurance_eob.end_time,1, false)
            if !params[:mpi_search][:mpi_start_time].blank?
              job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"MPI Search Started",Time.zone.parse(params[:mpi_search][:mpi_start_time]),nil, 1, false)
            end
            if !params[:mpi_search][:mpi_found_time].blank?
              job_activities << save_job_activity(@job.id,insurance_eob.id,@job.processor_id,nil,"MPI Match Found",Time.zone.parse(params[:mpi_search][:mpi_found_time]),nil, 1, false)
            end
            if !params[:mpi_search][:mpi_used_time].blank?
              job_activities << save_job_activity(@job.id,insurance_eob.id,nil,@job.qa_id,"MPI Match Used",Time.zone.parse(params[:mpi_search][:mpi_used_time]),nil, 1, false)
              # Saving all milestone events occured during MPI Search in mpi_statistics_reports table
              mpi_search_conditions << "PACNO" unless params[:mpi_search][:account_number].blank?
              mpi_search_conditions << "PLN" unless params[:mpi_search][:patient_last_name].blank?
              mpi_search_conditions << "PFN" unless params[:mpi_search][:patient_first_name].blank?
              mpi_search_conditions << "DOS" unless (params[:mpi_search][:date_of_service_from].blank? or params[:mpi_search][:date_of_service_from] == "MM/DD/YY")
              mpi_search_conditions_list = mpi_search_conditions.join(",")
              save_mpi_statistics(params[:batch_id],@current_user.id,insurance_eob,"Success",mpi_search_conditions_list,Time.zone.parse(params[:mpi_search][:mpi_used_time]))
            else
              if (params[:mpi_search_start_time].blank? and params[:account_number].blank? and params[:patient_last_name].blank? and params[:patient_first_name].blank? and (params[:date_of_service_from].blank? or params[:date_of_service_from] == "MM/DD/YY"))
                save_mpi_statistics(params[:batch_id], @current_user.id, insurance_eob, "MPI Not Used", nil, params[:acc_no_captured_time])
                job_activities << save_job_activity(@job.id, insurance_eob.id, nil, @job.qa_id, "MPI Not Used", Time.now, nil, 1, false)
              else
                mpi_search_conditions << "PACNO" unless params[:mpi_search][:account_number].blank?
                mpi_search_conditions << "PLN" unless params[:mpi_search][:patient_last_name].blank?
                mpi_search_conditions << "PFN" unless params[:mpi_search][:patient_first_name].blank?
                mpi_search_conditions << "DOS" unless (params[:mpi_search][:date_of_service_from].blank? or params[:mpi_search][:date_of_service_from] == "MM/DD/YY")
                mpi_search_conditions_list = mpi_search_conditions.join(",")
                save_mpi_statistics(params[:batch_id],@current_user.id,insurance_eob,"Failure",mpi_search_conditions_list,Time.zone.parse(params[:mpi_search_start_time]))
              end
            end
            job_activities << save_job_activity(@job.id,insurance_eob.id,nil,@job.qa_id,"QA Completed",insurance_eob.end_time,nil, 1, false)
          end
         
        end
        insurance_eob.alternate_payer_name = params[:alternate_payer_name_for_eob].to_s.strip
        if(params[:apply_to_all_checked_or_not] == "true")
          InsurancePaymentEob.where(:sub_job_id => @job.id).update_all(:alternate_payer_name => params[:alternate_payer_name_for_eob])
        end
       
        is_insurance_pay = insurance_eob?
        if @current_user.has_role?(:processor)
          insurance_eob.processor_id = @current_user.id
          insurance_eob.processing_completed = Time.now
        elsif @current_user.has_role?(:qa)
          insurance_eob.qa_id = @current_user.id
        end
        unless params[:provider_address].blank?
          params[:provider_address].store('entity', 'provider')
          provider_address = ContactInformation.find_or_create_by_address_line_one_and_address_line_two_and_city_and_state_and_zip_and_entity(params[:provider_address])
          insurance_eob.contact_information = provider_address
        end

        rejection_comment = params[:rejection_comment]
        unless rejection_comment.blank? || rejection_comment == '--'
          insurance_eob.rejection_comment = rejection_comment
          insurance_eob.rejection_comment = params[:rejection][:comment_area] unless
          params[:rejection][:comment_area].blank?
        else
          insurance_eob.rejection_comment = nil
        end

        balance_record_type = params[:balance_record_type]
        unless balance_record_type.blank? || balance_record_type.downcase == 'none'
          insurance_eob.balance_record_type = balance_record_type
        end

        insurance_eob.patient_type = params[:patient_type]

        if !(is_balance_record_object_created && insurance_eob.balance_record_type.present?)
          claim_from_date = ""
          claim_to_date = ""
          if !params[:insurance_payment_eob].blank? && !params[:insurance_payment_eob][:claim_from_date].blank?
            claim_from = params[:insurance_payment_eob][:claim_from_date].split("/")
            if claim_from[0] == "99" and claim_from[1] == "99" and claim_from[2] == "99"
              claim_from_date = "09/09/99" + claim_from[2]
            else
              claim_from_date = format_service_date(params[:insurance_payment_eob][:claim_from_date].to_s, @facility.default_service_date)
            end
          end
          if !params[:insurance_payment_eob].blank? && !params[:insurance_payment_eob][:claim_to_date].blank?
            claim_to = params[:insurance_payment_eob][:claim_to_date].split("/")
            if claim_to[0] == "99" and claim_to[1] == "99" and claim_to[2] == "99"
              claim_to_date = "09/09/99" + claim_to[2]
            else
              claim_to_date = format_service_date(params[:insurance_payment_eob][:claim_to_date].to_s, @facility.default_service_date)
            end
          end
          insurance_eob.claim_from_date = claim_from_date
          insurance_eob.claim_to_date = claim_to_date
        end
        insurance_eob.claim_tooth_number = params[:insurance_payment_eob][:claim_tooth_number]  if !params[:insurance_payment_eob].blank? && !params[:insurance_payment_eob][:claim_tooth_number].blank?

        if params[:claimleveleob] == "true"
          insurance_eob.category = "claim"
        end

        insurance_eob.sub_job_id = params[:job_id]
        unless params[:claim_information_id].blank?
          insurance_eob.claim_information_id = params[:claim_information_id]
          claim_information = ClaimInformation.find(:first,
            :conditions => "id = #{params[:claim_information_id]}",
            :select => "payid, plan_type, claim_file_information_id")
          insurance_eob.claim_payid = claim_information.payid
          insurance_eob.claim_file_information_id = claim_information.claim_file_information_id
        end
        @remark_code_adjustment_codes = []
        if insurance_eob.category.to_s.downcase == 'claim' && insurance_eob.balance_record_type.blank?
          @amount_value_for_adjustment_reason = { :claim_coinsurance => insurance_eob.total_co_insurance,
            :claim_copay => insurance_eob.total_co_pay,
            :claim_contractual => insurance_eob.total_contractual_amount,
            :claim_deductible => insurance_eob.total_deductible,
            :claim_denied => insurance_eob.total_denied,
            :claim_discount => insurance_eob.total_discount,
            :claim_noncovered => insurance_eob.total_non_covered,
            :claim_primary_payment => insurance_eob.total_primary_payer_amount,
            :claim_prepaid => insurance_eob.total_prepaid,
            :claim_patient_responsibility => insurance_eob.total_patient_responsibility,
            :claim_miscellaneous_one => insurance_eob.miscellaneous_one_adjustment_amount,
            :claim_miscellaneous_two => insurance_eob.miscellaneous_two_adjustment_amount
          }
          @entity = insurance_eob
          adjustment_reason_and_code_ids = save_adjustment_codes
          @reason_code_for_image_aggregate << adjustment_reason_and_code_ids[0][1] unless adjustment_reason_and_code_ids.blank? && adjustment_reason_and_code_ids[0].blank?
          if adjustment_reason_and_code_ids.present?
            save_secondary_reason_code_ids(adjustment_reason_and_code_ids)
          end
          if !@error_message.blank?
            return @error_message
          end
          set_ansi_remark_code(insurance_eob)
        end
        #Saving patient address for PatPays
        if not insurance_eob?
          save_patient_details(insurance_eob)
        end
        if insurance_eob.category != 'claim'
          min_date_from_svc = process_service_lines(insurance_eob)
          if !@error_message.blank?
            return @error_message
          end
          validation_for_eob_balance = save_total_amounts_in_patient_record(insurance_eob)
          if !validation_for_eob_balance
            @error_message = "EOB is not balanced"
            raise ActiveRecord::Rollback
            return @error_message
          end
        elsif @facility.details[:claim_level_service_lines]
          save_claim_level_service_lines(insurance_eob)
        end
        # Setting the claim type
        if insurance_eob?
          insurance_eob.claim_type = insurance_eob.get_insurance_eob_claim_type(params[:claim_type], @client, @facility, @remark_code_adjustment_codes)
        else
          insurance_eob.claim_type = insurance_eob.get_patient_pay_claim_type(params[:claim_type], @facility.details[:patpay_statement_fields])
        end
        
        #Setting place of service
        insurance_eob.place_of_service = set_place_of_service(params[:insurancepaymenteob][:place_of_service])

        # Gets the total field count for the eob(claim_level, insurance, simplified patpay) grid

        if !params[:insurance_payment_eob].blank? && @current_user.has_role?(:qa) && flag == 1
          total_eob_fields = params[:insurance_payment_eob][:processor_input_fields]
        end
        if (flag == 0 || (flag == 1 && @current_user.has_role?(:processor)))
          total_eob_fields = get_total_eob_field_count(@check_information, @payer, insurance_eob)
        end

        insurance_eob.processor_input_fields = total_eob_fields
        insurance_eob.claim_from_date = min_date_from_svc unless min_date_from_svc.blank?
        if(!params[:mpi_selected_or_not].blank?)
          unless (params[:mpi_selected_or_not] ==1)
            insurance_eob.claim_information_id = ""
            insurance_eob.claim_file_information_id = ""
          end
        end
        insurance_eob.plan_type = get_plan_type(@payer, insurance_eob)
        payer_type = @payer.payer_type if @payer
        insurance_eob.client_code = insurance_eob.get_client_code(@facility, @batch, payer_type)
        if insurance_eob.claim_number.blank?
          if @facility.details[:default_claim_number].present? && payer_type != 'PatPay'
            insurance_eob.claim_number = @facility.details[:default_claim_number]
          else
            insurance_eob.claim_number = nil
          end
        end
        insurance_eob.save
        # Saving the  Transaction Type.
        save_transaction_type if @facility.details[:transaction_type] == true
        # Saving the Image Type.
        save_image_type(insurance_eob)
        update_interest_eob_with_interest_amount
        save_twice_keying_field_statistics(insurance_eob)
        @check_information.populate_report_check_informations(is_insurance_pay, @batch.id, @parent_job.id, @facility)
      end
      payer = @payer.save_patient_payer_status_and_indicator(@check_information, insurance_eob)
      payer.commence_classification($IS_PARTNER_BAC, @facility)
    end
    JobActivityLog.import job_activities unless job_activities.blank?
    image_aggregation_for_medassets flag, insurance_eob
  end

  def image_aggregation_for_medassets flag, insurance_eob
    if @client.name.upcase == 'MEDASSETS'  ||  @client.name.upcase =='BARNABAS'
      if flag == 0
        create_eob_reason_code_records(insurance_eob)
      else
        update_eob_reason_codes_for_qa_view(insurance_eob)
      end
    end
  end

  def set_provider_npi_and_tin insurance_eob
    if params[:insurancepaymenteob].present?  && params[:provider].present?
      if (@facility.details[:default_rendering_provider_details] == true) && (params[:insurancepaymenteob][:provider_tin]).blank? && (params[:provider][:provider_npi_number]).blank?
        record = FacilitiesNpiAndTin.where(:facility_id => @facility.id)
        unless record.blank?
          insurance_eob.provider_tin = record.first.tin
          insurance_eob.provider_npi = record.first.npi
        end
      else
        insurance_eob.provider_tin = params[:insurancepaymenteob][:provider_tin]
        insurance_eob.provider_npi = params[:provider][:provider_npi_number] if params[:provider]
      end
    end
  end

  def save_image_type(insurance_eob)
    logger.debug "Image type : #{insurance_eob.id}"
    image_type_from_ui = params[:image_type]
    logger.debug "image_type_from_ui : #{image_type_from_ui}"
    image_page_no = params[:insurancepaymenteob][:image_page_no] unless params[:insurancepaymenteob].blank?
    logger.debug "image_page_no : #{image_page_no}"
    job = @parent_job
    logger.debug "job.id : #{job.id}"
    images_for_job_id = job.get_exact_images_for_job_reference(image_page_no)
    logger.debug "images_for_job_id : #{images_for_job_id}"
    insurance_payment_eob_id = insurance_eob.id unless insurance_eob.blank?
    logger.debug " insurance_payment_eob_id : #{insurance_payment_eob_id}"
    if !images_for_job_id.blank? && !image_page_no.blank? && !image_type_from_ui.blank?
      logger.debug "Entering updating condition"
      image_type = ImageType.update_all(
        "image_type = '#{image_type_from_ui}',
          image_page_number = #{image_page_no},
          images_for_job_id = #{images_for_job_id}",
        "insurance_payment_eob_id = '#{insurance_payment_eob_id}'")
      if image_type == 0
        logger.debug "Entering create condition"

        image_type = ImageType.create(
          :insurance_payment_eob_id => insurance_payment_eob_id,
          :image_type => image_type_from_ui,
          :image_page_number => image_page_no,
          :images_for_job_id => images_for_job_id)

        logger.debug "insurance_eob.image_types : #{insurance_eob.image_types}"
      end
    end
  end

  #  calculation of total field count for the claim_level, insurance and simplified patpay grid.
  def get_total_eob_field_count(check_information, payer, insurance_eob)
    logger.debug "Calculating field count in DC Grid for EOB ID : #{insurance_eob.id}"
    total_eob_fields = 0
    eob_type = 'eob'
    is_insurance_eob = insurance_eob?
    claim_level_eob_condition = (insurance_eob.category == "claim")
    transaction_type_present = @facility.details[:transaction_type] && is_insurance_eob
    micr_with_known_payer_condition = check_information.micr_line_information &&
      check_information.micr_line_information.payer && @facility.details[:micr_line_info]
    #    Calculating processor_input_field_count for each model(check level, payer level, eob level, micr level and svc level)
    #    using the model level method processor_input_field_count(facility) by passing the facility object
    total_check_fields = check_information.processor_input_field_count(@facility, eob_type)
    logger.debug "total_check_fields : #{total_check_fields}"
    total_payer_fields = payer.processor_input_field_count
    logger.debug "total_payer_fields : #{total_payer_fields}"
    total_eob_level_fields = insurance_eob.processor_input_field_count(@facility, @payer)
    logger.debug "total_eob_level_fields : #{total_eob_level_fields}"
    total_eob_fields += total_check_fields +
      total_payer_fields + total_eob_level_fields

    if micr_with_known_payer_condition
      total_micr_fields = check_information.micr_line_information.processor_input_field_count(@facility)
      logger.debug "total_micr_fields : #{total_micr_fields}"
      total_eob_fields += total_micr_fields
    end

    if !is_insurance_eob
      total_eob_fields += insurance_eob.patients.first.processor_input_field_count
      total_eob_fields -= 1  #removing payer_type field count if patient_pay
    end
    #    If transaction_type is selected from FCUI, then increment the count by 1 as transaction_type is a select tag
    #    with a value always except for patient pay
    if transaction_type_present
      logger.debug "transaction_type_present : adding 1 to field count"
      total_eob_fields += 1
    end

    #Adding provider address details if it is configured from FC UI
    if @facility.details[:provider_address] && !insurance_eob.contact_information.blank?
      total_contact_info_of_prov_fields = insurance_eob.contact_information.processor_input_field_count
      logger.debug "total_contact_info_of_prov_fields : #{total_contact_info_of_prov_fields}"
      total_eob_fields += total_contact_info_of_prov_fields
    end
    #Adding image type
    unless insurance_eob.image_types.blank?
      image_type_ids = insurance_eob.image_types.map(&:id)
      logger.debug "insurance_eob.image_types  : #{image_type_ids}"
      logger.debug "image_types_present : adding 1 to field count"
      total_eob_fields += 1
    end
    #Adding provider_adjustments details
    total_prov_adj_fields = ProviderAdjustment.processor_input_field_count(insurance_eob.image_page_no, @parent_job)
    logger.debug "total_prov_adj_fields : #{total_prov_adj_fields}"
    total_eob_fields += total_prov_adj_fields
    #    Excluding svc total calculation for claim level eobs
    unless claim_level_eob_condition
      insurance_eob.service_payment_eobs.each do |svc|
        total_service_line_fields = svc.processor_input_field_count(@facility, is_insurance_eob)
        logger.debug "total_service_line_fields : #{total_service_line_fields}"
        total_eob_fields += total_service_line_fields
      end
    end
    logger.debug "insurance_eob.processor_input_fields : #{total_eob_fields}"
    total_eob_fields
  end

  #----------------------------------------------------
  # Description  : Save Patient Details
  # Input        : None.
  # Output       : None.
  #----------------------------------------------------
  def save_patient_details(insurance_eob)
    if(!params[:patient].blank?)
      patient_exist = params[:patdetails][:patient_id]
    end
    if patient_exist.blank?
      patient = Patient.create!(params[:patient])
    else
      patient = Patient.find(params[:patdetails][:patient_id])
      patient.update_attributes(params[:patient])
    end

    patient.insurance_payment_eob_id = insurance_eob.id
    patient.last_name = params[:insurancepaymenteob][:patient_last_name] unless params[:insurancepaymenteob][:patient_last_name].blank?
    patient.first_name = params[:insurancepaymenteob][:patient_first_name] unless params[:insurancepaymenteob][:patient_first_name].blank?
    patient.middle_initial = params[:insurancepaymenteob][:patient_middle_initial] unless params[:insurancepaymenteob][:patient_middle_initial].blank?
    patient.suffix = params[:insurancepaymenteob][:patient_suffix] unless params[:insurancepaymenteob][:patient_suffix].blank?
    patient.patient_identification_code_qualifier = params[:insurancepaymenteob][:patient_identification_code_qualifier] unless params[:insurancepaymenteob][:patient_identification_code_qualifier].blank?
    patient.patient_account_number = params[:insurancepaymenteob][:patient_account_number] unless params[:insurancepaymenteob][:patient_account_number].blank?
    patient.patient_medistreams_id = params[:insurancepaymenteob][:patient_medistreams_id] unless params[:insurancepaymenteob][:patient_medistreams_id].blank?
    patient.insurance_policy_number = params[:insurancepaymenteob][:insurance_policy_number] unless params[:insurancepaymenteob][:insurance_policy_number].blank?
    patient.patient_type = params[:patient_type] unless params[:patient_type].blank?
    patient.subscriber_identification_code = params[:insurancepaymenteob][:subscriber_identification_code] unless params[:insurancepaymenteob][:subscriber_identification_code].blank?

    if patient_exist.blank?
      patient.save
    else
      patient.save
    end
  end

  def set_total_amounts(insurance_eob)
    if params[:insurancepaymenteob]
      insurance_eob.total_submitted_charge_for_claim = format_amount_ui_param(params[:insurancepaymenteob][:total_submitted_charge_for_claim])
      insurance_eob.total_amount_paid_for_claim = format_amount_ui_param(params[:insurancepaymenteob][:total_amount_paid_for_claim])
      insurance_eob.total_allowable = format_amount_ui_param(params[:insurancepaymenteob][:total_allowable])
      insurance_eob.total_pbid = format_amount_ui_param(params[:insurancepaymenteob][:total_pbid])
      insurance_eob.total_drg_amount = format_amount_ui_param(params[:insurancepaymenteob][:total_drg_amount])
      insurance_eob.total_expected_payment = format_amount_ui_param(params[:insurancepaymenteob][:total_expected_payment])
      insurance_eob.total_retention_fees = format_amount_ui_param(params[:insurancepaymenteob][:total_retention_fees])
      insurance_eob.total_prepaid = format_amount_ui_param(params[:insurancepaymenteob][:total_prepaid])
      insurance_eob.total_non_covered = format_amount_ui_param(params[:insurancepaymenteob][:total_non_covered])
      insurance_eob.total_denied = format_amount_ui_param(params[:insurancepaymenteob][:total_denied])
      insurance_eob.total_discount = format_amount_ui_param(params[:insurancepaymenteob][:total_discount])
      insurance_eob.total_co_insurance = format_amount_ui_param(params[:insurancepaymenteob][:total_co_insurance])
      insurance_eob.total_deductible = format_amount_ui_param(params[:insurancepaymenteob][:total_deductible])
      insurance_eob.total_co_pay = format_amount_ui_param(params[:insurancepaymenteob][:total_co_pay])
      insurance_eob.total_patient_responsibility = format_amount_ui_param(params[:insurancepaymenteob][:total_patient_responsibility])
      insurance_eob.total_primary_payer_amount = format_amount_ui_param(params[:insurancepaymenteob][:total_primary_payer_amount])
      insurance_eob.total_contractual_amount = format_amount_ui_param(params[:insurancepaymenteob][:total_contractual_amount])
      insurance_eob.miscellaneous_one_adjustment_amount = format_amount_ui_param(params[:insurancepaymenteob][:miscellaneous_one_adjustment_amount])
      insurance_eob.miscellaneous_two_adjustment_amount = format_amount_ui_param(params[:insurancepaymenteob][:miscellaneous_two_adjustment_amount])
      insurance_eob.miscellaneous_balance = format_amount_ui_param(params[:insurancepaymenteob][:miscellaneous_balance])
    end
  end

  # Saves the total amounts from all the service lines to the eob object
  # Input :
  #  insurance_eob : EOB object
  # Instance variables for different amount are added up for every service line
  # This also checks if the EOB is balanced or not.
  def save_total_amounts_in_patient_record(insurance_eob)
    insurance_eob.total_submitted_charge_for_claim = format_amount_ui_param(@total_charge)
    insurance_eob.total_pbid = format_amount_ui_param(@total_pbid)
    insurance_eob.total_allowable = format_amount_ui_param(@total_allowable)
    insurance_eob.total_drg_amount = format_amount_ui_param(@total_drg_amount)
    insurance_eob.total_expected_payment = format_amount_ui_param(@total_expected_payment)
    insurance_eob.total_retention_fees = format_amount_ui_param(@total_retention_fees)
    insurance_eob.total_prepaid = format_amount_ui_param(@total_prepaid)
    insurance_eob.total_amount_paid_for_claim = format_amount_ui_param(@total_payment)
    insurance_eob.total_non_covered = format_amount_ui_param(@total_non_covered)
    insurance_eob.total_denied = format_amount_ui_param(@total_denied)
    insurance_eob.total_discount = format_amount_ui_param(@total_discount)
    insurance_eob.total_co_insurance = format_amount_ui_param(@total_coinsurance)
    insurance_eob.total_deductible = format_amount_ui_param(@total_deductible)
    insurance_eob.total_co_pay = format_amount_ui_param(@total_copay)
    insurance_eob.total_patient_responsibility = format_amount_ui_param(@total_patient_responsibility)
    insurance_eob.total_primary_payer_amount = format_amount_ui_param(@total_primary_payment)
    insurance_eob.total_contractual_amount = format_amount_ui_param(@total_contractual)
    insurance_eob.miscellaneous_one_adjustment_amount = format_amount_ui_param(@total_miscellaneous_one)
    insurance_eob.miscellaneous_two_adjustment_amount = format_amount_ui_param(@total_miscellaneous_two)
    insurance_eob.miscellaneous_balance = format_amount_ui_param(@total_miscellaneous_balance)

    total_payment = @total_payment.to_f + @total_non_covered.to_f + @total_denied.to_f +
      @total_discount.to_f + @total_coinsurance.to_f + @total_deductible.to_f + @total_copay.to_f +
      @total_primary_payment.to_f + @total_prepaid.to_f + @total_contractual.to_f +
      @total_patient_responsibility.to_f + @total_miscellaneous_one.to_f +
      @total_miscellaneous_two.to_f + @total_miscellaneous_balance.to_f
    
    total_service_balance = @total_charge.to_f.round(2) - total_payment.round(2)
    if total_service_balance.zero?
      insurance_eob.total_service_balance = total_service_balance
      validation_for_eob_balance = true
    else
      validation_for_eob_balance = false
    end
    validation_for_eob_balance
  end

  def process_service_lines(insurance_eob)
    @adjustment_line_count = 0
    svc_lines_ids_to_delete = []
    min_date_from_svc = []
    deleted_entity_records = []
    if params[:service_line]
      serial_numbers = params[:service_line][:serial_numbers]
      serial_numbers = serial_numbers.split(',')
      svc_lines_to_delete = params[:service_line][:to_delete]
      svc_lines_to_delete = svc_lines_to_delete.split(',') if svc_lines_to_delete
      delete_all_svc_lines = params[:service_line][:delete_all]
    end
    if delete_all_svc_lines == 'true'
      # Delete all the existing service lines. This value is set when 'Remove All Service Line' is initiated
      deleted_service_lines = ServicePaymentEob.where(:insurance_payment_eob_id => insurance_eob.id).destroy_all
      deleted_service_lines.each do |deleted_service_line|
        parameters = { :entity => 'service_payment_eobs', :entity_id => deleted_service_line.id,
          :client_id => @client.id, :facility_id => @facility.id }
        deleted_entity_records << DeletedEntity.create_records(parameters)
      end
    end
    if !insurance_eob.service_payment_eobs.blank? && !svc_lines_to_delete.blank?
      # Delete the service lines one by one. This is initiated when each service line is deleted
      svc_lines_to_delete.each do |svc_lines_id|
        if !svc_lines_id.blank?
          svc_lines_ids_to_delete << svc_lines_id.to_i
        end
      end
      svc_lines_ids_to_delete = svc_lines_ids_to_delete.uniq
      if !svc_lines_ids_to_delete.blank?
        ServicePaymentEob.where(:id => (svc_lines_ids_to_delete)).destroy_all
        svc_lines_ids_to_delete.each do |svc_lines_id|
          parameters = { :entity => 'service_payment_eobs', :entity_id => svc_lines_id,
            :client_id => @client.id, :facility_id => @facility.id }
          deleted_entity_records << DeletedEntity.create_records(parameters)
        end
      end
    end
    DeletedEntity.import(deleted_entity_records) if deleted_entity_records.present?
      
    if serial_numbers.length > 0
      serial_numbers.each do |svc_line_serial_num|
        svc_line_serial_num_and_id = svc_line_serial_num.split('_')
        if !svc_line_serial_num_and_id.blank?
          serial_num = svc_line_serial_num_and_id[0]
          serial_num = serial_num.to_i
          line_id = svc_line_serial_num_and_id[1]
          if !serial_num.blank? && serial_num != 0 && (svc_lines_ids_to_delete.blank? || !svc_lines_ids_to_delete.include?(line_id))
            is_valid = validate_service_line(serial_num, insurance_eob.patient_account_number)
            if is_valid
              # If service line id is present for the service lines, find it else create new
              if !line_id.blank? && line_id != 'undefined' && line_id.downcase != 'null' && line_id.downcase != 'nan'
                service_payment_eob = ServicePaymentEob.find(line_id)
              else
                service_payment_eob = ServicePaymentEob.new
              end
              min_date_from_svc << format_service_date(params[:lineinformation]["dateofservice_from" + serial_num.to_s], @facility.default_service_date)
              save_service_line(service_payment_eob, serial_num, insurance_eob)
            end
          end
        end
      end
      if @adjustment_line_count == 1
        svc_line_count = ServicePaymentEob.count("insurance_payment_eob_id = #{insurance_eob.id}")
        if svc_line_count <= 1
          @error_message = "There is no normal service line when adjustment line is present for an EOB with Patient Acc # : #{insurance_eob.patient_account_number}."
          logger.error @error_message
          raise ActiveRecord::Rollback
        end
      elsif @adjustment_line_count > 1
        @error_message = "There are more than one adjustment line for an EOB with Patient Acc #  : #{insurance_eob.patient_account_number}."
        logger.error @error_message
        raise ActiveRecord::Rollback
      end
    end
    create_interest_service_line(insurance_eob)
    min_date_from_svc.compact.sort!.first unless min_date_from_svc.blank?
  end


  def create_interest_service_line(insurance_eob)
    unless insurance_eob.blank?
      interest = !insurance_eob.claim_interest.to_f.zero?
      interest_applicable_and_exists = @facility.details[:interest_in_service_line] && interest
      if interest_applicable_and_exists
        if !@interest_service_line_id.blank?
          service_line = ServicePaymentEob.find(@interest_service_line_id)
        else
          service_line = ServicePaymentEob.new
          service_line.insurance_payment_eob = insurance_eob
          service_line.save
        end
        service_line.update_attributes(service_line.prepare_interest_svc_line(@batch, @facility))
        if !service_line.service_procedure_charge_amount.blank?
          @total_charge = @total_charge.to_f + service_line.service_procedure_charge_amount.to_f
        end
        if !service_line.service_paid_amount.blank?
          @total_payment = @total_payment.to_f + service_line.service_paid_amount.to_f
        end
      end
    end
  end

  # Validates the service line
  # Input :
  # serial_number : Service Line serial number
  # patient_account_number : patient_account_number
  # Output :
  # True if valid else false
  def validate_service_line(serial_number, patient_account_number)
    set_service_line_adjustment_amounts(serial_number)
    svc_line_exists = params[:lineinformation]["charges" + serial_number.to_s]
    if !params[:lineinformation].blank? && svc_line_exists
      svc_date_from = format_service_date(params[:lineinformation]["dateofservice_from" + serial_number.to_s], @facility.default_service_date)
      svc_allowable = params[:lineinformation]["allowable" + serial_number.to_s]
      svc_payment = params[:lineinformation]["payment" + serial_number.to_s]
     
      adjustment_line_number = adjustment_line_number(serial_number)
      is_adjustment_line = !adjustment_line_number.blank?
      if is_adjustment_line
        is_adjustment_line_valid = is_adjustment_line_valid?(adjustment_line_number)
        if !is_adjustment_line_valid
          @error_message = "The adjustment line is not valid for an EOB with Patient Acc # : #{patient_account_number}."
          logger.error @error_message
          raise ActiveRecord::Rollback
        end
      end
      if is_adjustment_line
        @adjustment_line_count += 1        # Counting Adjustment Line
      end
      
      svc_date_from_applicable = @facility.details[:service_date_from]
      if !svc_date_from.blank?
        result = true
      elsif !svc_date_from_applicable && (!svc_allowable.blank? || !svc_payment.blank?)
        result = true
      elsif is_adjustment_line && is_adjustment_line_valid
        result = true                      # Validating Adjustment Line
      else
        result = false
      end
      if !@facility.details[:service_date_from].blank? && !is_adjustment_line && !is_adjustment_line_valid
        if svc_date_from.blank?
          result = false
        end
      end
    end
    logger.debug "validation result of service line #{serial_number} : #{result}"
    result
  end

  def save_service_line(service_payment_eob, serial_number, insurance_eob)
    logger.debug "Saving service line serial number : #{serial_number}"
    set_service_line_dates_charge_payment_cpt_code(insurance_eob, service_payment_eob, serial_number)
    set_service_line_other_attributes(service_payment_eob, serial_number)
    set_ansi_remark_code(service_payment_eob, serial_number)
    set_service_line_adjustments(service_payment_eob)
    adjustment_reason_and_code_ids = save_adjustment_codes(serial_number)
    if(!params[:mpi_selected_or_not].blank?)
      service_payment_eob.claim_service_information_id = "" unless (params[:mpi_selected_or_not] ==1)
    end
    set_allowance_capitation_inpatient_outpatient_codes(insurance_eob, service_payment_eob, serial_number)
    if !service_payment_eob.blank?
      service_payment_eob.insurance_payment_eob = insurance_eob
      if(!params[:mpi_selected_or_not].blank?)
        service_payment_eob.claim_service_information_id = "" unless (params[:mpi_selected_or_not] == 1)
      else
        service_payment_eob.claim_service_information_id  =  params[:lineinformation]["claim_information_id" + serial_number.to_s] unless (params[:lineinformation]["claim_information_id" + serial_number.to_s].blank?)
      end
      service_payment_eob.save
      @entity = service_payment_eob
      if adjustment_reason_and_code_ids.present?
        @reason_code_for_image_aggregate << adjustment_reason_and_code_ids[0][1] unless adjustment_reason_and_code_ids[0].blank?
        save_secondary_reason_code_ids(adjustment_reason_and_code_ids)
      end
    end
    if service_payment_eob.interest_service_line?(@previous_claim_interest)
      @interest_service_line_id ||= service_payment_eob.id
    end
  end

  def set_service_line_dates_charge_payment_cpt_code(insurance_eob, service_payment_eob, serial_number)
    service_from_date = params[:lineinformation]["dateofservice_from" + serial_number.to_s]
    service_to_date = params[:lineinformation]["dateofservice_to" + serial_number.to_s]
    charge_amount = params[:lineinformation]["charges" + serial_number.to_s]
    paid_amount = params[:lineinformation]["payment" + serial_number.to_s]
    patient_responsibility_amount = params[:lineinformation]["patient_responsibility" + serial_number.to_s]
    default_service_date = @facility.default_service_date
    if @facility.details[:service_date_from]
      service_from_date = format_service_date(service_from_date, default_service_date)
      service_to_date = format_service_date(service_to_date, default_service_date)
    end

    if (!insurance_eob? && !@facility.details[:simplified_patpay_multiple_service_lines])
      insurance_eob.claim_from_date = service_from_date
      insurance_eob.claim_to_date = service_to_date
      insurance_eob.total_submitted_charge_for_claim = normalize_amount(charge_amount)
      insurance_eob.total_amount_paid_for_claim = normalize_amount(paid_amount)
      insurance_eob.total_patient_responsibility = normalize_amount(patient_responsibility_amount)
      insurance_eob.total_service_balance = 0
    end
    service_payment_eob.date_of_service_from = service_from_date
    service_payment_eob.date_of_service_to = service_to_date
    service_payment_eob.service_procedure_charge_amount = normalize_amount(charge_amount)
    service_payment_eob.service_paid_amount = normalize_amount(paid_amount)
    service_payment_eob.patient_responsibility = normalize_amount(patient_responsibility_amount)
    if !service_payment_eob.service_procedure_charge_amount.blank?
      @total_charge = @total_charge.to_f + service_payment_eob.service_procedure_charge_amount.to_f
    end
    
    if !service_payment_eob.service_paid_amount.blank?
      @total_payment = @total_payment.to_f + service_payment_eob.service_paid_amount.to_f
    end
    
  end

  def set_service_line_other_attributes(service_payment_eob, serial_number)
    procedure_code = params[:lineinformation]["procedure_code" + serial_number.to_s]
    cdt_qualifier = params[:lineinformation]["cdt_qualifier_" + serial_number.to_s]
    tooth_number = params[:lineinformation]["tooth_number" + serial_number.to_s]
    bundled_procedure_code = params[:lineinformation]["bundled_procedure_code" + serial_number.to_s]
    revenue_code = params[:lineinformation]["revenue_code"+ serial_number.to_s]
    rx_number = params[:lineinformation]["rx_number"+ serial_number.to_s]
    modifier1 = params[:lineinformation]["modifier1" + serial_number.to_s]
    modifier2 = params[:lineinformation]["modifier2" + serial_number.to_s]
    modifier3 = params[:lineinformation]["modifier3" + serial_number.to_s]
    modifier4 = params[:lineinformation]["modifier4" + serial_number.to_s]
    quantity = params[:lineinformation]["units" + serial_number.to_s]
    allowable = params[:lineinformation]["allowable" + serial_number.to_s]
    expected_payment = params[:lineinformation]["expected_payment" + serial_number.to_s]
    balance = params[:lineinformation]["balance" + serial_number.to_s]
    procedure_code_type = params[:lineinformation]["code_type" + serial_number.to_s]
    provider_control_number =  params[:lineinformation]["provider_control_number" + serial_number.to_s]
    drg_amount = params[:lineinformation]["drg_amount" + serial_number.to_s]
    retention_fees = params[:lineinformation]["retention_fees" + serial_number.to_s]
    plan_coverage = params[:lineinformation]["plan_coverage" + serial_number.to_s]
    line_item_number = params[:lineinformation]["line_item_number" + serial_number.to_s]
    pbid = params[:lineinformation]["pbid" + serial_number.to_s]
    payment_status_code = params[:lineinformation]["payment_status_code" + serial_number.to_s]
    miscellaneous_balance = params[:lineinformation]["miscellaneous_balance" + serial_number.to_s]

    service_payment_eob.service_procedure_code = format_ui_param(procedure_code)
    service_payment_eob.service_cdt_qualifier = format_ui_param(cdt_qualifier)
    service_payment_eob.bundled_procedure_code = format_ui_param(bundled_procedure_code)
    service_payment_eob.revenue_code = format_ui_param(revenue_code)
    service_payment_eob.rx_number = format_ui_param(rx_number)
    service_payment_eob.service_modifier1 = format_ui_param(modifier1)
    service_payment_eob.service_modifier2 = format_ui_param(modifier2)
    service_payment_eob.service_modifier3 = format_ui_param(modifier3)
    service_payment_eob.service_modifier4 = format_ui_param(modifier4)
    service_payment_eob.tooth_number = format_ui_param(tooth_number)
    service_payment_eob.service_quantity = quantity.blank? ? '1.0' : quantity.to_f.to_s
    service_payment_eob.service_allowable = normalize_amount(allowable)
    service_payment_eob.expected_payment = normalize_amount(expected_payment)

    service_payment_eob.service_balance = normalize_amount(balance)
    service_payment_eob.procedure_code_type = format_ui_param(procedure_code_type)
    service_payment_eob.service_provider_control_number =  format_ui_param(provider_control_number)
    service_payment_eob.drg_amount = normalize_amount(drg_amount)
    service_payment_eob.retention_fees = normalize_amount(retention_fees)
    service_payment_eob.service_plan_coverage = format_ui_param(plan_coverage)
    service_payment_eob.line_item_number = format_ui_param(line_item_number)
    service_payment_eob.pbid = format_ui_param(pbid)
    service_payment_eob.payment_status_code = format_ui_param(payment_status_code)
    service_payment_eob.miscellaneous_balance = normalize_amount(miscellaneous_balance)

    if !service_payment_eob.pbid.blank?
      @total_pbid = @total_pbid.to_f + service_payment_eob.pbid.to_f
    end
    if !service_payment_eob.service_allowable.blank?
      @total_allowable = @total_allowable.to_f + service_payment_eob.service_allowable.to_f
    end
    if !service_payment_eob.drg_amount.blank?
      @total_drg_amount = @total_drg_amount.to_f + service_payment_eob.drg_amount.to_f
    end
    if !service_payment_eob.expected_payment.blank?
      @total_expected_payment = @total_expected_payment.to_f + service_payment_eob.expected_payment.to_f
    end
    if !service_payment_eob.retention_fees.blank?
      @total_retention_fees = @total_retention_fees.to_f + service_payment_eob.retention_fees.to_f
    end
    if !service_payment_eob.miscellaneous_balance.blank?
      @total_miscellaneous_balance = @total_miscellaneous_balance.to_f + service_payment_eob.miscellaneous_balance.to_f
    end

  end

  # Set the adjustment amount values of a service line in a hash
  # Input :
  # serial_number : Service Line serial number
  # Output :
  # @adjustment_amounts : A hash containing all the adjustment amount values
  def set_service_line_adjustment_amounts(serial_number)
    non_covered = params[:lineinformation]["non_covered" + serial_number.to_s]
    denied = params[:lineinformation]["denied" + serial_number.to_s]
    discount = params[:lineinformation]["discount" + serial_number.to_s]
    contractual_amount = params[:lineinformation]["contractual" + serial_number.to_s]
    co_insurance = params[:lineinformation]["co_insurance_id" + serial_number.to_s]
    deductible = params[:lineinformation]["deductable" + serial_number.to_s]
    co_pay = params[:lineinformation]["copay" + serial_number.to_s]
    primary_payment = params[:lineinformation]["primary_pay_payment" + serial_number.to_s]
    prepaid = params[:lineinformation]["prepaid" + serial_number.to_s]
    patient_responsibility = params[:lineinformation]["patient_responsibility" + serial_number.to_s]
    miscellaneous_one = params[:lineinformation]["miscellaneous_one" + serial_number.to_s]
    miscellaneous_two = params[:lineinformation]["miscellaneous_two" + serial_number.to_s]

    @adjustment_amounts = {
      :noncovered => format_amount_ui_param(non_covered),
      :denied => format_amount_ui_param(denied),
      :discount => format_amount_ui_param(discount),
      :contractual => format_amount_ui_param(contractual_amount),
      :coinsurance => format_amount_ui_param(co_insurance),
      :deductible => format_amount_ui_param(deductible),
      :copay => format_amount_ui_param(co_pay),
      :primary_payment => format_amount_ui_param(primary_payment),
      :prepaid => format_amount_ui_param(prepaid),
      :patient_responsibility => format_amount_ui_param(patient_responsibility),
      :miscellaneous_one => format_amount_ui_param(miscellaneous_one),
      :miscellaneous_two => format_amount_ui_param(miscellaneous_two)
    }

  end

  # Set the adjustment amount values of a service line in the ServicePaymentEob object
  # Input :
  # service_payment_eob : ServicePaymentEob object
  def set_service_line_adjustments(service_payment_eob)
    service_payment_eob.service_no_covered = @adjustment_amounts[:noncovered]
    service_payment_eob.denied = @adjustment_amounts[:denied]
    service_payment_eob.service_discount = @adjustment_amounts[:discount]
    service_payment_eob.contractual_amount = @adjustment_amounts[:contractual]
    service_payment_eob.service_co_insurance = @adjustment_amounts[:coinsurance]
    service_payment_eob.service_deductible = @adjustment_amounts[:deductible]
    service_payment_eob.service_co_pay = @adjustment_amounts[:copay]
    service_payment_eob.primary_payment = @adjustment_amounts[:primary_payment]
    service_payment_eob.service_prepaid = @adjustment_amounts[:prepaid]
    service_payment_eob.patient_responsibility = @adjustment_amounts[:patient_responsibility]
    service_payment_eob.miscellaneous_one_adjustment_amount = @adjustment_amounts[:miscellaneous_one]
    service_payment_eob.miscellaneous_two_adjustment_amount = @adjustment_amounts[:miscellaneous_two]

    if !service_payment_eob.service_no_covered.blank?
      @total_non_covered = @total_non_covered.to_f + service_payment_eob.service_no_covered.to_f
    end
    if !service_payment_eob.denied.blank?
      @total_denied = @total_denied.to_f + service_payment_eob.denied.to_f
    end
    if !service_payment_eob.service_discount.blank?
      @total_discount = @total_discount.to_f + service_payment_eob.service_discount.to_f
    end
    if !service_payment_eob.service_co_insurance.blank?
      @total_coinsurance = @total_coinsurance.to_f + service_payment_eob.service_co_insurance.to_f
    end
    if !service_payment_eob.service_deductible.blank?
      @total_deductible = @total_deductible.to_f + service_payment_eob.service_deductible.to_f
    end
    if !service_payment_eob.service_co_pay.blank?
      @total_copay = @total_copay.to_f + service_payment_eob.service_co_pay.to_f
    end
    if !service_payment_eob.primary_payment.blank?
      @total_primary_payment = @total_primary_payment.to_f + service_payment_eob.primary_payment.to_f
    end
    if !service_payment_eob.service_prepaid.blank?
      @total_prepaid = @total_prepaid.to_f + service_payment_eob.service_prepaid.to_f
    end

    if !service_payment_eob.patient_responsibility.blank?
      @total_patient_responsibility = @total_patient_responsibility.to_f + service_payment_eob.patient_responsibility.to_f
    end

    if !service_payment_eob.contractual_amount.blank?
      @total_contractual = @total_contractual.to_f + service_payment_eob.contractual_amount.to_f
    end

    if !service_payment_eob.miscellaneous_one_adjustment_amount.blank?
      @total_miscellaneous_one = @total_miscellaneous_one.to_f + service_payment_eob.miscellaneous_one_adjustment_amount.to_f
    end

    if !service_payment_eob.miscellaneous_two_adjustment_amount.blank?
      @total_miscellaneous_two = @total_miscellaneous_two.to_f + service_payment_eob.miscellaneous_two_adjustment_amount.to_f
    end

    @amount_value_for_adjustment_reason = { :coinsurance => service_payment_eob.service_co_insurance,
      :copay => service_payment_eob.service_co_pay,
      :contractual => service_payment_eob.contractual_amount,
      :deductible => service_payment_eob.service_deductible,
      :denied => service_payment_eob.denied,
      :discount => service_payment_eob.service_discount,
      :noncovered => service_payment_eob.service_no_covered,
      :primary_payment => service_payment_eob.primary_payment,
      :prepaid => service_payment_eob.service_prepaid,
      :patient_responsibility => service_payment_eob.patient_responsibility,
      :miscellaneous_one => service_payment_eob.miscellaneous_one_adjustment_amount,
      :miscellaneous_two => service_payment_eob.miscellaneous_two_adjustment_amount}
    @entity = service_payment_eob
  end

  def set_allowance_capitation_inpatient_outpatient_codes(insurance_eob, service_payment_eob, serial_number)
    allowance_code = ""
    patient_type = insurance_eob.patient_type
    allowance_code = "1" if(params[:lineinformation]["allowance_code" + serial_number.to_s] == "on")
    if(params[:lineinformation]["capitation_code" + serial_number.to_s] == "on")
      capitation_code = "2"
      if(allowance_code != "")
        allowance_code = allowance_code + "," + capitation_code
      else
        allowance_code = capitation_code
      end
    end
    if(patient_type == "INPATIENT")
      service_payment_eob.inpatient_code = allowance_code
    elsif(patient_type == "OUTPATIENT")
      service_payment_eob.outpatient_code = allowance_code
    end
  end

  def create_eob_reason_code_records insurance_eob
    records_to_create = []
    reason_code_ids =  get_reason_code_ids_in_eob(insurance_eob)
    logger.debug "reason_code_ids :#{reason_code_ids}"
    record_hash = frame_hash_with_reason_code_page_no
    logger.debug "record_hash : #{record_hash}"
    unless reason_code_ids.blank?
      reason_code_ids.each do |rc_id|
        logger.debug "rc_id :#{rc_id}"
        unless record_hash.blank?
          if record_hash.has_key?(rc_id)
            records_to_create << EobReasonCode.new(:reason_code_id => rc_id, :insurance_payment_eob_id => insurance_eob.id, :page_no => record_hash[rc_id], :job_id => @job.id)
          end
        end
      end
    end
    bulk_create_records_in_eob_rc records_to_create
  end

  def bulk_create_records_in_eob_rc records_to_create
    EobReasonCode.import(records_to_create) unless records_to_create.blank?
  end

  def get_reason_code_ids_in_eob insurance_eob
    reason_code_ids = []
    service_lines = ServicePaymentEob.where(:insurance_payment_eob_id => insurance_eob.id )
    service_lines.each do |service_line|
      reason_code_ids << service_line.get_primary_reason_code_ids_of_svc.compact.uniq
    end

    reason_code_ids << insurance_eob.get_primary_reason_code_ids_of_eob
    unless @reason_code_for_image_aggregate.blank?
      reason_code_ids << @reason_code_for_image_aggregate
    end
    reason_code_ids.flatten.compact.uniq unless reason_code_ids.blank?
  end

  def frame_hash_with_reason_code_page_no

    job = @job
    parent_job_exists = !job.parent_job_id.blank?

    if parent_job_exists
      jobid =  job.parent_job_id
    else
      child_job_exists = Job.exists?(:parent_job_id => job.parent_job_id)
      jobid = job.id if child_job_exists
    end

    unless jobid.blank?
      job_ids = Job.where(:parent_job_id => jobid).map(&:id)
      job_ids << jobid
    end
    job_ids = job_ids.compact.uniq unless job_ids.blank?
    record_hash = {}
    unless job_ids.blank?
      eob_reason_codes = EobReasonCode.where(" job_id in (?)", job_ids)
      unless eob_reason_codes.blank?
        eob_reason_codes.each do |eob_rc|
          record_hash[eob_rc.reason_code_id] = eob_rc.page_no
        end
      end
    end
    record_hash
  end

  def update_eob_reason_codes_for_qa_view insurance_eob

    eob_rc_records = EobReasonCode.where( :insurance_payment_eob_id => insurance_eob.id )
    eob_rc_ids = eob_rc_records.map(&:reason_code_id) unless eob_rc_records.blank?
    record_hash = frame_hash_with_reason_code_page_no
    reason_code_ids =  get_reason_code_ids_in_eob(insurance_eob)
    records_to_create =  create_records_for_new_rc_added_in_qa_view reason_code_ids, eob_rc_ids, record_hash, insurance_eob
    delete_unused_rc_from_eob_rc eob_rc_ids, reason_code_ids, insurance_eob
    bulk_create_records_in_eob_rc records_to_create
  end

  def create_records_for_new_rc_added_in_qa_view reason_code_ids, eob_rc_ids, record_hash, insurance_eob
    records_to_create = []
    if !reason_code_ids.blank?
      reason_code_ids.each do |rc_id|
        unless eob_rc_ids.blank? && record_hash.blank?
          if (!eob_rc_ids.include?(rc_id)) &&  (record_hash.has_key?(rc_id))
            records_to_create << EobReasonCode.new(:reason_code_id => rc_id, :insurance_payment_eob_id => insurance_eob.id, :page_no => record_hash[rc_id], :job_id => @job.id)
          end
        end
      end
    else
      EobReasonCode.destroy_all(:insurance_payment_eob_id => insurance_eob.id)
    end
    records_to_create
  end

  def delete_unused_rc_from_eob_rc eob_rc_ids, reason_code_ids, insurance_eob
    unless eob_rc_ids.blank? && reason_code_ids.blank?
      eob_rc_ids.each do |eob_rc_id|
        unless reason_code_ids.include?(eob_rc_id)
          EobReasonCode.destroy_all(:reason_code_id => eob_rc_id, :insurance_payment_eob_id => insurance_eob.id)
        end
      end
    end
  end

  def set_ansi_remark_code(entity, svc_line_serial_num = nil)
    if svc_line_serial_num && params[:lineinformation]
      remark_codes = params[:lineinformation]["remark_code" + svc_line_serial_num.to_s]
      charge_amount = entity.service_procedure_charge_amount.to_f
      payment_amount = entity.service_paid_amount.to_f
    elsif params[:claim_level]
      remark_codes = params[:claim_level]["remark_code"]
    end
    if !remark_codes.blank?
      remark_codes = remark_codes.split(':')
    else
      remark_codes = []
    end
    if svc_line_serial_num && params[:lineinformation]
      # ANSI Remark Code which indicates Zero Charge and Zero Payment Service Line
      zero_charge_and_payment_n365 = 'N365'
      if charge_amount.zero? && payment_amount.zero?
        remark_codes << zero_charge_and_payment_n365
      else
        remark_codes = remark_codes.delete_if {|code| code == zero_charge_and_payment_n365 }
      end
    end
    
    remark_codes = remark_codes.compact.uniq
    remark_code_objects = AnsiRemarkCode.find_all_by_adjustment_code(remark_codes)
    entity.ansi_remark_codes = remark_code_objects
    @remark_code_adjustment_codes << remark_code_objects.map(&:adjustment_code)
  end

  # This method fires the MPI search query for patient pay accounts
  # As a first step, MPI search params are retrieved from cookies
  # will_paginate plugin is used to restrict the no of results shown on the UI and also to get only x records, x being the no. of records per page, at a time from the server
  # As the user moves from one age to another, the results corresponding to that page are fetched from the server cache
  def mpi_search_patpay_NON_SPHNIX
    patpay_account_number = cookies[:patpay_account_number]
    unless patpay_account_number.nil?
      conditions = []
      conditions << "facility_id = #{@facility.id}" if @facility.mpi_search_type.eql?("FACILITY")
      conditions << "client_id = #{@client.id}" if @facility.mpi_search_type.eql?("CLIENT")
      conditions << "and patient_account_number like '%#{patpay_account_number}%'"
      mpi_conditions = conditions.join(" ")
      p mpi_conditions
      @patpay_mpi_results = ClaimInformation.paginate(:all,:conditions => mpi_conditions, :per_page => 10,:page => params[:page])
    end
  end

  def mpi_search_patpay
    return (Rails.env.production? ? mpi_search_patapy_sphinx : mpi_search_patpay_NON_SPHNIX)
  end


  def mpi_search_patapy_sphinx
    job = @job || Job.find(params[:job_id])
    patpay_account_number = cookies[:patpay_account_number]

    begin

      raise "No filter to do MPI search!" if patpay_account_number.nil? or patpay_account_number.blank?

      mpi_conditions = []
      condition_list = []
      condition_list << "("
      condition_list << "@patient_account_number #{Riddle.escape(patpay_account_number)}"
      condition_list << ")"
      mpi_conditions = condition_list.join(" ")
      if( @facility.mpi_search_type.eql?("FACILITY"))
        sort = {:facility_id => "#{@facility.id}"}
      elsif(@facility.mpi_search_type.eql?("CLIENT"))
        sort = {:client_id => "#{@facility.client.id}"}
      end
      @patpay_mpi_results = ClaimInformation.search mpi_conditions,
        :per_page => 15, :page => params[:page],:with => sort,
        :start => true, :match_mode => :boolean,
        :index => get_mpi_index_name,
        :classes => [ClaimInformation], :populate => true

      @patpay_mpi_results.compact!
    end
  end

  #'Insurance eob update' is using update insurance eob from QA side.There are two  buttons for this.
  # If select  'INCOMPLETE'  from the list box and clicked 'Update Job', marked that job as incomplete.
  # QA comment and qa id saved in both insurance and job table,ie save qa status and job status  as INCOMPLETED.
  # If select 'COMPLETE' from the list box  and clicked 'Update Job'  save that job as complete,change processor and job status as COMPLETED.
  # qa comment and qa id saved in both insurance and job table,ie save qa status and job satatus  as COMPLETED .
  #After job complete ,next job will automatically comes in the qa view.
  # If button 'SAVE EOB' clicked update that eob in the  'insurance_payment_eobs' table.
  # qa comment and qa id saved in  insurance  table.
  # It aslo save check level information,ie if provider adjustment amout proeset it will update in this function.
  # if 'Save Eob' clicked update patient pay eob and check information table.
  # In this fuction it checks if QA selects error type.


  def insurance_eob_save_update
    @qa_edit = QaEdit.new
    @qa_edit.qa_user_id = @current_user.id if @current_user.has_role?(:qa)
    #    @qa_edit.client_name = @client_name
    @qa_edit.insurance_eob_id = params[:insurance_id] if !params[:insurance_id].blank?
    @qa_edit.insurance_eob_id = params[:orbo_correspondance][:eob_id] unless (params[:orbo_correspondance].blank? && params[:eob_id].blank?)
    if !params[:patient_pay_eob].blank? && !params[:patient_pay_eob][:eob_id].blank?
      @qa_edit.next_gen_eob_id = params[:patient_pay_eob][:eob_id]
    end
    params[:mode] = nil
    @payer = @check_information.payer
    parent_job_id = @parent_job_id_or_id
    is_parent_job_id_present = !@job.parent_job_id.blank?
    view = ((params[:view].nil?) ?  "" : params[:view])
    params[:view] = view
    if !params[:payer].blank?
      payer_address_fields = {
        :address_one => params[:payer][:pay_address_one].to_s,
        :city => params[:payer][:payer_city].to_s,
        :state => params[:payer][:payer_state].to_s,
        :zip_code => params[:payer][:payer_zip].to_s
      }
    end

    if (params[:option1] == 'Delete EOB' || params[:option1] == 'DELETE EOB')
      if (params[:option1] == 'Delete EOB')
        eobs = InsurancePaymentEob.select("id, patient_account_number").where(:id => params[:insurance_id])
        eob = eobs.first
        if !eob.blank?
          JobActivityLog.delete_all(:eob_id => eob.id, :eob_type_id => '1')
          ImageType.delete_all(:insurance_payment_eob_id => eob.id)
          JobActivityLog.create_activity({:job_id => @job.id, :processor_id => @current_user.id,
              :activity => 'EOB Deleted', :start_time => Time.now, :eob_type_id => 1,
              :object_name => 'insurance_payment_eobs', :field_name => 'patient_account_number',
              :old_value => eob.patient_account_number })
          parameters = { :entity => 'insurance_payment_eobs', :entity_id => eob.id,
            :client_id => @client.id, :facility_id => @facility.id }
          DeletedEntity.create_records(parameters, true)
          eob.destroy
        end
        @check_information.populate_report_check_informations(insurance_eob?, @batch.id, @parent_job.id, @facility)
        recalculate_transaction_type("delete_eob") if @facility.details[:transaction_type] == true && @client_name == "MEDISTREAMS"
      elsif (params[:option1] == 'DELETE EOB')
        if @orbograph_correspondence_condition
          eobs = InsurancePaymentEob.select("id, patient_account_number").where(:id => params[:orbo_correspondance][:eob_id])
          entity = 'insurance_payment_eobs'
        else
          eobs = PatientPayEob.select("id, account_number").where(:id => params[:patient_pay_eob][:eob_id])
          entity = 'patient_pay_eobs'
        end

        eob = eobs.first
        if !eob.blank?
          JobActivityLog.delete_all(:eob_id => eob.id, :eob_type_id => '1')
          if eob.class == InsurancePaymentEob
            JobActivityLog.create_activity({:job_id => @job.id, :processor_id => @current_user.id,
                :activity => 'EOB Deleted', :start_time => Time.now, :eob_type_id => 1,
                :object_name => 'insurance_payment_eobs', :field_name => 'patient_account_number',
                :old_value => eob.patient_account_number })
          elsif eob.class == PatientPayEob
            JobActivityLog.create_activity({:job_id => @job.id, :processor_id => @current_user.id,
                :activity => 'EOB Deleted', :start_time => Time.now, :eob_type_id => 2,
                :object_name => 'patient_pay_eobs', :field_name => 'patient_account_number',
                :old_value => eob.account_number })
          end
          parameters = { :entity => entity, :entity_id => eob.id,
            :client_id => @client.id, :facility_id => @facility.id }
          DeletedEntity.create_records(parameters, true)
          eob.destroy
        end
      end
      job_count = @job.count
      job_co = job_count - 1
      if(job_co == 0)
        @job.apply_to_all_claims = "0"
      end
      @job.count = job_count - 1
      @job.save
      if @check_information.any_eob_processed? == false
        @check_information.payment_method = nil
        @check_information.save
      end
      Batch.where(:id => @batch.id).update_all(:associated_entity_updated_at => Time.now)
      if @current_user.has_role?(:qa)
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id]
      else    # This occurs when Processor deletes a record in 'Processor view' or 'CompletedEOB view'
        if(@current_user.has_role?(:processor) &&  view !="qa" &&  view !="CompletedEOB")   # This occurs when Processor deletes a record in 'Processor view'
          page = Integer(params[:page]) if !params[:page].blank?
          page = page+1
          redirect_to :controller => 'insurance_payment_eobs',:action => 'show_eob_grid',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber], :page => page,:mode => params[:mode]
          # for qa s and processors in CompletedEOB view, redirect to claimqa page
        else  # This occurs when Processor deletes a record in 'CompletedEOB view'
          redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :view => view
        end
      end
    elsif(params[:option1] == 'SAVE EOB')
      # This occurs when QA updates an Insurance Payment EOB record in 'QA view'
      if !(params[:insurancepaymenteob]).blank?
        invoice_by = params[:insurancepaymenteob][:statement_receiver]  unless (params[:insurancepaymenteob][:statement_receiver]).blank?
      end
      if !validate_eob_correctness
        flash[:notice] = 'Please enter Incorrect Field Count OR Error Type.'
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id],:checknumber => params[:checknumber], :page => params[:page]
      else
        insurance_eob = InsurancePaymentEob.find(params[:insurance_id])

        to_proceed, statement_to_alert = validate_payer_address(payer_address_fields)
        validate_patient_address_flag, patient_address_alert = validate_patient_address(params[:patient], @facility_name)

        if not to_proceed
          flash[:notice] = statement_to_alert
          redirect_when_invalid_data_exists
        elsif not validate_patient_address_flag
          flash[:notice] = patient_address_alert
          redirect_when_invalid_data_exists
        else
          # This occurs when Processor saves a record in 'Processor view' or 'CompletedEOB view'
          invalid_reason_codes = validate_adjustment_codes
          if !invalid_reason_codes.blank?
            flash[:notice] = "The following unique codes are not associated with this job : #{invalid_reason_codes.join('; ')}"
            redirect_when_invalid_data_exists
          else
            to_proceed, statement_to_alert = validate_payment_method
            if not to_proceed
              flash[:notice] = statement_to_alert
              redirect_when_invalid_data_exists
            else
              insertdata(1)
             
              if !@error_message.blank?
                flash[:notice] = @error_message
                redirect_when_invalid_data_exists
              else
                update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
                if @current_user.has_role?(:qa)
                  eobupdate(insurance_eob)
                end
                #for processor in VERIFICATION mode, to update records, redirect to insurance_payment_eob partial
                if(@current_user.has_role?(:processor) &&  view !="qa" &&  view !="CompletedEOB")   # This occurs when Processor saves a record in 'Processor view'
                  page = Integer(params[:page]) if !params[:page].blank?
                  redirect_to :controller => 'insurance_payment_eobs', :action => 'show_eob_grid',:batch_id => params[:batch_id],:job_id => params[:job_id],:checknumber => params[:checknumber], :page => page, :mode => 'VERIFICATION'
                  # for qa s and processors in CompletedEOB view, redirect to claimqa page
                else  # This occurs when Processor saves a record in 'CompletedEOB view'
                  redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :view => view,:checknumber => params[:checknumber], :page => params[:page]
                end
              end
            end
          end
        end
      end
      #     This occurs when QA updates a Patient Payment EOB  or ORBO correspondance EOB record in 'QA view'
    elsif(params[:option1] == 'Save Eob')
      page = params[:page] || 1
      if !validate_eob_correctness
        flash[:notice] = 'Please enter Incorrect Field Count OR Error Type'
        redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa',
          :job_id => params[:job_id], :batch_id => @batch.id, :page => params[:page]
      else
        if(@orbograph_correspondence_condition)
          orbo_eob = InsurancePaymentEob.find(params[:orbo_correspondance][:eob_id]) unless (params[:orbo_correspondance][:eob_id]).blank?
          orbo_correspondance_eob_insert
          if @current_user.has_role?(:qa)
            eobupdate(orbo_eob)
          end
          update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
          if(params[:verify_grid] == '1')
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa',
              :job_id => params[:job_id], :batch_id => @batch.id, :checknumber => @check_information.check_number,:page => params[:page], :verify_grid => '1'
          else
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa',
              :job_id => params[:job_id], :batch_id => @batch.id, :page => params[:page]
        
          end
        else
          @check_information.update_attributes(params[:checkinforamation])
          @patient_pay_info = PatientPayEob.find(params[:patient_pay_eob][:eob_id])
          if @patient_pay_info.processor_id.present? && @current_user.id != @patient_pay_info.processor_id &&
              @current_user.has_role?(:processor)
            eob_rekeyed_by_another_processor = true
          end
          @patient_pay_info.assign_attributes(params[:patientpayeob], :without_protection => true)
          is_client_orbograph = Client.is_client_orbograph?(@client_name)
          if !is_client_orbograph
            @patient_pay_info.account_number = @patient_pay_info.normalize_account_number(@facility.details[:practice_id])
          end
          account_number_length = @patient_pay_info.account_number.length          
          if !is_client_orbograph && (account_number_length == 0 || account_number_length != 16)
            flash[:notice] = "Account Number should contain 16 digits."
            redirect_when_invalid_data_exists
          else
            transaction_date = ""
            if !params[:patient_pay_eob].blank? && !params[:patient_pay_eob][:transaction_date].blank?
              transaction_date = Date.rr_parse(params[:patient_pay_eob][:transaction_date], true)
            end
            @patient_pay_info.transaction_date = transaction_date
            @patient_pay_info.document_classification = params[:insurancepaymenteob][:document_classification] if !params[:insurancepaymenteob].blank?
            @patient_pay_info.save
            if eob_rekeyed_by_another_processor
              save_job_activity(@job.id, @patient_pay_info.id, @current_user.id, nil, "EOB Re-keyed", Time.now, nil, 2, true)
            end
            if @current_user.has_role?(:qa)
              eobupdate(@patient_pay_info)
            end
            update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa',
              :job_id => params[:job_id], :batch_id => params[:batch_id], :view => params[:view]
          end
        end
      end
    elsif(params[:option1] == 'Update Job')
      @offset_eob_flag = params[:flag_for_offset_eob]
      if @current_user.has_role?(:qa)
        eob = nil
        if !params[:insurance_id].blank?
          eob = InsurancePaymentEob.find(params[:insurance_id])
        elsif !params[:orbo_correspondance].blank? && !params[:orbo_correspondance][:eob_id].blank?
          eob = InsurancePaymentEob.find(params[:orbo_correspondance][:eob_id])
        elsif !params[:patient_pay_eob].blank? && !params[:patient_pay_eob][:eob_id].blank?
          eob = PatientPayEob.find(params[:patient_pay_eob][:eob_id])
        end
      end
      complete_job()
      save_user_id_for_eobs
      if(params[:status] == "Complete")
        if @facility.details[:interest_only_835] &&
            !params[:checkinforamation][:interest_only_check].blank?
          save_interest_only_check_details
        end

        unless params[:complete_processor_comment].blank?
          qa_comments = get_qa_comments(params[:complete_processor_comment], params[:complete_proc_comment_other])
          @job.qa_comment = qa_comments
        end
        
        if @orbograph_correspondence_condition
          eob = @check_information.insurance_payment_eobs unless @check_information.blank?
          @job.set_total_edited_fields(eob)
          complete_job_and_update_user(JobStatus::COMPLETED)
          @batch.update_status
          save_job_activity(@job.id, nil, nil, @current_user.id, "Job Completed", Time.now, nil, nil, true)
          redirect_to :controller => 'qa', :action => 'my_job'
        else

          insurance_eobs = @check_information.insurance_payment_eobs unless @check_information.blank?
          unless insurance_eobs.blank?
            @first_eob = insurance_eobs.first
            save_eob_id_in_provider_adjustment
          end
          @job.set_total_edited_fields(insurance_eobs)
          validate_doc_classification_flag = true
          validate_image_type_for_pages_flag = true
          is_partner_bac = $IS_PARTNER_BAC

          if @facility.details[:document_classification] &&
              @facility.details[:same_document_classification_within_a_job]
            if !insurance_eobs.blank?
              validate_doc_classification_flag = validate_doc_classification(insurance_eobs)
            else
              patient_pay_eob = @check_information.patient_pay_eobs unless @check_information.blank?
              if !patient_pay_eob.blank?
                validate_doc_classification_flag = validate_doc_classification(patient_pay_eob)
              end
            end
          end

          if is_partner_bac
            validate_image_type_for_pages_flag = validate_image_type_for_pages
            validate_image_type_for_pages_flag &&= validate_eob_image_types(insurance_eobs.count)
          end
          if params[:complete_button_flag] == 'true'
            unless insurance_eobs.blank?
              last_eob = insurance_eobs.last
            end
            @last_eob_page_number = last_eob.image_page_no unless last_eob.blank?
            @alternate_payer_name = last_eob.alternate_payer_name unless @job.apply_to_all_claims
            @multiple_eob = params[:complete_button_flag]
            create_interest_eob(insurance_eobs)
          end
          if(@offset_eob_flag == 'true' && is_parent_job_id_present == false )
            offset_eob = create_offset_eob
            insurance_eobs << offset_eob unless offset_eob.blank?
          end
          if @check_information.is_transaction_type_missing_check_or_check_only? || @check_information.is_check_balanced?(@job, @facility)
            if validate_image_type_for_pages_flag && validate_doc_classification_flag
              complete_job_and_update_user(JobStatus::COMPLETED)
              @batch.update_status
              save_job_activity(@job.id, nil, nil, @current_user.id, "Job Completed", Time.now, nil, nil, true)

              # This is a special scenario in VERIFICATION mode where EOBs
              # get spanned across pages in the image.
              # The OCR Engine may create more than 1 EOB in this case.
              # The patient account number of redundant EOBs will be blank.
              # This method deletes such EOBs.
              @job.delete_invalid_eobs(@check_information, @client.id, @facility.id)
              #This is to delete reason_code_jobs records which are not associated
              # to any of the eobs.
              unless is_parent_job_id_present

                delete_reason_code_jobs_records(insurance_eobs, parent_job_id)
                #This is to delete unused reason_code_setname_records
                dummy_reason_code_set_name = ReasonCodeSetName.find_by_name("JOB_#{parent_job_id}_SET")
                delete_reason_code_set_name(parent_job_id, dummy_reason_code_set_name.id) unless dummy_reason_code_set_name.blank?
                if (@client_name == "QUADAX")
                  is_system_generated_check_number = @check_information.is_check_number_in_auto_generated_format?(@check_information.check_number, @batch, false, true, false)
                  @check_information.auto_generate_check_number(@batch) if (!is_system_generated_check_number)
                elsif (@client_name == "BARNABAS" || @client_name == "ASCEND CLINICAL LLC" || @client_name == "PACIFIC DENTAL SERVICES")
                  @check_information.auto_generate_check_number(@batch)
                end
                recalculate_transaction_type("complete_job") if @facility.details[:transaction_type] == true && @client_name == "MEDISTREAMS"
              end
              redirect_to :controller => 'qa', :action => 'my_job'
            else
              redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id]
            end
          else
            flash[:notice] = "Check is not balanced."
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id]
          end
        end
      elsif(params[:status] == "Incomplete")

        eob = @check_information.insurance_payment_eobs unless @check_information.blank?
        unless insurance_eobs.blank? && !@orbograph_correspondence_condition
          @first_eob = eob.first
          save_eob_id_in_provider_adjustment
        end
        @job.set_total_edited_fields(eob)
        complete_job()
        unless params[:incomplete_processor_comment].blank?
          qa_comments = get_qa_comments(params[:incomplete_processor_comment], params[:incomplete_proc_comment_other])
          @job.rejected_comment = qa_comments
          @job.qa_comment = qa_comments
        end
        complete_job_and_update_user(JobStatus::INCOMPLETED)
        @batch.update_status

        unless is_parent_job_id_present
          @check_information.auto_generate_check_number(@batch) if (@client_name == "ASCEND CLINICAL LLC")
        end
        save_job_activity(@job.id, nil, nil, @current_user.id, "Job Incompleted", Time.now, nil, nil, true)
        redirect_to :controller => 'qa', :action => 'my_job'
      end
      # Updating insurance eob details using retrieval -> verification grid
    elsif(params[:option1] == 'Save')
      to_proceed, statement_to_alert = validate_payer_address(payer_address_fields)
      if not to_proceed
        flash[:notice] = statement_to_alert
        redirect_when_invalid_data_exists
      else
        invalid_reason_codes = validate_adjustment_codes
        if !invalid_reason_codes.blank?
          flash[:notice] = "The following unique codes are not associated with this job : #{invalid_reason_codes.join('; ')}"
          redirect_when_invalid_data_exists
        else
          insertdata(1)
          if !@error_message.blank?
            flash[:notice] = "EOB is not balanced"
            redirect_when_invalid_data_exists
          else
            update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
            client_activity(@check_information.id, params[:insurance_id], "Updated EOB via Image and Grid", params[:job_id])
            redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :verify_grid => 1, :page => params[:page]
          end
        end
      end
      # Updating patient pay eob details using retrieval -> verification grid
    elsif(params[:option1] == 'SAVE')
      @check_information.update_attributes(params[:checkinforamation])
      @patient_pay_info = PatientPayEob.find(params[:patient_pay_eob][:eob_id])
      if @patient_pay_info.processor_id.present? && @current_user.id != @patient_pay_info.processor_id &&
          @current_user.has_role?(:processor)
        eob_rekeyed_by_another_processor = true
      end
      @patient_pay_info.assign_attributes(params[:patientpayeob])
      is_client_orbograph = Client.is_client_orbograph?(@client_name)
      if !is_client_orbograph
        @patient_pay_info.account_number = @patient_pay_info.normalize_account_number(@facility.details[:practice_id])
      end
      account_number_length = @patient_pay_info.account_number.length
      if !is_client_orbograph && (account_number_length == 0 || account_number_length != 16)
        flash[:notice] = "Account Number should contain 16 digits."
      else
        @patient_pay_info.save
        update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
        if eob_rekeyed_by_another_processor
          save_job_activity(@job.id, @patient_pay_info.id, @current_user.id, nil, "EOB Re-keyed", Time.now, nil, 2, true)
        end
        client_activity(@check_information.id, params[:patient_pay_eob][:eob_id], "Updated EOB via Image and Grid", params[:job_id])
      end
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :verify_grid => 1
    elsif(params[:option1] == 'Mark for 835 Regeneration/Insurance Eob')
      client_activity(params[:checknumber],params[:eob_id],"Marked for 835 Regeneration",params[:job_id])
      @check_information.check_regenerate =1
      @check_information.check_regenerate_comment =params[:rejected_comments]
      @check_information.save
      @insurance_eob = InsurancePaymentEob.find(params[:insurance_id])
      @insurance_eob.eob_regenerate=1
      @insurance_eob.save
      update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
      flash[:notice] = 'Eob/check Marked.'
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :verify_grid => 1
    elsif(params[:option1] == 'Mark for 835 Regeneration/Patientpay Eob')
      client_activity(params[:checknumber],params[:eob_id],"Marked for 835 Regeneration",params[:job_id])
      @check_information.check_regenerate =1
      @check_information.save
      @patient_pay_info = PatientPayEob.find(params[:patient_pay_eob][:eob_id])
      @patient_pay_info.patient_pay_eob_regenerate=1
      @patient_pay_info.save
      update_job_and_batch_when_associated_entities_are_changed(@batch, @job)
      flash[:notice] = 'Eob/check Marked.'
      redirect_to :controller => 'insurance_payment_eobs', :action => 'claimqa', :job_id => params[:job_id], :batch_id => params[:batch_id], :verify_grid => 1
    end

  end

  # The method "eob update" is used to create EobQa's which describes the number of number errors made by a processor
  # along with details such as id of qa, time of rejection, error type made, comments made by qa,total number of fields processed etc.
  # This method calls a subroutine called save_job_activity which saves the details such as
  # job id, qa id , processor id, time of qa verification started.
  # It also saves the one the following status as provided by QA.
  # 1.QaStatus::COMPLETED
  # 2.QaStatus::REJECTED
  # 3.QaStatus::INCOMPLETED
  # This is called from method "insurance_eob_save_update".
  def eobupdate(eob_obj)
    job = @job
    unless eob_obj.nil?      
      error_records = get_user_entered_error_list
      if error_records.present?        
        error_record_ids = error_records.map(&:id)
        job_id =  job.get_parent_job_id
        existing_eob_qa_records = get_existing_eob_qa_records(error_record_ids, job_id, eob_obj.id)
        if existing_eob_qa_records.length > 0
          existing_eob_error_ids = existing_eob_qa_records.map(&:eob_error_id)
          error_record_ids_to_create = error_record_ids - existing_eob_error_ids
        else
          error_record_ids_to_create = error_record_ids
        end
        if error_record_ids_to_create.present?
          error_record_ids_to_create = error_record_ids_to_create.compact.uniq
          parameters = get_eob_qa_parameters(eob_obj, job_id)
          EobQa.initialize_and_create(error_record_ids_to_create, parameters)
        end
        save_eob_qa_job_activity(job, eob_obj)
      end
    end
  end

  # The method "complete_job"is used to create the eob reports for a particular completed job and each of its associalted eobs.
  #It saves the details such as processor id, qa id , number of fields processed,
  # number of incorrect fields , type of error made etc.
  # This is called from the method "insurance_eob_save_update".
  def complete_job
    @eobs = @job.eob_qas
    @eobs.each do |eob|
      if eob.prev_status != "old"
        EobReport.create(:verify_time => eob.time_of_rejection , :processor => @job.processor_id, :accuracy => eob.accuracy,
          :qa => @current_user.id, :batch_date => @job.batch.date, :total_fields => eob.total_fields,
          :incorrect_fields => eob.total_incorrect_fields, :error_type => eob.eob_error.error_type, :error_severity => eob.eob_error.severity,
          :error_code => eob.eob_error.code, :status => eob.status, :payer => eob.payer )
      end
      eob.prev_status = "old"
      eob.save
    end
  end



  def reasoncode_descriptions
    reason_code = params[:reason_code]
    if not(reason_code.blank?)
      @reason_codes = ReasonCode.find(:first,:conditions => "reason_code = '#{reason_code}'")
      unless @reason_codes.blank?
        render :text =>  @reason_codes.reason_code_description
      else
        render :text => " "
      end
    else
      render :text => " "
    end
  end

  def stop_allocate
    @current_user.auto_allocation_enabled = false
    @current_user.save(:validate => false)
    if params[:location] == 'grid'
      render :text => "You are Removed From Batch Allocation"
    elsif params[:location] == 'dashboard'
      flash[:notice] = "You are Removed From Batch Allocation"
      render 'dashboard/index', :layout => 'standard'
    end
  end

  def payer_informations
    payer = params[:payer]
    payer_based_informations = Payer.payer_details(payer, @client, @facility )
    render :text => payer_based_informations
  end

  def uploadfile
    @documents = DataFile.paginate(:all,:page => params[:page], :per_page => 30)
  end


  # This fuction mailny used for navicure's client grid.
  #  Navicure's client needs claim level information.
  # If there claim level informations  then  its also need cliam level reason code type ahead fuctionality.Auto complete fuctionality used here.
  # Navicure based clients need cliam level information only in some case.This fuction is used for that purpose.

  def navicure_claim_based_information(insurance_eob)
    unless params[:payercode].blank?
      claim_deductuble_key = params[:payercode].keys[0]
      claim_contractual_key = params[:payercode].keys[1]
      claim_copay_key = params[:payercode].keys[4]
      claim_coinsurance_key = params[:payercode].keys[5]
      claim_noncovered_key = params[:payercode].keys[6]
      claim_discount_key = params[:payercode].keys[10]
      claim_primary_key = params[:payercode].keys[12]
      copay_code = params[:payercode][claim_copay_key][:adjustment_code] if (!params[:payercode].blank? and !claim_copay_key.blank?)
      noncovered_code = params[:payercode][claim_noncovered_key][:adjustment_code] if (!params[:payercode].blank? and !claim_noncovered_key.blank?)
      deductuble_code = params[:payercode][claim_deductuble_key][:adjustment_code] if (!params[:payercode].blank? and !claim_deductuble_key.blank?)
      contractual_code = params[:payercode][claim_contractual_key][:adjustment_code] if (!params[:payercode].blank? and !claim_contractual_key.blank?)
      primary_code = params[:payercode][claim_primary_key][:adjustment_code] if (!params[:payercode].blank? and !claim_primary_key.blank?)
      discount_code = params[:payercode][claim_discount_key][:adjustment_code] if (!params[:payercode].blank? and !claim_discount_key.blank?)
      coinsurance_code = params[:payercode][claim_coinsurance_key][:adjustment_code] if (!params[:payercode].blank? and !claim_coinsurance_key.blank?)
    end

    insurance_eob.claim_noncovered_reasoncode = noncovered_code
    insurance_eob.claim_discount_reasoncode = discount_code
    insurance_eob.claim_contractual_reasoncode = contractual_code
    insurance_eob.claim_coinsurance_reasoncode = coinsurance_code
    insurance_eob.claim_deductable_reasoncode = deductuble_code
    insurance_eob.claim_copay_reasoncode = copay_code
    insurance_eob.claim_primary_payment_reasoncode= primary_code
  end

  def micrwise_payer_informations
    micr_information = params[:micr_information]
    unless micr_information.blank?
      micr_based_payer_informations = MicrLineInformation.micr_wise_payer_details(micr_information, @client, @facility)
      render :text => micr_based_payer_informations
    end
  end

  def capitation_account_save
    @capitation_account = CapitationAccount.new(params[:capitation_account])
    @check_information = CheckInformation.check_information(params[:job_id])
    @micr_line_information = @check_information.micr_line_information unless @facility.details[:micr_line_info].blank?
    if !(@check_information.payer).blank?
      @payer_name = @check_information.payer.payer
    elsif !@micr_line_information.blank?
      @payer_name = @micr_line_information.payer.payer unless (@micr_line_information.payer).blank?
    end
    batch = Batch.find(params[:batch_id])
    @capitation_account.payer_name = @payer_name
    @capitation_account.user_id = @current_user.id
    if batch.capitation_accounts << @capitation_account
      flash[:notice] = "Capitation Account Details Added"
    else
      flash[:notice] = "#{@capitation_account.errors.full_messages.join(", ")}"
    end
    redirect_to :back
  end

  def capitation_account_edit
    @capitation_account = CapitationAccount.find(params[:id])
    render :layout => "standard"
  end

  def capitation_account_update
    @capitation_account = CapitationAccount.find(params[:id])
    @capitation_account.update_attributes(params[:capitation_account])
    if @capitation_account
      flash[:notice] = "Capitation Account updated successfully"
      redirect_to :action => "capitation_account"
    else
      flash[:notice] = "#{@capitation_account.errors.full_messages.join(', ')}"
      redirect_to :back
    end
  end

  def capitation_account_delete
    if CapitationAccount.destroy params[:id]
      flash[:notice] = "Capitation Account details successfully deleted"
    else
      flash[:notice] = "Failed to delete capitation account details"
    end
    redirect_to :back
  end

  def capitation_account
    @search_field = params[:to_find]
    @compare = params[:compare]
    @criteria = params[:criteria]

    @search_field.strip! unless @search_field.nil?

    unless @search_field.blank?
      filtered_capitations = filtering_capitation(@criteria, @compare, @search_field)
      unless filtered_capitations.blank?
        @capitation_account = filtered_capitations.paginate :page => params[:page], :per_page => 30
      else
        flash[:notice] = " No record found for <i>#{@criteria} #{@compare} \"#{@search_field}\"</i>"
      end
    else
      if @current_user.has_role?(:processor)
        @capitation_account = @current_user.capitation_accounts.scoped.paginate(:page => params[:page])
      else
        @capitation_account = CapitationAccount.scoped.paginate(:page => params[:page])
      end

    end

    # For AJAX requests, render the partial and disable the layout
    if request.xml_http_request?
      render :partial => "capitation_account_list", :layout => false
    end
    render :layout => "standard"
  end

  def export_to_csv
    @search_field = params[:search_field]
    @compare = params[:compare]
    @criteria = params[:criteria]
    @search_field.strip! unless @search_field.nil?

    unless @search_field.blank?
      filtered_capitations = filtering_capitation(@criteria, @compare, @search_field)
      unless filtered_capitations.blank?
        @capitation_account = filtered_capitations
      end
    else
      if @current_user.has_role?(:processor)
        @capitation_account = @current_user.capitation_accounts
      else
        @capitation_account = CapitationAccount.all
      end
    end

    file_name = "capitation_account#{Time.now.strftime("%y_%h_%d_%H%M%S")}.csv"
    unless @capitation_account.blank?
      csv_string = CSV.generate do |csv|
        csv << ["BATCH DATE", "BATCH NUMBER", "CHECK NUMBER", "FIRST NAME",
          "LAST NAME", "MIDDLE INITIAL", "SUFFIX", "PAYERNAME", "ACCOUNT NO", "PAYMENT"]
        @capitation_account.each do |capitation_account|
          csv << [capitation_account.batch.date, capitation_account.batch.batchid.split("_").first,
            capitation_account.checknumber, capitation_account.patient_first_name,
            capitation_account.patient_last_name, capitation_account.patient_initial,
            capitation_account.patient_suffix, capitation_account.payer_name,
            capitation_account.account, capitation_account.payment]
        end
      end
      send_data csv_string, :type => "text/csv",
        :filename => file_name,
        :disposition => 'attachment'
    else
      flash[:notice] = "No matching Report Found To Export."
      redirect_to :action => "capitation_account"
    end

  end

  # This method saves reason codes which are both primary and secondary.
  # A primary reason code is the first reason code given to an adjustment reason for a service line.
  # A secondary reason code are the reason codes excluding the primary reason code of an adjustment reason for a service line.
  # The params[:reason_code_id] is a set of IDs of reason codes separated by ';' for each adjustment reason.
  # array_of_row_values : the values that should be saved in insurance_payment_eob_id or
  #  service_payment_eob_id, reason_code_id, adjustment_reason of
  #  insurance_payment_eobs_reason_codes or service_payment_eobs_reason_codes.
  # Input :
  # service_line_count : count of service lines of a service level EOB.
  # This will be nil for claim level EOB,as it contains only one service line.
  def save_adjustment_codes(service_line_count = nil)
    service_line_count = service_line_count.to_s
    adjustment_reason_and_code_ids = []
    if !@amount_value_for_adjustment_reason.blank?
      @entity.reason_codes.delete_all if @entity
      @amount_value_for_adjustment_reason.each do |adjustment_reason, amount|
        adjustment_reason = adjustment_reason.to_s
        reason_code_ids, hipaa_code_ids = get_reason_code_and_hipaa_code_ids(adjustment_reason, amount, service_line_count)
        unless @error_message.blank?
          return @error_message
        else
          adjustment_reason  = adjustment_reason.sub(/claim_/,'')
          
          if hipaa_code_ids.present?
            hipaa_code_id = hipaa_code_ids.first
          else
            hipaa_code_id = nil
          end
          build_reason_or_hipaa_code_ids(adjustment_reason, "hipaa_code_id", hipaa_code_id)

          if reason_code_ids.present?
            reason_code_id = reason_code_ids.first
          else
            reason_code_id = nil
          end

          @entity = build_reason_or_hipaa_code_ids(adjustment_reason, "reason_code_id",reason_code_id)
          if reason_code_ids.present?
            reason_code_ids.delete_at(0)
            if @facility.details[:multiple_reason_codes_in_adjustment_field] && reason_code_ids.present?
              reason_code_ids.each do |rc_id|
                if rc_id.present?
                  adjustment_reason_and_code_ids << [adjustment_reason, rc_id]
                end
              end
            end
          end
        end
      end
      adjustment_reason_and_code_ids
    end
  end

  # Provides the id of reason_code record for saving.
  # reason_code_ids are obtained from 2 ways,
  # 1. hidden fields of reason_code_ids
  # 2. search reason_codes by unique codes to obtain the id, if reason_code_ids are not set in the hidden fields
  # Input :
  # adjustment_reason : Amount field name Eg : denied, copay.
  # service_line_count : count of service lines of a service level EOB.
  # This will be nil for claim level EOB,as it contains only one service line.
  # Output :
  # reason_code_ids : IDs of reason code records associated with an adjustment reason in a service line
  def get_reason_code_and_hipaa_code_ids(adjustment_reason, amount, service_line_count = nil)
    hipaa_code_ids, reason_code_ids, unique_codes_array = [], [], []
    service_line_count = service_line_count.to_s
    reason  = adjustment_reason.sub(/claim_/,'')

    codes = params[:reason_code][(adjustment_reason + service_line_count).to_sym][:unique_code].to_s.strip if (!params[:reason_code].blank? &&
        !params[:reason_code][(adjustment_reason + service_line_count).to_sym].blank?)

    if codes.present?
      codes = codes.split(';').compact.uniq
    end

    if(amount.present? && @facility.details[:reason_code_mandatory] && codes.blank?)
      @error_message = "Please enter unique code for #{reason} amount "
      logger.error @error_message
      raise ActiveRecord::Rollback
      return @error_message
    elsif(@facility.details[:adjustment_amount_mandatory] && codes.present? && amount.blank?)
      @error_message = "Please enter amount for #{reason}"
      logger.error @error_message
      raise ActiveRecord::Rollback
      return @error_message
    else
      standard_hipaa_codes_hash = get_standard_hipaa_codes
      if codes.present?
        length_of_codes = codes.length
        count_of_hipaa_codes, count_of_reason_codes = 0, 0
        codes.each do | code |
          if standard_hipaa_codes_hash[code].present?
            hipaa_code_ids << standard_hipaa_codes_hash[code]
            count_of_hipaa_codes += 1
          else
            unique_codes_array << code
            count_of_reason_codes += 1
          end
        end
        if length_of_codes && length_of_codes > 1  &&
            (count_of_hipaa_codes > 0 || (count_of_reason_codes != 0 && count_of_hipaa_codes != 0))
          @error_message = "Please enter either all HIPAA Codes or all Reason Codes for #{adjustment_reason}"
          logger.error @error_message
          raise ActiveRecord::Rollback
          return @error_message
        end
        reason_code_ids = get_reason_code_ids(unique_codes_array)
      end
    end
    return reason_code_ids, hipaa_code_ids
  end

  # Provides the id of reason_code record for saving.
  # reason_code_ids are obtained from 2 ways,
  # 1. hidden fields of reason_code_ids
  # 2. search reason_codes by unique codes to obtain the id, if reason_code_ids are not set in the hidden fields
  # Input :
  # adjustment_reason : Amount field name Eg : denied, copay.
  # service_line_count : count of service lines of a service level EOB.
  # This will be nil for claim level EOB,as it contains only one service line.
  # Output :
  # reason_code_ids : IDs of reason code records associated with an adjustment reason in a service line
  def get_reason_code_ids(unique_codes)
    
    #      if !params[:reason_code_id].blank?
    #        reason_code_ids = params[:reason_code_id][(adjustment_reason + service_line_count).to_sym].to_s.strip
    #      end
    #
    #      if !reason_code_ids.blank? && @hash_for_replacing_unique_code.blank?
    #        reason_code_ids = reason_code_ids + ';'
    #        reason_code_ids = reason_code_ids.split(';').compact.uniq
    #        reason_code_ids.collect!{ |rc_id| rc_id.to_i}
    #      else
    if !unique_codes.blank?
      if !@hash_for_replacing_unique_code.blank?
        unique_codes.each_with_index do |unique_code, index|
          @hash_for_replacing_unique_code.each do |old_vlaue, new_value|
            if unique_code.to_s.upcase == old_vlaue.to_s.upcase # NOT HIPAA
              unique_codes[index] = new_value
            end
          end
        end
      end
      parent_job_id = @parent_job_id_or_id
      if !parent_job_id.blank? && !unique_codes.blank?
        reason_code_record_ids = []
        reason_code_records = ReasonCodesJob.get_valid_reason_codes parent_job_id
        unless reason_code_records.blank?
          unique_codes.each do |uc|
            reason_code_records.each do |rc|
              reason_code_record_ids << rc.id if rc.get_unique_code == uc.to_s.upcase
            end
          end
        end
        reason_code_record_ids
      end
    end
    #      end
  end

  # This method saves primary reason codes in the object of InsurancePaymentEob or ServicePaymentEob
  # Input :
  # adjustment_reason : Amount field names, Eg : copay, denied, etc
  # reason_code_id : ID of a reason code
  # Output :
  # @entity : object of InsurancePaymentEob or ServicePaymentEob
  # the method will take care of hipaa code and reason code generically
  def build_reason_or_hipaa_code_ids(adjustment_reason, type_id, id)
    adjustment_reasons = ["coinsurance","contractual","copay","deductible", "denied","discount","noncovered","primary_payment","prepaid","patient_responsibility","miscellaneous_one","miscellaneous_two"]
    if adjustment_reasons.include?adjustment_reason
      adjustment_reason = "pr" if adjustment_reason == "patient_responsibility"
      @entity.send(adjustment_reason+"_"+type_id+"=", id) 
    end
    @entity
  end
  
  # This method saves secondary reason codes in the InsurancePaymentEobReasonCodes or ServicePaymentEobReasonCodes
  # Input :
  # array_of_row_values : the values that should be saved in insurance_payment_eob_id or
  #  service_payment_eob_id, reason_code_id, adjustment_reason of
  #  insurance_payment_eobs_reason_codes or service_payment_eobs_reason_codes.
  def save_secondary_reason_code_ids(adjustment_reason_and_code_ids)
    if adjustment_reason_and_code_ids.present?
      @entity.reason_codes = []
      secondary_reason_code_records = []
      if @entity.class == ServicePaymentEob
        secondary_reason_code_class = ServicePaymentEobsReasonCode
        entity_id_attribute = 'service_payment_eob_id'
      elsif @entity.class == InsurancePaymentEob
        secondary_reason_code_class = InsurancePaymentEobsReasonCode
        entity_id_attribute = 'insurance_payment_eob_id'
      end
      adjustment_reason_and_code_ids.each do |adjustment_reason_and_code_id |
        if adjustment_reason_and_code_id.present? && adjustment_reason_and_code_id[0].present? &&
            adjustment_reason_and_code_id[1].present?
          attributes = { entity_id_attribute.to_sym => @entity.id, :reason_code_id => adjustment_reason_and_code_id[1],
            :adjustment_reason => adjustment_reason_and_code_id[0] }
          secondary_reason_code_records << secondary_reason_code_class.new(attributes)
        end
      end
      secondary_reason_code_class.import secondary_reason_code_records if secondary_reason_code_records.present?
    end
  end

  
  def delete_reason_code_jobs_records(insurance_payment_eobs, parent_job_id)
    reason_code_ids_of_eob_and_svc = []
    reason_code_ids_of_job = []
    rc_jobs_to_be_deleted = []
    reason_codes_jobs = ReasonCodesJob.find(:all,
      :conditions => ["parent_job_id = ?", parent_job_id])
    unless reason_codes_jobs.blank?
      reason_codes_jobs.each do |rc_job|
        reason_code_ids_of_job << rc_job.reason_code_id
      end
    end

    unless insurance_payment_eobs.blank?
      insurance_payment_eobs.each do |eob|
        reason_code_ids_of_eob_and_svc += eob.get_reason_code_ids_of_eob_and_svc_of_a_job
        reason_code_ids_of_eob_and_svc.uniq!
      end
    end

    unless reason_code_ids_of_job.blank?
      delete_reason_code_ids = reason_code_ids_of_job
      delete_reason_code_ids = reason_code_ids_of_job.delete_if { |value| reason_code_ids_of_eob_and_svc.include?(value)} unless reason_code_ids_of_eob_and_svc.blank?
      unless delete_reason_code_ids.blank?
        reason_codes_jobs.each do |reason_code_job|
          delete_reason_code_ids.each do |reason_code_id|
            rc_jobs_to_be_deleted << reason_code_job.id if reason_code_job.reason_code_id == reason_code_id
          end
        end
      end
      ReasonCodesJob.destroy(rc_jobs_to_be_deleted) unless rc_jobs_to_be_deleted.blank?
    end
  end

  #Delete unused reason_code_set_names records.
  def delete_reason_code_set_name(parent_job_id, rc_set_name_id)
    reason_code_ids_of_job = []
    reason_codes_jobs = ReasonCodesJob.where("parent_job_id = ?", parent_job_id)
    unless reason_codes_jobs.blank?
      reason_codes_jobs.each do |rc_job|
        reason_code_ids_of_job << rc_job.reason_code_id
      end
    end

    unless rc_set_name_id.blank?
      reason_code_record = ReasonCode.where("reason_codes.reason_code_set_name_id =? and reason_codes.id IN (?) ",
        rc_set_name_id, reason_code_ids_of_job) unless reason_code_ids_of_job.blank?

      if reason_code_record.blank?
        reason_code = ReasonCode.where("reason_codes.reason_code_set_name_id =?",
          rc_set_name_id)
        ReasonCode.delete_all "reason_codes.reason_code_set_name_id = #{rc_set_name_id}" if reason_code
        ReasonCodeSetName.destroy(rc_set_name_id)
      end
    end
  end
  def validate_check_date
    validate_check_date_flag = true
    validate_check_date_alert = nil
    check_date = params[:checkinforamation][:check_date]
    check_number =   params[:checkinforamation][:check_number]
    check_amount = params[:checkinforamation][:check_amount]
    if(!@facility.details[:transaction_type].blank?)
      is_check_no_blank = check_number.nil? || check_number == '' || check_number.match(/[^0]/).blank?
      is_checkamount = check_amount.to_f.zero?
      is_check_date_invalid = !check_date.nil? && (check_date == '' || check_date == 'mm/dd/yy' || check_date == 'MM/DD/YY')
      if  (is_check_no_blank == false && is_checkamount == false)
        if (is_check_date_invalid == true)
          validate_check_date_flag = false
          validate_check_date_alert = "The check is not correspondance,Please enter check date"
        end
      end
    end
    return validate_check_date_flag,validate_check_date_alert
  end

  def validate_payment_method
    to_proceed = nil
    statement_to_alert = nil
    is_client_ascend_clinical = (@client_name == "ASCEND CLINICAL LLC")
    is_client_quadax = (@client_name == "QUADAX")
    is_client_qsi = (@client_name == "PACIFIC DENTAL SERVICES")
    if @facility.details[:transaction_type].blank?
      if !params[:check].blank? && !params[:check][:payment_method].blank?
        payment_method = params[:check][:payment_method]
      elsif params[:check_information]
        payment_method = params[:check_information][:payment_method]
      end

      case payment_method
      when 'CHK'
        to_proceed, statement_to_alert = validate_for_payment_method_chk(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
      when 'OTH'
        to_proceed, statement_to_alert = validate_for_payment_method_chk(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
      when 'COR'
        to_proceed, statement_to_alert = validate_for_payment_method_cor(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
      when 'EFT'
        to_proceed, statement_to_alert = validate_for_payment_method_eft(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
      when 'ACH'
        to_proceed, statement_to_alert = validate_for_payment_method_eft(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
      else
        to_proceed = false
        statement_to_alert = 'Payment method is missing or invalid'
      end
    else
      to_proceed = true
    end
    return to_proceed, statement_to_alert
  end

  def save_transaction_type
    log.debug "\n\n Saving transaction type for Parent or Normal Job : #{@parent_job.id}"
    transaction_type = compute_transaction_type("save_eob")
    log.debug "transaction_type : #{transaction_type}"
    transaction_type = params[:images_for_jobs][:transaction_type] if transaction_type.blank? && !params[:images_for_jobs].blank?
    log.debug "transaction_type from DC grid: #{transaction_type}"
    @parent_job.images_for_jobs.update_all(:transaction_type => transaction_type) unless transaction_type.blank?
  end

  def recalculate_transaction_type( event )
    log.debug "\n\n Recalculating transaction type for Parent or Normal Job : #{@parent_job.id}"
    calculated_transaction_type = compute_transaction_type( event )
    log.debug "calculated_transaction_type : #{calculated_transaction_type}"
    saved_transaction_type = @parent_job.images_for_jobs[0].transaction_type
    log.debug "saved_transaction_type : #{saved_transaction_type}"
    unless saved_transaction_type == calculated_transaction_type
      @parent_job.images_for_jobs.update_all(:transaction_type => calculated_transaction_type) unless calculated_transaction_type.blank?
    end
  end

  def compute_transaction_type(event)
    log.debug "event : #{event}"
    eobs = @check_information.insurance_payment_eobs
    eob_with_service_line_exists = false
    eob_without_service_line_exists = false
    patient_pay = (@payer.payer_type == "PatPay") if @payer
    log.debug "patient_pay : #{patient_pay}"
    balance = get_job_level_balance(@check_information, @parent_job, @facility)
    log.debug "balance : #{balance}"
    log.debug "eob count : #{eobs.count if !eobs.blank?}"
    unless eobs.blank?
      eobs.each do |eob|
        if !eob.service_payment_eobs.blank?
          eob_with_service_line_exists = true
          break
        else
          eob_without_service_line_exists = true if(eob.category == "service")
        end
      end
    end
    log.debug "eob_without_service_line_exists : #{eob_without_service_line_exists}"
    micr_line_information = @check_information.micr_line_information
    payment_check = (!micr_line_information.blank? &&
        (@check_information.check_amount > 0 || @check_information.check_amount != 0))
    log.debug "payment_check : #{payment_check}"
    check_is_absent = (micr_line_information.blank? &&
        @check_information.check_amount.to_f.zero?)
    log.debug "check_is_absent : #{check_is_absent}"

    complete_eob_payment_check_condition = (payment_check &&
        !patient_pay && eob_with_service_line_exists)
    complete_eob_payment_check_condition = complete_eob_payment_check_condition &&
      balance == 0 if event == "complete_job" || event == "delete_eob"
    log.debug "complete_eob_payment_check_condition : #{complete_eob_payment_check_condition}"
    complete_eob_check_absent_condition = check_is_absent && !patient_pay &&
      balance == 0 && eob_with_service_line_exists
    log.debug "complete_eob_check_absent_condition : #{complete_eob_check_absent_condition}"

    complete_eob_condition = complete_eob_payment_check_condition || complete_eob_check_absent_condition
    log.debug "complete_eob_condition : #{complete_eob_condition}"
    missing_check_condition = (check_is_absent && balance != 0 &&
        !patient_pay && eob_with_service_line_exists)
    log.debug "missing_check_condition : #{missing_check_condition}"
    check_only_condition = (payment_check && !patient_pay &&
        balance == @check_information.check_amount &&
        eob_without_service_line_exists)
    log.debug "check_only_condition : #{check_only_condition}"
    correspondence_condition = (check_is_absent && balance == 0 &&
        eob_without_service_line_exists && !patient_pay)
    log.debug "correspondence_condition : #{correspondence_condition}"
    patient_pay_condition = ((payment_check ||check_is_absent) &&
        patient_pay && eob_with_service_line_exists)
    log.debug "patient_pay_condition : #{patient_pay_condition}"

    if complete_eob_condition
      "Complete EOB"
    elsif missing_check_condition
      "Missing Check"
    elsif check_only_condition
      "Check Only"
    elsif correspondence_condition
      "Correspondence"
    elsif patient_pay_condition
      "Patient Pay"
    end
  end

  def log
    @dc_grid_logger ||= RevRemitLogger.new_logger(LogLocation::DCGRIDLOG)
  end

  def save_eob_id_in_provider_adjustment
    @provider_adjustments = ProviderAdjustment.where("job_id =?",@job.id).update_all("insurance_payment_eob_id = #{@first_eob.id}")
  end

  def save_interest_only_check_details
    facility_payids = {:commercial_payid => @facility.commercial_payerid, :patient_payid => @facility.patient_payerid}
    @payer = save_payer(@check_information, facility_payids)
    @check_information = save_check(@check_information,facility_payids)
  end

  def get_standard_hipaa_codes
    @standard_hipaa_code_array ||= $HIPAA_CODES
    hipaa_codes_hash = @standard_hipaa_codes_hash
    if hipaa_codes_hash.blank?
      hipaa_codes_hash = {}
      if @standard_hipaa_code_array
        @standard_hipaa_code_array.each do |id_and_code_and_description|
          hipaa_codes_hash[id_and_code_and_description[1]] = id_and_code_and_description[0]
        end
      end
    end
    hipaa_codes_hash
  end

  private ######################################################################### PRIVATE METHODS ###########################################

  def validate_for_payment_method_chk(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    invalid_fields = []
    check_number = params[:checkinforamation][:check_number]
    is_check_number_invalid = check_number == '' || check_number.match(/^[\w]+$/).blank? ||
      check_number.match(/[^0]/).blank? || @check_information.is_check_number_in_auto_generated_format?(check_number, @batch, is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    if is_check_number_invalid
      invalid_fields << 'Check Number'
    end

    check_date = params[:checkinforamation][:check_date]
    is_check_date_invalid = !check_date.nil? && (check_date == '' || check_date == 'mm/dd/yy' || check_date == 'MM/DD/YY')
    if is_check_date_invalid
      invalid_fields << 'Check Date'
    end

    invalid_fields << 'Check Amount' if params[:checkinforamation][:check_amount].to_f.zero?
    if !@client_name == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'
      if !params[:micr_line_information].blank?
        routing_number = params[:micr_line_information][:aba_routing_number]
        if !is_micr_format_valid?(routing_number)
          invalid_fields << 'ABA Routing #'
        end

        account_number = params[:micr_line_information][:payer_account_number]
        if !is_micr_format_valid?(account_number)
          invalid_fields << 'Payer Account #'
        end
      end
    end

    if invalid_fields.length > 0
      validation_result = false
      statement_to_alert = "The payment method is selected as CHK. Please enter value in #{invalid_fields.join(', ')}"
    else
      validation_result = true
    end
    return validation_result, statement_to_alert
  end

  def validate_for_payment_method_cor(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    invalid_fields = []
    check_number = params[:checkinforamation][:check_number]
    is_check_number_invalid = !check_number.match(/^[\w]+$/).blank? &&
      !check_number.match(/[^0]/).blank? &&
      !@check_information.is_check_number_in_auto_generated_format?(check_number, @batch, is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    if is_check_number_invalid
      invalid_fields << 'Check Number'
    end

    if @client_name != 'PACIFIC DENTAL SERVICES' &&  @client_name != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' && @facility_name != 'SOUTH NASSAU COMMUNITY HOSPITAL'
      check_date = params[:checkinforamation][:check_date]
      is_check_date_invalid = !check_date.nil? && check_date != '' &&
        check_date.to_s.downcase != 'mm/dd/yy'
      if is_check_date_invalid
        invalid_fields << 'Check Date'
      end
    end
    invalid_fields << 'Check Amount' if !params[:checkinforamation][:check_amount].to_f.zero?

    if !params[:micr_line_information].blank?
      routing_number = params[:micr_line_information][:aba_routing_number]
      if is_micr_format_valid?(routing_number)
        invalid_fields << 'ABA Routing #'
      end

      account_number = params[:micr_line_information][:payer_account_number]
      if is_micr_format_valid?(account_number)
        invalid_fields << 'Payer Account #'
      end
    end

    if invalid_fields.length > 0
      validation_result = false
      statement_to_alert = "The payment method is selected as COR. Please do not enter value in #{invalid_fields.join(', ')}"
    else
      validation_result = true
    end
    return validation_result, statement_to_alert
  end

  def validate_for_payment_method_eft(is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    check_number = params[:checkinforamation][:check_number]
    is_check_number_valid = check_number != '' &&
      !check_number.match(/^[\w]+$/).blank? && !check_number.match(/[^0]/).blank? &&
      !@check_information.is_check_number_in_auto_generated_format?(check_number, @batch, is_client_ascend_clinical, is_client_quadax, is_client_qsi)
    if !is_check_number_valid && params[:checkinforamation][:check_amount].to_f.zero?
      statement_to_alert = "The payment method is selected as #{params[:check][:payment_method]}. Please enter value in Check Number OR Check Amount"
      validation_result = false
    else
      validation_result = true
    end
    return validation_result, statement_to_alert
  end

  def prepare
    logger.debug "prepare ->"
    @is_partner_bac = $IS_PARTNER_BAC
    unless params[:job_id].blank?
      @job = Job.includes({:batch => {:facility => :client}}).find(params[:job_id])
      @parent_job_id = @job.parent_job_id
      @parent_job_id_or_id = @job.get_parent_job_id
      @batch = @job.batch
      @facility = @batch.facility
      @client = @facility.client
      @client_name = @client.name.upcase
      @facility_name = @facility.name.upcase
      @check_information = CheckInformation.check_information(params[:job_id])
      if !@parent_job_id.blank?
        @parent_job = @check_information.job
      else
        @parent_job = @job
      end
      @eobs_count_on_job = @check_information.patient_pay_eobs.count
      activity = JobActivityLog.new
      activity.current_user_id = current_user.id
      activity.associated_job_id = @job.id
      @orbograph_correspondence_condition = @job.orbograph_correspondence?(@client_name)
    end
    logger.debug "<- prepare"
  end

  def filtering_capitation(field, comp, search)
    flash[:notice] = nil
    case field
    when 'Batch ID'
      batch_id = Batch.find_by_batchid(search)
      if !batch_id.blank?
        conditions = "batch_id #{comp} '#{batch_id.id}'"
      end
    when 'Check Number'
      conditions = "checknumber #{comp} '#{search.to_s}'"
    when 'Account'
      conditions = "account #{comp} '#{search.to_s}'"
    when 'Payment'
      conditions = "payment #{comp} '#{search.to_f}'"
    end
    if @current_user.has_role?(:processor)
      capitation_account = @current_user.capitation_accounts.where(conditions)
    else
      capitation_account = CapitationAccount.where(conditions)
    end
    return capitation_account
  end

  def supervisor_processor_validate
    unless  @current_user and (@current_user.has_role?(:supervisor) || @current_user.has_role?(:processor))
      store_location
      flash[:error] = "Not Authorized to view this page"
      redirect_to root_path
    end
  end

  def save_check(check_information, balance_record_type = nil, facility_payids)
    #Inserts a new record with aba_routing_number,payer_account_number, payer_id  and status as "New", if user manually keys in micr data,
    #Also updates check details with micr data association.
    unless params[:micr_line_information].blank?
      aba_routing_number = params[:micr_line_information][:aba_routing_number].strip unless params[:micr_line_information][:aba_routing_number].blank?
      payer_account_number = params[:micr_line_information][:payer_account_number].strip unless params[:micr_line_information][:payer_account_number].blank?
      payer_type = @payer.payer_type
      temp_payid = @payer.get_payid(payer_type, facility_payids)
      unless aba_routing_number.blank? and payer_account_number.blank?
        micr = MicrLineInformation.micr_record(aba_routing_number,payer_account_number)
        if (!micr.nil?)
          micr.payid_temp = temp_payid
        end
        micr ||= MicrLineInformation.new(:aba_routing_number => aba_routing_number,
          :payer_account_number => payer_account_number,
          :payer_id => check_information.payer_id,
          :status => MicrLineInformation::NEW,
          :payid_temp => temp_payid
        )
        check_information.micr_line_information = micr
      else
        check_information.micr_line_information = nil
      end
    end
    micr_exists_and_is_applicable = check_information.micr_line_information && !@facility.details[:micr_line_info].blank?
    check_information.micr_line_information.payer = check_information.payer if micr_exists_and_is_applicable

    if @facility.is_check_date_as_batch_date == true
      check_information.check_date = @batch.date # check_information.job.batch.date
    else
      check_information.check_date = format_date(params[:checkinforamation][:check_date])
    end

    check_information.check_mailed_date = format_date(params[:checkinforamation][:check_mailed_date])
    check_information.check_received_date = format_date(params[:checkinforamation][:check_received_date])
    check_information.check_amount = params[:checkinforamation][:check_amount].to_f.round(2)
    if !params[:checkinforamation][:check_number].blank?
      check_information.check_number = params[:checkinforamation][:check_number]
      check_information.job.check_number = params[:checkinforamation][:check_number]
    else
      check_information.check_number = 0
      check_information.job.check_number = 0
    end

    unless params[:checkinforamation][:alternate_payer_name].blank?
      check_information.alternate_payer_name = params[:checkinforamation][:alternate_payer_name]
    else
      check_information.alternate_payer_name = nil
    end
    unless params[:checkinforamation][:payment_type] == ""
      check_information.payment_type = params[:checkinforamation][:payment_type]
    else
      check_information.payment_type = nil
    end
    check_information.payee_npi = params[:checkinforamation][:payee_npi]
    check_information.payee_tin = params[:checkinforamation][:payee_tin]
    check_information.payee_name = params[:checkinforamation][:payee_name]
    check_information.mismatch_transaction = params[:checkinforamation][:mismatch_transaction]
    check_information.interest_only_check = params[:checkinforamation][:interest_only_check] if params[:checkinforamation][:interest_only_check]
    save_payment_method(check_information, balance_record_type)
    check_information.job.save
    check_information.micr_line_information.save if !check_information.micr_line_information.blank?
    check_information.save
    check_information
  end

  def save_payer(check_information, facility_payids)
    payer_already_exists = false
    payer_id = params[:payer][:payer_id] unless params[:payer][:payer_id].blank? || params[:payer][:payer_id] == 'undefined' || params[:payer][:payer_id] == 'null'
    payer_type = params[:payer_type] unless params[:payer_type].blank?
    name = params[:payer][:popup].to_s.strip.upcase
    address_one = params[:payer][:pay_address_one].to_s.strip.upcase
    address_two = params[:payer][:pay_address_two].to_s.strip.upcase
    city = params[:payer][:payer_city].to_s.strip.upcase
    state = params[:payer][:payer_state].to_s.strip.upcase
    zip = params[:payer][:payer_zip].to_s.strip
    tin = params[:payer][:payer_tin].to_s.strip unless params[:payer][:payer_tin].blank?
    payer_demographics = {:name => name, :address_one => address_one,
      :address_two => address_two, :city => city, :state => state, :zip => zip}
    is_correspondence_check = check_information.correspondence?(@batch, @facility)
    payer_type ||= 'PatPay' if @patient_pay

    payer_type_commercial_or_patient = payer_type == 'Commercial' || payer_type == 'PatPay'
    payer_object = Payer.get_payer_object(payer_demographics)
    if !$IS_PARTNER_BAC || is_correspondence_check
      unless payer_object.blank?
        payer_already_exists = true
        payer_id = payer_object.id
      end
    end
    existing_payer_with_new_demographics_or_name = !payer_id.blank? && !payer_already_exists
    new_payer = (payer_type_commercial_or_patient && payer_id.blank?  && !payer_already_exists)
    if new_payer
      payer = Payer.new(
        :payer => name,
        :pay_address_one => address_one,
        :pay_address_two => address_two,
        :payer_city => city,
        :payer_state => state,
        :payer_zip => zip,
        :payer_tin => tin,
        :payer_type => payer_type,
        :batch_target_time  =>  @batch.target_time
      )
      if not payer_already_exists
        payer.payid = payer.get_payid(payer_type, facility_payids)
        payer.status, payer.footnote_indicator = payer.get_status_and_footnote_indicator(is_correspondence_check, $IS_PARTNER_BAC)
        payer.gateway = payer.get_gateway
      end
    elsif existing_payer_with_new_demographics_or_name
      payer = Payer.find(payer_id)
      if payer.payer != 'UNKNOWN' && !payer.accepted?
        payer.payer = name
        payer.pay_address_one = address_one
        payer.pay_address_two = address_two
        payer.payer_city = city
        payer.payer_state = state
        payer.payer_zip  = zip
        payer.payer_tin = tin if tin
        payer.payer_type = payer_type
      end
    end
    if payer.blank? && !payer_id.blank?
      payer = Payer.find(payer_id)
    end
    unless payer.blank?
      payer.save!
      payer.reload
      check_information.payer = payer
      payer
    end
  end

  def create_balance_record
    is_balance_record_object_created = nil
    if !params[:balance_record_type].blank?
      balance_record_config = @facility.balance_record_configs.find(:first,
        :conditions => ['category = ?', params[:balance_record_type]])
      if balance_record_config
        if !@facility.details[:transaction_type] && @check_information.payment_method.blank?
          params[:check_information][:payment_method] = 'CHK'
        end
        parameters = {}
        parameters[:check_id] = @check_information.id
        parameters[:balance_record_config] = balance_record_config
        parameters[:payer_name] = @payer.payer
        parameters[:check_amount] = params[:checkinforamation][:check_amount].to_f
        parameters[:balance_amount] = params[:balance]
        parameters[:image_page_no] = params[:insurancepaymenteob][:image_page_no]
        parameters[:image_page_to_number] = params[:insurancepaymenteob][:image_page_to_number]
        parameters[:sub_job_id] = params[:job_id]
        parameters[:alternate_payer_name] = params[:alternate_payer_name_for_eob].strip
        parameters[:payer_indicator_config] = @facility.details[:payer_indicator]
        parameters[:patient_identification_code_qualifier] = params[:insurancepaymenteob][:patient_identification_code_qualifier]
        parameters[:patient_identification_code] = set_patient_identification_code_for_balance_record(@facility.sitecode, params[:insurancepaymenteob][:patient_identification_code_qualifier], params[:insurancepaymenteob][:patient_identification_code])
        build_an_eob_for_balance_record(parameters)

        if !balance_record_config.is_claim_level_eob
          parameters = {}
          parameters[:balance_record_config] = balance_record_config
          parameters[:check_amount] = params[:checkinforamation][:check_amount]
          parameters[:balance_amount] = params[:balance]
          build_a_service_line_for_balance_record(parameters)
        end
        is_balance_record_object_created = true
      end
    end
    is_balance_record_object_created
  end

  # Creates an InsurancePaymentEob parameter hash for Balance Record EOB.
  # Input :
  # parameters : A hash which contains all the variables that
  #  needs in this method from its caller method.
  def build_an_eob_for_balance_record(parameters = {})
    if parameters[:balance_record_config] && !parameters[:balance_record_config].category.blank? &&
        parameters[:balance_record_config].category.upcase != 'NONE'
      patient_first_name, patient_last_name = get_patient_name(parameters)      
      charge_amount, paid_amount = get_charge_and_payment(parameters)
      payer_indicator = 'ALL' unless parameters[:payer_indicator_config].blank?
      image_page_no = parameters[:image_page_no].blank? ? '1' : parameters[:image_page_no]
      date = format_service_date(get_date, @facility.default_service_date)
      params[:insurancepaymenteob][:patient_account_number] = parameters[:balance_record_config].account_number
      params[:insurancepaymenteob][:check_information_id] = parameters[:check_id]
      params[:insurancepaymenteob][:category] = parameters[:balance_record_config].is_claim_level_eob ? 'claim' : 'service'
      params[:insurancepaymenteob][:patient_first_name] = patient_first_name
      params[:insurancepaymenteob][:patient_last_name] = patient_last_name
      params[:insurancepaymenteob][:subscriber_first_name] = patient_first_name
      params[:insurancepaymenteob][:subscriber_last_name] = patient_last_name
      params[:insurancepaymenteob][:total_submitted_charge_for_claim] = charge_amount
      params[:insurancepaymenteob][:total_amount_paid_for_claim] = paid_amount
      params[:insurancepaymenteob][:total_allowable] = '0.00'
      params[:insurancepaymenteob][:total_service_balance] = 0.00
      params[:insurancepaymenteob][:image_page_no] = image_page_no
      params[:insurancepaymenteob][:image_page_to_number] = image_page_no
      params[:insurancepaymenteob][:payer_indicator] = payer_indicator
      params[:insurancepaymenteob][:balance_record_type] = parameters[:balance_record_config].category
      params[:insurancepaymenteob][:sub_job_id] = parameters[:sub_job_id]
      params[:insurancepaymenteob][:patient_identification_code] = parameters[:patient_identification_code]
      params[:insurancepaymenteob][:patient_identification_code_qualifier] = parameters[:patient_identification_code_qualifier]
      params[:insurancepaymenteob][:claim_from_date] = date
      params[:insurancepaymenteob][:claim_to_date] = date
      params[:insurancepaymenteob][:total_pbid] = nil
      params[:insurancepaymenteob][:total_drg_amount] = nil
      params[:insurancepaymenteob][:total_expected_payment] = nil
      params[:insurancepaymenteob][:total_retention_fees] = nil
      params[:insurancepaymenteob][:total_prepaid] = nil
      params[:insurancepaymenteob][:total_non_covered] = nil
      params[:insurancepaymenteob][:total_denied] = nil
      params[:insurancepaymenteob][:total_discount] = nil
      params[:insurancepaymenteob][:total_co_insurance] = nil
      params[:insurancepaymenteob][:total_deductible] = nil
      params[:insurancepaymenteob][:total_co_pay] = nil
      params[:insurancepaymenteob][:total_patient_responsibility] = nil
      params[:insurancepaymenteob][:total_primary_payer_amount] = nil
      params[:insurancepaymenteob][:total_contractual_amount] = nil
      params[:insurancepaymenteob][:miscellaneous_one_adjustment_amount] = nil
      params[:insurancepaymenteob][:miscellaneous_two_adjustment_amount] = nil
      params[:insurancepaymenteob][:miscellaneous_balance] = nil
    end
  end

  # Creates an ServicePaymentEob parameter hash for Balance Record EOB.
  # Input :
  # parameters : A hash which contains all the variables that
  #  needs in this method from its caller method.
  def build_a_service_line_for_balance_record(parameters = {})
    if parameters[:balance_record_config] && params[:insurancepaymenteob] &&
        !params[:insurancepaymenteob][:balance_record_type].blank?
      charge_amount, paid_amount = get_charge_and_payment(parameters)
      default_service_date = get_date
      params[:service_line] = {
        :serial_numbers => '1'
      }
      params[:lineinformation] = {} if params[:lineinformation].blank?
      params[:lineinformation]["procedure_code1"] = @facility.default_cpt_code
      params[:lineinformation]["dateofservice_from1"] = default_service_date
      params[:lineinformation]["dateofservice_to1"] = default_service_date
      params[:lineinformation]["charges1"] = charge_amount
      params[:lineinformation]["payment1"] = paid_amount
      params[:lineinformation]["service_allowable1"] = '0.00'
      params[:lineinformation]["provider_control_number1"] = @facility.default_ref_number
      params[:lineinformation]["units1"] = 1
    end
  end

  # Redirect to show_eob_grid method in InsurancePaymentEobsController
  #  in 'Processor view' when a Job or Check or Payer is missing
  def redirect_to_show_eob_grid
    page = Integer(params[:page])
    page += 1
    redirect_to :controller => 'insurance_payment_eobs',
      :action => 'show_eob_grid', :batch_id => params[:batch_id],
      :checknumber => params[:checknumber], :job_id => params[:job_id],:mode => params[:mode]
  end

  # Save the processor_id & qa_id for the eobs whose those values are blank
  #  while completion & incompletion of a job.
  def save_user_id_for_eobs
    if @current_user.has_role?(:processor)
      InsurancePaymentEob.where(:check_information_id => @check_information.id,
        :processor_id=> nil).update_all(:processor_id => @current_user.id)
    end
    if @current_user.has_role?(:qa)
      InsurancePaymentEob.where(:check_information_id => @check_information.id,
        :qa_id => nil).update_all(:qa_id => @current_user.id)
    end
  end

  def validate_adjustment_codes
    if !params[:reason_code].blank?
      all_codes = get_all_adjustment_codes
      if !@parent_job_id_or_id.blank? && !all_codes.blank?
        reason_code_records = ReasonCodesJob.get_valid_reason_codes @parent_job_id_or_id
        valid_unique_codes = reason_code_records.map{ |rc| rc.get_unique_code } if reason_code_records
        invalid_codes = all_codes.delete_if { |value| valid_unique_codes.include?(value)}
        if invalid_codes.present?
          standard_hipaa_codes_hash = get_standard_hipaa_codes
          invalid_codes = invalid_codes.delete_if { |value| standard_hipaa_codes_hash[value].present?}
        end
        invalid_codes
      end
    end
  end

  def get_all_adjustment_codes
    if !params[:reason_code].blank?
      if params[:claimleveleob] == "true"
        get_adjustment_codes_from_claim_level_service_lines
      else
        get_adjustment_codes_from_service_lines
      end
    end
  end

  def get_adjustment_codes_from_claim_level_service_lines
    adjustment_reasons = adjustment_reason_elements
    adjustment_reasons = adjustment_reasons.map{ |value| 'claim_' + value }
    codes = get_adjustment_codes_for_adjustment_reasons(adjustment_reasons)
    codes = codes.flatten.compact.uniq if codes
  end

  def get_adjustment_codes_from_service_lines
    codes = []
    array_of_service_lines = get_all_service_line_numbers
    adjustment_reasons = adjustment_reason_elements
    array_of_service_lines.each do |service_line_count|
      codes << get_adjustment_codes_for_adjustment_reasons(adjustment_reasons, service_line_count)
    end
    codes = codes.flatten.compact.uniq
  end

  def get_all_service_line_numbers
    array_of_service_lines = []
    unless params[:lineinformation].blank?
      params[:lineinformation].each do |key, value|
        key = key.to_s
        if key.start_with?("payment") && !value.blank?
          array_of_service_lines << key.slice(/[0-9]*$/).to_i
        end
      end
    end
    array_of_service_lines
  end

  def get_adjustment_codes_for_adjustment_reasons(adjustment_reasons, service_line_count = nil)
    service_line_count = service_line_count.to_s
    codes = []
    adjustment_reasons.each do |adjustment_reason|
      if params[:reason_code][(adjustment_reason + service_line_count).to_sym]
        code_element = params[:reason_code][(adjustment_reason + service_line_count).to_sym][:unique_code].to_s.strip
        if code_element.present?
          codes << code_element.split(';').flatten.compact.uniq
        end
      end
    end
    codes = codes.flatten.compact.uniq
  end


  #This is for setting patient_identification_code to null.
  # if qualifier is HIC & character length of patient_identification_code is 1,
  #this will return true.
  def set_patient_identification_code_to_blank(qualifier, identification_code)
    (!qualifier.blank? && !identification_code.blank? && qualifier == "HIC" &&
        identification_code.length == 1)
  end

  #This is for setting patient identification code as 'BALANCERECORD'
  #This is calling in create_balance_record.
  # if its qualifier is HIC and site_code is 896 for balanced eob.
  def set_patient_identification_code_for_balance_record(facility_sitecode, qualifier, identification_code)
    sitecode_after_trimming_left_padded_zeroes =  facility_sitecode.to_s.gsub(/^[0]+/, '')
    if qualifier == "HIC" && sitecode_after_trimming_left_padded_zeroes == "896"
      "BALANCERECORD"
    else
      identification_code
    end
  end

  def set_place_of_service(pos)
    result = nil
    if @facility.details[:place_of_service]
      result = (pos.blank? ? 11 : pos)
    end
    result
  end

  def redirect_when_invalid_data_exists
    grid_type = params[:grid][:type] if params[:grid]
    page = params[:page]
    page = params[:page] if params[:page].blank?
    if params[:view] == "qa" ||  params[:view] == "CompletedEOB"
      redirect_to :controller => 'insurance_payment_eobs',
        :action => 'claimqa', :batch_id => params[:batch_id],
        :checknumber => params[:checknumber], :job_id => params[:job_id],
        :page => page
    elsif grid_type == 'orbograph_correspondance'
      redirect_to :controller => 'datacaptures',
        :action => 'show_orbograph_correspondance_grid', :batch_id => session[:batch_id],
        :checknumber => session[:checknumber], :job_id => session[:job_id]
    elsif grid_type == 'nextgen'
      redirect_to :controller => 'datacaptures',
        :action => 'patient_pay', :batch_id => params[:batch_id],
        :checknumber => params[:checknumber], :job_id => params[:job_id]
    else
      redirect_to :controller => 'insurance_payment_eobs',
        :action => 'show_eob_grid', :batch_id => params[:batch_id],
        :checknumber => params[:checknumber], :job_id => params[:job_id],:mode => params[:mode]
    end
  end

  def complete_job_and_update_user(job_status)
    @job.update_status(job_status, @current_user.roles.first.name)
    if (@job.payer_group == '--' || @job.payer_group.blank?)
      if @payer
        @job.payer_group = @payer.get_payer_group
      elsif @orbograph_correspondence_condition
        @job.payer_group = 'Insurance'
      else # Nextgen condition
        @job.payer_group = 'PatPay'
      end
    end
    @job.save
    eob_count = @job.eob_count
    @current_user.update_processing_attributes(@facility.id, eob_count)
  end

  def save_payment_method(check_information, balance_record_type)
    if @facility.details[:transaction_type].blank?
      if !params[:check].blank? && !params[:check][:payment_method].blank?
        payment_method = params[:check][:payment_method]
      elsif params[:check_information]
        payment_method = params[:check_information][:payment_method]
      end
      if !payment_method.blank?
        check_information.payment_method = payment_method
      end
    end
  end

  def save_claim_level_service_lines(insurance_eob)
    svc_lines_ids_to_delete = []
    if params[:claim_level_svc]
      serial_and_record_ids = params[:claim_level_svc][:serial_and_record_ids]
      serial_and_record_ids = serial_and_record_ids.split(',')
      record_ids_to_delete = params[:claim_level_svc][:record_ids_to_delete]
      record_ids_to_delete = record_ids_to_delete.split(',') if record_ids_to_delete
    end
    if !record_ids_to_delete.blank?
      record_ids_to_delete.each do |svc_lines_id|
        if !svc_lines_id.blank?
          svc_lines_ids_to_delete << svc_lines_id.to_i
        end
      end
      ClaimLevelServiceLine.where(:id => (svc_lines_ids_to_delete.uniq)).destroy_all if !svc_lines_ids_to_delete.blank?
    end
    if !serial_and_record_ids.blank?
      service_lines_to_create = []
      serial_and_record_ids.each do |serial_num_and_record_id|
        if !serial_num_and_record_id.blank?
          svc_line_serial_num_and_id = serial_num_and_record_id.split('_')
          if !svc_line_serial_num_and_id.blank?
            serial_num = svc_line_serial_num_and_id[0].to_i
            record_id = svc_line_serial_num_and_id[1]
            if !serial_num.blank? && serial_num != 0 && (svc_lines_ids_to_delete.blank? || !svc_lines_ids_to_delete.include?(record_id))
              if !record_id.blank?
                service_line = ClaimLevelServiceLine.find(record_id)
                set_claim_level_service_line_attribute(service_line, serial_num)
                if !service_line.description.blank? && !service_line.amount.blank?
                  service_line.save if service_line.changed?
                end
              else
                service_line = ClaimLevelServiceLine.new
                set_claim_level_service_line_attribute(service_line, serial_num)
                service_line.insurance_payment_eob_id = insurance_eob.id
                if !service_line.description.blank? && !service_line.amount.blank?
                  service_lines_to_create << service_line
                end
              end
            end
          end
        end
      end
      if !service_lines_to_create.blank?
        ClaimLevelServiceLine.import service_lines_to_create
      end
    end
  end

  def set_claim_level_service_line_attribute(service_line, serial_num)
    if params[:claim_level_service_line]
      serial_num = serial_num.to_s
      description = format_ui_param(params[:claim_level_service_line]["description_#{serial_num}"])
      amount = normalize_amount(params[:claim_level_service_line]["amount_#{serial_num}"])
      if !description.blank? && !amount.blank?
        service_line.description = description
        service_line.amount = amount
      end
    end
  end

  # Provides the adjustment line serial number
  # Input :
  # serial_number : Serial number of the service lines
  # Output :
  # adjustment_line_serial_number : adjustment line serial number
  def adjustment_line_number(serial_number)
    if params[:adjustment_line]
      adjustment_line_number = params[:adjustment_line][:to_save].to_s
    end
    if !adjustment_line_number.blank?
      if serial_number.to_s == adjustment_line_number
        adjustment_line_serial_number = adjustment_line_number
      end
    end
    adjustment_line_serial_number
  end

  # Predicate method that validates the adjustment line
  # Input :
  # adjustment_line_number : adjustment line serial number
  # Output :
  # True if valid else false
  def is_adjustment_line_valid?(adjustment_line_number)
    if !adjustment_line_number.blank?
      allowable_amount = params[:lineinformation]["allowable" + adjustment_line_number]
      charge_amount = params[:lineinformation]["charges" + adjustment_line_number]
      payment_amount = params[:lineinformation]["payment" + adjustment_line_number]
      adjustment_amounts = [@adjustment_amounts[:noncovered], @adjustment_amounts[:denied],
        @adjustment_amounts[:discount], @adjustment_amounts[:contractual], @adjustment_amounts[:coinsurance],
        @adjustment_amounts[:deductible], @adjustment_amounts[:copay], @adjustment_amounts[:primary_payment],
        @adjustment_amounts[:prepaid], @adjustment_amounts[:patient_responsibility],
        @adjustment_amounts[:miscellaneous_one], @adjustment_amounts[:miscellaneous_two],
        params[:lineinformation]["miscellaneous_balance" + adjustment_line_number]]
      total_adjustment_amount = adjustment_amounts.inject(0) {|sum, value| sum + value.to_f }
      balance_amount = charge_amount.to_f - (payment_amount.to_f + total_adjustment_amount)

      non_zero_adjustment_amounts = adjustment_amounts.keep_if {|v| !v.to_f.zero?}
      is_there_atleast_one_adjustment_amount = non_zero_adjustment_amounts.length > 0
      balance_amount.to_f.round(2).zero? && charge_amount.blank? && allowable_amount.blank? &&
        is_there_atleast_one_adjustment_amount
    end
  end

  def get_plan_type(payer, eob)
    plan_type = nil
    if params[:insurancepaymenteob]
      plan_type = params[:insurancepaymenteob][:plan_type]
    end
    if plan_type.blank?
      plan_type_config = @facility.plan_type.to_s.upcase
      if plan_type_config == '837 SPECIFIC'
        if eob && !eob.claim_information_id.blank?
          plan_type = eob.claim_information.plan_type
        elsif @client.name.upcase == 'QUADAX' && eob && eob.claim_type == "Secondary"
          plan_type = "CI"
        end
      end
      if (plan_type.blank? || plan_type_config == 'PAYER SPECIFIC ONLY') && !payer.blank?
        plan_type = payer.normalized_plan_type(@client.id, @facility.id, @facility.details[:default_plan_type])
      end
    end
    plan_type
  end

  def validate_payee_name_and_tin_upmc(check_information)
    error_message = ''
    if @client_name == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' && !(check_information[:payee_name].blank?)
      payee_name_flag = UpmcFacility.exists?(:name => "#{check_information[:payee_name]}")
      payee_tin_flag = UpmcFacility.exists?(:name => "#{check_information[:payee_name]}",
        :tin => "#{check_information[:payee_tin]}") if payee_name_flag == true
      
      if payee_name_flag != true
        error_message = "Invalid Payee Name, Please Recheck"
      elsif payee_tin_flag != true
        error_message = "Invalid Payee Name and Payee Tin Combination, Please Recheck"
      end
    end
    error_message
  end

  def save_twice_keying_field_statistics(eob)
    if params[:twice_keying_first_attempt_statistics].present?
      attributes_array = []
      values = params[:twice_keying_first_attempt_statistics].split(',')
      values.each do |value|
        value_array = value.split(':')
        field_name = value_array[0]
        status = value_array[1]

        if field_name.present? && status.present?
          status = case status
          when "1"
            true
          else
            false
          end
          attributes = {:field_name => field_name, :first_attempt_status => status,
            :processor_id => eob.processor_id,
            :date_of_keying => Time.now,
            :client_id => @client.id,
            :facility_id => @facility.id,
            :batch_date => @batch.date,
            :batchid => @batch.batchid,
            :payid => @payer.payid,
            :payer_name => @payer.payer,
            :check_number => @check_information.check_number,
            :patient_account_number => eob.patient_account_number,
            :payer_id => @payer.id,
            :check_information_id => @check_information.id,
            :insurance_payment_eob_id => eob.id
          }
          attributes_array << attributes
        end
      end
      TwiceKeyingFieldsStatistics.create_all_records(attributes_array)
    end
  end

  def validate_eob_correctness
    result = true
    if  @current_user.has_role?(:qa) && params[:eobqa]
      incorrect_field_count_must_be_present = params[:eobqa][:total_incorrect_fields].blank?
      incorrect_field_count_more_than_1_but_error_type_is_blank = (params[:eobqa][:total_incorrect_fields].to_i > 0 &&
          (params[:pro_error_type].blank? || params[:pro_error_type] && params[:pro_error_type][:id].blank?))
      if incorrect_field_count_must_be_present ||
          incorrect_field_count_more_than_1_but_error_type_is_blank 
        result = false
      end
    end
    result
  end

  def get_user_entered_error_list
    error_types, error_records = [], []
    if params[:pro_error_type].present?
      error_types  <<  params[:pro_error_type][:id]
    end
    if error_types.blank? && params[:eobqa] && params[:eobqa][:total_incorrect_fields].to_i == 0
      error_types  << 'Correct'
    end
    error_types = error_types.flatten.compact.uniq
    error_records = EobError.where("error_type IN (?)", error_types) if error_types.present?
    error_records
  end

  def get_existing_eob_qa_records(error_record_ids, job_id, eob_obj_id)
    condition_string = "job_id = :job_id AND qa_id = :qa_id AND eob_error_id IN (:eob_error_ids) AND eob_id = :eob_id"
    condition_values = {
      :job_id => job_id,
      :qa_id => @current_user.id,
      :eob_error_ids => error_record_ids,
      :eob_id => eob_obj_id
    }
    EobQa.where(condition_string, condition_values)
  end

  def get_eob_qa_parameters(eob_obj, job_id)
    qa_comment = params[:qa_comment] unless params[:qa_comment].blank?
    if params[:status] == 'Complete'
      status = "Accepted"
      prev_status = "new"
    elsif params[:status] == 'Reject'
      status = "Rejected"
      prev_status = "new"
    else
      status = "Incomplete"
      prev_status = "new"
    end
    parameters = {
      :job_id => job_id,
      :qa_id => @current_user.id,
      :eob_obj => eob_obj,
      :comment => qa_comment,
      :total_incorrect_fields => params[:eobqa][:total_incorrect_fields],
      :status => status,
      :prev_status => prev_status
    }
    parameters
  end

  def save_eob_qa_job_activity(job, eob_obj)
    if eob_obj
      eob_id = eob_obj.id
      eob_type_id = (eob_obj.class.name == "PatientPayEob") ? 2 : 1
    end
    job_activities = []
    if params[:status] == 'Complete'
      job_activities << save_job_activity(job.id, eob_id, nil, job.qa_id, "QA Verification Started",Time.zone.parse(params[:claimqa][:start_time]),Time.now,eob_type_id,false)
      job_activities << save_job_activity(job.id, eob_id, nil, job.qa_id, "QA Completed", Time.now,nil, eob_type_id,false)
    elsif params[:status] == 'Reject'
      job_activities << save_job_activity(job.id, eob_id, nil, job.qa_id, "QA Verification Started",Time.zone.parse(params[:claimqa][:start_time]),Time.now,eob_type_id,false)
      job_activities << save_job_activity(job.id, eob_id, nil, job.qa_id, "QA Rejected", Time.now,nil, eob_type_id,false)
    else
      job_activities << save_job_activity(job.id, eob_id, nil, job.qa_id, "QA Verification Started", Time.zone.parse(params[:claimqa][:start_time]),Time.now,eob_type_id,false)
      job_activities << save_job_activity(job.id, eob_id, nil, job.qa_id, "QA Incompleted", Time.now,nil, eob_type_id,false)
    end
    JobActivityLog.import job_activities unless job_activities.blank?
  end
 
end
