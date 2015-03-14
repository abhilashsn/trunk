# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class HlscController < ApplicationController
  layout "standard"
  require_role ["admin","supervisor","TL"]
  
  auto_complete_for :batch_rejection_comment , :comment
  auto_complete_for :job_rejection_comment , :comment

  def index
    batch_status
    render :action => 'batch_status'
  end

  def batch_status
    handle_mark_or_unmark_for_batch_setup
    handle_accepted_batches
    conditions = "batches.status in ('#{BatchStatus::COMPLETED}', '#{BatchStatus::OUTPUT_READY}')" 
    conditions = frame_batch_criteria(conditions) unless params[:to_find].blank?
   
    # RAILS3.1 Correction
    # @batches = Batch.paginate(:all, 
    #  :conditions => conditions, :include => [:facility], 
    #  :group => "batches.id", :order => "batches.arrival_time desc", :per_page => 30, 
    #  :page => params[:page]) unless conditions.blank?
      
    @batches = Batch.where(conditions).includes(:facility).group("batches.id").order("batches.arrival_time desc").paginate(:page => params[:page]) unless conditions.blank?
  end
  
  def handle_mark_or_unmark_for_batch_setup
    if params[:mark] or params[:unmark]
      batch = Batch.find_by_batchid(params[:batch])
      if params[:mark]
        if !batch.hlsc.nil? and batch.hlsc != @user
          flash[:notice] = "Batch already marked by #{batch.hlsc}"
        else
          batch.hlsc = @user
          unless batch.save
            flash[:notice] = "Batch cannot be marked. Reason : #{batch.errors.entries[0]}"
          else
            flash[:notice] = "Batch marked successfully."
          end
        end
      end
      
      if params[:unmark]
        batch.hlsc = nil
        batch.status = BatchStatus::COMPLETED
        unless batch.save
          flash[:notice] = "Batch cannot be unmarked. Reason : #{batch.errors.entries[0]}"
        else
          flash[:notice] = "Batch unmarked successfully."
        end
      end
    end
  end
  
  def handle_accepted_batches
    if params[:accept] and request.post?
      batch = Batch.find_by_batchid(params[:batch])

      #only payment batches are entered in report
      if batch.correspondence == false or batch.correspondence.nil?
        hlsc_report = HlscQa.create(:batch => batch,
          :total_eobs => batch.get_completed_eobs,
          :rejected_eobs => 0,
          :user => @user )
      end

      batch.hlsc = nil
      status_history = ClientStatusHistory.new
      status_history.time = Time.now
      status_history.status = batch.status
      status_history.user = @user.userid
      unless status_history.save
        flash[:notice]  = 'Failed updating batch status history'
      end
      batch.client_status_histories << status_history
      batch.save

      flash[:notice] = "Batch #{batch.batchid} accepted on request"
    end
  end

  def reject_batch
    @batch = Batch.find(params[:id])
    @batch.update_attributes(params[:batch_rejection_comment])
    if params[:commit] == "Reject"
      #TODO: what will be job status
      @batch.jobs.each do |job|
        job.comment = params[:batch_rejection_comment][:comment]
        job.save
      end
      @batch.hlsc = nil

      #only payment batch are entered in report
      if @batch.correspondence == false or @batch.correspondence.nil?
        hlsc_report = HlscQa.create(:batch => @batch,
          :total_eobs => @batch.get_completed_eobs,
          :rejected_eobs => @batch.least_eobs,
          :user => @user)
      end

      status_history = ClientStatusHistory.new
      status_history.time = Time.now
      status_history.status = @batch.status
      status_history.user = @user.userid
      unless status_history.save
        flash[:notice]  = 'Failed updating batch status history'
      end
      @batch.client_status_histories << status_history
      @batch.save
      flash[:notice] = "Batch #{@batch.batchid} rejected on request"
      redirect_to :action => "batch_status"
    end
  end

  def reject_checks
    @batch = Batch.find(params[:id])
    @checks = []
    @batch.jobs.each do |job|
      @checks << job.check_number
    end
    @checks.uniq!

    #rejected_check_number = 0
    if params[:commit] == "Reject"
      #rejected_check_number = params[:job][:check_number]
      @jobs = Job.find(:all, :conditions => ["batch_id = ? and check_number = ?", @batch.id, params[:job][:check_number]])
      total_rejected_eobs = 0
      @jobs.each do |job|
        job.comment = params[:job_rejection_comment][:comment]
        # job.eob_count will fetch total EOB count for the job based on count of database table records for EOBs
        total_rejected_eobs += job.eob_count
        job.save
      end
      #only payment batch are entered in report
      if @batch.correspondence == false or @batch.correspondence.nil?
        create_entry_for_check_rejection(params[:job][:check_number], total_rejected_eobs)
      end
    end

    unless params[:accept_job].nil?
      check_numbers = Array.new
      accept_jobs  = Job.find_by_id(:all,params[:accept_job])
      accept_jobs.each do |accept_job|
        check_numbers << accept_job.check_number
      end

      accept_jobs = Array.new
      check_numbers.each do |check_number|
        accept_jobs = Job.find(:all,
          :conditions => ["batch_id =? and check_number = ?", @batch.id, check_number])
        accept_jobs.each do |accept_job|
          accept_job.comment = ""
          accept_job.job_status = JobStatus::COMPLETED
          accept_job.save
        end
      end
    end

    check_numbers = Array.new
    rejected_jobs = @batch.jobs.select do |job|
      check_numbers << job.check_number
    end

    check_numbers.uniq!
    @rejected_jobs = Array.new

    check_numbers.each do |check_number|
      @rejected_jobs <<  Job.find(:first, :conditions => ["batch_id =? and check_number = ?", @batch.id, check_number])
    end

    #create_entry_for_check_rejection(rejected_check_number, total_rejected_eobs, @rejected_jobs)

    @batch.update_status
  end

  def create_entry_for_check_rejection(check_number, rejected_eobs)
    job_for_check_number = Job.find(:first, :conditions => ["batch_id = ? and check_number = ?", @batch.id, check_number])
    #if HlscQa.find_by_job_id(job_for_check_number.id).nil?
    hlsc_report = HlscQa.new
    hlsc_report.batch = @batch
    #hlsc_report.job = job_for_check_number
    hlsc_report.total_eobs = @batch.get_completed_eobs
    hlsc_report.rejected_eobs = rejected_eobs
    hlsc_report.user = @user
    hlsc_report.save
    #end
    return
  end

  def hlsc_report
    search_field_from = params[:find_from]
    search_field_to = params[:find_to]
    search_field_from.strip! unless search_field_from.nil?
    search_field_to.strip! unless search_field_to.nil?

    if not search_field_from.blank? and not search_field_to.blank?
      begin
        date_from = Date.strptime(search_field_from,"%m/%d/%y")
        date_to = Date.strptime(search_field_to,"%m/%d/%y")
      rescue
        flash[:notice] = "Invalid date format (mm/dd/yy)"
      end
      reports = HlscQa.find(:all, :conditions => "batches.date >= '#{date_from}' and batches.date <= '#{date_to}'",
        :joins => "left join batches on batches.id = hlsc_qas.batch_id",
        :group => "batches.date",
        :select => "batches.date batch_date, sum(total_eobs), sum(rejected_eobs) rejected_eobs")
      @batches_processed = Batch.find(:all, :conditions => "date >= '#{date_from}' and date <= '#{date_to}' and status != '#{BatchStatus::NEW}'",
        :group => "date", :select => "count(batches.id) batch_count, batches.date date")
      total_eobs, total_batches, total_rejected = filter_batches(@batches_processed)
      date_range = date_from.strftime('%m/%d/%y').to_s + " - " + date_to.strftime('%m/%d/%y').to_s
    else
      reports = HlscQa.find(:all, :conditions => "batches.date >= '#{Date.today}' and batches.date <= '#{Date.today}'",
        :joins => "left join batches on batches.id = hlsc_qas.batch_id",
        :group => "batches.date",
        :select => "batches.date batch_date, sum(total_eobs), sum(rejected_eobs) rejected_eobs")
      @batches_processed = Batch.find(:all, :conditions => "date >= '#{Date.today}' and date <= '#{Date.today}' and status != '#{BatchStatus::NEW}'",
        :group => "date", :select => "count(batches.id) batch_count, batches.date date")
      total_eobs, total_batches, total_rejected = filter_batches(@batches_processed)
      date_range = Date.today.to_s
    end
    summary_report(reports, date_range, total_eobs, total_batches, total_rejected)
    @reports = reports.paginate(:page => params[:page], :per_page => 30)
  end

  def summary_report(report, date_range, eobs, batches, rejected)
    summary_report = report
    @summary = Hash.new
    @summary['eobs_rejected'] = 0
    @summary['batches_processed'] = batches
    @summary['batches_rejected'] = rejected
    @summary['eobs_processed'] = eobs
    summary_report.each do |sr|
      @summary['eobs_rejected'] = @summary['eobs_rejected'] + sr.rejected_eobs
    end
    if summary_report.size > 1
      @summary['date'] = date_range
    else
      @summary['date'] = Date.today.to_s
    end
    return
  end

  def filter_batches(batches_processed)
    total_batches = 0
    total_rejected_batches = 0
    total_eobs_processed = 0
    total_eobs_rejected = 0
    total_eobs = 0
    total_batches_complete = 0

    batches_processed.each do |b|
      rejected_batch_count = 0
      complete_batches = 0
      total_batches+= b.batch_count.to_i
      Batch.find_by_date(:all,b.date).each do |bb|
        hlsc_qas = HlscQa.find_by_batch_id(:all,bb.id)
        rejections = hlsc_qas.select {|hq| hq.rejected_eobs > 0}
        if rejections.size > 0
          rejected_batch_count += 1
          total_rejected_batches += 1
        end
        if hlsc_qas.size > 0
          complete_batches += 1
          total_batches_complete += 1
          total_eobs_processed += bb.get_completed_eobs
        end
        hlsc_qa_eobs = 0
        hlsc_qas.each do |hq|
          hlsc_qa_eobs += hq.rejected_eobs unless hq.rejected_eobs.nil?
        end
        total_eobs_rejected += hlsc_qa_eobs unless hlsc_qa_eobs.nil?
      end
      b['total_eobs'] = total_eobs_processed
      b['total_rejected_eobs'] = total_eobs_rejected
      b['complete_batches'] = complete_batches
      b['total_rejected_batches'] = rejected_batch_count
      total_eobs += total_eobs_processed
      total_eobs_rejected = 0
      total_eobs_processed = 0
    end
    return total_eobs, total_batches_complete, total_rejected_batches
  end

  #Report of Batches Completed by HLSC
  def completed_batches_report
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    @from_date = params[:from_date]
    @to_date = params[:to_date]

    search_field.strip! unless search_field.nil?
    from_date = (Time.now.to_time).at_beginning_of_day
    to_date = (Time.now.to_time).tomorrow.at_beginning_of_day

    conditions = "client_status_histories.status = 'HLSC Verified' and (batches.correspondence = 'false' or batches.correspondence is null)"
    
    if !@from_date.blank? and !@to_date.blank? then
      begin
        from_date = (@from_date.to_time).at_beginning_of_day
        to_date = ((@to_date.to_time).tomorrow).at_beginning_of_day
      rescue ArgumentError
        flash[:notice] = "Invalid date format"
      end

      @reports = paginate :client_status_histories, 
        :joins => "left join client_status_histories c2 on client_status_histories.batch_id = c2.batch_id and c2.time > client_status_histories.time",
        :include => [{:batch => :facility}],
        :conditions => [conditions + " and c2.batch_id is null and client_status_histories.time > ? and client_status_histories.time < ?", from_date, to_date],
        :per_page => 30

      
    elsif not search_field.blank?
      case criteria
      when "Batch ID"
        temp_search = search_field
        temp_search = temp_search.to_i
        @reports = ClientStatusHistory.find(:all,
          :include => :batch,
          :joins => "left join client_status_histories c2 on client_status_histories.batch_id = c2.batch_id and c2.time > client_status_histories.time",
          :conditions => conditions + " and c2.batch_id is null and batches.batchid #{compare} #{temp_search}").paginate(:page => params[:page], :per_page => 30)
      when "Batch Date"
        begin
          date = Date.strptime(search_field,"%m/%d/%y")
        rescue ArgumentError
          flash[:notice] = "Invalid date format"
        end
        @reports = ClientStatusHistory.find(:all,
          :include => :batch,
          :joins => "left join client_status_histories c2 on client_status_histories.batch_id = c2.batch_id and c2.time > client_status_histories.time",
          :conditions => conditions + " and c2.batch_id is null and batches.date #{compare} '#{date}'").paginate(:page => params[:page], :per_page => 30)
      when "Report on Date"
        begin
          date = Date.strptime(search_field,"%m/%d/%y")
          @from_date = (search_field.to_time).at_beginning_of_day
          @to_date = ((search_field.to_time).tomorrow).at_beginning_of_day
        rescue ArgumentError
          flash[:notice] = "Invalid date format"
        end
        @reports = ClientStatusHistory.find(:all,
          :include => :batch,
          :joins => "left join client_status_histories c2 on client_status_histories.batch_id = c2.batch_id and c2.time > client_status_histories.time",
          :conditions => [conditions + " and c2.batch_id is null and client_status_histories.time > ? and client_status_histories.time < ?",
            from_date, to_date]).paginate(:page => params[:page], :per_page => 30)
      end
    else
      @reports = ClientStatusHistory.find(:all,
        :include => :batch,
        :joins => "left join client_status_histories c2 on client_status_histories.batch_id = c2.batch_id and c2.time > client_status_histories.time",
        :conditions => [conditions + " and c2.batch_id is null and client_status_histories.time > ? and client_status_histories.time < ?",
          from_date, to_date]).paginate(:page => params[:page], :per_page => 30)
    end

    if @reports.nil? && @reports.size < 1
      flash[:notice] = "No Match Found"

      @reports = ClientStatusHistory.find(:all,
        :include => :batch,
        :joins => "left join client_status_histories c2 on client_status_histories.batch_id = c2.batch_id and c2.time > client_status_histories.time",
        :conditions => [conditions + " and c2.batch_id is null and client_status_histories.time > ? and client_status_histories.time < ?",
          from_date, to_date]).paginate(:page => params[:page], :per_page => 30)
    end

  end
  
  def batchlist
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    conditions = " batches.status = '#{BatchStatus::PROCESSING}' and 
                jobs.job_status = '#{JobStatus::COMPLETED}' and 
                (batches.correspondence = 'false' or  batches.correspondence is NULL )"
    #TODO: Replace these lines of code and reuse frame_batch_criteria method in application_helper.rb
    unless search_field.nil?
      case criteria
      when 'Batch Date'
        begin
          date = Date.strptime(search_field,"%m/%d/%y")
        rescue ArgumentError
          flash[:notice] = "Invalid date format"
        end
        @batches = Batch.find(:all,
          :conditions => conditions + " and date #{compare} '#{date}'",
          :include => :jobs).paginate(:page => params[:page], :per_page => 30)
                             
      when 'Batch ID'
        @batches = Batch.find(:all,
          :conditions => conditions + " and batchid #{compare} #{search_field.to_i}",    
          :include => :jobs).paginate(:page => params[:page], :per_page => 30)
       
      when 'Site Name'
        @batches = Batch.find(:all,
          :conditions =>  " batches.status = '#{BatchStatus::PROCESSING}' and 
              batches.id = jobs.batch_id and jobs.job_status = '#{JobStatus::COMPLETED}' and 
              facilities.name like '%#{search_field}%'",
          :include=>[:jobs,:facility ]).paginate(:page => params[:page], :per_page => 30)
        flash[:notice] = "String search, #{compare} ignored."
      end

    else
      @batches=Batch.find(:all, :conditions=>" batches.status = '#{BatchStatus::PROCESSING}' and
              jobs.job_status = '#{JobStatus::COMPLETED}' and batches.id = jobs.batch_id and
              (batches.correspondence = 'false' or  batches.correspondence is NULL ) ",
        :include=>:jobs).paginate(:page => params[:page], :per_page => 30)
 
    end
    
  end

  def view_completed_jobs
    if params[:mark] or params[:unmark]
      batch = Batch.find_by_batchid(params[:batch])
      job = Job.find_by_id(params[:job])
      if params[:mark]
        if !job.hlsc.nil? and job.hlsc != @user
          flash[:notice] = "Job already marked by #{job.hlsc}"
        else
          job.hlsc = @user
          unless job.save
            flash[:notice] = "Job cannot be marked."
          else
            flash[:notice] = "Job marked successfully."
          end
        end
      end
      if params[:unmark]
        job.hlsc = nil
        job.job_status = JobStatus::COMPLETED
        unless job.save
          flash[:notice] = "Job cannot be unmarked."
        else
          flash[:notice] = "Job unmarked successfully."
        end
      end
    end

    # Handle mark/unmark
    if params[:mark] or params[:unmark]
      job = Job.find_by_id(params[:job])
      batch = Batch.find_by_batchid(params[:batch])
      if params[:mark]
        if !job.hlsc_id.nil? and job.hlsc_id != @user
          #flash[:notice] = "Job already marked by #{batch.hlsc}"
        else
          job.hlsc_id = @user
          unless job.save
            flash[:notice] = "Job cannot be marked. Reason : #{batch.errors.entries[0]}"
          else
            flash[:notice] = "Job marked successfully."
          end#unless
        end
      end#if mark
      if params[:unmark]
        job.hlsc_id = nil
        batch.status = BatchStatus::COMPLETED
        batch.save
        unless job.save
          flash[:notice] = "Job cannot be unmarked. Reason : #{batch.errors.entries[0]}"
        else
          flash[:notice] = "Job unmarked successfully."
        end#unless
      end#is unmark
    end#if mark /unmark
    @selected_batch = ""
    if !params[:payer].nil?
      payer = Payer.find(params[:payer])
    end

    payer.nil? == true ? payer_condition = "": payer_condition = "and payer_id = #{payer.id} "

    search_field = params[:job][:to_find] unless params[:job].nil?
    if search_field.blank?
      if params[:id].nil?
        @batch = Batch.find(session[:batch])
        @selected_batch = @batch
      else
        @batch = Batch.find(params[:id])
        @selected_batch = @batch
        session[:batch] = @batch.id
      end

      @jobs = Job.find(:all, :conditions => ["batch_id = ? and job_status = ?", 
          @batch.id, JobStatus::COMPLETED]).paginate(:page => params[:page], :per_page => 30)
    else
      @selected_batch = session[:batch]
      @jobs =  filter_jobs(params[:job][:criteria], params[:job][:compare], 
        params[:job][:to_find], payer_condition,@selected_batch).paginate(:page => params[:page], :per_page => 30)
    end
    
  end#view completed jobs
  

  def filter_jobs(field, comp, search, condition,selected)
    @job_batchid = params[:jobs]
    batch = Batch.find_by_id(selected)
    selected = batch.batchid
    case field
    when 'Check Number'
      @jobs = Job.find(:all, :conditions => "check_number #{comp} '#{search}' and  batchid = #{selected} and job_status = '#{JobStatus::COMPLETED}' " ,
        :include => :batch)
                        
    when 'Tiff Number'
      @jobs = Job.find(:all, :conditions => "tiff_number #{comp} '#{search}'and  batchid = #{selected} and job_status = '#{JobStatus::COMPLETED}' " ,
        :include => :batch)
                          

    end
    if @jobs.size == 0
      flash[:notice] = "Search for #{search} did not return any results. Try another keyword!"
      redirect_to :action => 'view_completed_jobs'
    end
    return @jobs
  end
  
  def reject_tiff
    unless params[:id].nil?
      @batch = Batch.find(params[:id])
      @tiff = params[:tiff]
      @job = params[:job]
      @check = params[:check]
      @payer = params[:payer]
      @facility = params[:facility]
    end
  end  

  #uploading  document for comments
  def add
    upload = params[:upload]
    if params[:upload][:file].size == 0
      flash[:notice] = "No File selected / File does not exist!"
      redirect_to :action => 'reject_tiff',:id => params[:batch] ,:tiff => params[:tiff] ,:check => params[:check],:payer => params[:payer] ,:facility => params[:facility]
    else
      data = params[:upload][:file]
      path = File.join('public/data/', data.original_filename)
      File.open(path, "wb") { |f| f.write(upload["file"].read) }
      doc = HlscDocument.new
      doc.file_name = data.original_filename
      doc.file_comments = params[:file_upload_comment][:comment]
      temp_file = data.original_filename
      doc.file_location = 'public/data/' + temp_file
      doc.file_created_time = Time.now
      doc.facility_id = params[:facility]
      doc.payer_id = params[:payer]
      doc.user_id = session[:user_id]
      if doc.save
        flash[:notice] = "File was successfully uploaded"
      else
        flash[:notice] = "Problem encountered during file upload!"
      end
      redirect_to :action => 'reject_tiff' ,:id => params[:batch] ,:tiff => params[:tiff] ,:check => params[:check],:payer => params[:payer] ,:facility => params[:facility]
    end
  end
  
  # add rejecting comment
  def add_rejection_comment
    @batch = Batch.find(params[:batch])
    @tiff = params[:tiff]
    count = 0
    @batch.update_attributes(params[:batch_rejection_comment])
    if params[:commit] == "Reject"
      @batch.jobs.each do |job|
        if params[:tiff].nil?
          if job.check_number == params[:check] 
            job.comment = params[:batch_rejection_comment][:comment]
            job.hlsc = nil
            job.save
          end
        else
          if job.tiff_number == params[:tiff] and job.check_number == params[:check]
            job.comment = params[:batch_rejection_comment][:comment]
            job.hlsc = nil
            job.save
            count = count + 1
          end
        end
      end
      @batch.hlsc = nil
      #only payment batch are entered in report
      if @batch.correspondence == false or @batch.correspondence.nil?
        hlsc_report = HlscQa.create(:batch => @batch,
          :total_eobs => @batch.get_completed_eobs,
          :rejected_eobs => @batch.least_eobs,
          :user => @user)
      end

      status_history = ClientStatusHistory.new
      status_history.time = Time.now
      status_history.status = @batch.status
      status_history.user = @user.userid
      unless status_history.save
        flash[:notice]  = 'Failed updating batch status history'
      end
      @batch.client_status_histories << status_history
      @batch.comment = "Sub Jobs Rejected"
      @batch.save
      flash[:notice] = "Job  rejected on request"
      redirect_to :action => "view_completed_jobs" ,:batch => params[:batch]
    end
  end  

end
