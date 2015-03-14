class InsurancePaymentEobsController < ApplicationController

  include InsurancePaymentEobsHelper
  include ApplicationHelper
  before_filter :prepare, :except => [:auto_complete_for_reason_description, :get_invalid_cpt_codes,
    :get_invalid_remark_codes, :auto_complete_for_hipaa_code_hipaa_adjustment_code,
    :auto_complete_for_insurancepaymenteob_place_of_service,
    :auto_complete_for_provider_provider_last_name, :auto_complete_for_provider_provider_npi_number,
    :auto_complete_for_payer_popup, :auto_complete_for_payer_pay_address_one, :auto_complete_for_payer_payer_state, :auto_complete_for_reason_code_unique_code,
    :auto_complete_for_reason_code_reason_code, :any_eob_present,
    :auto_complete_for_reason_code_reason_code_description ,:check_presence_of_url ]
  layout 'datacapture',:except => [:mpisearch]
  require_role ["supervisor","admin", "processor","qa","partner","client","facility"]


  # The method 'claim' displays the grid for the processor to operate.
  # The view file of this method renders patials : _insurance_eob_payment & _ocr_service_line for the grid.
  # The input to the method are image number, batch id, job id & check number.
  # The fields in the grid  are associted with the columns of tables 'PatientPayEob' ,'InsurancePaymentEob' , 'ServicePaymentEob' and CheckInformation.
  # For split jobs there will be a column called parent_job_id in the jobs table under which the associate jobs lie in the sub_job_id.
  # image_type '0' specifies a single tiff image.
  # image_type '1' specifies a multi tiff image.
  # A function public_filename(), defined in the 'attachment_fu' plugin,
  # is called to obtain the path of the folder where the image resides. The base path is the private folder. It provides the full path to the filename of the image in a format.
  def claim
    # session[:mode] ||= params[:mode] if !params[:mode].blank?
    ocr_comment = @job.is_ocr
    @mode = (ocr_comment == 'OCR') ? "VERIFICATION" : "NON_VERIFICATION"
    @insurance_eobs_saved = @check_information.insurance_payment_eobs.exists? if !@orbograph_correspondence_condition
    if @insurance_eobs_saved
      @offset_eob_present = @check_information.insurance_payment_eobs.exists?( :patient_first_name => "NEGATIVE", :patient_last_name=> "OFFSET")
    end
    $flag_after_eobs_deletion_for_hosp = nil
    $flag_after_eobs_deletion_for_physician = nil
    @view = params[:view]
    @patient_pay_eobs_saved = @check_information.patient_pay_eobs.exists?
    #      session[:view] = params[:view].to_s
    @total_image_array = []
    if @image_page_no == nil
      @page_number = params[:image_number]
    else
      @page_number = @image_page_no
    end
    @facility_name = @facility.name
    @facility_pat_pay_format = @facility.patient_pay_format
   
    facility_image_type = @facility.image_type

    get_images(@parent_job_id, facility_image_type, params[:job_id])
    # Provides the Adjustment Line
    @adjustment_service_line = []
    @adjustment_service_line << ServicePaymentEob.new
    @service_line = @adjustment_service_line
    get_incomplete_comment_list
    complete_rejection_comment, incomplete_rejection_comment, @orbo_rejection_comments = RejectionComment.find_complete_and_incomplete_rejection_comments(@facility.id)
    unless complete_rejection_comment.blank?
      @complete_job_comment_list = complete_rejection_comment.name.split(%r{\n}).compact.uniq
      @complete_job_comment_list << "--"
    else
      @complete_job_comment_list = ["--\n"]
    end

    unless incomplete_rejection_comment.blank?
      @incomplete_job_comment_list = incomplete_rejection_comment.name.split(%r{\n}).compact.uniq
      @incomplete_job_comment_list << "--"
    else
      @incomplete_job_comment_list = ["--\n"]
    end

    @populate_values_for_eob_incompletion = (@client_name == "GOODMAN CAMPBELL" || @client_name == "QUADAX")
    @show_prov_adj_chk_box = ! @facility.details[:plb_applicable].blank?
    @show_patient_pay_grid_by_default = @check_information.display_patpay_grid_by_default?(@client_name, @facility, @job.payer_group)
    @claim_enabled_for_patient_pay  = @facility.details[:patpay_claim_level_eob]
    @claim_enabled_for_insurance_pay = @facility.details[:insurance_claim_level_eob]
    render_grid_links
  end

  #~ The method 'claimqa' displays the grid for the qa to operate.
  #~ The view file of this method renders patials : service_line for the grid.
  #~ The inputs to the method are batch id & job id.
  #~ It provides the necessary values to populate fields in the grid from the table 'PatientPayEob' ,'InsurancePaymentEob' , 'ServicePaymentEob' and CheckInformation.
  #~ Error types of eob are populated from the table EobError.
  #~ For split jobs there will be a column called parent_job_id in the jobs table under which the associate jobs lie in the sub_job_id.
  #~ It calls methods 'claim()' and 'insurance_payment_eob()', for the pupose of qa to update the fields and to save the eob accordingly.
  def claimqa
    if params[:verify_grid] == '1' # Image Retrieval
      client_activity(params[:checknumber], params[:eob_id], "Viewed Image and Grid", params[:job_id])
    end
    logger.debug "claimqa -> "
    @current_time = params[:proc_start_time] unless params[:proc_start_time].nil?
    if params[:verify_grid] != '1' && (processor_completed_or_incompleted_job || qa_completed_or_incompleted_job)
      render :template => "access_message", :layout => 'standard'
    else
      if current_user.has_role?(:qa)
        if params[:verify_grid] != '1'
          @job.qa_status = QaStatus::PROCESSING
          @job.save
        end
        @job.batch.set_qa_status
      end
      @facility ||= @job.batch.facility
      @error_type_new = EobError.find(:all)
      @error_type_new.delete_at(0)

      conditions_for_insurance_eob = "check_information_id = #{@check_information.id} and (processor_id is not null or qa_id is not null)"
      if not @parent_job_id.blank?
        conditions_for_insurance_eob = "sub_job_id = #{params[:job_id]} and (processor_id is not null or qa_id is not null)"
      end
      conditions_for_patient_pay_eob = "check_information_id = #{@check_information.id}"
      user_report
      get_saved_ins_data = InsurancePaymentEob.where(conditions_for_insurance_eob).paginate(:per_page => 1, :page => params[:page])
      if(@orbograph_correspondence_condition)
        @orbo_correspondance_eob_saved_data = get_saved_ins_data
      else
        @insurance_eob_saved_data = get_saved_ins_data
      end
      @patient_pay_eobs_saved_data = PatientPayEob.where(conditions_for_patient_pay_eob).paginate(:per_page => 1, :page => params[:page])
      if !@insurance_eob_saved_data.blank?        
        @insurance_eob_saved_data = InsurancePaymentEob.set_unique_codes_and_reason_code_ids_for_claim(@insurance_eob_saved_data, @is_multiple_reason_codes_applicable)
        eob = @insurance_eob_saved_data.first
        @image_page_no = eob.image_page_no # if !eob.blank?
      elsif !@patient_pay_eobs_saved_data.blank?
        @statementamount, @stubamt = PatientPayEob.statement_and_stub_amount(@check_information.id)
        @grid_type = 'nextgen'
      end
      if @grid_type == 'nextgen'
        @eobs_count_on_job = @check_information.patient_pay_eobs.count
      end
      if params[:page].blank?
        @image_page_no ||= 1
      end
      claim()
      if(@orbograph_correspondence_condition)
        show_orbograph_correspondance_grid();
      else
        show_eob_grid()
      end
    
    end
  end
  
  def capitation_account_save 
    @capitation_account = CapitationAccount.new(params[:capitation_account])
    @payer_name = @payer_of_check.payer if @payer_of_check
    @capitation_account.payer_name = @payer_name
    @capitation_account.user_id = current_user.id
    if @batch.capitation_accounts << @capitation_account
      flash[:notice] = "Capitation Account Details Added"
    else
      flash[:notice] = "#{@capitation_account.errors.full_messages.join(", ")}"
    end
    redirect_to :back
  end

  def show_orbograph_correspondance_grid
 
    #    session[:mode] ||= params[:mode] if !params[:mode].blank?
    mode = get_mode
    populate_grid_data
    @grid_type = 'orbograph_correspondance'
    complete_rejection_comment, incomplete_rejection_comment, @orbo_rejection_comments = RejectionComment.find_complete_and_incomplete_rejection_comments(@facility.id)
    unless @orbo_rejection_comments.blank?
      @orbhograph_rejection_comment = @orbo_rejection_comments.name.split(%r{\n}).compact.uniq
      @orbhograph_rejection_comment << "--"
    else
      @orbhograph_rejection_comment = ["--\n"]
    end
    if (mode == 'edit' && (params[:view] != "Add_EOB"))
      process_edit
    elsif (mode == 'new' || (params[:view]  == "Add_EOB"))
      process_new
    end
  end
  
  def show_eob_grid
    processor_report
    @mode_value = params[:mode]
    @check_box_value =  params[:mpi_data_selected] unless  params[:mpi_data_selected].blank?

    #    session[:mode] ||= params[:mode] if !params[:mode].blank?
    mode = get_mode
    @current_time = params[:proc_start_time] unless params[:proc_start_time].nil?
    @patient_stmt_flds_present = (@facility.details[:patpay_statement_fields] &&
        @patient_pay)
    @check_payer = @check_information.payer
    if (@client_name == "QUADAX")
      @has_system_generated_check_number = @check_information.is_check_number_in_auto_generated_format?(@check_information.check_number, @batch, false, true, false)
    else
      @has_system_generated_check_number = @check_information.has_system_generated_check_number?(@batch, @facility)
    end
    #---------------------START of Reason Code Grid Processing -----------------
    if @check_payer.blank?
      ReasonCodesJob.delete_all("parent_job_id = #{@get_parent_job_id}")
    end
    parent_job_id = @job.get_parent_job_id
    unless @is_partner_bac
      @is_facility_horizon_eye = (@facility.name == "HORIZON EYE")
      @hash_with_default_rc_ids = ReasonCode.get_default_reason_code_ids(@is_facility_horizon_eye)
      @default_reason_code_id_list = @hash_with_default_rc_ids.values
    end
    @reason_codes = ReasonCodesJob.get_valid_reason_codes parent_job_id
    @total_hipaa_and_unique_codes_of_parent_job = get_valid_hipaa_codes_and_unique_codes_in_job(@reason_codes)
   
    if(@job.apply_to_all_claims)
      alternate_payer_name_info = InsurancePaymentEob.select("alternate_payer_name").where("sub_job_id = #{@job.id}")
      @alternate_payer_name = alternate_payer_name_info.first.alternate_payer_name
    end
    #---------------------END of Reason Code Grid Processing--------------------
    if @payer_of_check && @payer_of_check.footnote_indicator && @eobs_count_on_job == 0
      @is_footnote_payer = true
    end
    if params[:claimleveleob] == "true"
      @claim_level_eob = true
    elsif (@payer_of_check && @payer_of_check.payer_type == 'Insurance' && @job.payer_group != 'PatPay') || @job.payer_group == 'Insurance' || @insurance_pay
      @claim_level_eob = @facility.details[:insurance_claim_level_eob]
    else
      if (params[:tab] == "patient_pay") || @patient_pay == true || @job.payer_group == 'PatPay' || (@payer_of_check && @payer_of_check.payer_type == 'PatPay')
   
        @claim_level_eob = @facility.details[:patpay_claim_level_eob]
      else
        @claim_level_eob = @facility.details[:insurance_claim_level_eob]
      end
    end
    @site_code = @facility.sitecode.to_s.strip.gsub(/^[0]+/, '').upcase

    get_incomplete_comment_list
    eob_wise_rejection_comment_list_specific_to_gcbs = {
      'EOB' => 'EOB',
      'Payer Check w/o EOB' => 'Payer Check w/o EOB',
      'Patient Payment' => 'Patient Payment',
      'Patient Payment w/ Updates' => 'Patient Payment w/ Updates',
      'Patient Payment w/o Statement' => 'Patient Payment w/o Statement',
      'Other Payment' => 'Other Payment',
      'EOB w/ EFT' => 'EOB w/ EFT',
      'Total Denial' => 'Total Denial'}
    @incomplete_comment_list = @incomplete_comment_list.merge(eob_wise_rejection_comment_list_specific_to_gcbs) if @client_name == "GOODMAN CAMPBELL"
    @prov_adjustment_description = provider_adjustment_descriptions
    @display_balance_record_field = (!@facility.details[:balance_record_applicable].blank? &&
        !@check_information.balance_record_eob_exist?)
    @balance_record_configs = @facility.balance_record_configs
    @balance_record_types = ['None']
    @balance_record_types += @balance_record_configs.map(&:category) unless
    @balance_record_configs.blank?
    loading_patient_details_in_eob_grid
    populate_grid_data
    @populate_values_for_eob_incompletion = (@client_name == "GOODMAN CAMPBELL" || @client_name == "QUADAX")
   
    if (mode == 'edit' && (params[:view] != "Add_EOB"))
      process_edit
    elsif (mode == 'new' || (params[:view]  == "Add_EOB"))
      @mode_value = 'new'
      process_new
    end
  end

  # Prepares the claim and claim service records which are to be used to
  # populate the form with details from the MPI record selected
  # this action is called through AJAX
  # params[:patient_id] is the id of claim record, chosen through radio button
  # params[:claim_info_id_array] is an array of ids of claims selected through
  # check boxes- indicating user's desire to import service lines from
  # one or more records
  # pat_eob_with_consolidated_svc_line holds the condition under which
  # a unified version of service lines chosen through MPI search is to be
  # imported into the form
  def loading_patient_details_in_eob_grid
    logger.debug "loading_patient_details_in_eob_grid ->"

    claim_ids, @mpi_service_line = [], []
    claim_id = params[:patient_id] unless params[:patient_id].blank?
    pat_eob_with_consolidated_svc_line = !@insurance_pay &&
      (!@facility.details[:simplified_patpay_multiple_service_lines] ||
        @claim_level_eob)
    if not params[:claim_info_id_array].blank?
      claim_ids = params[:claim_info_id_array].split(",")
    elsif not params[:patient_id].blank?
      claim_ids << params[:patient_id]
    end

    if claim_id && !claim_ids.blank?
      @patient_837_information = ClaimInformation.find(claim_id)
      if pat_eob_with_consolidated_svc_line
        cons_svc_line = ClaimInformation.consolidated_svc_line(claim_ids)
        set_procedure_code(cons_svc_line)
        @mpi_service_line << cons_svc_line
      else
        @mpi_service_line << ClaimServiceInformation.
          find_all_by_claim_information_id(claim_ids)
      end
      
    end
    svc_lines = []
    svc_lines << ServicePaymentEob.new
    @service_line = svc_lines if @mpi_service_line.blank?
    hipaa_code_array = $HIPAA_CODES
    @hipaa_adjustment_codes = []
    hipaa_code_array.each do |id_and_code_and_description|
      @hipaa_adjustment_codes << id_and_code_and_description[1]
    end

    logger.debug "<- loading_patient_details_in_eob_grid"
  end

  # Switch method uses Sphinx search in production
  def mpi_search
    return (Rails.env.production? ? mpi_search_sphinx : mpi_search_non_sphinx)
  end
  
  # Recieves the parameters for MPI search,
  # search can be performed on the following:
  # account number, first name, last name, service date
  # and delegates the search to the model
  # applies pagination on the result set
  # will_paginate plugin is used to restrict display of the num of results/page
  
  def mpi_search_sphinx
    facility_id = @facility.id                              if @facility.mpi_search_type.eql?("FACILITY")
    client_id = @client.id                                 if @facility.mpi_search_type.eql?("CLIENT")
    account_number = params[:patient_no]
    patient_last_name = params[:patient_lname]
    patient_first_name = params[:patient_fname]
    date_of_service_from = params[:dateofservice_from_status]
    insured_id = params[:insured_id]
    total_charges = params[:total_charges]
    service_from_date = normalize_date date_of_service_from
    @mpi_results = ClaimInformation.mpi_search_for_sphinx(facility_id,client_id,account_number,patient_last_name,patient_first_name,service_from_date,insured_id,total_charges,params[:page])
  end

  def is_npi_tin_valid_for_facility
    flag = true;
    unless @facility.details[:npi_or_tin_validation].blank?
      if(@facility.details[:npi_or_tin_validation] == 'NPI')
        if(@facility.name == 'METROHEALTH SYSTEM' || @facility.name == 'AVITA HEALTH SYSTEMS')
          flag = FacilityLockboxMapping.exists?(:npi => params[:npi], :lockbox_number => @batch.lockbox,:facility_id => params[:facility_id])
        else
          flag = FacilitiesNpiAndTin.exists?(:npi => params[:npi], :facility_id => params[:facility_id])
        end

      elsif(@facility.details[:npi_or_tin_validation] == 'TIN')
        if(@facility.name == 'METROHEALTH SYSTEM' || @facility.name == 'AVITA HEALTH SYSTEMS')
          flag = FacilityLockboxMapping.exists?(:tin => params[:tin], :lockbox_number => @batch.lockbox,:facility_id => params[:facility_id])
        else
          flag = FacilitiesNpiAndTin.exists?(:tin => params[:tin], :facility_id => params[:facility_id])
        end
      end
    end
    render :text => flag
  end


  def mpi_search_non_sphinx
    account_number = params[:patient_no]
    patient_last_name = params[:patient_lname]
    patient_first_name = params[:patient_fname]
    date_of_service_from = params[:date_of_service_from]
    service_from_date = normalize_date date_of_service_from


    query_condition = Array.new
    mpi_query_condition = Array.new

    query_condition << "facility_id = #{@facility.id}" if @facility.mpi_search_type.eql?("FACILITY")
    query_condition << "client_id = #{@client.id}" if @facility.mpi_search_type.eql?("CLIENT")

    unless account_number.blank?
      account_number_len = account_number.length
      actual_account_number = account_number.gsub( "*", "" )
      if account_number[0,1] == '*'
        if account_number[(account_number_len-1),1] == '*'
          query_condition << "patient_account_number like '%#{actual_account_number}%'"
        else
          query_condition << "patient_account_number like '%#{actual_account_number}'"
        end
      elsif account_number[(account_number_len-1),1] == '*'
        query_condition << "patient_account_number like '#{actual_account_number}%'"
      else
        query_condition << "patient_account_number = '#{actual_account_number}'"
      end
    end

    unless patient_last_name.blank?
      patient_last_name_len = patient_last_name.length
      actual_patient_last_name = patient_last_name.gsub( "*", "" )
      if patient_last_name[0,1] == '*'
        if patient_last_name[(patient_last_name_len-1),1] == '*'
          query_condition << "patient_last_name like '%#{actual_patient_last_name}%'"
        else
          query_condition << "patient_last_name like '%#{actual_patient_last_name}'"
        end
      elsif patient_last_name[(patient_last_name_len-1),1] == '*'
        query_condition << "patient_last_name like '#{actual_patient_last_name}%'"
      else
        query_condition << "patient_last_name = '#{actual_patient_last_name}'"
      end
    end
   
    unless patient_first_name.blank?
      patient_first_name_len = patient_first_name.length
      actual_patient_first_name = patient_first_name.gsub( "*", "" )
      if patient_first_name[0,1] == '*'
        if patient_first_name[(patient_first_name_len-1),1] == '*'
          query_condition << "patient_first_name like '%#{actual_patient_first_name}%'"
        else
          query_condition << "patient_first_name like '%#{actual_patient_first_name}'"
        end
      elsif patient_first_name[(patient_first_name_len-1),1] == '*'
        query_condition << "patient_first_name like '#{actual_patient_first_name}%'"
      else
        query_condition << "patient_first_name = '#{actual_patient_first_name}'"
      end
    end
    # query_condition << "facility_id = #{@facility.id}"
    mpi_query_condition = query_condition.join(" and ")
       
    unless service_from_date.blank?
      join_condition = "inner join claim_service_informations on claim_service_informations.claim_information_id = claim_informations.id"
    else
      join_condition = ""
    end
    
    @mpi_results = ClaimInformation.select("distinct claim_informations.*").
      where(mpi_query_condition).joins(join_condition).paginate(:page => params[:page])

    @mpi_results
  end
  
  def get_mode
    if current_user.has_role?('qa')
      'edit'
    else
      (params[:mode] != 'VERIFICATION') ? 'new' : 'edit'
    end
  end
  
  def process_new
    @insurance_eobs_unsaved,  @insurance_eob_unsaved_data = [],[]

    @insurance_eob_unsaved_data << InsurancePaymentEob.new
    @plan_type = get_plan_type(@payer_of_check)

  end
  
  # @insurance_eob_unsaved_data holds eobs OCR'd or imported from an external source
  # and are not reviewed by processor
  def process_edit
    if @parent_job_id.blank?
      condition = "check_information_id = '#{@check_information.id}' and processor_id is null"
    else
      condition = "sub_job_id = '#{params[:job_id]}' and processor_id is null"
    end
    @insurance_eob_unsaved_data = InsurancePaymentEob.where(condition).paginate(:per_page => 1, :page => params[:page])
    if @insurance_eob_unsaved_data.blank?
      @insurance_eob_unsaved_data_length = "0"
      @insurance_eob_unsaved_data = []

      @insurance_eob_unsaved_data << InsurancePaymentEob.new


    else
      @insurance_eob_unsaved_data_length = @insurance_eob_unsaved_data.length
      eob = @insurance_eob_unsaved_data.first
      @image_page_no = eob.image_page_no if !eob.blank?
      @verification_mode_with_saved_eobs = true
      if(@job.is_ocr == "OCR")
        @ocr_service_line = []
        check_box_value = "true"
        check_box_value = @check_box_value unless @check_box_value.blank?
        if(!@patient_837_information.blank?)
          ClaimInformation.compare_and_associate_claim_and_eob(@patient_837_information.id, @insurance_eob_unsaved_data.first.id)
          @insurance_eob_unsaved_data = InsurancePaymentEob.where(condition).paginate(:per_page => 1, :page => params[:page])
        end
        if(!@insurance_eob_unsaved_data.first.claim_information_id.blank?)
          if(check_box_value == "true")
            
            @patient_837_information =   ClaimInformation.find(@insurance_eob_unsaved_data.first.claim_information_id)
            @ocr_service_line << ServicePaymentEob.where("insurance_payment_eob_id = #{@insurance_eob_unsaved_data.first.id}",:include=>:claim_service_information)
            @claim_linkage_present = true
          else
            @ocr_service_line << ServicePaymentEob.where("insurance_payment_eob_id = #{@insurance_eob_unsaved_data.first.id}")
            @claim_linkage_present= true
          end
        else
          @ocr_service_line << ServicePaymentEob.where("insurance_payment_eob_id = #{@insurance_eob_unsaved_data.first.id}")
        end
      end
    end
    @image_page_no ||= 1
  end
  
  # The following 'auto_complete' methods are for the type ahead functionality of the various field

  # Auto Complete for Payer
  def auto_complete_for_payer_popup
    @payers = get_matching_payers(params[:payer_name], params[:payer_address_one])
  end

  # Auto Complete for Payer Address One
  def auto_complete_for_payer_pay_address_one
    @payers = get_matching_payers(params[:payer_name], params[:payer_address_one])
  end
  
  def auto_complete_for_payer_payer_state
    user_input = params[:payer][:payer_state]
    @us_states = us_states.select{|k, v| k.start_with?(user_input) || k.swapcase.start_with?(user_input)}
    render :layout => false
  end

  def auto_complete_for_payee_name
    if @facility.details[:upmc_payee_name_config]
      @payee_name =  UpmcFacility.select(:name).where("lockbox_id = #{params[:facility_id]} and name like '#{params[:checkinforamation][:payee_name]}%'")
    else
      @payee_name =  UpmcFacility.select(:name).where("name like '#{params[:checkinforamation][:payee_name]}%'")
    end
    render :layout => false
  end

  def auto_complete_for_reason_description
    @reason = Reason.where("description like '#{ params[:reason][:description]}%'")
    render :layout => false
  end

  # Auto Complete for $ Amount Reason Codes fields in the Add Row of Data Captures Grid
  def auto_complete_for_reason_code_unique_code
    if params[:reason_code]
      adjustment_reason = params[:reason_code].keys[0]
      if adjustment_reason
        code = params[:reason_code][adjustment_reason][:unique_code]
        if code.present?
          auto_complete_for_unique_code(code.strip)
        end
      end
    end
  end

  # Provides auto complete / type ahead for unique code fields.
  # Input :
  # unique_code : A Few character of the unique code eneterd for obtaining the type ahead.
  # Calls the partial to display the result. Eg : unique_code+reason code ID
  
  def auto_complete_for_unique_code(code)
    @adjustment_codes = []
    begin
      job = Job.select('id, parent_job_id').find(params[:job_id])
      parent_job_id = job.get_parent_job_id
      reason_code_records = ReasonCode.find_by_sql("select distinct reason_codes.unique_code, \
        reason_codes.id, reason_codes.reason_code, reason_codes.reason_code_description \
        from reason_codes \
        inner join reason_codes_jobs on \
        reason_codes.id = reason_codes_jobs.reason_code_id \
        where (reason_codes_jobs.parent_job_id = #{parent_job_id} and \
        reason_codes.unique_code like '#{code}%') limit 10")
      reason_code_records.each do |record|
        @adjustment_codes << [record.unique_code, record.id, record.reason_code, record.reason_code_description]
      end
      hipaa_codes = $HIPAA_CODES
      count = 0
      hipaa_codes.each do |hipaa_code_array|
        if count != 10 && hipaa_code_array[1].upcase.start_with?(code.upcase)
          @adjustment_codes << [hipaa_code_array[1], hipaa_code_array[0], hipaa_code_array[2], '']
          count += 1
        end
      end
    rescue
      @adjustment_codes = []
    end
    render :partial => 'auto_complete_for_unique_code'
  end

  # Auto Complete for $ Amount Reason Codes fields in the Add Row of Reason Code Grid
  def auto_complete_for_reason_code_reason_code
    reason_code = params[:reason_code][:reason_code]
    auto_complete_for_reasoncode(reason_code)
  end

  # Auto Complete for $ Amount Reason Codes fields in the Add Row of Reason Code Grid
  def auto_complete_for_reason_code_reason_code_description
    reason_code_desc = params[:reason_code][:reason_code_description]
    auto_complete_for_reasoncode_desc(reason_code_desc)
  end
  
  # Auto Complete for Hipaacode of Reason Code Grid used for non bank only.
  def auto_complete_for_hipaa_code_hipaa_adjustment_code
    hipaa_code = params[:hipaa_code][:hipaa_adjustment_code]
    auto_complete_for_hipaacode(hipaa_code)
  end

  # Provides auto complete / type ahead for unique code fields.
  # Input :
  # unique_code : A Few character of the unique code eneterd for obtaining the type ahead.
  # Calls the partial to display the result. Eg : unique_code+reason code ID

  def auto_complete_for_reasoncode(reason_code)
    begin
      payer_id = params[:payer_id]
      payer = Payer.select('reason_code_set_name_id').find(payer_id) unless payer_id.blank?
      rc_set_name_id = payer.reason_code_set_name_id
      if $IS_PARTNER_BAC
        conditions = "reason_codes.status = 'ACCEPT' && "
      else
        conditions = ""
      end
      conditions += "reason_codes.reason_code_set_name_id = #{rc_set_name_id} && reason_codes.reason_code like ? && active = 1"
      @reason_codes = ReasonCode.find(:all, :conditions => [conditions, reason_code.to_s+'%'],
        :select => ['reason_codes.id, reason_codes.reason_code, reason_codes.reason_code_description'],
        :order => "reason_codes.id ASC", :limit => 10)
    rescue
      @reason_codes = nil
    end
    render :partial => 'auto_complete_for_reasoncode'
  end

  def auto_complete_for_reasoncode_desc(reason_code_description)
    begin
      payer_id = cookies[:payer_id]
      payer = Payer.select('reason_code_set_name_id').find(payer_id) unless payer_id.blank?
      rc_set_name_id = payer.reason_code_set_name_id
      if $IS_PARTNER_BAC
        conditions = "reason_codes.status = 'ACCEPT' && "
      else
        conditions = ""
      end
      conditions += "reason_codes.reason_code_set_name_id = #{rc_set_name_id} && reason_codes.reason_code_description like ? && active = 1"
      @reason_codes = ReasonCode.find(:all, :conditions => [conditions, reason_code_description.to_s+'%'],
        :select => ['reason_codes.id, reason_codes.reason_code, reason_codes.reason_code_description'],
        :order => "reason_codes.id ASC", :limit => 10)
    rescue
      @reason_codes = nil
    end
    render :partial => 'auto_complete_for_reasoncode_desc'
  end

  # Type ahead in the HIPAA code field in RC Grid to retrieve all hipaa codes in the master hipaa codes table.
  def auto_complete_for_hipaacode(hipaa_code)
    begin
      conditions = "hipaa_codes.active_indicator = true and hipaa_codes.hipaa_adjustment_code like ?"
      @hipaa_codes = HipaaCode.find(:all, :conditions => [conditions, hipaa_code.to_s+'%'],
        :select => ['hipaa_codes.id, hipaa_codes.hipaa_adjustment_code, hipaa_codes.hipaa_code_description'],
        :order => "hipaa_codes.id ASC", :limit => 10)
    rescue
      @hipaa_codes = nil
    end
    render :partial => 'auto_complete_for_hipaacode'
  end

  def auto_complete_for_insurancepaymenteob_place_of_service
    code = params[:insurancepaymenteob][:place_of_service]
    place_of_service_codes = ('01'..'99').to_a
    @array = place_of_service_codes.find_all{|item| item =~ /#{code}/ }
    render :partial => 'auto_complete_for_array'
  end

  def auto_complete_for_provider_provider_last_name
    facility_id = params[:facility_id]
    provider_last_name = params[:provider][:provider_last_name]
    @array = Provider.select("provider_last_name").where("facility_id = #{facility_id}").order("provider_last_name ASC").collect(&:provider_last_name)
    render :partial => 'auto_complete_for_array'
  end

  def auto_complete_for_provider_provider_npi_number
    facility_id = params[:facility_id]
    provider_npi_number = params[:provider][:provider_npi_number]
    @array = Provider.select("provider_npi_number").where("facility_id = #{facility_id}").order("provider_npi_number ASC").collect(&:provider_npi_number)
    render :partial => 'auto_complete_for_array'
  end

  # Provides data for the ajax request that requires invalid Remark Codes.
  #
  # Input :
  # 'remark_codes_entered' : an array of Remark Codes. Eg ["code1", code2", ..]
  # 'remark_code_ids' : an array of Remark Code Field Ids. Eg ["id1", "id2", ..]
  # 'code_length' : an array containing the number of the RemarkCodes
  # in each field. Like ["1", "1", ..]
  # code_length.length == remark_code_ids.length
  #
  # With the Inputs a hash 'remark_codes_and_ids_in_hash' is created  with
  # keys as Field Ids & values as Remark Codes.
  #
  # Valid Remark Codes contained in the 'remark_codes_entered' is obtained
  #  and they are deleted from the 'remark_codes_and_ids_in_hash'.
  # Remaining in 'remark_codes_and_ids_in_hash' is the Output.
  #
  # Output:
  # 'remark_codes_and_ids' is an array containing Field Ids and its
  # Remark codes(in an array) in alternate position, starting with a Field Id.
  # Like [['id1', 'code1'], ['id2', 'code2'],..];
  # obtained out of 'remark_codes_and_ids_in_hash'.
  def get_invalid_remark_codes
    begin
      remark_codes_and_ids_in_hash = nil
      unless params[:remark_codes_entered].blank?
        remark_codes_entered = params[:remark_codes_entered].split(",")
        unless remark_codes_entered.blank?
          remark_code_ids = params[:remark_code_ids].split(",") unless
          params[:remark_code_ids].blank?
          code_length = params[:code_length].split(",") unless
          params[:code_length].blank?
          remark_codes_and_ids_in_hash = Hash.new
          code_length.each_with_index do | value, index |
            value = value.to_i
            codes = []
            value.downto(1) { | value | codes << remark_codes_entered.slice!(
                value - 1)}
            remark_codes_and_ids_in_hash[remark_code_ids[index]] = codes
          end
          remark_codes = remark_codes_and_ids_in_hash.values.flatten
          remark_codes = AnsiRemarkCode.find_all_by_adjustment_code(
            remark_codes).map(&:adjustment_code)
          remark_codes_and_ids_in_hash.values.each do |values|
            values.delete_if do |value|
              remark_codes.include?(value) || value == "" || value == nil
            end
          end
          remark_codes_and_ids_in_hash.delete_if do |key, value|
            value == "" || value == nil || value == []
          end
          remark_codes_and_ids_in_hash = remark_codes_and_ids_in_hash.to_a
        end
      end
    ensure
      invalid_remark_codes = remark_codes_and_ids_in_hash
    end
    render :text => invalid_remark_codes.to_json
  end

  def get_saved_transaction_type
    job = @job
    if !job.parent_job_id.blank?
      job = Job.find(job.parent_job_id)
    end
    image_for_job = job.images_for_jobs.first
    transaction_type = image_for_job.transaction_type
    transaction_type = transaction_type || ''
    render :text => transaction_type.to_json
  end

  def get_job_allocation_queue
    job = Job.find(params[:job_id])
    p "job"
    if(job.processor_id == current_user.id)
      queue_value = true
    else
      queue_value = false
    end
    render :text => queue_value.to_json
  end

  def calculate_total_claim_interest
    check = CheckInformation.find(:all, :conditions => "job_id = #{params[:job_id]}").first
    sum = InsurancePaymentEob.select("SUM(claim_interest) AS total_interest").
      where("check_information_id = #{check.id}").first
    total = sum.total_interest
    render :text => total
  end

  def get_upmc_tin
    result = UpmcFacility.select(:tin).find_by_name(params[:facility_name])
    tin = result.tin unless result.blank?
    render :text => tin
  end

  def user_report
    @job = @job || Job.find_by_id(params[:job_id])
    @total_qa_time = 0
    if (current_user.has_role?(:qa))
      @hour_eob_count = 0
      @eob = JobActivityLog.where("qa_id = ? and start_time >= ? and activity =?",current_user.id,(Time.now-12.hour),'QA Verification Started').order(:eob_id).select("sum(timediff(time_to_sec(end_time),time_to_sec(start_time)))AS total_eob_time,count(distinct(eob_id)) AS count ")
      @total_time = @eob.first.total_eob_time
      @current_eob_count = @eob.first.count
      if (!@total_time.blank? && @total_time != 0)
        @total_qa_time = (@total_time/3600)
        @hour_eob_count =  (@current_eob_count/@total_qa_time).round
      end
      batch_tat = @batch.target_time
      @batch_tat_in_ist =  format_complete_date_and_time(convert_to_ist_time(batch_tat))
      normalization_factor = @facility.details[:claim_normalized_factor]
      normalization_factor= normalization_factor.to_f
      @normalized_eobs_count =  (@current_eob_count*normalization_factor).round(2)

      @formatted_time = to_dot_time(@total_time)
    elsif (current_user.has_role?(:processor))
      processor_report
    end
  end

  def get_invalid_cpt_codes
    invalid_cpt_codes_and_ids = []
    if !params[:cpt_codes].blank? && !params[:cpt_code_ids].blank?
      cpt_codes = params[:cpt_codes].split(',')
      cpt_code_ids = params[:cpt_code_ids].split(',')
      cpt_codes_and_ids_in_hash = {}
      if !cpt_codes.blank? && !cpt_code_ids.blank?
        cpt_code_ids.each_with_index do | value, index|
          cpt_codes_and_ids_in_hash[value] = cpt_codes[index]
        end
        valid_cpt_codes = CptCode.find_all_by_name(cpt_codes).map(&:name)
        cpt_codes_and_ids_in_hash.each do |cpt_code_id, cpt_code|
          if !valid_cpt_codes.include?(cpt_code)
            invalid_cpt_codes_and_ids << [cpt_code, cpt_code_id]
          end
        end
      end
    end
    render :text => invalid_cpt_codes_and_ids.to_json
  end

  def check_presence_of_url
    require "net/http"
    require "uri"
    
    url = URI.parse(params[:url_for])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url.path)
    response = http.start {|http| http.request(request)}
    if(response.code == '200')
      queue_value = true
    else
      queue_value = false
    end
    render :text => queue_value.to_json
  end

  def any_eob_present
    eob_count = 0
    if params[:check_information_id].present?
      check = CheckInformation.select("COUNT(insurance_payment_eobs.id) AS insurance_eob_count, \
        COUNT(patient_pay_eobs.id)  AS patient_eob_count").
        joins("LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id \
               LEFT OUTER JOIN patient_pay_eobs ON patient_pay_eobs.check_information_id = check_informations.id").
        where(:id => params[:check_information_id]).first
      if check
        eob_count = check.insurance_eob_count.to_i + check.patient_eob_count.to_i
      end
    end
    if eob_count.zero?
      presence_of_eob = false
    else
      presence_of_eob = true
    end
    render :text => presence_of_eob.to_json
  end

  private

  def prepare
    logger.debug "prepare ->"
    @is_partner_bac = $IS_PARTNER_BAC
    @job = Job.includes({:batch => {:facility => :client}}).find(params[:job_id])
    @batch = @job.batch
    @facility = @batch.facility
    @client = @facility.client
    @parent_job_id = @job.parent_job_id
    @get_parent_job_id = @job.get_parent_job_id
    @client_name = @client.name.upcase
    @check_information = CheckInformation.includes(:micr_line_information, {:payer => :micr_line_informations}, :insurance_payment_eobs).find_by_job_id(@get_parent_job_id)
    if !@parent_job_id.blank?
      @parent_job = @check_information.job
    else
      @parent_job = @job
    end
    micr_line_information = @check_information.micr_line_information
    payer_of_micr = micr_line_information.payer if micr_line_information
    is_micr_payer_present = micr_line_information && payer_of_micr && @facility.details[:micr_line_info]
    @payer_of_check = is_micr_payer_present ? payer_of_micr : @check_information.payer
    @eobs_count_on_job = @check_information.insurance_payment_eobs.count
    @eob_type = eob_type
    @patient_pay = (@eob_type == 'Patient')
    @insurance_pay = (@eob_type == 'Insurance')
    @report_view = 'non_report'
    @is_multiple_reason_codes_applicable = @facility.details[:multiple_reason_codes_in_adjustment_field]
    @orbograph_correspondence_condition = @job.orbograph_correspondence?(@client_name)
    activity = JobActivityLog.new
    activity.current_user_id = current_user.id
    activity.associated_job_id = @job.id
    logger.debug "<- prepare"
  end

  def get_matching_payers(payer_name, payer_address_one)
    @payers = []
    if payer_name.present? || payer_address_one.present?
      job = Job.select("jobs.*, clients.name AS client_name").joins({:batch => :client}).
        where(:id => params[:job_id]).first
      if job.present?
        batch = job.batch
        facility = batch.facility
        get_parent_job_id = job.get_parent_job_id
        check_information = CheckInformation.select("check_informations.*, COUNT(insurance_payment_eobs.id) AS count_of_eobs").
          joins("LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id").
          where(:job_id => get_parent_job_id).first
        if check_information
          orbograph_correspondence_condition = job.orbograph_correspondence?(job.client_name)
          is_eob_saved = check_information.count_of_eobs  if !orbograph_correspondence_condition
          if is_eob_saved.to_i == 0 && (!$IS_PARTNER_BAC || check_information.correspondence?(batch, facility))
            excluded_payids = ["#{facility.commercial_payerid}", "#{facility.patient_payerid}"]
            @payers = Payer.approved_payers_begins_with_name_or_address(payer_name, payer_address_one).exclude_payids(excluded_payids)
          end
        end
      end
    end
    render :layout => false
  end
  
  # Initializes all the objects which are referred in the view
  # populates the form with all the fields of which the value is known beforehand
  # '@transaction_type_hash' contain the various transaction_types defined by business
  # ------------------------------------------------------------------
  # adjustment line show/hide logic:
  # adj line is a special type of service line, refer ServicePaymentEob#adjustment_line_is?
  # adj line is created and kept hidden in 2 cases -
  # i. insurance eob  ii. patient eob with multiple svc lines
  # in these cases, unless the user clicks on 'adjustment line' button, it should not be displayed
  #
  # It needs to be displayed (serves as manually indexable svc line) in 1 case -
  # iii. patient eob with single svc line & no mpi svc lines
  #
  # It need not be created in 1 case:
  # iv. patient eob with single svc line & mpi svc lines exist

  def populate_grid_data
    logger.debug "populate_grid_data ->"
    @insurance_eobs_saved ||= @check_information.insurance_payment_eobs.exists? if !@orbograph_correspondence_condition
    @patient_pay_eobs_saved ||= @check_information.patient_pay_eobs.exists?
    if @insurance_eobs_saved.blank? and @patient_pay_eobs_saved.blank?
      if @job.split_parent_job_id.blank?
        @check_information.index_file_check_amount = @check_information.check_amount
        @check_information.save
      end
    end
    @hide_adj_line = @insurance_pay
    if @hide_adj_line || @mpi_service_line.blank?
      svc_lines = []
      svc_lines << ServicePaymentEob.new
      @service_line = svc_lines
    end

    @micr_line_information = @check_information.micr_line_information unless
    @facility.details[:micr_line_info].blank?
    @amount_so_far = InsurancePaymentEob.amount_so_far(@check_information, @facility)
    @facility_name = @facility.name
    if(@facility_name == 'METROHEALTH SYSTEM' || @facility_name == 'AVITA HEALTH SYSTEMS')
      @faciltiy_lockbox = FacilityLockboxMapping.find_by_lockbox_number_and_facility_id(@batch.lockbox,@facility.id)
      @facility_lock_box_npi = @faciltiy_lockbox.npi unless @faciltiy_lockbox.nil?
      @facility_lock_box_tin = @faciltiy_lockbox.tin unless @faciltiy_lockbox.nil?
    end
    if @check_information.payer
      @payer = @check_information.payer
    elsif @micr_line_information && @micr_line_information.payer
      @payer = @micr_line_information.payer
    end

    if !@payer.blank?
      @payer_name = @payer.payer
      @payer_type = @payer.payer_type
      @payer_address_one = @payer.pay_address_one
      @payer_address_two = @payer.pay_address_two
      @payer_city = @payer.payer_city
      @payer_state = @payer.payer_state
      @payer_zip = @payer.payer_zip
      @payer_id = @payer.id
      @payid = @payer.supply_payid
      @rc_set_name_id = @payer.reason_code_set_name_id
      @payer_indicator_hash, @default_payer_indicator = applicable_payer_indicator(@payid)
    else
      @payer_indicator_hash = {"ALL" => "ALL"}
    end
    if @facility.details[:payer_tin]
      if @payer && !@payer.payer_tin.blank?
        @payer_tin = @payer.payer_tin
      elsif !@job.payer_tin.blank?
        @payer_tin = @job.payer_tin
      elsif @patient_pay
        @payer_tin = @facility.default_patpay_payer_tin unless @facility.default_patpay_payer_tin.blank?
      else
        @payer_tin = @facility.default_insurance_payer_tin unless @facility.default_insurance_payer_tin.blank?
      end
    end
    if @patient_837_information
      @organization = (@client_name.upcase.strip == 'UPMC' || @client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER') ? (@check_information.payee_name.blank? ?  @patient_837_information.payee_name : @check_information.payee_name ) :  (@patient_837_information.payee_name || @facility.name)
    else
      if (@check_information.insurance_payment_eobs.exists? && (@client_name.upcase.strip == 'UPMC' || @client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'))
        @organization = @check_information.insurance_payment_eobs.first.provider_organisation
      else
        @organization = @facility.name unless (@client_name.upcase.strip == 'UPMC' || @client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER')
      end
    end
    if not @insurance_pay
      @claim_type_hash = {"--" => "Primary", "Primary" => "Primary", "Secondary" => "Secondary", "Tertiary" => "Tertiary" }
    else
      @claim_type_hash = {"--" => "--", "Primary" => "Primary", "Secondary" => "Secondary", "Tertiary" => "Tertiary",
        "Denial" => "Denial", "RPP" => "Reversal of Prior payment",
        "PPO - No Payment" => "Predetermination Pricing Only - No Payment",
        "FAP" => "Processed as Primary - FAP" }
    end
    @payment_type_items = ['', 'Money Order', 'Check']
    #  HLSC Requirement
    #  @payment_type_items = ['']
    #  Exclude CHK from the dropdown box if the check type is correspondence
    #  @payment_type_items << 'CHK' unless @check_information.correspondence?
    #  @payment_type_items.concat(['EOB', 'HIP', 'PAY'])

    @job_payment_so_far = @check_information.total_payment_amount.to_f
    @transaction_type_hash = {"Complete EOB" => "Complete EOB",
      "Missing Check" => "Missing Check", "Check Only" => "Check Only", "Correspondence" => "Correspondence"}
    # The '@transaction_type_selection_value' holds the default seletion value of 'transaction_type'
    @transaction_type_selection_value = "Complete EOB"
    # The '@job_payment_so_far' holds the the total payment for this check
    if @job_payment_so_far.zero?
      @transaction_type_possible_value = "Complete EOB"
    else
      @transaction_type_possible_value = "Missing Check"
    end
    @hash_for_payee_type_format = {'' => nil, 'A' => 'A', 'B' => 'B', 'C' => 'C'}
    @hash_for_patpay_statement_fields = {'' => nil, 'Yes' => true, 'No' => false}
    @hash_for_statement_receiver = {'' => nil, 'Hospital' => 'Hospital', 'Physician' => 'Physician'}
    @show_patpay_statement_fields = (@facility.details[:patpay_statement_fields] &&
        @patient_pay)
    @twice_keying_fields = TwiceKeyingField.get_all_twice_keying_fields(@batch.client_id, @batch.facility_id, current_user.id, @rc_set_name_id)
    @allow_special_characters = @facility.details[:patient_account_number_hyphen_format]
    logger.debug "<- populate_grid_data"

  end

  def normalize_date(date)
    if (date != "mm/dd/yy" && !date.blank? )
      date_parts = date.split("/")
      "20" + date_parts[2] + "-" + date_parts[0] + "-" + date_parts[1]
    end
  end
  # Sets the CPT code to the default CPT code
  # when it is blank in the svc line object passed
  def set_procedure_code(service_line)
    if service_line && service_line.service_procedure_code.blank?
      service_line.service_procedure_code = @facility.default_cpt_code
      service_line
    end
  end

  def processor_completed_or_incompleted_job
    current_user.has_role?(:processor) &&
      (@job.processor_status == ProcessorStatus::COMPLETED || @job.processor_status == ProcessorStatus::INCOMPLETED)
  end

  def qa_completed_or_incompleted_job
    current_user.has_role?(:qa) &&
      (@job.qa_status == QaStatus::COMPLETED || @job.qa_status == QaStatus::INCOMPLETED)
  end

  def job_of_other_processor_or_qa
    other_processor_user = (current_user.has_role?(:processor) && @job.processor_id != current_user.id)
    other_qa_user = (current_user.has_role?(:qa) && @job.qa_id != current_user.id)
    other_processor_user || other_qa_user
  end

  def render_grid_links
    @show_insurance_link, @show_patpay_simplified_link, @show_patpay_nextgen_link, @show_orbograph_correspondance_link = false, false, false, false
    if (@patient_pay_eobs_saved || @insurance_eobs_saved)
      if(@insurance_eobs_saved == true && @job.payer_group != 'PatPay')
        @show_insurance_link = true
      elsif @job.payer_group == 'PatPay' && !@facility.patient_payerid.blank?
        if @insurance_eobs_saved == true && @facility_pat_pay_format == "Simplified Format"
          @show_patpay_simplified_link = true
        elsif @patient_pay_eobs_saved == true && @facility_pat_pay_format == "Nextgen Format"
          @show_patpay_nextgen_link = true
        end
      end
    elsif @orbograph_correspondence_condition
      @show_orbograph_correspondance_link = true

    else
      if (@client_name == 'GOODMAN CAMPBELL' && !@facility.patient_payerid.blank? && @facility_pat_pay_format == "Nextgen Format")
        if (@job.payer_group.blank? || @job.payer_group == '--')
          @show_insurance_link = true
          if @payer_of_check.blank? || (@payer_of_check && @payer_of_check.payer_type == 'PatPay')
            if !@facility.patient_payerid.blank? && @facility_pat_pay_format == "Nextgen Format"
              @show_patpay_nextgen_link = true
            end
          end
        elsif @job.payer_group == 'Insurance'
          @show_insurance_link = true
          @show_patpay_nextgen_link = false
        elsif @job.payer_group == 'PatPay'
          @show_insurance_link = true
          if !@facility.patient_payerid.blank? && @facility_pat_pay_format == "Nextgen Format"
            @show_patpay_nextgen_link = true
          end
        end
      else
        if @job.payer_group.blank? || @job.payer_group == '--'
          if @payer_of_check.blank? || (@payer_of_check && @payer_of_check.payer_type != 'PatPay')
            @show_insurance_link = true
          end
          if @payer_of_check.blank? || (@payer_of_check && @payer_of_check.payer_type == 'PatPay')
            if  (!@facility.patient_payerid.blank? && @facility_pat_pay_format == "Simplified Format")
              @show_patpay_simplified_link = true
            elsif (!@facility.patient_payerid.blank? && @facility_pat_pay_format == "Nextgen Format")
              @show_patpay_nextgen_link = true
            end
          end
        elsif @job.payer_group == 'Insurance'
          @show_insurance_link = true
        elsif @job.payer_group == 'PatPay'
          if (!@facility.patient_payerid.blank? && @facility_pat_pay_format == "Simplified Format")
            @show_patpay_simplified_link = true
          elsif (!@facility.patient_payerid.blank? && @facility_pat_pay_format == "Nextgen Format")
            @show_patpay_nextgen_link = true
          end
        end
      end
    end
  end

  def get_plan_type(payer)
    plan_type = nil
    plan_type_config = @facility.plan_type.to_s.upcase
    if plan_type_config == '837 SPECIFIC'
      if !@patient_837_information.blank?
        plan_type = @patient_837_information.plan_type
      end
    end
    if (plan_type.blank? || plan_type_config == 'PAYER SPECIFIC ONLY') && !payer.blank?
      plan_type = payer.normalized_plan_type(@client.id, @facility.id, @facility.details[:default_plan_type])
    end
    plan_type
  end

  def get_incomplete_comment_list
    @incomplete_comment_list = { '--' => '--',
      'Missing EOB image' => 'Missing EOB image',
      'Mismatch EOB image' => 'Mismatch EOB image',
      'Unreadable EOB image' => 'Unreadable EOB image',
      'Excluded payer' => 'Excluded payer','Roster' => 'Roster',
      'Roster without known MICR' => 'Roster without known MICR',
      'Self pay' => 'Self pay',
      'Misc-A/C# not starting with PM' => 'Misc-A/C# not starting with PM',
      'Updates' => 'Updates', 'Mail Returns' => 'Mail Returns',
      'Bankruptcy' => 'Bankruptcy','Credit Card' => 'Credit Card',
      'EFT/ERA EOB' => 'EFT/ERA EOB', 'Review' => 'Review',
      '835 Not Useful' => '835 Not Useful', 'Correspondence' => 'Correspondence',
      'EOB Out of Balance' => 'EOB Out of Balance', 'FL' => 'FL',
      'MISC' => 'MISC', 'Collections' => 'Collections',
      'Claim Updates' => 'Claim Updates', 'Refunds' => 'Refunds',
      'Exceptions' => 'Exceptions', '1099' => '1099'
    }
  end
  
end

