# Copyright (c) 2007. client, Inc. All rights reserved.
require 'utils/rr_logger'
class Admin::FacilityController < ApplicationController
  require_role ["admin","supervisor","manager"]
  layout 'standard' ,:except=>[:config_835, :config_oplog]
  auto_complete_for :client_code, :adjustment_code
  auto_complete_for :hipaa_code, :hipaa_adjustment_code
  auto_complete_for :ansi_remark_code, :adjustment_code
  include Admin::FacilityHelper
  before_filter:check_edit_permissions, :only => [:update, :config_oplog_save, :config_835_save,
    :save_facility_cut_configurations, :delete_facility_cut_configurations]

  # RAILS3.1 TODO
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #  :redirect_to => { :action => :index }

  def index
    search_field = params[:to_find]
    criteria = params[:criteria]
    search_field.strip! unless search_field.nil?
    if search_field.blank?
      facilities = Facility
    else
      facilities = filter_facilities(criteria, search_field)
    end
    @facilities =   facilities.includes([:client,:facility_output_configs]).paginate :page => params[:page]
  end

  def clientcode
    @id= params[:id]
  end

  def filter_facilities(field, search)
    case field
    when 'Name'
      facilities = Facility.where("name like '%#{search}%'")
    when 'Code'
      facilities = Facility.where("sitecode like '%#{search}%'")
    when 'Client'
      facilities = Facility.where("clients.name like '%#{search}%'").includes([:client])
    end
    if facilities.size == 0
      flash[:notice] = " Search for \"#{search}\" did not return any results."
      redirect_to :action => 'index'
    end
    return facilities
  end

  def show
    @facility = Facility.find(params[:id])
    facility_list =  Facility.select("facilities.name,facilities.id").where("client_id =#{@facility.client_id}")
    @facility_list = facility_list.collect{ |user| [user.name, user.id]}.sort
  end

  def config_835
    #For 835 Segments
    @segments_options = {}
    @segments = {}
    @options = {}
    @facility = Facility.find(params[:id])
    eob_type = nil
    eob_type = (params[:eob_type].include? "patpay") ? "Patient Payment" : "Insurance EOB" if params[:eob_type]
    if eob_type.nil?
      @facility_config = FacilityOutputConfig.find(:first,:conditions=>["facility_id=#{params[:id]} and eob_type='Insurance EOB' and report_type='Output'"])
    else
      @facility_config = FacilityOutputConfig.find(:first,:conditions=>["facility_id=#{params[:id]} and eob_type='#{eob_type}' and report_type='Output'"])
    end
    @all_segements = FacilityLookupField.by_835
    unless @all_segements.blank?
      @segments_options = @all_segements.group_by{|i| i.lookup_type}
      @headers = @segments_options["835_SEG"].group_by{|i| i.category}
      @options = @segments_options["835_SEG_OPT"].group_by{|i| i.sub_category}
    end
    render :layout=>'output_config'
  end

  def config_835_save
    @eob_value = params[:eob_value]
    split_eob_type = params[:eob_value].split('_')
    eob_type = (split_eob_type.include? "insurance") ? "Insurance EOB" : "Patient Payment"
    facility_config = FacilityOutputConfig.find_by_facility_id_and_eob_type(params[:id],eob_type)
    query = "select details from facility_output_configs where id =#{facility_config.id}"
    old_facility_details_hash = FacilityOutputConfig.connection.execute(query);
    old_facility_details_hash_value = ""
    old_facility_details_hash.each do |val|
      old_facility_details_hash_value = val
    end
    @old_facility_config_details = facility_config.details.dup
    facility_config.multi_transaction = (split_eob_type.include? "multi") ? true : false
    @segments = FacilityLookupField.segment_835
    config_hash ={}
    @message = nil
    @segments.each do |segment|
      segment_name = "#{segment.sub_category.downcase}_segment".to_sym
      segment_value = {}
      unless params[segment_name].blank?
        params[segment_name].each do |key,values|
          segment_key = key
          if  !values[1].to_s.include?("@") and !values[0].to_s.include?("@")
            unless values[1].blank?
              if values[1].to_s.include?("]") and !values[0].to_s.include?("]")
                values.reverse!
                segment_value[key] = values
              end
            end
            segment_value[key] = params[segment_name].values_at(key).join("@")
            if !facility_config.details.blank?
              facility_config.details.merge!({"#{segment.sub_category.downcase}_segment"=>segment_value})
            else
              facility_config.details = {"#{segment.sub_category.downcase}_segment"=>segment_value}
            end
             
          else
            flash[:notice] = "Updation failed. Please check the data."
            redirect_to :action=>"config_835",:id=>params[:id],:facility_eob_type=>eob_type
            return nil
          end
        end
      end
      copy_data_from_835 = segment.sub_category.downcase+"_from_code"
      unless params[copy_data_from_835.to_sym].nil?
        if params[copy_data_from_835.to_sym] == "1"
          config = true
        else
          config = false
        end
        if config_hash.blank?
          config_hash = {"#{copy_data_from_835.to_sym}"=> config}
        else
          config_hash.merge!({"#{copy_data_from_835.to_sym}"=> config})
        end
      end
      if params[segment.sub_category.to_sym] == "1"
        config = true
      else
        config = false
      end
      if config_hash.blank?
        config_hash = {"#{segment.sub_category.downcase.to_sym}"=> config}
      else
        config_hash.merge!({"#{segment.sub_category.downcase.to_sym}"=> config})
      end
    end
    facility_config.details.merge!({:configurable_segments=> config_hash})
    if params[:disable_835_config][:status] == "1"
      facility_config.details.merge!({:configurable_835=> false})
    else
      facility_config.details.merge!({:configurable_835=> true})
    end
    if facility_config.save
      @new_facility_details = facility_config.details
      @facility = Facility.find(params[:id])
      @edit_flag = 0
      @edit_835_message = "\n\n"
      modified_time = Time.now.strftime("%d-%m-%Y  %H:%M:%S")
      @edit_835_subject = "The 835 configuration for #{eob_type} of #{@facility.name} is changed. Key : #{modified_time} "
      begin
        unless @old_facility_config_details[:configurable_segments].blank?
          query = "select details from facility_output_configs where id =#{facility_config.id}"

          new_facility_details_hash = FacilityOutputConfig.connection.execute(query);
          new_facility_details_hash_value = ""
          new_facility_details_hash.each do |val|
            new_facility_details_hash_value = val
          end
          log =  RevRemitLogger.new_logger(LogLocation::CONFIGEDITLOG)
          log.info "********************************************"
         
          log.info "Key : #{modified_time}"
          log.info "================================"
          log.info "Old Value :"
          log.info old_facility_details_hash_value
          log.info "================================"
          log.info "New Value :"
          log.info new_facility_details_hash_value
          log.info "================================"
          log.info "Modified by  #{@current_user.login} on #{modified_time}"
          log.info "********************************************"


          unless @old_facility_config_details[:configurable_segments].diff(@new_facility_details[:configurable_segments]).empty?
            @edit_flag = 1
            @edit_835_message += "Segment level changes\n\n"
            @edit_835_message += "This is the old hash\n\n"
            @edit_835_message += "#{@old_facility_config_details[:configurable_segments].diff(@new_facility_details[:configurable_segments])}"
            @edit_835_message += "\n\n\n"
            @edit_835_message += "This is the new hash \n\n"
            @edit_835_message += "#{@new_facility_details[:configurable_segments].diff(@old_facility_config_details[:configurable_segments])}"
            @edit_835_message += "\n\n\n"
          end
          @segments.each do |segment|
            segment_name = "#{segment.sub_category.downcase}_segment".to_sym
            unless params[segment_name].blank?
              segment_name_new = "#{segment.sub_category.downcase}_segment"
              unless @old_facility_config_details["#{segment_name_new}"].blank?
                unless (@old_facility_config_details["#{segment_name_new}"].diff(@new_facility_details["#{segment_name_new}"]).empty?)
                  @edit_flag = 1
                  @edit_835_message += "Value of segments modified\n\n\n"
                  @edit_835_message +=  "#{segment_name_new.upcase}"
                  @edit_835_message += "\n\n\n This is the old hash\n\n"
                  @edit_835_message +=  "#{@old_facility_config_details["#{segment_name_new}"]}"
                  @edit_835_message += "\n\n\n"
                  @edit_835_message += "This is the new hash\n\n"
                  @edit_835_message += "#{@new_facility_details["#{segment_name_new}"]}"
                  @edit_835_message += "\n\n\n"
                  @edit_835_message += "This is the difference \n\n"
                  @edit_835_message +=  "#{@new_facility_details["#{segment_name_new}"].diff(@old_facility_config_details["#{segment_name_new}"])}"
                  @edit_835_message += "\n\n\n\n"
                end
              end
            end
          end
          if @edit_flag == 1
            @edit_835_message += "\n\n"
            @edit_835_message += "Modified by "
            @edit_835_message += "#{@current_user.login}  on #{modified_time.to_s}"
            @edit_835_message += "\n\n"
            @edit_835_message += "URL "
            @edit_835_message += "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
            @edit_835_message += "\n\n"
            @edit_835_message +=  "IP address "
            @edit_835_message += "#{request.remote_ip}"
            @edit_835_message += "\n"
            RevremitMailer.notify_output_config_edit_status(old_facility_details_hash_value,new_facility_details_hash_value, @edit_835_subject, @edit_835_message).deliver
          end
        end
        @message = "Chosen Configs are saved..."
      rescue
        flash[:notice] = "Updation Failed"
        render :action=>"config_835",:id => params[:id], :eob_type => @eob_value
      end
    else
      flash[:notice] = "Updation Failed"
      render :action=>"config_835",:id => params[:id], :eob_type => @eob_value
    end
    
    unless @message.blank?
      flash[:notice] = @message
      redirect_to :action=>"config_835", :id => params[:id], :eob_type => @eob_value
    end
  end


  def config_oplog
    get_client_or_facility_config(params[:obj_type], params[:id])
    render :layout=>'output_config'
  end

  def config_oplog_save
    @opconfig = get_client_or_facility_config(params[:obj_type], params[:id])
    oplog_config = get_oplog_config(params)
    unless oplog_config.empty?
      unless @opconfig.blank?
        @opconfig.operation_log_config = oplog_config
        @opconfig.save
      else
        ClientOutputConfig.create(:client_id => params[:id], :report_type => 'Operation Log', :operation_log_config => oplog_config)
      end
      
      access_info = "HOST:#{request.host} IP:#{request.remote_ip}"
      RevremitMailer.notify_fc_config_edit(@config_object.name, current_user, 'Operation Log', Time.now, access_info).deliver
      flash[:notice] = "operation log configuration was sucessfully updated!"
    end
    redirect_to :action => "config_oplog", :id => params[:id], :obj_type => params[:obj_type]

  end

  def get_client_or_facility_config(config_type, id)
    if config_type == "client"
      @config_object = Client.find(id)
      @opconfig = ClientOutputConfig.find(:last, :conditions => ["client_id = ? and report_type = 'Operation Log'", params[:id]])
    else
      @config_object = Facility.find(id)
      @opconfig = FacilityOutputConfig.find(:last, :conditions => ["facility_id = ? and report_type = 'Operation Log'", params[:id]])
    end
    @parameters = FacilityLookupField.operation_log
    return @opconfig
  end

  def manage_other_outputs
    @facility = Facility.find(params[:id])
    @other_output_configs =  FacilityOutputConfig.find(:all, :conditions=>["facility_id=? and report_type='Other Outputs'",params[:id]])
    @other_output_params = FacilityLookupField.other_outputs
    @report_types = @other_output_params.select{|j| j.name == "ReportType"}    
  end

  def configure_other_outputs
    if request.method != "POST"        
      redirect_to :action => 'config_other_outputs', :id=> params[:id]
    else
      @facility = Facility.find(params[:id])
      @other_output_configs =  FacilityOutputConfig.find(:all, :conditions=>["facility_id=? and report_type='Other Outputs'",params[:id]])    
      @other_output_params = FacilityLookupField.other_outputs
      @report_types = @other_output_params.select{|j| j.name == "ReportType"}
      report_types = params["report_type"].values.uniq if params["report_type"]
      report_types ||= []
      report_types_present = @other_output_configs.collect(&:other_output_type)
      report_types_present ||= []
      (report_types - report_types_present).each do |rt|
        f = FacilityOutputConfig.new({:facility_id => @facility.id, :report_type => "Other Outputs", :other_output_type => rt })      
        f.save(:validate=>false)
      end      
      (report_types_present - report_types).each do |rt|
        conf = @other_output_configs.select{|o| o.other_output_type == rt}
        conf.first.destroy if conf.first
      end
      @other_output_configs =  FacilityOutputConfig.find(:all, :conditions=>["facility_id=? and report_type='Other Outputs'",params[:id]])    
      flash[:notice] = "Updated Sucessfully"
      redirect_to :action => :config_other_outputs, :id=> params[:id]
    end
  end


  def config_other_outputs
    @facility = Facility.find(params[:id])
    @other_output_configs = FacilityOutputConfig.find(:all, :conditions=>["facility_id=? and report_type='Other Outputs'",params[:id]])
    @parameters = FacilityLookupField.other_outputs
  end

  def config_cut
    @facility = Facility.find(params[:id])
    @facility_cut_relations = FacilityCutRelationship.find_all_by_facility_id(params[:id])
    @lockbox_numbers = FacilityLockboxMapping.find_all_by_facility_id(params[:id]).map{|x| x.lockbox_number}
    @cuts = ["A", "B", "C", "D", "E", "F"]
    @days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    @hours = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
  end

  def save_facility_cut_configurations
    params[:facility_cut_relationship][:time] = Time.parse(params[:facility_cut_relationship][:time]).utc
    FacilityCutRelationship.create(params[:facility_cut_relationship])
    facility = Facility.find(params[:facility_cut_relationship][:facility_id])
    access_info = "HOST:#{request.host} IP:#{request.remote_ip}"
    RevremitMailer.notify_fc_config_edit(facility.name, current_user, 'Cuts', Time.now, access_info).deliver
    @facility_cut_relations = FacilityCutRelationship.find_all_by_facility_id(params[:facility_cut_relationship][:facility_id])
    respond_to do |format|
      format.js{}
    end
  end

  def delete_facility_cut_configurations
    facility_cut_relation = FacilityCutRelationship.find(params[:id])
    facility = facility_cut_relation.facility
    facility_cut_relation.destroy
    access_info = "HOST:#{request.host} IP:#{request.remote_ip}"
    RevremitMailer.notify_fc_config_edit(facility.name, current_user, 'Cuts', Time.now, access_info).deliver
    @facility_cut_relations = FacilityCutRelationship.find_all_by_facility_id(facility_cut_relation.facility_id)
    respond_to do |format|
      format.js{}
    end
  end

  def save_other_outputs_config    
    @facility = Facility.find(params[:id])
    @other_output_configs = FacilityOutputConfig.find(:all, :conditions=>["facility_id=? and report_type='Other Outputs'",params[:id]])
    @parameters = FacilityLookupField.other_outputs
    msg =""
    @other_output_configs.reject!{|c| c.other_output_type == "Human Readable Eob"}
    @other_output_configs.each do |config|
      config.operation_log_config = params[config.other_output_type].merge({:report_type => config.other_output_type})
      config.save(:validate=>false)
      msg << "#{config.other_output_type} was saved sucessfully"
    end
    render :action=>"config_other_outputs"
  end

  def default_facility_values
    @clients = Client.find(:all).map{|client| [client.name, client.id]}
    # when the page comes, some values should be defaulted. So we pass value
    # for list boxes and true for check boxes and radio buttons to be checked by default
    #@app_root  = root_url
    @app_root  = ""
    @batch_load_type = ["C","P"]
    @simplified_patpay_multiple_service_lines = false
    @default_check_date_to_b_date = false
    @def_pat_name_payer = true
    @def_svc_chec_dt = true
    @check_date = true
    @payee_name = true
    @service_date_from = true
    @claim_type = true
    @multi_transaction = true
    if @is_partner_bac
      @is_warrant = true
      @is_transpose = true
    end
    @multi_transaction_pat_pay = true
    default_facility_values_for_output_setup_tab
    default_facility_values_for_grid_setup_tab

    @op_log_specific_file_name_comps = [
      ["Lockbox Number", "[Lockbox Num]"]
    ]

    # file name fields used for supplemental outputs
    @op_log_file_name_comps = file_name_componets.concat(@op_log_specific_file_name_comps)
    #    @predefined_check = true
    @isa_06_prepayer = true
    @isa_06_prepayer_pat_pay = true
    @partners = Partner.all
    # values to be fetched from facility_lookup_fileds are collected here
    @image_file_formats = []
    @index_file_formats = []
    @claim_file_parsers = []
    @claim_file_types = ['837', '1500', 'UB04','Custom-Xml']
    @patient_pay_formats = []
    @index_file_parsers = []
    @output_groups = []
    @output_formats = []
    @supplemental_output_formats = []
    @supplemental_output_groupings = []
    @supplemental_output_content_layouts = []
    @batch_upload_parsers = BatchUploadParser.order(:name).collect{|p| [p.name, p.id]}
    op_log_fields = ["batch_name", "export_date", "check_serial_number", "check_number"]
    op_log_fields += ["check_amount", "payer_name", "ststus", "image_id", "reject_reason"]
    name_bank = []
    name_non_bank = []
    op_log_fields.each{|field|instance_variable_set("@#{field}", true)}
    FacilityLookupField.all.each do |field|
      name = field.name
      case field.lookup_type
      when "Image File Format"
        @image_file_formats << name
      when "Index File Format"
        @index_file_formats << name
      when "Index File Parser Type"
        (name.include?("_bank")? (name_bank << name) : (name_non_bank << name))
        @is_partner_bac?  @index_file_parsers =  name_bank : @index_file_parsers = name_non_bank
      when "Claim File Parser"
        @claim_file_parsers << name
      when "Patient Pay Format"
        @patient_pay_formats << name
      when "Output Group"
        @output_groups << name
      when "Output Format"
        @output_formats << [name, name.downcase.gsub(" ", "_")]
      when "Supplemental Output Group"
        @supplemental_output_groupings << name
      when "Supplemental Output Content Layout"
        @supplemental_output_content_layouts << name
      when "Supplemental Output Format"
        @supplemental_output_formats << [name, name.downcase.gsub(" ", "_")]
      end
    end
    @index_file_parsers = [] if @index_file_parsers.nil?
    @patpay_output_groups = @output_groups.reject{|grouping| grouping == 'By Payer Id'}
    @index_file_parsers.sort!
    @claim_number = false
    @control_number = false
    @none = true
    #default values for balance record related fields
    @visibility_of_balancing_tab = false
    @balance_record_applicable = false
    @plb_applicable = false
    @missing_image_check = false
    @missing_image_balance = true
    @mismatch_image_check = false
    @mismatch_image_balance = true
    @unreadable_image_check = false
    @unreadable_image_balance = true
    @balancing_eob_check = false
    @balancing_eob_balance = true
    @correspondence_check = false
    @correspondence_balance = true
    @enable_crosswalk = {}
    @allowed_amount_mandatory = true
    @incomplete_rejection_comment = ""
    @complete_rejection_comment = ""
    @orbhograph_rejection_comment = ""
    @mpi_search_by_facility = false
    @mpi_search_by_client = true
    @output_notification_file_yes = false
    @output_notification_file_no = true
  end

  #This method is for setting balncing record values for editting or updating
  def balancing_record_values(facility)
    if facility.details && facility.details["balance_record_applicable"] == true
      @visibility_of_balancing_tab = true
      @disable = "style='disabled:false'"
    end
    @balancing_records = BalanceRecordConfig.where(:facility_id => facility.id)
  end

  #This is for setting values for details columns
  def set_values_for_details_column(details)
    details.each do |key, value|
      if value == "1"
        details[key] = true
      elsif value == "0"
        details[key] = false
      elsif value == 'control'
        details[key] = 'control'
      elsif value == 'claim'
        details[key] = 'claim'
      elsif value == 'none'
        details[key] = 'none'
      end
      instance_variable_set("@#{key}", details[key])
    end
    details
  end

  def new
    @facility = Facility.new
    @message = "New Lockbox"
    @action = "create"
    @button = "Save"
    @is_partner_bac = $IS_PARTNER_BAC
    default_facility_values
  end
  
  
  def save_facilities_npi_and_tin
    params[:facilities].each {|k,v|
      next if v["tin"].blank? && v["npi"].blank? 
      facility_npi_tin = FacilitiesNpiAndTin.new
      facility_npi_tin.npi = v["npi"]
      facility_npi_tin.facility_id = @facility.id
      facility_npi_tin.tin = v["tin"]
      facility_npi_tin.save!
    }
  end
  
  def assign_facilities_aba_and_dda
    params[:abaddas].each {|k,v|
      next if v["aba"].blank? && v["dda"].blank? 
      aba_dda_lookup = AbaDdaLookup.find_or_create_by_aba_number_and_dda_number(v["aba"],v["dda"])
      aba_dda_lookup.update_attributes(:facility_id => @facility.id)
      CrTransaction.update_site_status(aba_dda_lookup, "remove")
    }
  end
  
  def create
    flash[:notice] = nil
    new
    # storage into facilities table starts here
    params[:facility].each{|k,v| params[:facility][k] = nil if v.blank?}
    @facility = Facility.new(params[:facility])
    @facility.facility_npi = params['facilities']['1']['npi']
    @facility.facility_tin = params['facilities']['1']['tin']
    params[:facil][:client] = params[:facil][:client].to_i
    client = Client.find(params[:facil][:client])
    @facility.client = client
    @batch_load_type = params[:facility][:batch_load_type]
    @facility.batch_load_type = @batch_load_type.join(",") unless @batch_load_type.blank?
    @commercial_payer = true if params[:facil][:commercial_payer] == "1"
    @facility.details = set_values_for_details_column(params[:details])
    @facility.details[:default_cdt_qualifier] = params[:detail][:default_cdt_qualifier]
    @facility.details[:hide_incomplete_button_for_all] = params[:detail][:hide_incomplete_button_for_all]
    @facility.details[:hide_incomplete_button_for_non_zero_payment] = params[:detail][:hide_incomplete_button_for_non_zero_payment]
    @facility.details[:hide_incomplete_button_for_correspondance] = params[:detail][:hide_incomplete_button_for_correspondance]
    @facility.details[:npi_or_tin_validation] = params[:detail][:npi_or_tin_validation]
    @facility.details[:claim_normalized_factor] = params[:detail][:claim_normalized_factor]
    @facility.details[:service_line_normalised_factor] = params[:detail][:service_line_normalised_factor]
    @facility.details[:default_plan_type]= params[:detail][:default_plan_type]
    @facility.details[:configurable_835]= true if params[:detail][:configurable_835]  == "1"
    
    
    #used to insert the reasoncode crosswalk
    params[:details_str].each do |key,value|
      @facility.details[key] = value
    end
    params[:payer_classification].each do |key, value|
      @facility.details[key] = value
    end
    
    set_default_payer_details
    
    params[:details_insu] = set_facility_output_config_details_for_insurance(params[:details_insu])
    params[:details_pat_pay] = set_facility_output_config_details_for_patpay(params[:details_pat_pay])
    
    if params[:facility][:patient_pay_format] == "Simplified Format"
      @visible_multiple_service_lines = "style='visibility:visible;'"
    end
    @facility.is_check_date_as_batch_date = (params[:facility][:is_check_date_as_batch_date] == "1" ? true : false)
    @default_check_date_to_b_date = @facility.is_check_date_as_batch_date

    update_mpi_search
    
    if params[:facility][:random_sampling] == 'false'
      @facility.random_sampling_percentage = ''
    end
    if params[:facility][:default_service_date] == "Other"
      unless params[:other_date].blank?
        other_date = Date.strptime(params[:other_date], "%m/%d/%Y")
        @facility.default_service_date = other_date.strftime("%m/%d/%Y")
      end
      @def_svc_oth = true
      @visible_def_svc_date = "style='visibility:visible;'"
      @other_date = params[:other_date]
    elsif params[:facility][:default_service_date] == "Batch Date"
      @def_svc_bat_dt = true
    end
      
    handle_default_patient_data

    if !params[:facil][:unidentified_acc_no].blank?
      @facility.unidentified_account_number = params[:facil][:unidentified_acc_no].to_s.upcase
    end

    @facil = Hashit.new(params[:facil]) # changing a hash into an object using Hashit model
    # data storage into facility_output_configs table starts here.Type Insurance EOB
    @output_insu = FacilityOutputConfig.new(params[:output_insu])
    @output_insu.eob_type = "Insurance EOB"
    @output_insu.report_type = "Output"
    @predefined_check = true if params[:output_ins][:predefined_check] == "1"
    @payee_name_check = true if params[:detail][:payee_name_check] == "1"
    @output_insu.payment_corres_patpay_in_one_file = (params[:output_insu][:payment_corres_patpay_in_one_file] == "1" ? true : false)
    @payment_corres_patpay_in_one_file = @output_insu.payment_corres_patpay_in_one_file
    @output_insu.payment_corres_in_one_patpay_in_separate_file = (params[:output_insu][:payment_corres_in_one_patpay_in_separate_file] == "1" ? true : false)
    @payment_corres_in_one_patpay_in_separate_file = @output_insu.payment_corres_in_one_patpay_in_separate_file
    @output_insu.payment_patpay_in_one_corres_in_separate_file = (params[:output_insu][:payment_patpay_in_one_corres_in_separate_file] == "1" ? true : false)
    @payment_patpay_in_one_corres_in_separate_file = @output_insu.payment_patpay_in_one_corres_in_separate_file
    @output_insu.multi_transaction = (params[:output_insu][:multi_transaction] == "1" ? true : false)
    @multi_transaction = @output_insu.multi_transaction

    if params[:output_insu][:format] == "835" or params[:output_insu][:format] == "835_and_xml"
      if params[:details_insu][:isa_06] == "Other"
        params[:details_insu][:isa_06] = params[:details_ins][:other_isa_06]
        @details_ins = Hashit.new(params[:details_ins])
        @isa_06_other = true
        @visible_other_isa_06 = "style='visibility:visible;'"
      end
      params[:details_insu][:zero_pay] = nil if params[:details_insu][:zero_pay].blank?
      @details_insu = Hashit.new(params[:details_insu])
      @output_insu.details = params[:details_insu]
    else
      @disable_835_section_insu = true
    end
    @output_insu.details[:output_version] = params[:output_version]
   # @output_insu.details[:configurable_835] = (params[:enable_835_config][:status] == "1")? true :false
    @details_insu = Hashit.new(params[:details_insu])
    @output_insu.details = params[:details_insu]
    @facility.facility_output_configs << @output_insu
    # facility_output_configs. Type Patient Payment starts here
    unless params[:facil][:patient_payer] == "0"
      @visible_pat_pay_div = "style='display:block;'"
      @patient_payer = true
      @output_pat_pay = FacilityOutputConfig.new(params[:output_pat_pay])
      @output_pat_pay.eob_type = "Patient Payment"
      @output_pat_pay.report_type = "Output"
      @predefined_check_pat_pay = true if params[:output_pat_pa][:predefined_check] == "1"
      @output_pat_pay.multi_transaction = (params[:output_pat_pay][:multi_transaction] == "1" ? true : false)
      @multi_transaction_pat_pay = @output_pat_pay.multi_transaction

      if params[:output_pat_pay][:format] == "835" or params[:output_pat_pay][:format] == "835_and_xml"
        if params[:details_pat_pay][:isa_06] == "Other"
          params[:details_pat_pay][:isa_06] = params[:details_pat_pa][:other_isa_06]
          @details_pat_pa = Hashit.new(params[:details_pat_pa])
          @isa_06_other_pat_pay = true
          @visible_isa_06_other_pat_pay = "style='visibility:visible;'"
        end

        params[:details_pat_pay][:zero_pay] = nil if params[:details_pat_pay][:zero_pay].blank?
        params[:details_pat_pay][:lq_he] = nil if params[:details_pat_pay][:lq_he].blank?
        @output_pat_pay.details = params[:details_pat_pay]
        @details_pat_pay = Hashit.new(params[:details_pat_pay])
      else
        @disable_835_section_pat_pay = true
      end
      @facility.facility_output_configs << @output_pat_pay
    end

   set_instance_variables_for_supplemental_output
    # facility_output_configs. Type Patient Payment starts here
    
    set_instance_variable_for_oplogdetails

    if params[:supple]['Operation Log'] == "1"
      @oper_log = FacilityOutputConfig.new(params[:oper_log])
      @oper_log.report_type = "Operation Log"
      @oper_log.details = params[:op_log_details]
      @facility.facility_output_configs << @oper_log
      @visible_op_log = "style='visibility:visible;'"
    end
   
    # UI validations
    @flash_message = nil
    validation = validate_facility
    if !validation
      flash[:notice] = @flash_message
      render :action => "new"
    elsif @facility.save
      BalanceRecordConfig.create_or_delete_records(@facility, params[:balancing_record])
      facility_id = @facility.id
      create_or_update_rejection_comment(facility_id)
      if client.name.upcase == "PACIFIC DENTAL SERVICES"
        Facility.delay({:queue => 'updating_facility_mapped_details'}).update_facility_mapped_details(facility_id, params[:facility][:lockbox_number], params[:facility][:abbr_name], request.referer, current_user)
      end
      save_facilities_npi_and_tin
      assign_facilities_aba_and_dda
      #Default code Adjustment Reason
      default_code_adjustment_reason
      
      flash[:notice] = "Lockbox created successfully"
      redirect_to :action => "index"
    else
      flash[:notice] = "Lockbox creation failed"
      render :action => "new"
    end
  end

  def delete_facilities
    id_1 = 0
    flag = 0
    facilities = params[:facility_to_delete]
    facilities.delete_if do |key, value|
      value == "0"
    end
    facilities.keys.each do |id|
      unless Batch.find_by_facility_id(id).blank?
        id_1 = id
        flag = 1
        break
      end
    end

    if facilities.size != 0  && flag == 0

      Facility.destroy_all(["id in (?)",facilities.keys] ) unless facilities.keys.blank?
      flash[:notice] = "Deleted #{facilities.keys.size} facilitie(s)."
    elsif flag == 1
      flash[:notice] = "Facility '#{Facility.find(id_1).name}' cannot be deleted,since it has got reference to batch(s).
                                                                   Please select the facilities not having any references to batch(s)"
    else
      flash[:notice]= "Please select atleast one facility to delete "
    end
    redirect_to :action => 'index'
  end

  #@Geegee these actions have to be removed 
  def facility_reasoncode_payer
    render :text => "to be removed!"
    #redirect_to :action => 'facility_reasoncode',:id=>params[:id],:payer => params[:payer]
  end

  def  update_mpi_search
    if(params[:facility][:mpi_serach_type] == "FACILITY")
      @facility.details[:facility_ids] = params[:details][:facility_ids]
      @facility_ids_selected = params[:details][:facility_ids]
      @mpi_search_by_facility = true
      @mpi_search_by_client = false
    else
      @mpi_search_by_client = true
      @mpi_search_by_facility = false
      @facility.details[:facility_ids] = ''
    end
  end

  #@Geegee these actions have to be removed 
  def facility_reasoncode
    return     render :text => "to be removed!"
    @reason_code = []
    #   @payer_names = []
    @payers = []
    @facility_id = params[:id]
    @payer_names   = ["--"]
    @all_payer = FacilityPayerRelation.find(:all, :conditions => ["facility_id = ?",@facility_id])
    @all_payer.each do|payer|
      @payers << Payer.find(payer.payer_id).payer
    end
    @payers.each do|pay|
      @payer_names << pay
    end
    #   payer = Payer.find(:all,:conditions=>"facility_id= #{@facility_id}").map{|f|f.payer}
    #   @payer = @default_payer.concat(payer)
    @all_payers = Payer.find(:all)
    if(params[:payer].blank? or params[:payer]=="--" )
      @payers = FacilityPayerRelation.find(:all, :conditions => ["facility_id = ?",@facility_id])
      @payers.each do |payerid|
        @reason_code << ReasonCodesClientsFacilitiesSetName.find(:all,:conditions=>"payer_id =#{payerid.payer_id}")
      end
    else
      @payer_info = Payer.find_by_payer(params[:payer])
      @payers = FacilityPayerRelation.find(:all,:conditions=>"facility_id =#{@facility_id} and payer_id=#{@payer_info.id}")
      @payers.each do |payerid|
        @reason_code << ReasonCodesClientsFacilitiesSetName.find(:all,:conditions=>"payer_id =#{payerid.payer_id}")
      end
    end
  end

  def edit
    @facility = Facility.find(params[:id])
    @facility_npi_tin = FacilitiesNpiAndTin.find(:all,:conditions=> "facility_id =#{@facility.id}")
    @abaddalookups = AbaDdaLookup.where(:facility_id => @facility.id)
    facility_list =  Facility.select("facilities.name,facilities.id").where("client_id =#{@facility.client_id}")
    @facility_list = facility_list.collect{ |user| [user.name, user.id]}.sort
    @message = "Editing Lockbox"
    @action = "update"
    @button = "Edit"
    @edit = true
    @image_file_format_edit = !@facility.image_file_format.blank?
    @index_file_format_edit = !@facility.index_file_format.blank?
    @is_batch_upload = @facility.batch_upload_check
    @is_partner_bac = $IS_PARTNER_BAC
    default_facility_values
    @facility_ids_selected = @facility.details[:facility_ids]
    balancing_record_values(@facility)
    facil = {'client' => @facility.client.id, 'def_pat_first_name' => '', 'def_pat_last_name' => ''}
    @facil = Hashit.new(facil) # changing a hash into an object using Hashit model
    @details = @facility.details || {}
    @complete_rejection_comment, @incomplete_rejection_comment, @orbhograph_rejection_comment = RejectionComment.find_complete_and_incomplete_rejection_comments(@facility.id)
    #For editing reference code
    if @details["reference_code"] == true
      @ref_code_mandatory_visible = "style='visibility:visible'"
    end
    
    if @details["document_classification"] == true
      @doc_classification_mandatory_visible = "style='visibility:visible;'"
    end
    
    if @details["document_classification"] == true
      @same_doc_classificn_within_a_job_visible = "style='visibility:visible;'"
    end
    
    if @details["number"] == 'claim'
      @claim_number = true
      @none = false
    elsif @details["number"] == 'control'
      @control_number = true
      @none = false
    elsif @details["number"] == 'none'
      @control_number = true
    end

    if @details["output_notification_file"] == true
      @output_notification_file_yes = true
      @output_notification_file_no = false
    else
      @output_notification_file_no = true
      @output_notification_file_yes = false
    end
    
    if @facility.mpi_search_type == "FACILITY"
      @mpi_search_by_facility = true
      @mpi_search_by_client = false
    else
      @mpi_search_by_client = true
      @mpi_search_by_facility = false
    end
    @enable_double_keying_for_837, @disable_double_keying_for_837 = set_double_keying_for_837_fields
    @facility_specific_pay_name, @global_pay_name = set_facility_specific_or_global_pay_name
    @facility_specific_pay_id, @global_pay_id =  set_facility_specific_or_global_pay_id
    @enable_random_sampling, @disable_random_sampling = set_random_sampling

    @enable_crosswalk = {}
    @facility.default_codes_for_adjustment_reasons.each do |default_code|
      is_hipaa_absent = default_code.hipaa_code.blank?

      case  default_code.adjustment_reason
      when "noncovered"
        @non_covered_group_code = default_code.group_code
        @non_covered_hippa_default = ""
        @non_covered_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:noncovered] = default_code.enable_crosswalk
      when "contractual"
        @contractual_group_code = default_code.group_code
        @contractual_hippa_default = ""
        @contractual_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:contractual] = default_code.enable_crosswalk
      when "denied"
        @denied_group_code = default_code.group_code
        @denied_hippa_default = ""
        @denied_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:denied] = default_code.enable_crosswalk
      when "primary_payment"
        @ppp_group_code = default_code.group_code
        @ppp_hippa_default = ""
        @ppp_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:primary_payment] = default_code.enable_crosswalk
      when "copay"
        @copay_group_code = default_code.group_code
        @copay_hippa_default = ""
        @copay_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:copay] = default_code.enable_crosswalk
      when "coinsurance"
        @coinsurance_group_code = default_code.group_code
        @coinsurance_hippa_default = ""
        @coinsurance_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:coinsurance] = default_code.enable_crosswalk
      when "deductible"
        @deductible_group_code = default_code.group_code
        @deductible_hippa_default = ""
        @deductible_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:deductible] = default_code.enable_crosswalk
      when "discount"
        @discount_group_code = default_code.group_code
        @discount_hippa_default = ""
        @discount_hippa_default = default_code.hipaa_code.hipaa_adjustment_code unless is_hipaa_absent
        @enable_crosswalk[:discount] = default_code.enable_crosswalk
      end
    end
    
    @batch_load_type = @facility.batch_load_type.split(",") unless @facility.batch_load_type.blank?

    if @facility.patient_pay_format == "Simplified Format"
      @visible_multiple_service_lines = "style='visibility:visible;'"
    end

    #used for enable vrosswalk check options
    if @facility.enable_crosswalk == true
      @crosswalk_t = true
    else
      @crosswalk_f = true
      @crosswalk_t = false
    end

    case @facility.default_service_date
    when "Batch Date"
      @def_svc_bat_dt = true
      @def_svc_chec_dt = false
    when "Check Date"
      @def_svc_chec_dt = true
    else
      unless @facility.default_service_date.blank?
        @def_svc_oth = true
        if @facility.default_service_date.length == 8
          default_service_date = @facility.default_service_date.insert(6, '20')
        else
          default_service_date = @facility.default_service_date
        end
        other_date = Date.strptime(default_service_date, "%m/%d/%Y")
        @other_date = other_date.strftime("%m/%d/%Y")
        @visible_def_svc_date = "visibility:visible;"
      end
    end

    @default_check_date_to_b_date = true if @facility.is_check_date_as_batch_date == true
    unless @facility.default_patient_name == "Payer Name" or @facility.default_patient_name.nil?
      pat_name_arr = @facility.default_patient_name.split(",")
      facil = {'def_pat_first_name' => pat_name_arr[1], 'def_pat_last_name' => pat_name_arr[0], 'client' => @facility.client.id}
      @facil = Hashit.new(facil)
      @visible_oth_def_pat_name = "style='visibility:visible;'"
      @def_pat_name_oth = true
    end

    @unidentified_acc_no = @facility.unidentified_account_number
    @commercial_payer = true if @facility.commercial_payerid
    if @facility.patient_payerid
      @patient_payer = true
      @visible_pat_pay_div = "style='display:block;'"
    end

    unless @details.blank?
      @details.each{|k, v| instance_variable_set("@#{k}", v) unless k.respond_to?("include?") &&  k.include?('t.')}   # setting instance variables to pass values of checkboxes, 'unless k.include?'t.'' is a hack..Need to find the real issue
    end

    unless @facility.facility_output_configs.blank?
      @facility.facility_output_configs.each do |output|
        @output_insu = output if output.eob_type == "Insurance EOB"
        @output_pat_pay = output if output.eob_type == "Patient Payment"
        @oper_log = output if output.report_type == "Operation Log"
      end
      @predefined_check = true unless @output_insu.predefined_payer.nil?
      @multi_transaction = @output_insu.multi_transaction
      @payment_corres_patpay_in_one_file = @output_insu.payment_corres_patpay_in_one_file
      @payment_corres_in_one_patpay_in_separate_file = @output_insu.payment_corres_in_one_patpay_in_separate_file
      @payment_patpay_in_one_corres_in_separate_file = @output_insu.payment_patpay_in_one_corres_in_separate_file
      if !@output_insu.details.blank?  
        @zip_output_insurance =  @output_insu.details[:zip_output] if !@output_insu.details[:zip_output].blank?
        @insurance_output_folder =  @output_insu.details[:output_folder] if !@output_insu.details[:output_folder].blank?
        @content_835_no_wrap =  @output_insu.details[:content_835_no_wrap] if !@output_insu.details[:content_835_no_wrap].blank?
        @generate_null_835 =  @output_insu.details[:generate_null_835] if !@output_insu.details[:generate_null_835].blank?
        @ref_ev_batchid_insu = @output_insu.details[:ref_ev_batchid] if !@output_insu.details[:ref_ev_batchid].blank?
        @claim_level_allowed_amt_insu = @output_insu.details[:claim_level_allowed_amt] if !@output_insu.details[:claim_level_allowed_amt].blank?
        @correspondence_output_format = @output_insu.details[:correspondence_output_format].to_s if !@output_insu.details[:correspondence_output_format].blank?
        version = @output_insu.details[:output_version]
        case version
        when '4010'
          @v_4010 = true
        when '5010'
          @v_5010 = true
        when 'both'
          @v_both = true
        end
      end
      @convert_tiff_to_jpeg = @output_insu.details[:convert_tiff_to_jpeg] if @output_insu.details

      unless @output_insu.details[:bpr_16]
        details_bpr = @output_insu.details.merge(:bpr_16 => '')
      else
        details_bpr = @output_insu.details
      end
      @details_insu = Hashit.new(details_bpr) 
      unless @output_insu.details[:correspondence_output_format]
        details_correspondence_output_format= @output_insu.details.merge(:correspondence_output_format => '835')
      else
        details_correspondence_output_format = @output_insu.details
      end
      # converting hash into an object
      @details_insu = Hashit.new(details_correspondence_output_format)
      unless @output_insu.details[:zero_pay]
        details_zero_pay = @output_insu.details.merge(:zero_pay => '')
      else
        details_zero_pay = @output_insu.details
      end
      @details_insu = Hashit.new(details_zero_pay)    # converting hash into an object
      unless @output_insu.details[:bpr_16_correspondence]
        details_corr = @output_insu.details.merge(:bpr_16_correspondence => '')
      else
        details_corr = @output_insu.details
      end
      @details_insu = Hashit.new(details_corr)    # converting hash into an object
      unless @output_insu.details[:plb_separator]
        details_plb = @output_insu.details.merge(:plb_separator => ':')
      else
        details_plb = @output_insu.details
      end
      @details_insu = Hashit.new(details_plb) # converting hash into an object
      if @output_insu.format == "835" or @output_insu.format == "835_and_xml"
        unless @details_insu.isa_06 == "Predefined Payer ID"
          @isa_06_other = true
          @visible_other_isa_06 = "visibility:visible;"
          details_ins = {'other_isa_06' => @details_insu.isa_06}
          @details_ins = Hashit.new(details_ins)   # converting hash into an object
        end
        if @details_insu.methods.include? "interest_amount".to_sym # This check is added as a quick fix as this is a show stopper and due to time constraints.
          if @details_insu.interest_amount == "Add Interest With Payment"
            @interest_with_payment = true
            @interest_in_plb = false
          elsif @details_insu.interest_amount == "Interest in PLB"
            @interest_with_payment = false
            @interest_in_plb = true
          else
            @interest_with_payment = false
            @interest_in_plb = false
          end
        end
      else
        @disable_835_section_insu = true
      end

      unless @output_insu.details[:payee_name]
        details_payee_name = @output_insu.details.merge(:payee_name => '')
      else
        details_payee_name = @output_insu.details
      end
      @details_insu = Hashit.new(details_payee_name)    # converting hash into an object
      @payee_name_check = true unless @details_insu.payee_name == ""
      unless @output_pat_pay.blank?
        @default_patient_name =  @output_pat_pay.details[:default_patient_name] if @output_pat_pay.details
        @predefined_check_pat_pay = true unless @output_pat_pay.predefined_payer.nil?
        @multi_transaction_pat_pay = @output_pat_pay.multi_transaction
        if @output_pat_pay.format == "835" ||  @output_pat_pay.format == "835_and_xml"
          @details_pat_pay = Hashit.new(@output_pat_pay.details)
          unless @details_pat_pay.isa_06 == "Predefined Payer ID"
            @isa_06_other_pat_pay = true
            @visible_isa_06_other_pat_pay = "visibility:visible;"
            details_pat_pa = {'other_isa_06' => @details_pat_pay.isa_06}
            @details_pat_pa = Hashit.new(details_pat_pa)
          end
          unless @output_pat_pay.details[:plb_separator]
            details_plb_pat_pay = @output_pat_pay.details.merge(:plb_separator => ':')
          else
            details_plb_pat_pay = @output_pat_pay.details
          end
          @details_pat_pay = Hashit.new(details_plb_pat_pay)
          if @details_pat_pay.methods.include? "interest_amount".to_sym # This check is added as a quick fix as this is a show stopper and due to time constraints.
            if @details_pat_pay.interest_amount == "Add Interest With Payment"
              @interest_with_payment_pat_pay = true
              @interest_in_plb_pat_pay = false
            elsif @details_pat_pay.interest_amount == "Interest in PLB"
              @interest_with_payment_pat_pay = false
              @interest_in_plb_pat_pay = true
            else
              @interest_with_payment_pat_pay = false
              @interest_in_plb_pat_pay = false
            end
          end
        else
          @disable_835_section_pat_pay = true
        end
        @ref_ev_batchid_patpay = @output_pat_pay.details[:ref_ev_batchid] if !@output_pat_pay.details[:ref_ev_batchid].blank?
        if !@output_pat_pay.details.blank?  
          @zip_output_patpay =  @output_pat_pay.details[:zip_output] if !@output_pat_pay.details[:zip_output].blank?
          @patpay_output_folder = @output_pat_pay.details[:output_folder] if !@output_pat_pay.details[:output_folder].blank?
          @claim_level_allowed_amt_patpay = @output_pat_pay.details[:claim_level_allowed_amt] if !@output_pat_pay.details[:claim_level_allowed_amt].blank?
          @zip_nextgen_output = @output_pat_pay.details[:zip_nextgen_output] if !@output_pat_pay.details[:zip_nextgen_output].blank?
          @nextgen_output_folder = @output_pat_pay.details[:nextgen_output_folder] if !@output_pat_pay.details[:nextgen_output_folder].blank?
        end
      end

      if @facility.supplemental_outputs
        @facility.supplemental_outputs.split(",").each do |outpt|
          var = outpt.downcase.gsub(" ", "_").gsub("/", "")
          instance_variable_set("@#{var}", true)
        end
      end

      unless @oper_log.blank?
        @visible_op_log = "visibility:visible;"
        @oper_log.details.each{|k,v| instance_variable_set("@#{k}", v)}
        @oper_log_folder = @oper_log.details[:folder_name] if !@oper_log.details[:folder_name].blank?
      end

      unless @zip_output_patpay.blank?
        @visible_pat_pay_zip = "visibility:visible;"
      end
      unless @zip_output_insurance.blank?
        @visible_ins_zip = "visibility:visible;"
      end

      unless @insurance_output_folder.blank?
        @visible_ins_folder = "visibility:visible;"
      end
      unless @patpay_output_folder.blank?
        @visible_pat_folder = "visibility:visible;"
      end
      @visible_nextgen_zip = "visibility:visible;" if (!@zip_nextgen_output.blank? && @zip_nextgen_output == true)
      @visible_nextgen_folder = "visibility:visible;" if (!@nextgen_output_folder.blank? && @nextgen_output_folder == true)
    end
  end

  def destroy
    Facility.destroy params[:id]
    redirect_to :action => 'index'
  end

  # This have code references in Facility Administration. But the Reason Code Management from Facility Admin View is not being used.
  def change_code
    reason_code_payer = ReasonCodesClientsFacilitiesSetName.find(params[:id].split('/')[0])
    reason_code = reason_code_payer.reason_code
    @facility_id = params[:id].split('/')[1]
    if reason_code.ansi_remark_codes.blank?
      @ansi_remark_code = ""
    else
      @ansi_remark_code = reason_code.ansi_remark_codes.first.adjustment_code
    end
    if(!params[:client_code].blank? or !params[:hipaa_code].blank? )
      if $IS_PARTNER_BAC && !params[:client_code].blank?
        client_code = params[:client_code][:adjustment_code]
        if(!client_code.blank?)
          client_code = ClientCode.find_by_adjustment_code(client_code)
          if reason_code_payer.reason_codes_clients_facilities_set_names_client_codes.blank?
            reason_code_payer.client_codes << client_code  if !client_code.blank?
          end
        end
      end
      if(!params[:hipaa_code].blank? )
        hipaa_code = params[:hipaa_code][:hipaa_adjustment_code]
        if(!hipaa_code.blank?)
          hipaa_code = HipaaCode.find_by_hipaa_adjustment_code(hipaa_code)
          reason_code_payer.hipaa_code_id = hipaa_code.id if !hipaa_code.blank?
        end
      end
      unless params[:ansi_remark_code].blank?
        ansi_remark_code = params[:ansi_remark_code][:adjustment_code]
        unless ansi_remark_code.blank?
          ansi_remark_code_exists = AnsiRemarkCode.find(:first, :conditions => ["adjustment_code = ?", ansi_remark_code], :select => ["id"])
          unless ansi_remark_code_exists.blank?
            unless reason_code_payer.hipaa_codes.blank?
              if reason_code.reason_codes_ansi_remark_codes.blank?
                reason_code.ansi_remark_codes << ansi_remark_code_exists
              end
              flash[:notice] = "Reason Code was successfully updated with ANSI Remark Code - #{ansi_remark_code} "
            else
              flash[:notice] = 'Please enter a valid HIPAA code for this reason code to enter ANSI Remark Code'
            end
          else
            flash[:notice] = 'Please enter a valid ANSI Remark Code'
          end
        else
          flash[:notice] = 'Please enter valid Codes'
        end
      end
      reason_code.save
      reason_code_payer.save
      redirect_to :action => 'facility_reasoncode',:id=> @facility_id
    end
  end

  def add_payer
    payers  =  params[:pro_error_type][:id]
    payers.each do |payer|
      payer_id = Payer.find_by_payer(payer).id
      payer = FacilityPayerRelation.new
      payer.payer_id = payer_id
      payer.facility_id = params[:id]
      payer.save
    end
    redirect_to :action => 'facility_reasoncode',:id=> params[:id]
  end
  
  def update_tin_and_npi
    unless params[:facilities].blank?
      params[:facilities].each {|k,v|
        if v["id"].present?
          facility_npi_tin = FacilitiesNpiAndTin.find(v["id"]) 
          if v["npi"].blank? &&  v["tin"].blank?
            facility_npi_tin.destroy
          else
            facility_npi_tin.npi = v["npi"] 
            facility_npi_tin.tin = v["tin"] 
            facility_npi_tin.save!            
          end
        else
          if v["npi"].present? ||  v["tin"].present?
            fnt = FacilitiesNpiAndTin.new(v) 
            @facility.facilities_npi_and_tins << fnt
          end
        end
      }
      @facility.facility_npi = params['facilities']['1']['npi']
      @facility.facility_tin = params['facilities']['1']['tin']
    end
  end
  
  def update_aba_and_dda
    unless params[:abaddas].blank?
      params[:abaddas].each {|k,v|
        if v["id"].present? && v["aba"].blank? &&  v["dda"].blank?
          aba_dda_lookup = AbaDdaLookup.find(v["id"]) 
          aba_dda_lookup.update_attributes(:facility_id => nil)
          CrTransaction.update_site_status(aba_dda_lookup, "add")
        else
          aba_dda_lookup = AbaDdaLookup.find_or_create_by_aba_number_and_dda_number(v["aba"], v["dda"]) 
          aba_dda_lookup.update_attributes(:facility_id => @facility.id)
          CrTransaction.update_site_status(aba_dda_lookup, "remove")
        end
      }
    end
  end
    
  def update
    flash[:notice] = nil
    @message = "Editing Lockbox"
    @action = "update"
    @button = "Edit"
    @edit = true
    @is_partner_bac = $IS_PARTNER_BAC
    default_facility_values
    # storage into facilities table starts here
    @facility = Facility.find(params[:id])
    update_tin_and_npi
    update_aba_and_dda
    params[:facility].each{|k,v| params[:facility][k] = nil if v.blank?}
    @client = @facility.client
    params[:facil][:client] = @client.id
    @facility.attributes = params[:facility]
    @batch_load_type = params[:facility][:batch_load_type]
    facility_list =  Facility.select("facilities.name,facilities.id").where("client_id =#{@facility.client_id}")
    @facility_list = facility_list.collect{ |user| [user.name, user.id]}.sort
    @facility.facility_npi = params['facilities']['1']['npi']
    @facility.batch_load_type = @batch_load_type.join(",") unless @batch_load_type.blank?
    @facility.details = set_values_for_details_column(params[:details])
    @facility.details[:default_cdt_qualifier] = params[:detail][:default_cdt_qualifier]
    @facility.details[:hide_incomplete_button_for_all] = params[:detail][:hide_incomplete_button_for_all]
    @facility.details[:hide_incomplete_button_for_non_zero_payment] = params[:detail][:hide_incomplete_button_for_non_zero_payment]
    @facility.details[:hide_incomplete_button_for_correspondance] = params[:detail][:hide_incomplete_button_for_correspondance]
    @facility.details[:npi_or_tin_validation] = params[:detail][:npi_or_tin_validation]
    @facility.details[:claim_normalized_factor] = params[:detail][:claim_normalized_factor]
    @facility.details[:service_line_normalised_factor] = params[:detail][:service_line_normalised_factor]
    @facility.details[:default_plan_type] = params[:detail][:default_plan_type]
     @facility.details[:configurable_835]= true if params[:detail][:configurable_835]  == "1"
    if(params[:facility][:mpi_search_type] == "FACILITY")
      @facility.details[:facility_ids] = params[:details][:facility_ids]
      @facility_ids_selected = params[:details][:facility_ids]
      @mpi_search_by_facility = true
      @mpi_search_by_client = false
    else
      @mpi_search_by_client = true
      @mpi_search_by_facility = false
      @facility.details[:facility_ids] = ''
    end

    #used to insert the reasoncode crosswalk

    if params[:facility][:random_sampling] == 'false'
      @facility.random_sampling_percentage = ''
    end

    params[:details_str].each do |key,value|
      @facility.details[key] = value
    end
    @details = @facility.details || {}
    @details[:practice_id] = params[:details_str][:practice_id] if params[:details_str]
    params[:payer_classification].each do |key, value|
      @facility.details[key] = value
    end

    set_default_payer_details
    #Default code Adjustment Reason
    default_code_adjustment_reason
    #checks whether the refernece code is checked or not.
    if @facility.details["reference_code"]== false
      @facility.details["reference_code_mandatory"] = false
    end
    
    if params[:facil][:patient_payer] == "0"
      @facility.patient_payerid = nil
    else
      @patient_payer = true
    end
    if params[:facil][:commercial_payer] == "0"
      @facility.commercial_payerid = nil
    else
      @commercial_payer = true
    end
    if params[:facility][:patient_pay_format] == "Simplified Format"
      @visible_multiple_service_lines = "style='visibility:visible;'"
    end

    @facility.is_check_date_as_batch_date = (params[:facility][:is_check_date_as_batch_date] == "1" ? true : false)
    @default_check_date_to_b_date = @facility.is_check_date_as_batch_date
    if params[:facility][:default_service_date] == "Other"
      unless params[:other_date].blank?
        other_date = Date.strptime(params[:other_date], "%m/%d/%Y")
        @facility.default_service_date = other_date.strftime("%m/%d/%Y")
      end
      @visible_def_svc_date = "style='visibility:visible;'"
      @def_svc_oth = true
      @other_date = params[:other_date]
    elsif params[:facility][:default_service_date] == "Batch Date"
      @def_svc_bat_dt = true
    end
    
    handle_default_patient_data

    unidentified_account_number = get_unidentified_account_number
    @facility.unidentified_account_number = unidentified_account_number
    @facil = Hashit.new(params[:facil])
    @payment_corres_patpay_in_one_file = (params[:output_insu][:payment_corres_patpay_in_one_file] == "1" ? true : false)
    @payment_corres_in_one_patpay_in_separate_file = (params[:output_insu][:payment_corres_in_one_patpay_in_separate_file] == "1" ? true : false)
    @payment_patpay_in_one_corres_in_separate_file = (params[:output_insu][:payment_patpay_in_one_corres_in_separate_file] == "1" ? true : false)
    @multi_transaction = (params[:output_insu][:multi_transaction] == "1" ? true : false)
    # data storage into facility_output_configs table starts here.Type Insurance EOB
    @output_insu = @facility.facility_output_configs.find(:first, :conditions => "eob_type = 'Insurance EOB'")
    @output_insu = FacilityOutputConfig.new if @output_insu.blank?
    @output_insu.attributes = params[:output_insu]
    @output_insu.eob_type = "Insurance EOB"
    @output_insu.report_type = "Output"
    @output_insu.payment_corres_patpay_in_one_file = @payment_corres_patpay_in_one_file
    @output_insu.payment_corres_in_one_patpay_in_separate_file = @payment_corres_in_one_patpay_in_separate_file
    @output_insu.payment_patpay_in_one_corres_in_separate_file = @payment_patpay_in_one_corres_in_separate_file
    @output_insu.multi_transaction = @multi_transaction
    if params[:output_ins][:predefined_check] == "0"
      @output_insu.predefined_payer = nil
      @predefined_check = false
    else
      @predefined_check = true
    end
    params[:details_insu] = set_facility_output_config_details_for_insurance(params[:details_insu])
    params[:details_insu][:ref_ev_batchid] = (params[:details_insu][:ref_ev_batchid] == "1") ? true: false
    params[:detail][:payee_name_check] = (params[:detail][:payee_name_check] == "1") ? true: false
    params[:details_insu][:claim_level_allowed_amt] = (params[:details_insu][:claim_level_allowed_amt] == "1") ? true: false
    if params[:output_insu][:format] == "835" or params[:output_insu][:format] == "835_and_xml"
      if params[:details_insu][:isa_06] == "Other"
        params[:details_insu][:isa_06] = params[:details_ins][:other_isa_06]
        @details_ins = Hashit.new(params[:details_ins])
        @isa_06_other = true
        @visible_other_isa_06 = "style='visibility:visible;'"
      end
      params[:details_insu][:zero_pay] = nil if params[:details_insu][:zero_pay].blank?
      @details_insu = Hashit.new(params[:details_insu])
      if !@output_insu.details.blank?
        @output_insu.details.merge!(params[:details_insu])
      else
        @output_insu.details = params[:details_insu]
      end
      @output_insu.details[:output_version] = params[:output_version]
    #  @output_insu.details[:configurable_835] =  (params[:enable_835_config][:status] == "1")? true :false
    else
      @disable_835_section_insu = true
    end
    @output_insu.details[:output_folder] =  params[:details_insu][:output_folder]
    @output_insu.details = {} if @output_insu.details.blank?
    if params[:detail][:payee_name_check] == false || params[:detail][:payee_name_check] == "0"
      @output_insu.details[:payee_name] = ""
      @payee_name_check = false
    else
      @payee_name_check = true
    end
    @facility.facility_output_configs << @output_insu
    # facility_output_configs. Type Patient Payment starts here
    @output_pat_pay = @facility.facility_output_configs.find(:first, :conditions => "eob_type = 'Patient Payment'")
    unless params[:facil][:patient_payer] == "0"
      @visible_pat_pay_div = "style='visibility:visible;'"
      @patient_payer = true
      @output_pat_pay = FacilityOutputConfig.new if @output_pat_pay.blank?
      @output_pat_pay.attributes = params[:output_pat_pay]
      @output_pat_pay.eob_type = "Patient Payment"
      @output_pat_pay.report_type = "Output"
      @output_pat_pay.multi_transaction = (params[:output_pat_pay][:multi_transaction] == "1" ? true : false)
      @multi_transaction_pat_pay = @output_pat_pay.multi_transaction
      if params[:output_pat_pa][:predefined_check] == "0"
        @output_pat_pay.predefined_payer = nil
        @predefined_check_pat_pay = false
      else
        @predefined_check_pat_pay = true
      end
      params[:details_pat_pay] = set_facility_output_config_details_for_patpay(params[:details_pat_pay])
      params[:details_pat_pay][:ref_ev_batchid] = (params[:details_pat_pay][:ref_ev_batchid] == "1") ? true: false
      params[:details_pat_pay][:claim_level_allowed_amt] = (params[:details_pat_pay][:claim_level_allowed_amt] == "1") ? true: false
      params[:details_insu][:convert_tiff_to_jpeg] = (params[:details_insu][:convert_tiff_to_jpeg] == "1") ? true: false
      if params[:output_pat_pay][:format] == "835" or params[:output_pat_pay][:format] == "835_and_xml"
        if params[:details_pat_pay][:isa_06] == "Other"
          params[:details_pat_pay][:isa_06] = params[:details_pat_pa][:other_isa_06]
          @details_pat_pa = Hashit.new(params[:details_pat_pa])
          @isa_06_other_pat_pay = true
          @visible_isa_06_other_pat_pay = "style='visibility:visible;'"
        end
        params[:details_pat_pay][:zero_pay] = nil if params[:details_pat_pay][:zero_pay].blank?
        params[:details_pat_pay][:lq_he] = nil if params[:details_pat_pay][:lq_he].blank?
        #  @output_pat_pay.details = params[:details_pat_pay]
        @details_pat_pay = Hashit.new(params[:details_pat_pay])
        if !@output_pat_pay.details.blank?
          @output_pat_pay.details.merge!(params[:details_pat_pay])
        else
          @output_pat_pay.details = params[:details_pat_pay]
        end
      else
        @disable_835_section_pat_pay = true
        @output_pat_pay.details = nil
      end
      @facility.facility_output_configs << @output_pat_pay
    else
      @output_pat_pay.destroy unless @output_pat_pay.blank?
    end

    set_instance_variables_for_supplemental_output
    
    set_instance_variable_for_oplogdetails
    # facility_output_configs. Report Type Operation Log starts here
    @oper_log = @facility.facility_output_configs.find(:first, :conditions => "report_type = 'Operation Log'")
    if params[:supple]['Operation Log'] == "1"
      @oper_log = FacilityOutputConfig.new if @oper_log.blank?
      @oper_log.attributes = params[:oper_log]
      @oper_log.report_type = "Operation Log"
      @oper_log.details = params[:op_log_details]
      @facility.facility_output_configs << @oper_log
      @visible_op_log = "style='visibility:visible;'"
    else
      @oper_log.destroy unless @oper_log.blank?
    end

    # UI validations
    @flash_message = nil
    validation = validate_facility
    if !validation
      flash[:notice] = @flash_message
      render :action => "edit"
    elsif @facility.save
      access_info = "HOST:#{request.host} IP:#{request.remote_ip}"
      RevremitMailer.notify_fc_config_edit(@facility.name, current_user, 'Configuration', Time.now, access_info).deliver
      BalanceRecordConfig.create_or_delete_records(@facility, params[:balancing_record])
      facility_id = @facility.id

      create_or_update_rejection_comment(facility_id)
      if @client.name.upcase == "PACIFIC DENTAL SERVICES"
        Facility.delay({:queue => 'updating_facility_mapped_details'}).update_facility_mapped_details(facility_id, params[:facility][:lockbox_number], params[:facility][:abbr_name], request.referer, current_user)
      end
      flash[:notice] = "Lockbox edited successfully"
      redirect_to :action => "index"
    else
      flash[:notice] = "Lockbox could not be updated"
      render :action => "edit"
    end
  end

  def get_unidentified_account_number
    if !params[:facil][:unidentified_acc_no].blank?
      unidentified_account_number = params[:facil][:unidentified_acc_no].to_s.upcase
    else
      unidentified_account_number = params[:facil][:unidentified_acc_no]
    end
    unidentified_account_number
  end

  def create_or_update_rejection_comment(facility_id)
    incomplete_rejection_comment = RejectionComment.where("facility_id = #{facility_id} and job_status = 'incomplete'").first
    complete_rejection_comment = RejectionComment.where("facility_id = #{facility_id} and job_status = 'complete'").first
    orbhograph_rejection_comment = RejectionComment.where("facility_id = #{facility_id} and job_status = 'orbo_rejection'").first
    if incomplete_rejection_comment.present?
      incomplete_rejection_comment.update_attributes(:name => params[:incomplete_rejection_comment].strip )
    else
      RejectionComment.create(:name => params[:incomplete_rejection_comment].strip,
        :facility_id => facility_id)
    end

    if complete_rejection_comment.present?
      complete_rejection_comment.update_attributes(:name => params[:complete_rejection_comment].strip)
    else
      RejectionComment.create(:name => params[:complete_rejection_comment].strip,
        :facility_id => facility_id, :job_status => 'complete')
    end
    if orbhograph_rejection_comment.present?
      orbhograph_rejection_comment.update_attributes(:name => params[:orbhograph_rejection_comment].strip)
    else
      RejectionComment.create(:name => params[:orbhograph_rejection_comment].strip,
        :facility_id => facility_id, :job_status => 'orbo_rejection')
    end
  end

  def auto_complete_for_output_insu_predefined_payer
    search = params[:output_insu][:predefined_payer] + '%'
    find_options = {:conditions => ['lower(payer) like ?', search], :order => 'payer asc', :limit => 6}
    @payers = Payer.find(:all, find_options).map{|payer| payer.payer}
    render :inline => "<%= content_tag(:ul, @payers.map { |name| content_tag(:li, h(name)) }) %>"
  end

  def auto_complete_for_output_pat_pay_predefined_payer
    search = params[:output_pat_pay][:predefined_payer] + '%'
    find_options = {:conditions => ['lower(payer) like ?', search], :order => 'payer asc', :limit => 6}
    @payers = Payer.find(:all, find_options).map{|payer| payer.payer}
    render :inline => "<%= content_tag(:ul, @payers.map { |name| content_tag(:li, h(name)) }) %>"
  end

  def default_code_adjustment_reason
    parameters = {}
    parameters[:noncovered] = [ params[:default_codes_for_adjustment_reasons][:non_covered_hippa_default],
      params[:default_codes_for_adjustment_reasons][:non_covered_group_code],
      params[:enable_crosswalk][:noncovered] ]
    parameters[:contractual] = [ params[:default_codes_for_adjustment_reasons][:contractual_hippa_default],
      params[:default_codes_for_adjustment_reasons][:contractual_group_code],
      params[:enable_crosswalk][:contractual] ]
    parameters[:denied] = [ params[:default_codes_for_adjustment_reasons][:denied_hippa_default],
      params[:default_codes_for_adjustment_reasons][:denied_group_code],
      params[:enable_crosswalk][:denied] ]
    parameters[:primary_payment] = [ params[:default_codes_for_adjustment_reasons][:ppp_hippa_default],
      params[:default_codes_for_adjustment_reasons][:ppp_group_code],
      params[:enable_crosswalk][:primary_payment] ]
    parameters[:copay] = [ params[:default_codes_for_adjustment_reasons][:copay_hippa_default],
      params[:default_codes_for_adjustment_reasons][:copay_group_code],
      params[:enable_crosswalk][:copay] ]
    parameters[:coinsurance] = [ params[:default_codes_for_adjustment_reasons][:coinsurance_hippa_default],
      params[:default_codes_for_adjustment_reasons][:coinsurance_group_code],
      params[:enable_crosswalk][:coinsurance] ]
    parameters[:deductible] = [ params[:default_codes_for_adjustment_reasons][:deductible_hippa_default],
      params[:default_codes_for_adjustment_reasons][:deductible_group_code],
      params[:enable_crosswalk][:deductible] ]
    parameters[:discount] = [ params[:default_codes_for_adjustment_reasons][:discount_hippa_default],
      params[:default_codes_for_adjustment_reasons][:discount_group_code],
      params[:enable_crosswalk][:discount] ]

    DefaultCodesForAdjustmentReason.create_or_update(@facility.id, parameters)
  end

  def update_rejection_comments_for_client
    render :update do |page|
      params.each do |key, pair|
        if pair.nil?
          @client = Client.find_by_id(key)
          @client_rejection_comment = @client.rejection_comment
          break
        end
      end
      unless @client_rejection_comment.blank?
        page.replace_html("client_rejection_comments",
          "<label>#{@client.name} : </label><textarea name='client_rejection_comments_name' cols='25' rows='5'>#{@client_rejection_comment.name.gsub("- ", "").gsub("--","")}</textarea>
                         <input type='hidden' name='client_id' value = #{@client.id} />")
      else
        page.replace_html("client_rejection_comments", "<label>#{@client.name} : </label><textarea name='client_rejection_comments_name' cols='25' rows='5'></textarea>
                                      <input type='hidden' name='client_id' value = #{@client.id} />")
      end
    end
  end

  def set_facility_output_config_details_for_insurance(details_insu)
    if details_insu[:zip_output] == "1"
      @visible_ins_zip = "style='visibility:visible;'"
      details_insu[:zip_output] = true
    else
      details_insu[:zip_output] = false
    end

    if details_insu[:output_folder] == "1"
      details_insu[:output_folder] = true
      @visible_ins_folder = "style='visibility:visible;'"
    else
      details_insu[:output_folder] = false
    end
    details_insu[:content_835_no_wrap] = (details_insu[:content_835_no_wrap] == "1") ? true : false
    details_insu[:generate_null_835] = (details_insu[:generate_null_835] == "1") ? true: false
    details_insu[:convert_tiff_to_jpeg] = (details_insu[:convert_tiff_to_jpeg] == "1") ? true: false
    details_insu
  end
  
  def set_facility_output_config_details_for_patpay(details_patpay) 
    if details_patpay[:output_folder] == "1"
      @visible_pat_folder = "style='visibility:visible;'"
      details_patpay[:output_folder] = true
    else
      details_patpay[:output_folder] = false
    end

    if details_patpay[:zip_output] == "1"
      @visible_pat_pay_zip = "style='visibility:visible;'"
      details_patpay[:zip_output] = true
    else
      details_patpay[:zip_output] = false
    end
    
    details_patpay[:zip_nextgen_output] = (details_patpay[:zip_nextgen_output] == "1") ? true: false
    details_patpay[:nextgen_output_folder] = (details_patpay[:nextgen_output_folder] == "1") ? true: false
    details_patpay
  end

  def validate_facility
    
    facility, other_date, facil, output_ins, output_insu, details_insu, detail, output_pat_pay, output_pat_pa, details_pat_pay, oper_log, supple, count, details = params[:facility], params[:other_date], params[:facil], params[:output_ins],params[:output_insu], params[:details_insu], params[:detail],params[:output_pat_pay], params[:output_pat_pa], params[:details_pat_pay],params[:oper_log], params[:supple], count, params[:details] 
    
    validation = true
    groupings = ["SITE SPECIFIC","SINGLE DAILY MERGED CUT","SEQUENCE CUT"]
    if facility[:batch_load_type].blank?
      @flash_message = "Select atleast one type of batch to load in the Input Setup"
      validation = false
    elsif facility[:default_service_date] == "Other" and other_date.blank?
      @flash_message = "Select a date from Calendar for Default Date of Service in Grid setup if you are selecting Other"
      validation = false
    elsif facil[:commercial_payer] == "1" and facility[:commercial_payerid].blank?
      @flash_message = "Please give a commercial payer ID if you check checkbox"
      validation = false
    elsif facility[:default_patient_name] == "Other" and (facil[:def_pat_last_name].blank? or facil[:def_pat_first_name].blank?)
      @flash_message = "Please give default patient first and last name if you are selecting Other"
      validation = false
    elsif facility[:random_sampling] == 'true' and facility[:random_sampling_percentage].blank?
      @flash_message = "Please give Random Sampling Percentage"
      validation = false
    elsif facil[:patient_payer] == "1" and facility[:patient_payerid].blank?
      @flash_message = "Please give a patient payer ID if you check checkbox"
      validation = false
    elsif output_ins[:predefined_check] == "1" and output_insu[:predefined_payer].blank?
      @flash_message = "Please give a Predefined Payer in the Insurance EOB section of Output Setup if you check the checkbox"
      validation = false
    elsif output_insu[:file_name].blank? and !groupings.include?(output_insu[:grouping])
      @flash_message = "File Name Format in the Insurance EOB section of Output Setup cannot be empty"
      validation = false
    elsif detail[:payee_name_check] == true and details_insu[:payee_name].blank?
      @flash_message = "Please give a Payee Name in the Insurance EOB section of Output Setup if you check the checkbox"
      validation = false
    elsif details_insu[:zip_output] == true and output_insu[:zip_file_name].blank?
      @flash_message = "Zip File Name Format in the Insurance EOB section of Output Setup cannot be empty"
      validation = false
    elsif details_insu[:output_folder] == true and output_insu[:folder_name].blank?
      @flash_message = "Folder Name Format in the Insurance EOB section of Output Setup cannot be empty"
      validation = false
    elsif output_insu[:format] == "835" && details_insu[:isa_06].blank?
      @flash_message = "Text box cannot be blank if Other is selected for ISA 06/GS 02 in the Insurance EOB section of Output Setup"
      validation = false
    elsif facil[:patient_payer] == "1" and output_pat_pa[:predefined_check] == "1" and output_pat_pay[:predefined_payer].blank?
      @flash_message = "Please give a Predefined Payer in the Patient Payment section of Output Setup if you check the checkbox"
      validation = false
    elsif facil[:patient_payer] == "1" && facility[:patient_pay_format] == "Simplified Format" && output_pat_pay[:file_name].blank? and !groupings.include?(output_pat_pay[:grouping])
      @flash_message = "ANSI 835 File Name Format in the Patient Payment section of Output Setup cannot be empty"
      validation = false
    elsif facil[:patient_payer] == "1" && facility[:patient_pay_format] == "Nextgen Format" && output_pat_pay[:nextgen_file_name].blank?
      @flash_message = "NextGen File Name Format in the Patient Payment section of Output Setup cannot be empty"
      validation = false
    elsif details_pat_pay[:zip_output] == true and output_pat_pay[:zip_file_name].blank?
      @flash_message = "ANSI 835 Zip File Name Format in the Patient Payment section of Output Setup cannot be empty"
      validation = false
    elsif details_pat_pay[:output_folder] == true and output_pat_pay[:folder_name].blank?
      @flash_message = "ANSI 835 Folder Name Format in the Patient Payment section of Output Setup cannot be empty"
      validation = false
    elsif details_pat_pay[:zip_nextgen_output] == true and output_pat_pay[:nextgen_zip_file_name].blank?
      @flash_message = "NextGen Zip File Name Format in the Patient Payment section of Output Setup cannot be empty"
      validation = false
    elsif details_pat_pay[:nextgen_output_folder] == true and output_pat_pay[:nextgen_folder_name].blank?
      @flash_message = "NextGen Folder Name Format in the Patient Payment section of Output Setup cannot be empty"
      validation = false
    elsif output_pat_pay[:format] == "835" && details_pat_pay[:isa_06].blank?
      @flash_message = "Text box cannot be blank if Other is selected for ISA 06/GS 02 in the Patient Payment section of Output Setup"
      validation = false
    elsif supple['Operation Log'] == "1" && oper_log[:file_name].blank?
      @flash_message = "Please give atleast one File Name Format in the Supplemental Outputs section of Output Setup"
      validation = false
    elsif supple['Operation Log'] == "1" && count == 0
      @flash_message = "Please give atleast one field required for operation log in the Supplemental Outputs section of Output Setup"
      validation = false
    elsif details[:cpt_or_revenue_code_mandatory] == true && facility[:default_cpt_code].blank?
      @flash_message = "Please enter Default CPT Code"
      validation = false

    elsif detail[:default_cdt_qualifier].blank?
      @flash_message = "Please enter Default CDT Qualifier"
      validation = false
    elsif details[:reference_code] == true && details[:reference_code_mandatory] == true && facility[:default_ref_number].blank?
      @flash_message = "Please enter Default Ref#"
      validation = false
    elsif !detail[:claim_normalized_factor].blank? && !(/^(\d{0,2}\.)?\d{1,2}$/ === detail[:claim_normalized_factor])
      @flash_message = "Please enter Numeric value for Claim Normalised Factor less than 100"
      validation = false
    elsif !detail[:service_line_normalised_factor].blank? && !(/^(\d{0,2}\.)?\d{1,2}$/ === detail[:service_line_normalised_factor])
      @flash_message = "Please enter Numeric value for Service Line Normalised Factor less than 100"
      validation = false
    end
    validation
  end

  def get_faiclity_ids
    facility_list =  Facility.select("facilities.name,facilities.id").where("client_id =#{params[:client_id]}")
    @facility_list = facility_list.collect{ |user| [user.name, user.id]}.sort

    respond_to do |format|
      format.json { render :json => @facility_list}
    end
  end

  def set_double_keying_for_837_fields
    if @facility.double_keying_for_837_fields == false
      enable_double_keying_for_837 = false
      disable_double_keying_for_837 = true
    else
      disable_double_keying_for_837 = false
      enable_double_keying_for_837 = true
    end
    return [enable_double_keying_for_837, disable_double_keying_for_837]
  end
  
  def set_facility_specific_or_global_pay_name
    if @facility.details[:custom_payer_name_in_op] == true
      facility_specific_pay_name = true
      global_pay_name = false
    else
      facility_specific_pay_name = false
      global_pay_name = true
    end
    return [facility_specific_pay_name, global_pay_name]
  end
  
  def set_facility_specific_or_global_pay_id
    if @facility.details[:custom_payer_id_in_op] == true
      facility_specific_pay_id = true
      global_pay_id = false
    else
      facility_specific_pay_id = false
      global_pay_id = true
    end
    return facility_specific_pay_id, global_pay_id
  end

  def set_random_sampling
    if @facility.random_sampling == true
      enable_random_sampling = true
      disable_random_sampling = false
    else
      disable_random_sampling = true
      enable_random_sampling = false
    end
    return enable_random_sampling, disable_random_sampling
  end

  private
  
  def get_oplog_config (p)
    oplog_config = p.clone
    ["action", "id", "authenticity_token", "controller","commit","file_format_options","folder_format_options"].each do |k|
      oplog_config.delete(k)
    end
    oplog_config
  end

  def check_edit_permissions
    unless current_user.fc_edit_permission
      flash[:notice] = "You don't have Write Access. Please contact Admin"
      redirect_to request.referer
    end
  end
  
 def handle_default_patient_data
    if params[:facility][:default_patient_name] == "Other"
      @def_pat_name_oth = true
      @visible_oth_def_pat_name = "style='visibility:visible;'"
      unless params[:facil][:def_pat_last_name].blank? or params[:facil][:def_pat_first_name].blank?
        @facility.default_patient_name = params[:facil][:def_pat_last_name] + "," + params[:facil][:def_pat_first_name]
      end
    end
  end
  
  def set_instance_variable_for_oplogdetails
    count = 0
    params[:op_log_details].each do |k,v|
      if v == "1"
        params[:op_log_details][k] = true
        instance_variable_set("@#{k}", true)
        count += 1
      else
        params[:op_log_details][k] = false
        instance_variable_set("@#{k}", false)
      end
    end
  end
  
  def set_instance_variables_for_supplemental_output
    suppl_outputs = ""
    params[:supple].each do |k,v|
      if v == "1"
        suppl_outputs << k + ","
        var = k.downcase.gsub(" ", "_").gsub("/","")
        instance_variable_set("@#{var}", true)
      end
    end
    @facility.supplemental_outputs = suppl_outputs.chop
  end
  
  def set_default_payer_details
      params[:default_payer].each do |key, value|
      element = ('default_payer_' + key.to_s).to_sym
      @facility.details[element] = value.to_s.upcase
    end
  end

end
