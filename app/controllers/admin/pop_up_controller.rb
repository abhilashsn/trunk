class Admin::PopUpController < ApplicationController

  include Admin::PopUpHelper
  require_role ["admin","supervisor"]
  layout 'standard'
  require 'will_paginate/array'
  # RAILS3.1 TODO
  # verify :method => :post, :only => [ :destroy ],
  #  :redirect_to => { :action => :add_message }

  def alert_list
    @alert_messages = ErrorPopup.find(:all,
      :select => "  error_popups.id as id\
                    , error_popups.comment as comment \
                    , error_popups.facility_id as facility_id \
                    , error_popups.start_date as start_date \
                    , error_popups.end_date as end_date \
                    , error_popups.processor_id as processor_id \
                    , error_popups.Question as Question \
                    , error_popups.choice1 as choice1 \
                    , error_popups.choice2 as choice2 \
                    , error_popups.choice3 as choice3 \
                    , error_popups.answer as answer \
                    , error_popups.field_id as field_id \
                    , error_popups.parent_id as parent_id \
                    , error_popups.reason_code_set_name_id as reason_code_set_name_id \
                    , error_popups.client_id as client_id \
                    , error_popups.end_date as end_date \
                    , payers.id as payer_id \
                    , payers.payer as payer \
                    , payers.payid as payid",
      :group => "error_popups.id",
      :conditions => "error_popups.parent_id is null",
      :joins => "LEFT OUTER JOIN payers ON payers.reason_code_set_name_id = error_popups.reason_code_set_name_id").
      paginate(:per_page => 15 ,:page => params[:page])
    date = Date.today
    today_in_utc = Time.utc(date.year, date.month, date.day)
    today_in_array = today_in_utc.to_s.split(' ')
    today_in_string = today_in_array[0]
    @today = Date.parse(today_in_string.to_s)
    @field_names_hash = get_field_name_list
  end
  
  def add_message
    @twice_key_field = TwiceKeyingField.new
    @selected_client = params[:client]
    @mode = params[:mode]
    @question = params[:question]
    @choice1 = params[:choice1]
    @choice2 = params[:choice2]
    @choice3 = params[:choice3]
    @answer = params[:answer]
    @all_users =  User.find(:all).compact.sort.collect {|c| [c.name, c.id]}
    if @answer != '' && @answer != nil
      if @answer == @choice1
        @selected_choice = 'choice1'
      elsif @answer == @choice2
        @selected_choice = 'choice2'
      elsif @answer == @choice3
        @selected_choice = 'choice3'
      end
    else
      @selected_choice = ''
    end
    @selected_duration = params[:duration]
    @field_names_hash = get_field_name_list
    @selected_field_name = params[:field_name]
    @comment = params[:comment]
    @payer = Payer.find(params[:payer]) unless params[:payer].blank?
    @document = DataFile.find(params[:document_id]) unless params[:document_id].blank?
       
    #If an alert is set for elements in MPI or OCR service lines, exclude it from getting listed
    # since the alert set for elements in the very first service line will be displayed in the list
    mpi_or_ocr_svc_line_fields = [ "date_service_from_", "date_service_to_",
      "procedure_code_", "bundled_procedure_code_", "rx_code_", "revenue_code_",
      "provider_control_number_", "units_", "service_modifier1_id", "service_modifier2_id",
      "service_modifier3_id", "service_modifier4_id", "service_procedure_charge_amount_id",
      "service_allowable_id", "service_expected_payment_id", "service_paid_amount_id",
      "service_non_covered_id", "noncovered_", "noncovered_desc_", "denied_id",
      "denied_", "denied__desc_", "service_discount_id", "discount_", "discount_desc_",
      "service_co_insurance_id", "coinsurance_", "coinsurance_desc_", "service_deductible_id",
      "deductuble_", "deductuble_desc_", "service_co_pay_id", "copay_", "copay_desc_",
      "service_submitted_charge_for_claim_id", "primary_", "primary_desc_",
      "service_contractual_amount_id", "contractual_", "contractual_desc_" ]


    @alert_messages = ErrorPopup.find(:all,
      :select => "  error_popups.id as id\
                    , error_popups.comment as comment \
                    , error_popups.facility_id as facility_id \
                    , error_popups.start_date as start_date \
                    , error_popups.end_date as end_date \
                    , error_popups.processor_id as processor_id \
                    , error_popups.Question as Question \
                    , error_popups.choice1 as choice1 \
                    , error_popups.choice2 as choice2 \
                    , error_popups.choice3 as choice3 \
                    , error_popups.answer as answer \
                    , error_popups.field_id as field_id \
                    , error_popups.parent_id as parent_id \
                    , error_popups.reason_code_set_name_id as reason_code_set_name_id \
                    , error_popups.client_id as client_id \
                    , error_popups.end_date as end_date \
                    , payers.id as payer_id \
                    , payers.payer as payer \
                    , payers.payid as payid",
      :group => "error_popups.id",
      :conditions => "error_popups.parent_id is null",
      :joins => "LEFT OUTER JOIN payers ON payers.reason_code_set_name_id = error_popups.reason_code_set_name_id").
      paginate(:per_page => 15 ,:page => params[:page])

    count_of_active_and_inactive_records = TwiceKeyingField.find_by_sql("
      SELECT COUNT(id) AS count_of_records FROM twice_keying_fields WHERE end_date >= DATE(NOW())
      UNION ALL
      SELECT COUNT(id) AS count_of_records FROM twice_keying_fields WHERE end_date < DATE(NOW())
      UNION ALL
      SELECT COUNT(id) AS count_of_records FROM error_popups WHERE end_date >= DATE(NOW())
      UNION ALL
      SELECT COUNT(id) AS count_of_records FROM error_popups WHERE end_date < DATE(NOW())")
    if count_of_active_and_inactive_records
      @active_twice_keying_field_records = count_of_active_and_inactive_records[0].count_of_records if count_of_active_and_inactive_records[0]
      @inactive_twice_keying_field_records = count_of_active_and_inactive_records[1].count_of_records  if count_of_active_and_inactive_records[1]
      @active_error_popup_records = count_of_active_and_inactive_records[2].count_of_records if count_of_active_and_inactive_records[2]
      @inactive_error_popup_records = count_of_active_and_inactive_records[3].count_of_records if count_of_active_and_inactive_records[3]
    end


    @users = User.find(:all,
      :select => "  users.id as id\
                    , users.login as login \
                    , roles_users.user_id as user_id \
                    , roles_users.role_id as role_id \
                    , roles.id as actual_role_id ",
      :conditions => "roles_users.role_id = 4",
      :joins => "LEFT OUTER JOIN roles_users ON roles_users.user_id = users.id \
                   LEFT OUTER JOIN roles ON roles.id = roles_users.role_id")
    @choices = ['', 'choice1', 'choice2', 'choice3']
    @duration = ['1 week','2 weeks', '3 weeks', '3 months', '6 months']
    @clients = Client.find(:all).collect {|c| [c.name.upcase, c.id]}
    date = Date.today
    today_in_utc = Time.utc(date.year, date.month, date.day)
    today_in_array = today_in_utc.to_s.split(' ')
    today_in_string = today_in_array[0]
    @today = Date.parse(today_in_string.to_s)
  end
   
  def edit
    @error_popups = ErrorPopup.find(params[:id])
    @choice_list = ['', 'choice1', 'choice2', 'choice3']
    @payer = Payer.find(params[:payer]) unless params[:payer].blank?
    if @error_popups.answer != ''
      if @error_popups.answer == @error_popups.choice1
        @selected_choice = 'choice1'
      elsif @error_popups.answer == @error_popups.choice2
        @selected_choice = 'choice2'
      elsif @error_popups.answer == @error_popups.choice3
        @selected_choice = 'choice3'
      end
    else
      @selected_choice = ''
    end
    data_file_id = ( params[:document_id].blank?) ? (@error_popups.data_file_id) : ( params[:document_id])
    @document = DataFile.find(data_file_id) unless data_file_id.blank?
  end
  
  def update
    if params[:answer]=="choice1"
      params[:answer]=params[:choice1]
    elsif params[:answer]=="choice2"
      params[:answer]=params[:choice2]
    elsif params[:answer]=="choice3"
      params[:answer]=params[:choice3]
    elsif params[:answer] == ""
      params[:answer] = ""
    end
    payer = Payer.find(params[:payer_id]) unless params[:payer_id].blank?
    reason_code_set_name_id = payer.reason_code_set_name_id unless payer.blank?
    error_popups = ErrorPopup.where(["(id = ?) or (parent_id = ?)", params[:id], params[:id]])
    
    error_popups.each do |error_popup|
      error_popup.end_date = params[:end_date]
      error_popup.comment = params[:comment]
      error_popup.Question = params[:question]
      error_popup.choice1 = params[:choice1]
      error_popup.choice2 = params[:choice2]
      error_popup.choice3 = params[:choice3]
      error_popup.answer = params[:answer]
      error_popup.data_file_id = params[:data_file_id] unless params[:data_file_id].blank?
      if error_popup.parent_id.blank?
        error_popup.field_id = params[:field_name]
      else
        mpi_svc_field_name = get_mpi_svc_field_name
        error_popup.field_id =  mpi_svc_field_name
      end
      error_popup.reason_code_set_name_id = reason_code_set_name_id

      @success = error_popup.save
    end
    if @success
      flash[:notice] = 'Details updated.'
      redirect_to :action => 'alert_list', :page => params[:page]
    else
      render :action => 'edit'
    end
  end

  def upload_document
    @documents = DataFile.scoped.paginate(:page => params[:page])
  end
   
  def save_upload_document
    file,flag,name= DataFile.save_upload_document(params[:upload])
    flash[:notice] = case file
    when 0
      "Select a file to upload"
    when true
      "File successfully uploaded"
    when false
      "Error while uploading"
    end
   
    if (file == true)
      redirect_to :action => 'upload_document',:document_id => flag,:document_name => name ,:value => file
    else
      redirect_to :action => 'upload_document',:flag => file
    end

  end

  def delete_documents
    files  = params[:documents_to_delete]   
    files.delete_if do |key, value|
      value == "0"
    end
   
    delet_popup =  ErrorPopup.where(:data_file_id =>files.keys).update_all(:data_file_id => nil)
    files.keys.each do |id|
      file_name = DataFile.find(id).file_name
      file_location = Rails.root.to_s + "/public/documents/" + file_name
      File.delete(file_location)
      DataFile.destroy id
    end
    if files.size != 0
      flash[:notice] = "Deleted #{files.size} File(s)."
    else
      flash[:notice] = "Please select atleast one File "
    end
    redirect_to :action => 'upload_document'
  end

  def get_facilities_by_client
    @facilities = Facility.find(:all ,:conditions => ["client_id =?", params[:id]], :order => ["name ASC"])
    update_facility
  end
  
  def create_alerts
    if params[:answer]=="choice1"
      params[:answer]=params[:choice1]
    elsif params[:answer]=="choice2"
      params[:answer]=params[:choice2]
    elsif params[:answer]=="choice3"
      params[:answer]=params[:choice3]
    elsif params[:answer] == ""
      params[:answer] = ""
    end
 
    payer = Payer.find(params[:payer_id]) unless params[:payer_id].blank?
    data_file_id = params[:data_file_id] unless params[:data_file_id].blank?
    if not params[:client].blank?
      if not params[:comment].blank?
        if not params[:field_name].blank?
          client_id = params[:client]
          duration_pop = params[:duration]
          field_name = params[:field_name]
          message = params[:comment].strip

          case duration_pop
          when '1 week'
            end_time = Time.now + 7.days
          when '2 weeks'
            end_time = Time.now + 14.days
          when '3 weeks'
            end_time = Time.now + 21.days
          when '3 months'
            end_time = Time.now + 3.months
          when '6 months'
            end_time = Time.now + 6.months
          end
            
          reason_code_set_name_id = payer.reason_code_set_name_id unless payer.blank?

          #When pop ups are set for any field in the 1st service line,
          #copy them for the corresponding fields in service lines retrieved through MPI or from OCR
          #mpi_svc_field_name will hold the id of the svc line field corresponding to field_name
          mpi_svc_field_name = get_mpi_svc_field_name
            
          if params[:user].blank?
            if params[:facility].blank?
              errormsg =  ErrorPopup.create(:Question => params[:question],
                :choice1 => params[:choice1], :choice2 => params[:choice2],
                :choice3 => params[:choice3], :answer => params[:answer],
                :reason_code_set_name_id => reason_code_set_name_id,
                :client_id => client_id, :start_date => Time.now,
                :end_date => end_time, :comment => message, :field_id => field_name, :data_file_id => data_file_id )
              if (!mpi_svc_field_name.nil? && !mpi_svc_field_name.blank?)
                ErrorPopup.create(:Question => params[:question],
                  :choice1 => params[:choice1], :choice2 => params[:choice2],
                  :choice3 => params[:choice3], :answer => params[:answer],
                  :reason_code_set_name_id => reason_code_set_name_id,
                  :client_id => client_id, :start_date => Time.now,
                  :end_date => end_time, :comment => message,
                  :field_id  => mpi_svc_field_name, :parent_id => errormsg.id, :data_file_id => data_file_id )
              end
            else
              facility_id_list = params[:facility][:id]
              facility_id_list.each do |facility_id|
                client_id = params[:client]
                errormsg =  ErrorPopup.create(:Question => params[:question],
                  :choice1 => params[:choice1], :choice2 => params[:choice2],
                  :choice3 => params[:choice3], :answer => params[:answer],
                  :reason_code_set_name_id => reason_code_set_name_id,
                  :client_id => client_id, :facility_id => facility_id, :start_date => Time.now,
                  :end_date => end_time, :comment => message, :field_id => field_name, :data_file_id => data_file_id )
                if (!mpi_svc_field_name.nil? && !mpi_svc_field_name.blank?)
                  ErrorPopup.create(:Question => params[:question],
                    :choice1 => params[:choice1], :choice2 => params[:choice2],
                    :choice3 => params[:choice3], :answer => params[:answer],
                    :reason_code_set_name_id => reason_code_set_name_id,
                    :client_id => client_id, :facility_id => facility_id, :start_date => Time.now,
                    :end_date => end_time, :comment => message,
                    :field_id  => mpi_svc_field_name, :parent_id => errormsg.id, :data_file_id => data_file_id )
                end
              end
            end

          else
            user_id_list = params[:user][:id]
            if params[:facility].blank?
              user_id_list.each do |user_id|
                errormsg =  ErrorPopup.create(:Question => params[:question],
                  :choice1 => params[:choice1], :choice2 => params[:choice2],
                  :choice3 => params[:choice3], :answer => params[:answer],
                  :reason_code_set_name_id => reason_code_set_name_id,
                  :client_id => client_id, :start_date => Time.now,
                  :end_date => end_time, :comment => message,
                  :processor_id => user_id, :field_id => field_name, :data_file_id => data_file_id )
                if (!mpi_svc_field_name.nil? && !mpi_svc_field_name.blank?)
                  ErrorPopup.create(:Question => params[:question],
                    :choice1 => params[:choice1], :choice2 => params[:choice2],
                    :choice3 => params[:choice3], :answer => params[:answer],
                    :reason_code_set_name_id => reason_code_set_name_id,
                    :client_id => client_id, :start_date => Time.now,
                    :end_date => end_time, :comment => message, :processor_id => user_id,
                    :field_id  => mpi_svc_field_name, :parent_id => errormsg.id, :data_file_id => data_file_id )
                end
              end
            else
              user_id_list = params[:user][:id]
              facility_id_list = params[:facility][:id]
              client_id = params[:client]
              facility_id_list.each do |facility_id|
                user_id_list.each do |user_id|
                  errormsg =  ErrorPopup.create(:Question => params[:question],
                    :choice1 => params[:choice1], :choice2 => params[:choice2],
                    :choice3 => params[:choice3], :answer => params[:answer],
                    :reason_code_set_name_id => reason_code_set_name_id,
                    :client_id => client_id, :facility_id => facility_id, :start_date => Time.now,
                    :end_date => end_time, :comment => message,
                    :processor_id => user_id, :field_id => field_name, :data_file_id => data_file_id )
                  if (!mpi_svc_field_name.nil? && !mpi_svc_field_name.blank?)
                    ErrorPopup.create(:Question => params[:question],
                      :choice1 => params[:choice1], :choice2 => params[:choice2],
                      :choice3 => params[:choice3], :answer => params[:answer],
                      :reason_code_set_name_id => reason_code_set_name_id,
                      :client_id => client_id, :facility_id => facility_id, :start_date => Time.now,
                      :end_date => end_time, :comment => message, :processor_id => user_id,
                      :field_id  => mpi_svc_field_name, :parent_id => errormsg.id, :data_file_id => data_file_id )
                  end
                end
              end
            end
          end
          flash[:notice]='Alert Set Sucessfully'
          redirect_to :action=>'add_message', :mode => params[:mode]
        else
          flash[:notice]='Please Select Field Name!'
          redirect_to :action => 'add_message',
            :client => params[:client], :payer => params[:payer_id],
            :choice1 => params[:choice1], :choice2 => params[:choice2],
            :choice3 => params[:choice3], :question => params[:question],
            :answer => params[:answer], :comment => params[:comment],
            :duration => params[:duration], :field_name => params[:field_name],
            :data_file_id => data_file_id, :mode => params[:mode]
        end # if field name not selected
      else
        flash[:notice]='Please Enter Comments!'
        redirect_to :action => 'add_message',
          :client => params[:client], :payer => params[:payer_id],
          :choice1 => params[:choice1], :choice2 => params[:choice2],
          :choice3 => params[:choice3], :question => params[:question],
          :answer => params[:answer], :comment => params[:comment],
          :duration => params[:duration], :field_name => params[:field_name],
          :data_file_id => data_file_id, :mode => params[:mode]
      end # if comments not enter
    else
      flash[:notice]='Please Select a Client!'
      redirect_to :action => 'add_message',
        :client => params[:client], :payer => params[:payer_id],
        :choice1 => params[:choice1], :choice2 => params[:choice2],
        :choice3 => params[:choice3], :question => params[:question],
        :answer => params[:answer], :comment => params[:comment],
        :duration => params[:duration], :field_name => params[:field_name],
        :data_file_id => data_file_id, :mode => params[:mode]
    end
  end

  def get_mpi_svc_field_name

    field_name = params[:field_name]
    svc_line1_fields =  ["dateofservicefrom", "dateofserviceto", "cpt_procedure_code", "bundled_procedure_code", "rx_code", "revenue_code", "provider_control_number", "units_id", "modifier_id1","modifier_id2", "modifier_id3", "modifier_id4", "charges_id", "allowable_id","expected_payment_id", "payment_id", "non_covered_id", "payercode_noncovered_adjustment_code", "noncovered_reasoncode_description_id", "discount_id", "payercode_discount_adjustment_code", "discount_reasoncode_description_id", "co_insurance_id", "payercode_coinsurance_adjustment_code", "coinsurance_reasoncode_description_id", "deductable_id", "payercode_deductable_adjustment_code", "deductable_reasoncode_description_id", "copay_id", "payercode_copay_adjustment_code", "copay_reasoncode_description_id", "primary_pay_payment_id", "payercode_primary_adjustment_code", "primary_payment_reasoncode_description_id", "contractualamount_id", "payercode_contractual_adjustment_code", "contractual_reasoncode_description_id"]
    mpi_svc_field_name = ""
    if(svc_line1_fields.include?field_name)
      case field_name
      when "dateofservicefrom"
        mpi_svc_field_name = "date_service_from_"
      when "dateofserviceto"
        mpi_svc_field_name = "date_service_to_"
      when "cpt_procedure_code"
        mpi_svc_field_name = "procedure_code_"
      when "bundled_procedure_code"
        mpi_svc_field_name = "bundled_procedure_code_"
      when "rx_code"
        mpi_svc_field_name = "rx_code_"
      when "revenue_code"
        mpi_svc_field_name = "revenue_code_"
      when "provider_control_number"
        mpi_svc_field_name = "provider_control_number_"
      when "units_id"
        mpi_svc_field_name = "units_"
      when "modifier_id1"
        mpi_svc_field_name = "service_modifier1_id"
      when "modifier_id2"
        mpi_svc_field_name = "service_modifier2_id"
      when "modifier_id3"
        mpi_svc_field_name = "service_modifier3_id"
      when "modifier_id4"
        mpi_svc_field_name = "service_modifier4_id"
      when "charges_id"
        mpi_svc_field_name = "service_procedure_charge_amount_id"
      when "allowable_id"
        mpi_svc_field_name = "service_allowable_id"
      when "expected_payment_id"
        mpi_svc_field_name = "service_expected_payment_id"
      when "payment_id"
        mpi_svc_field_name = "service_paid_amount_id"
      when "non_covered_id"
        mpi_svc_field_name = "service_non_covered_id"
      when "payercode_noncovered_adjustment_code"
        mpi_svc_field_name = "noncovered_"
      when "payercode_noncovered_desc_adjustment_desc"
        mpi_svc_field_name = "noncovered_desc_"
      when "denied_id"
        mpi_svc_field_name = "denied_id"
      when "payercode_denied_adjustment_code"
        mpi_svc_field_name = "denied_"
      when "payercode_denied_desc_adjustment_desc"
        mpi_svc_field_name = "denied_desc_"
      when "discount_id"
        mpi_svc_field_name = "service_discount_id"
      when "payercode_discount_adjustment_code"
        mpi_svc_field_name = "discount_"
      when "payercode_discount_desc_adjustment_desc"
        mpi_svc_field_name = "discount_desc_"
      when "co_insurance_id"
        mpi_svc_field_name = "service_co_insurance_id"
      when "payercode_coinsurance_adjustment_code"
        mpi_svc_field_name = "coinsurance_"
      when "payercode_coinsurance_desc_adjustment_desc"
        mpi_svc_field_name = "coinsurance_desc_"
      when "deductable_id"
        mpi_svc_field_name = "service_deductible_id"
      when "payercode_deductable_adjustment_code"
        mpi_svc_field_name = "deductuble_"
      when "payercode_deductuble_desc_adjustment_desc"
        mpi_svc_field_name = "deductuble_desc_"
      when "copay_id"
        mpi_svc_field_name = "service_co_pay_id"
      when "payercode_copay_adjustment_code"
        mpi_svc_field_name = "copay_"
      when "payercode_copay_desc_adjustment_desc"
        mpi_svc_field_name = "copay_desc_"
      when "primary_pay_payment_id"
        mpi_svc_field_name = "service_submitted_charge_for_claim_id"
      when "payercode_primary_adjustment_code"
        mpi_svc_field_name = "primary_"
      when "payercode_primary_desc_adjustment_desc"
        mpi_svc_field_name = "primary_desc_"
      when "contractualamount_id"
        mpi_svc_field_name = "service_contractual_amount_id"
      when "payercode_contractual_adjustment_code"
        mpi_svc_field_name = "contractual_"
      when "payercode_contractual_desc_adjustment_desc"
        mpi_svc_field_name = "contractual_desc_"
      end
    end
  end

  def select_payer
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    @previous_page = params[:previous_page]
    @mode = params[:mode]
    if search_field.blank?
      payers = Payer.where("client='PEMA'")
    else
      payers = filter_payers(criteria, compare, search_field, action = 'select', @previous_page, @mode)
    end
    @payers =  payers.paginate(:per_page => 30 ,:page => params[:page])
  end


  def filter_payers(field, comp, search, act, previous_page, mode)
    flash[:notice] = nil
    case field
    when 'Date Added'
      if search !~ /\d{4}-\d{2}-\d{2}/ then @flag_incorect_date = 0; end
      payers = Payer.where("date_added #{comp} '#{search}'")
    when 'Initials'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where( "initials like '%#{search}%'")
    when 'From Date'
      if search !~ /\d{4}-\d{2}-\d{2}/ then @flag_incorect_date = 0; end
      payers = Payer.where("from_date #{comp} '#{search}'")
    when 'Gateway'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("gateway like '%#{search}%'")
    when 'Payer Id'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("payid like '%#{search}%'")
    when 'Payer'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("payer like '%#{search}%'")
    when 'Address-1'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("pay_address_one like '%#{search}%'")
    when 'Address-2'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("pay_address_two like '%#{search}%'")
    when 'Address-3'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("pay_address_three like '%#{search}%'")
    when 'Phone'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.where("phone like '%#{search}%'")
    end
    if @flag_incorect_date == 0
      flash[:notice] = "Invalid Date format. Please re-enter! Format - DATE : yyyy-mm-dd"
      if act == 'select'
        redirect_to :action => 'select_payer',:previous_page => previous_page, :mode => mode
      else
        redirect_to :action => 'add_message'
      end
    elsif payers.size == 0
      flash[:notice] = "Search for \"#{search}\" did not return any results. Try another keyword!"
      if act == 'select'
        redirect_to :action => 'select_payer',:previous_page => previous_page, :mode => mode
      else
        redirect_to :action => 'add_message'
      end
    end
    return payers

  end

  def delete_messages
    mes = params[:message_to_delete]
    mes.delete_if do |key, value|
      value == "0"
    end
    mes.keys.each do |id|
      ErrorPopup.destroy id
      parent_record = ErrorPopup.find_by_parent_id(id)
      if parent_record 
        parent_record.destroy
        #        parent_record = nil
      end
    end
    if mes.size != 0
      flash[:notice] = "Deleted #{mes.size} Message(s)."
    else
      flash[:notice]="Please select atleast one "
    end
    redirect_to :action => 'add_message'
  end#delete 

  def document_list
    @facilityid=params[:facility]
    @payer1=params[:payer1]
    @userid =params[:userid]
    @docs = HlscDocument.find(:all).paginate(:page => params[:page], :per_page => 20)
  end
  
  def uploadfile
    upload = params[:upload]
    hlsc_file_comments = params[:hlsc_file_comment]
    if params[:upload][:datafile].size == 0
      flash[:notice] = "No File selected / File does not exist!"
      redirect_to :action => 'add_message'
    else
      name =  upload['datafile'].original_filename
      directory = "public/data/"
      location ="public/data/"+name
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
      new_hlsc_document_entry = HlscDocument.new
      new_hlsc_document_entry.file_name = name
      new_hlsc_document_entry.file_location = location
      new_hlsc_document_entry.file_comments = hlsc_file_comments
      new_hlsc_document_entry.file_created_time = Time.now
      new_hlsc_document_entry.user_id = session[:user_id]
      if new_hlsc_document_entry.save
        flash[:notice] = "File was successfully uploaded"
      else
        flash[:notice] = "Problem encountered during file upload!"
      end
      redirect_to :action =>'add_message'
    end
  end


  def destroy1 
    hlsc_file_list = HlscDocument.find_by_id(params[:id])
    pop_file_list = ErrorPopup.find_by_file_id(hlsc_file_list)
    if not pop_file_list.blank? 
      if pop_file_list.file_id==hlsc_file_list.id 
        flash[:notice] = "File is already in use!"
      end
    else
      hlsc_file_list = HlscDocument.find_by_id(params[:id]).destroy
      @file_location = hlsc_file_list.file_location
      File.delete("#{@file_location}") 
      if File.exist?("#{@file_location}")
      end
    end
    redirect_to :action => 'document_list'
  end

  def document_upload(upload)
    if upload.present? && upload['datafile'].present?
      name =  upload['datafile'].original_filename
      directory = "public/documents"
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
      file_name =  name
    else
      file_name = ""
    end
    file_name
  end


end

