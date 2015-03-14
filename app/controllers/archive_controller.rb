require 'adjustment_reason'
include AdjustmentReason
require 'will_paginate/array' 
class ArchiveController < ApplicationController
  ##   before_filter :validate_supervisor
    require_role ["admin", "processor","qa","manager","partner","supervisor","client",'facility','TL']
  require_role ["manager", "admin"],:only=>[:regenerate]
  
  layout 'datacapture_for_archive_view',:except =>[:view_log,:eob_information_summary, :search, :viewimage]
  
  def regenerate
    @insurance_eob_regenerate = InsurancePaymentEob.find(:all,:conditions => "eob_regenerate='1'")
    @patient_eob_regenerate = PatientPayEob.find(:all,:conditions => "patient_pay_eob_regenerate='1'")
  end
   
  def view_log
    @eob_id = params[:eob_id]
    @job_id = params[:jobid]
    @eob_type = nil
    @list =[]
    if @eob_id != "0" && !@eob_id.blank?
      check_information = CheckInformation.find_by_job_id(@job_id)
      eob_type = CheckInformation.where("job_id =?",@job_id).joins("inner join payers on payers.id = check_informations.payer_id").select("payers.payer")
      @eob_type = eob_type.first.payer unless eob_type.blank?
      batch =  Job.where("jobs.id=?",@job_id).joins('inner join batches on batches.id = jobs.batch_id').select("batches.id")
      if !@eob_type.blank?
        @ins_eob =  InsurancePaymentEob.find_by_id(@eob_id)
        eob=@ins_eob
      else
        @patient_data =  PatientPayEob.find_by_id(@eob_id)
        eob =@patient_data
      end

      @client_log = ClientActivityLog.where("client_activity_logs.eob_id = ?", @eob_id).joins("inner join users on users.id = client_activity_logs.user_id" ).select("client_activity_logs.activity as activity,\
client_activity_logs.start_time as start_time, users.name user_name")
      @list << @client_log

      batch_id = batch.first.id
      @output_log = OutputActivityLog.where("output_activity_logs.batch_id=  ?", batch_id).joins("inner join users on users.id = output_activity_logs.user_id" ).select("output_activity_logs.activity as activity,\
output_activity_logs.start_time as start_time, users.name user_name")
      @list << @output_log

      @regenerated_log = OutputRegeneratedLog.where("output_regenerated_logs.eob_id = ?", @eob_id).joins("inner join users on users.id = output_regenerated_logs.user_id" ).select("output_regenerated_logs.activity as activity,\
output_regenerated_logs.start_time as start_time, users.name user_name")
      @list << @regenerated_log

      @jobs_allocated = JobActivityLog.where("job_activity_logs.job_id = ? && job_activity_logs.eob_id IS NULL", @job_id).
        joins("LEFT OUTER JOIN users user_proc ON user_proc.id = job_activity_logs.processor_id   \
          LEFT OUTER JOIN users user_qa ON user_qa.id = job_activity_logs.qa_id  \
          LEFT OUTER JOIN users user_allocater ON  user_allocater.id =job_activity_logs.allocated_user_id  " ).
        select("job_activity_logs .activity AS activity,
          job_activity_logs.start_time AS start_time,\
          user_proc.name AS processorname,\
          user_qa.name AS qa_name ,\
          user_allocater.name AS allocater_name,
          job_activity_logs.object_name,
          job_activity_logs.field_name,
          job_activity_logs.old_value,
          job_activity_logs.new_value")
      @list << @jobs_allocated
      
      @eobs_allocated = JobActivityLog.where("job_activity_logs.eob_id = ?",  @eob_id).
        joins("LEFT OUTER JOIN users user_proc ON user_proc.id = job_activity_logs.processor_id   \
          LEFT OUTER JOIN users user_qa ON user_qa.id = job_activity_logs.qa_id  \
          LEFT OUTER JOIN users user_allocater ON  user_allocater.id =job_activity_logs.allocated_user_id  " ).
        select("job_activity_logs .activity AS activity,
          job_activity_logs.start_time AS start_time,\
          user_proc.name AS processorname,\
          user_qa.name AS qa_name ,\
          user_allocater.name AS allocater_name,
          job_activity_logs.object_name,
          job_activity_logs.field_name,
          job_activity_logs.old_value,
          job_activity_logs.new_value")
      @list << @eobs_allocated

      @list << JobActivityLog.find_by_sql("SELECT job_activity_logs .activity AS activity,
        job_activity_logs.start_time AS start_time, \
        job_activity_logs.end_time AS end_time, \
        user_proc.name AS processorname, \
        user_qa.name AS qa_name, \
        user_allocater.name AS allocater_name, \
        job_activity_logs.object_name, \
        job_activity_logs.field_name, \
        job_activity_logs.old_value, \
        job_activity_logs.new_value \
        FROM job_activity_logs \
        LEFT OUTER JOIN users user_proc ON user_proc.id = job_activity_logs.processor_id  \
        LEFT OUTER JOIN users user_qa ON user_qa.id = job_activity_logs.qa_id \
        LEFT OUTER JOIN users user_allocater ON  user_allocater.id =job_activity_logs.allocated_user_id \
        WHERE object_name = 'reason_codes' AND object_id IN \
        (SELECT reason_code_id FROM reason_codes_jobs WHERE parent_job_id = #{@job_id}) \

        UNION \

        SELECT job_activity_logs .activity AS activity, \
        job_activity_logs.start_time AS start_time, \
        job_activity_logs.end_time AS end_time, \
        user_proc.name AS processorname, \
        user_qa.name AS qa_name , \
        user_allocater.name AS allocater_name, \
        job_activity_logs.object_name, \
        job_activity_logs.field_name, \
        job_activity_logs.old_value, \
        job_activity_logs.new_value \
        FROM job_activity_logs \
        LEFT OUTER JOIN users user_proc ON user_proc.id = job_activity_logs.processor_id  \
        LEFT OUTER JOIN users user_qa ON user_qa.id = job_activity_logs.qa_id \
        LEFT OUTER JOIN users user_allocater ON  user_allocater.id =job_activity_logs.allocated_user_id \
        WHERE object_name = 'payers' AND object_id IN \
        (SELECT payer_id FROM check_informations WHERE job_id = #{@job_id}) \

        UNION \

        SELECT job_activity_logs .activity AS activity, \
        job_activity_logs.start_time AS start_time, \
        job_activity_logs.end_time AS end_time, \
        user_proc.name AS processorname, \
        user_qa.name AS qa_name , \
        user_allocater.name AS allocater_name, \
        job_activity_logs.object_name, \
        job_activity_logs.field_name, \
        job_activity_logs.old_value, \
        job_activity_logs.new_value \
        FROM job_activity_logs \
        LEFT OUTER JOIN users user_proc ON user_proc.id = job_activity_logs.processor_id  \
        LEFT OUTER JOIN users user_qa ON user_qa.id = job_activity_logs.qa_id \
        LEFT OUTER JOIN users user_allocater ON  user_allocater.id =job_activity_logs.allocated_user_id \
        WHERE object_name = 'batches' AND object_id IN \
        (SELECT batch_id FROM jobs WHERE id = #{@job_id})")
      
      @list = @list.flatten.sort { |a,b| a.start_time <=> b.start_time }
    end
  end

  def eob_archive
    insurance_eob_ids = params[:insurance_eob_to_generate]
    patient_eob_ids = params[:patient_eob_to_generate]
    if not insurance_eob_ids.blank?
      insurance_eob_ids.delete_if do |key,value|
        value == "0"
      end
    end
    if  not patient_eob_ids.blank?
      patient_eob_ids.delete_if do |key,value|
        value == "0"
      end
    end
    @batches = []
    if params[:option1]=="Regenerate 835/NextGen"
      if not (patient_eob_ids or insurance_eob_ids)
        flag=0
      else
        flag=1
        @ins_batches=[]
        if not insurance_eob_ids.blank?
          insurance_eob_ids.keys.each do |id|
            @ins_batches << id
          end
        end
        @patient_batches=[]
        if not patient_eob_ids.blank?
          patient_eob_ids.keys.each do |id|
            @patient_batches << id
          end
        end
      end
    end
    if flag == 0
      flash[:notice] = "Please select one eob"
      redirect_to :controller => 'archive',:action => 'regenerate'
    elsif flag == 1
      redirect_to :action => 'eobwise_835_report', :ins_batches => @ins_batches,:pat_batches => @patient_batches
    end
  end
  
  def eobwise_835_report
    @ins_eob_id_array = params[:ins_batches]
    @patient_eob_id_array = params[:pat_batches]
    @batchwise_file_array = []
    @patient_report_array = []
    @message = ""
    @batch_835 = 0  
    @batchwise = 1
    @patient_report = 0
    if @patient_eob_id_array
      for j in 0..@patient_eob_id_array.size-1
        @patient_eobs = PatientPayEob.find(:all,:conditions => ["id = ?",@patient_eob_id_array[j]])
        @check_infns=CheckInformation.find(:all,:conditions => ["id = ?",@patient_eobs[0].check_information_id])
        @job=Job.find(@check_infns[0].job_id)
        save_regenerated_activity(@patient_eobs[0].id,current_user.id,"Output Regenerated")
        @batch=Batch.find(@job.batch_id)
        @batch_payee = Facility.find(@batch.facility_id)
        @payee = @batch_payee.name
        @client = Client.find(@batch.client_id)
        Dir.chdir("public/data") do
          client_dir = Dir.mkdir(@client.name) unless File.exists? @client.name
          Dir.chdir(@client.name) do
            client_dir_name = @client.name #client_dir.path
            production_date_dir =Dir.mkdir(Date.today.to_s) unless File.exists? Date.today.to_s
            Dir.chdir(Date.today.to_s) do
              production_date_dir_name = Date.today.to_s #production_date_dir.path
              deposit_date_dir = Dir.mkdir(@batch.bank_deposit_date.to_s) unless File.exists? @batch.bank_deposit_date.to_s    
              Dir.chdir(@batch.bank_deposit_date.to_s) 
              deposit_date_dir_name = @batch.bank_deposit_date.to_s #deposit_date_dir.path
            end
          end
        end
        Dir.chdir("public/data/#{@client.name}/#{Date.today.to_s}/#{@batch.bank_deposit_date.to_s}") do
          output_dir = Dir.mkdir("regenerated") unless File.exists? "regenerated"
          #           Dir.chdir("selfpays") 
          output_dir_name = "regenerated" #output_dir.path
        end  
        if @patient_eobs
          @patient_report=1
          payee_output_directory = @payee.downcase
          #      id_835 = id_835 + 1
          #      cms_count= @patient_eobs.length
          deposit_date = format_deposit_date(@batch.bank_deposit_date.to_s)
          file_name = deposit_date+"_"+ @batch.batchid+"_"+Date.today.to_s+"_"+j.to_s+"_"+"resend.txt"
          if file_name.include?("/")
            file_name= report_file_name(file_name)
          end
          @patient_report_array<<file_name
          template = ERB.new(File.open('app/views/admin/batch/patient_eob.txt.erb').read)
          File.open("public/data/#{@client.name}/#{Date.today.to_s}/#{@batch.bank_deposit_date.to_s}/regenerated/#{file_name}" ,'w') do |f|
            output = template.result(binding)
            f.write output
          end
        end
      end
    end
    if @ins_eob_id_array
      for i in 0..@ins_eob_id_array.size-1
        @ins_eob=InsurancePaymentEob.find(@ins_eob_id_array[i])
        @check_infns=CheckInformation.find(:all,:conditions => ["id = ?",@ins_eob.check_information_id])
        @job = Job.find(@check_infns[0].job_id)
        save_regenerated_activity(@ins_eob.id,current_user.id,"Output Regenerated")
        @batch = Batch.find(@job.batch_id)
        @deposit_date = @batch.bank_deposit_date
        @batch_id_output = @batch.batchid
        @batch_payee = Facility.find(@batch.facility_id)
        @payee = @batch_payee.name
        @batch_client = Client.find(@batch.client_id)
        @client = @batch_client.name
        #        @client = Client.find(@batch.client_id)
        Dir.chdir("public/data") do
          client_dir = Dir.mkdir(@client) unless File.exists? @client
          Dir.chdir(@client) do
            client_dir_name = @client #client_dir.path
            production_date_dir =Dir.mkdir(Date.today.to_s) unless File.exists? Date.today.to_s
            Dir.chdir(Date.today.to_s) do
              production_date_dir_name = Date.today.to_s #production_date_dir.path
              deposit_date_dir = Dir.mkdir(@batch.bank_deposit_date.to_s) unless File.exists? @batch.bank_deposit_date.to_s    
              Dir.chdir(@batch.bank_deposit_date.to_s) 
              deposit_date_dir_name = @batch.bank_deposit_date.to_s #deposit_date_dir.path
            end
          end
        end
        Dir.chdir("public/data/#{@client}/#{Date.today.to_s}/#{@batch.bank_deposit_date.to_s}") do
          output_dir = Dir.mkdir("regenerated") unless File.exists? "regenerated"
          #           Dir.chdir("selfpays") 
          output_dir_name = "regenerated" #output_dir.path
        end  
      
        @isa_identifier = IsaIdentifier.find(:first)
        id_835 = @isa_identifier.isa_number
        offset = 0
        #from here
        #      payername_clientname_dateofgeneration_resend.835
        deposit_date = format_deposit_date(@batch.bank_deposit_date.to_s)
        file_name = deposit_date + "_" + @check_infns[0].payer_name + "_" + @client + "_" + @batch.batchid + "_" + i.to_s + "_" + Date.today.to_s + "_" + "resend.835"
        if file_name.include?("/")
          file_name= report_file_name(file_name)
        end
        @payer_new = Payer.find_by_payid(@check_infns[0].payid)
        if @check_infns.length > 0
          @payer_new = Payer.find_by_payid(@check_infns[0].payid)
          if @payee.upcase == "PEMA" or  @payee.upcase == "HSS" 
            template_file = "835_regenerate.txt.erb"
          else
            template_file = "835_navicure.txt.erb"
          end
          #            template = ERB.new(File.open("app/views/archive/#{template_file}").read)
          template = ERB.new(File.open("app/views/admin/batch/#{template_file}").read)     
          batch_output_directory = @payee.downcase.split(" ")
          id_835 = id_835 + 1
          #               @payer_new = Payer.find_by_payid(@check_infns[0].payid)
          File.open("public/data/#{@client}/#{Date.today.to_s}/#{@batch.bank_deposit_date.to_s}/regenerated/#{file_name}" ,'w') do |f|
            output = template.result(binding)
            output.gsub!(/\s+$/, '')
            f.puts output
            @batch_835=1
            @batchwise_file_array << file_name
            @isa_identifier = IsaIdentifier.find(:first)
            @isa_identifier.isa_number = id_835
            @isa_identifier.save
          end
        end
      end  
    end
    if @batch_835==1 and @patient_report==1
      @message="Both NextGen and 835 Reports are generated"
    elsif @batch_835==1 and @patient_report==0
      @message="835 Reports are generated"
    elsif @batch_835==0 and @patient_report==1
      @message="NextGen outputs are generated"
    else
      @message="No output generated"
    end
  end
   
  def eob_information_summary
    job_id = params[:jobid]
    job = Job.find(job_id)
    @facility = job.batch.facility
    parent_job_id = job.parent_job_id
    if(parent_job_id.blank?)
      @insurance_eob_information = CheckInformation.where("check_informations.job_id = ? ", job_id).
        joins(:insurance_payment_eobs).
        select("insurance_payment_eobs.patient_first_name patient_first_name,\
              insurance_payment_eobs.patient_last_name patient_last_name,\
              insurance_payment_eobs.patient_account_number patient_account_number,\
              insurance_payment_eobs.total_submitted_charge_for_claim \
              total_submitted_charge_for_claim,\
              insurance_payment_eobs.total_amount_paid_for_claim total_amount_paid_for_claim,\
              insurance_payment_eobs.claim_interest claim_interest,\
              insurance_payment_eobs.image_page_no image_page_no,\insurance_payment_eobs.claim_type claim_type ,\insurance_payment_eobs.rejection_comment rejection_comment")
    else
      @insurance_eob_information = CheckInformation.where("check_informations.job_id = ? and sub_job_id = ?", parent_job_id, job_id).
        joins(:insurance_payment_eobs).
        select("insurance_payment_eobs.patient_first_name patient_first_name,\
              insurance_payment_eobs.patient_last_name patient_last_name,\
              insurance_payment_eobs.patient_account_number patient_account_number,\
              insurance_payment_eobs.total_submitted_charge_for_claim \
              total_submitted_charge_for_claim,\
              insurance_payment_eobs.total_amount_paid_for_claim total_amount_paid_for_claim,\
              insurance_payment_eobs.claim_interest claim_interest,\
              insurance_payment_eobs.image_page_no image_page_no,\insurance_payment_eobs.claim_type claim_type ,\insurance_payment_eobs.rejection_comment rejection_comment")
    end
  end
  
  def search
    @facility_names = []
     
    if current_user.has_role?:admin
      user_facility_records = Facility.all
    else
      user_facility_records = current_user.lockboxes
    end
    @facility_names << ['All','0']
    user_facility_records.each do |fr|
      @facility_names << [fr.name,fr.id.to_s]
    end
    unless params[:facility].nil?
      @facility_chosen = params[:facility]
    else
      @facility_chosen = '0'
    end
    if(current_user.has_role?(:client)  or current_user.has_role?(:facility))
      if(current_user.lockboxes.first.client.name == 'Navicure')
        render :layout => 'navicure_img_retrieval'
      else
        render :layout=>'ext'
      end
    else
      render :layout=>'ext'
    end
  end
  
  def ret_search
    condition_list =[]
    lastname = params[:pat_lastname]
    accountnumber =params[:accountnumber]
    firstname = params[:pat_firstname]
    fromdate = params[:service_from]
    servicetodate = params[:service_to]
    check_number = params[:check_number]
    check_amount = params[:check_amount]
    from_date = params[:date_from]
    to_date   = params[:date_to]
    batchid = params[:batchid]
    total_charge = params[:total_charge]
    total_paid_amount = params[:total_amount_paid]
    unique_id = params[:unique_id]
    page = (params[:start].to_i/30)+1

    conditions, next_gen_condition_list = [], []
    values, next_gen_condition_values = [], []

    lockboxes = @current_user.lockboxes
    if (params[:facility]== "0")
      if (!@current_user.has_role?:admin) && (!lockboxes.empty?)
        facility_condition = "facilities.id in (#{lockboxes.collect(&:id).join(',')}) "
      end
    elsif !params[:facility].blank?
      facility_condition = "facilities.id = #{params[:facility]}"
    end
    unless check_amount.blank?
      condition_list << "check_informations.check_amount= '#{check_amount}'"
    end
    unless check_number.blank?
      condition_list << "check_informations.check_number like '%#{check_number}%'"
    end
    unless from_date.blank?
      condition_list << "batches.date >= '#{from_date}'"
    end
    unless to_date.blank?
      condition_list << "batches.date <= '#{to_date}'"
    end
    unless batchid.blank?
      condition_list << "batches.batchid like '#{batchid}%'"
    end

    next_gen_condition_list << condition_list
    next_gen_condition_list = next_gen_condition_list.flatten
    next_gen_condition_values << values
    next_gen_condition_values = next_gen_condition_values.flatten
    unless lastname.blank?
      condition_list << "insurance_payment_eobs.patient_last_name like '%#{lastname}%'"
      next_gen_condition_list << "patient_pay_eobs.patient_last_name like '%#{lastname}%'"
    end
    unless firstname.blank?
      condition_list << "insurance_payment_eobs.patient_first_name like '%#{firstname}%'"
      next_gen_condition_list << "patient_pay_eobs.patient_first_name like '%#{firstname}%'"
    end
    unless accountnumber.blank?
      condition_list << "insurance_payment_eobs.patient_account_number like '%#{accountnumber}%'"
      next_gen_condition_list << "patient_pay_eobs.account_number like '%#{accountnumber}%'"
    end
    unless total_charge.blank?
      condition_list << "insurance_payment_eobs.total_submitted_charge_for_claim = '#{total_charge}'"
      next_gen_condition_list << "patient_pay_eobs.statement_amount = '#{total_charge}'"
    end
    unless total_paid_amount.blank?
      condition_list << "insurance_payment_eobs.total_amount_paid_for_claim = '#{total_paid_amount}'"
      next_gen_condition_list << "patient_pay_eobs.stub_amount = '#{total_paid_amount}'"
    end
    unless fromdate.blank?
      condition_list << "service_payment_eobs.date_of_service_from >= '#{fromdate}'"
    end
    unless servicetodate.blank?
      condition_list << "service_payment_eobs.date_of_service_to <= '#{servicetodate}'"
    end
    unless unique_id.blank?
      condition_list << "insurance_payment_eobs.uid = '#{unique_id}'"
      next_gen_condition_list << "patient_pay_eobs.uid = '#{unique_id}'"
    end
    if params[:eob_type] == '1' && params[:filter][:flag] == '1'
      payer_type_condition = "CASE WHEN jobs.payer_group = '--' THEN  payers.payer_type = 'PatPay' ELSE  jobs.payer_group =  'PatPay' END"
    elsif params[:eob_type] == '0' && params[:filter][:flag] == '1'
      payer_type_condition = "CASE WHEN jobs.payer_group = '--' THEN  payers.payer_type != 'PatPay' ELSE  jobs.payer_group !=  'PatPay' END"
    end
    if !payer_type_condition.blank?
      condition_list << payer_type_condition
    end
    filter_data = true if !condition_list.blank?
    if !facility_condition.blank?
      condition_list << facility_condition
      next_gen_condition_list << facility_condition
    end

    next_gen_condition_list << "patient_pay_eobs.account_number IS NOT NULL"
    if condition_list.length > 1
      conditions = condition_list.join(" AND ")
    else
      conditions = condition_list
    end
    if next_gen_condition_list.length > 1
      next_gen_conditions = next_gen_condition_list.join(" AND ")
    else
      next_gen_conditions = next_gen_condition_list
    end

    select = "batches.batchid as b_id, check_informations.check_amount as c_amount, \
              check_informations.check_number as c_number, batches.id as batch_id, \
              check_informations.job_id as job_id, check_informations.id as chk_id, \
              check_informations.payer_id as payer_id, "
    next_gen_selection_items = select + "patient_pay_eobs.id as id, \
              patient_pay_eobs.patient_last_name, patient_pay_eobs.patient_first_name, \
              patient_pay_eobs.account_number as patient_account_number, \
              patient_pay_eobs.image_page_no as image_page_no, patient_pay_eobs.uid as uid,\
              patient_pay_eobs.transaction_date as claim_from_date"
    select += "insurance_payment_eobs.id as id, insurance_payment_eobs.patient_last_name, \
              insurance_payment_eobs.patient_first_name,
              insurance_payment_eobs.patient_account_number as patient_account_number, \
              insurance_payment_eobs.image_page_no as image_page_no,insurance_payment_eobs.uid as uid,\
              insurance_payment_eobs.claim_from_date as claim_from_date"

    table_joins = "
    INNER JOIN jobs ON jobs.id = check_informations.job_id
    INNER JOIN batches ON batches.id = jobs.batch_id
    INNER JOIN facilities ON facilities.id = batches.facility_id"

    next_gen_join_items = "INNER JOIN check_informations ON check_informations.id = patient_pay_eobs.check_information_id " + table_joins
    joins = "INNER JOIN check_informations ON check_informations.id = insurance_payment_eobs.check_information_id \
             LEFT OUTER JOIN payers ON payers.id = check_informations.payer_id" + table_joins

    if params[:eob_type] == '1'
      patpay_query_string = " \
      SELECT #{select} \
      FROM insurance_payment_eobs \
      #{joins} \
      WHERE #{conditions} \
      UNION \
      SELECT #{next_gen_selection_items} \
      FROM patient_pay_eobs \
      #{next_gen_join_items} \
      WHERE #{next_gen_conditions} \ "

      if filter_data == true
        order = "trim(patient_last_name)"
        eobs = InsurancePaymentEob.paginate_by_sql("
                  #{patpay_query_string}
                  ORDER BY #{order}", :page => page, :per_page =>30)
        total_entries = eobs.total_entries
      end
    else

      if (!fromdate.blank? || !servicetodate.blank?)
        joins = "#{joins} INNER JOIN service_payment_eobs ON insurance_payment_eob_id = insurance_payment_eobs.id"
      end
      if filter_data == true
        order = "trim(insurance_payment_eobs.patient_last_name)"
        eobs = InsurancePaymentEob.select(select).joins(joins).where(conditions).order(order).paginate(:page => page, :per_page =>30)
        total_entries = eobs.total_entries
      end
    end

    eobs = [] if eobs.nil?

    lnk = ""
    img_access = @current_user.image_permision == "1"
    return_data = Hash.new()
    return_data[:Total] = total_entries
    return_data[:Eobs] = eobs.collect{|data|
      lnk = ""
      lnk = "<a href='viewimage?job_id=#{data.job_id}&eob_id=#{data.id}&eob_check_number=#{data.chk_id}&image_number=#{data.image_page_no}' target='_blank'><img title='Image' src='../assets/image_1.gif' alt='Image'/></a>&nbsp;|&nbsp;" if (@current_user.image_permision == "1")
      if @current_user.image_835_permision == "1" && !params[:eob_type].blank?
        if data.class == InsurancePaymentEob
          lnk = "#{lnk}<a href='view_835?eob_check_number=#{data.chk_id}&eob_id=#{data.id}&job_id=#{data.job_id}&page=#{InsurancePaymentEob.page_number(data.chk_id, data.id)}' target='_blank'><img title='835' src='../assets/835.gif' alt='835'/></a>&nbsp;|&nbsp;"
        elsif data.class == PatientPayEob
          lnk = "#{lnk}<a href='view_835?eob_check_number=#{data.chk_id}&eob_id=#{data.id}&job_id=#{data.job_id}&page=#{PatientPayEob.page_number(data.chk_id, data.id)}' target='_blank'><img title='835' src='../assets/835.gif' alt='835'/></a>&nbsp;|&nbsp;"
        end
      end
      if @current_user.image_grid_permision == "1"
        if data.class == InsurancePaymentEob
          lnk = "#{lnk} <a href='../insurance_payment_eobs/claimqa?batch_id=#{data.batch_id}&checknumber=#{data.chk_id}&eob_id=#{data.id}&job_id=#{data.job_id}&image_number=#{data.image_page_no}&page=#{InsurancePaymentEob.page_number(data.chk_id, data.id)}&verify_grid=1' target='_blank'><img title='Image & Grid' src='../assets/image_grid.gif' alt='Image & Grid'/></a>&nbsp;|&nbsp;"
        elsif data.class == PatientPayEob
          lnk = "#{lnk} <a href='../insurance_payment_eobs/claimqa?batch_id=#{data.batch_id}&checknumber=#{data.chk_id}&eob_id=#{data.id}&job_id=#{data.job_id}&image_number=#{data.image_page_no}&page=#{PatientPayEob.page_number(data.chk_id, data.id)}&verify_grid=1' target='_blank'><img title='Image & Grid' src='../assets/image_grid.gif' alt='Image & Grid'/></a>&nbsp;|&nbsp;"
        end
      end
      lnk = "#{lnk} <a href='javascript:pop(#{data.job_id},#{data.id},#{data.chk_id})'><img title='logs' src='../assets/logs.gif' alt='logs'/></a>" if @current_user.activity_log_permission == "1" and !@current_user.has_role?:partner and !@current_user.has_role?:client and !@current_user.has_role?:facility
      lnk = "<div align='center'> #{lnk} </div>"
      claim_from_date = data.claim_from_date.strftime("%m/%d/%Y") unless data.claim_from_date.blank?
      { :uid=>data.uid,
        :a_no=>data.patient_account_number,
        :l_name=>data.patient_last_name,
        :f_name=>data.patient_first_name,
        :claim_from_date => claim_from_date,
        :v_info=>lnk,
        :c_num=>data.c_number,
        :c_amt=>'$'+data.c_amount.to_s,
        :b_id=>data.b_id
      }
    }
    render :text=>"#{return_data.to_json}", :layout=>false
  end

   
  def filter_data(lastname,firstname,suffix,initial,accountnumber,fromdate,todate,check_number,from_date,to_date,check_amount,batchid, facility_name )
    patient_data = []
    values = []
    facility_search_condition= []
    if(! facility_name.empty?||! facility_name.nil?||!facility_name.blank?)
      if(facility_name =="All")
        facility_name =""
      end
      #If there's a facility_name mentioned and if there's some patient_search_condition or insurance_search_conditions then append an 'and' to where clause
      if((!facility_name.blank?&&!facility_name.empty?)&&(!patient_search_condition.empty?||!insurance_search_conditions.blank?))
        facility_search_condition+="and "
      elsif((patient_search_condition.empty?||insurance_search_conditions.empty?)&&!facility_name.blank?)
        facility_search_condition+="where "
      end
      unless facility_name.blank?
        facility_search_condition += "fac.name like ?"
        values << "%#{facility_name}%"
        facility_search_condition = facility_search_condition, *values
      end
    end

    insurance_eob_data = InsurancePaymentEob.find_by_sql("select distinct ins.check_information_id check_information_id,ins.image_page_no image_page_no, ins.id id,ins.patient_account_number patient_account_number,ins.patient_last_name patient_last_name,ins.patient_first_name patient_first_name,ins.total_submitted_charge_for_claim total_submitted_charge_for_claim
    from batches inner join jobs on batches.id = jobs.batch_id
    inner join check_informations chec on jobs.id = chec.job_id
    inner join insurance_payment_eobs ins on chec.id=ins.check_information_id 
    left join service_payment_eobs srv on srv.insurance_payment_eob_id = ins.id
 LEFT OUTER JOIN facilities fac on batches.facility_id=fac.id
     #{insurance_search_conditions} #{facility_search_condition}")
    patient_data << insurance_eob_data
    return patient_data
  end
  
  def viewimage
    if( current_user.has_role?(:partner) or current_user.has_role?(:client))
      @enable_applet_controls = 1
    end
    @page_number = params[:image_number]
    @job = Job.find(params[:job_id])
    session[:batchid] = @job.batch_id
    client_activity(params[:eob_check_number],params[:eob_id],"Viewed Image",params[:job_id])
    session[:checknumber] = params[:checknumber]

    @parent_job_id = @job.parent_job_id
    @checkinformation = CheckInformation.find_by_job_id(@job.get_parent_job_id)
    if !@parent_job_id.blank?
      @parent_job = @checkinformation.job
    end
    facility_image_type = Batch.find(session[:batchid]).facility.image_type

    get_images(@parent_job_id, facility_image_type,params[:job_id])

    if( current_user.lockboxes.size >= 1 && current_user.lockboxes.first.client.name == 'Navicure' && (current_user.has_role?(:client)|| current_user.has_role?(:facility)))
      render :layout => 'navicure'
    end
  end


  def view_835
    if( current_user.has_role?(:partner) or current_user.has_role?(:client))
      @enable_applet_controls = 1
    end
    @claimtype = ClaimType.find(:all).map{|f|f.claim_type}
    client_activity(params[:eob_check_number],params[:eob_id],"Viewed Image and 835",params[:job_id])
    @job = Job.find(params[:job_id])
    session[:batchid]= @job.batch_id
    job = @job
    @facility = job.batch.facility
    @client = @facility.client
    session[:checknumber] = params[:checknumber]
    @checkinformation = CheckInformation.find_by_job_id(@job.get_parent_job_id)
    @parent_job_id = @job.parent_job_id
    if !@parent_job_id.blank?
      @parent_job = @check_information.job
    end
    facility_image_type = @facility.image_type

    get_images(@parent_job_id, facility_image_type,params[:job_id])
    get_default_groupcode(@facility)
    
    payers = Payer.select("payer, pay_address_one, pay_address_two, payer_zip, payer_state, payer_city, payer_type, id, reason_code_set_name_id, footnote_indicator").
      where(:id => @checkinformation.payer_id)
    @payer = payers.first if !payers.blank?
    @micr_line_information = @checkinformation.micr_line_information
    @eobinformation = InsurancePaymentEob.where(["check_information_id = ?", @checkinformation.id])
    @patinfo = PatientPayEob.where(["check_information_id = ?", @checkinformation.id])
    @reason_codes = ReasonCodesJob.get_valid_reason_codes job.get_parent_job_id
    if !@eobinformation.blank?
      @informations =  @eobinformation.paginate :per_page => 1, :page => params[:page]
      @page_number =  (@eobinformation.fetch((params[:page].to_i) - 1)).image_page_no
      @informations = InsurancePaymentEob.set_crosswalked_codes(@payer, @informations, @client, @facility)
    else
      @informations =  @patinfo.paginate :per_page => 1, :page => params[:page]
    end
    @show_patpay_statement_fields = @facility.details[:patpay_statement_fields]
    if( current_user.lockboxes.size >= 1 && current_user.lockboxes.first.client.name == 'Navicure' && (current_user.has_role?(:facility)|| current_user.has_role?(:facility)))
      render :layout => 'navicure'
    end
  end
  
  #Method to retrieve default groupcode set from default_codes_for_adjustment_reasons table
  def get_default_groupcode(facility)
    default_code_records = facility.default_codes_for_adjustment_reasons
    unless default_code_records.blank?
      default_code_records.each do |default_code_record|
        adjustment_reason = default_code_record.adjustment_reason
        unless adjustment_reason.blank?
          eval("@#{adjustment_reason}_group_code = default_code_record")
        end
      end
    end
  end

  def set_adjustment_codes(entity)
    if entity.noncovered_hipaa_code_id.present?
      record = entity.noncovered_hipaa_code
      adjustment_code = record.hipaa_adjustment_code if record
    elsif entity.noncovered_reason_code_id.present?
      record = entity.noncovered_reason_code
      adjustment_code = record.code if record
    end
    eval("@#{adjustment_reason}_adjustment_code = adjustment_code")
  end
  

  protected
 


  def insurance_search_conditions
    condition_list =[]
    values = []
    lastname = params[:pat_lastname]
    accountnumber =params[:accountnumber]
    firstname = params[:pat_firstname]
    suffix = params[:pat_suffix]
    initial = params[:pat_initial]
    fromdate = params[:service_from]
    servicetodate = params[:service_to]
    check_number = params[:check_number]
    check_amount = params[:check_amount]
    from_date = params[:date_from]
    to_date   = params[:date_to]
    batchid = params[:batchid]
    total_charge = params[:total_charge]
    total_paid_amount = params[:total_amount_paid]
    conditions = ""
    if(fromdate.blank?)
      unless lastname.blank?
        condition_list << "patient_last_name like ?"
        values << "%#{lastname}%"
      end
      unless firstname.blank?
        condition_list << "patient_first_name like ?"
        values << "%#{firstname}%"
      end
      unless accountnumber.blank?
        condition_list << "patient_account_number like ?"
        values << "#{accountnumber}"
      end
      unless total_charge.blank?
        condition_list << "total_submitted_charge_for_claim = ?"
        values << "#{total_charge}"
      end
      unless total_paid_amount.blank?
        condition_list << "total_amount_paid_for_claim = ?"
        values << "#{total_paid_amount}"
      end
    end
    if(!fromdate.blank? and check_number.blank?)
      unless lastname.blank?
        condition_list << "ins.patient_last_name= ?"
        values << "#{lastname}"
      end
      unless firstname.blank?
        condition_list << "ins.patient_first_name= ?"
        values << "#{firstname}"
      end
      unless fromdate.blank?
        condition_list << "srv.date_of_service_from>= ?"
        values << "#{fromdate}"
      end
      unless accountnumber.blank?
        condition_list << "ins.patient_account_number like ?"
        values << "%#{accountnumber}%"
      end
      unless servicetodate.blank?
        condition_list << "srv.date_of_service_to<= ?"
        values << "#{servicetodate}"
      end
    end
    if(fromdate.blank? and (!check_number.blank?))
      unless lastname.blank?
        condition_list << "ins.patient_last_name= ?"
        values << "#{lastname}"
      end
      unless firstname.blank?
        condition_list << "ins.patient_first_name= ?"
        values << "#{firstname}"
      end
      unless accountnumber.blank?
        condition_list << "ins.patient_account_number like ?"
        values << "%#{accountnumber}%"
      end
      unless check_number.blank?
        condition_list << "chec.check_number= ?"
        values << "#{check_number}"
      end
    end
    if(fromdate.blank? and (!check_amount.blank?))
      unless lastname.blank?
        condition_list << "ins.patient_last_name= ?"
        values << "#{lastname}"
      end
      unless firstname.blank?
        condition_list << "ins.patient_first_name= ?"
        values << "#{firstname}"
      end
      unless accountnumber.blank?
        condition_list << "ins.patient_account_number like ?"
        values << "%#{accountnumber}%"
      end
      unless check_amount.blank?
        condition_list << "chec.check_amount= ?"
        values << "#{check_amount}"
      end
      unless check_number.blank?
        condition_list << "chec.check_number= ?"
        values << "#{check_number}"
      end
    end
    if(!from_date.blank? or !batchid.blank?)
      unless lastname.blank?
        condition_list << "ins.patient_last_name= ?"
        values << "#{lastname}"
      end
      unless firstname.blank?
        condition_list << "ins.patient_first_name= ?"
        values << "#{firstname}"
      end
      unless accountnumber.blank?
        condition_list << "ins.patient_account_number like ?"
        values << "%#{accountnumber}%"
      end
      unless check_number.blank?
        condition_list << "chec.check_number = ?"
        values << "#{check_number}"
      end
      unless from_date.blank?
        condition_list << "batches.date >= ?"
        values << "#{from_date}"
      end
      unless to_date.blank?
        condition_list << "batches.date <= ?"
        values << "#{to_date}"
      end
      unless batchid.blank?
        condition_list << "batches.batchid like ?"
        values << "%#{batchid}%"
      end
    end
    conditions = condition_list.join(" and ")
    conditions = conditions, * values
    if(!conditions.empty?)
      conditions ="where "+conditions
    end

    return conditions
  end

  def patient_search_condition
    lastname = params[:pat_lastname]
    accountnumber = params[:accountnumber]
    firstname = params[:pat_firstname]
    suffix = params[:pat_suffix]
    initial = params[:pat_initial]
    fromdate = params[:service_from]
    servicetodate = params[:service_to]
    check_number = params[:check_number]
    check_amount = params[:check_amount]
    from_date = params[:date_from]
    to_date   = params[:date_to]
    batchid = params[:batchid]
    total_charge = params[:total_charge]
    total_paid_amount = params[:total_amount_paid]
    pat_conditions =""
    puts total_paid_amount
    patient_data =[]
    condition_list = []
    condition_list_patientpay =[]
    values = []
    if(!from_date.blank? or !check_number.blank? or !check_amount.blank? or !batchid.blank?)
      unless lastname.blank?
        condition_list_patientpay << "pat.patient_last_name= ?"
        values << "#{lastname}"
      end
      unless firstname.blank?
        condition_list_patientpay << "pat.patient_first_name= ?"
        values << "#{firstname}"
      end
      unless accountnumber.blank?
        condition_list_patientpay << "pat.account_number like ?"
        values << "%#{accountnumber}%"
      end
      unless check_number.blank?
        condition_list_patientpay << "chec.check_number like ?"
        values << "%#{check_number}%"
      end
      unless check_amount.blank?
        condition_list_patientpay << "chec.check_amount like ?"
        values << "#{check_amount}"
      end
      unless from_date.blank?
        condition_list_patientpay << "batches.date >= ?"
        values << "#{from_date}"
      end
      unless from_date.blank?
        condition_list_patientpay << "batches.date <= ?"
        values << "#{from_date}"
      end
      unless batchid.blank?
        condition_list_patientpay << "batches.batchid = ?"
        values << "#{batchid}"
      end
      unless total_charge.blank?
        condition_list_patientpay << "statement_amount = ?"
        values << "#{total_charge}"
      end
      unless total_paid_amount.blank?
        condition_list_patientpay << "stub_amount = ?"
        values << " #{total_paid_amount}"
      end
      pat_conditions = condition_list_patientpay.join(" and ")
      pat_conditions = pat_conditions, *values
    else

      unless lastname.blank?
        condition_list_patientpay << "patient_last_name like ?"
        values << "%#{lastname}%"
      end
      unless firstname.blank?
        condition_list_patientpay << "patient_first_name like ?"
        values << "%#{firstname}%"
      end
      unless total_charge.blank?
        condition_list_patientpay << "statement_amount = ?"
        values << "#{total_charge}"
      end
      unless accountnumber.blank?
        condition_list_patientpay << "account_number like ?"
        values << "%#{accountnumber}%"
      end
      unless check_amount.blank?
        condition_list_patientpay << "chec.check_amount like ?"
        values << "#{check_amount}"
      end
      unless total_paid_amount.blank?
        condition_list_patientpay << "stub_amount = ?"
        values << "#{total_paid_amount}"
      end
      pat_conditions = condition_list_patientpay.join(" and ")
      pat_conditions = pat_conditions, *values
    end
    if(!pat_conditions.empty?)
      pat_conditions= "where "+pat_conditions
    end
    return pat_conditions
  end

end
