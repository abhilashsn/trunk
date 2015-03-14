class OperationLog::Generator
  attr_accessor :facility, :facility_name, :batch_ids,:config, :checks
  include Output835Helper
  include OperationLogHelper
  def initialize batch_ids,ack_latest_count,current_user = nil, facility=nil, config = nil
    @current_user = (current_user || User.find(:first,:conditions=>["login='admin'"]))
    @batch_ids = batch_ids
    @facility = facility || Batch.find(@batch_ids.first).facility
    @client = Batch.find(@batch_ids.first).client
    @config = config || get_oplog_config
    @ack_latest_count = ack_latest_count
  end

  def generate
    if @config
      segregate_checks
      generate_file
    else
      puts "Configuration for generationg operation log not found...........\n Please configure it and try again"
    end
  end

  private

  def get_oplog_config
    if @client.supplemental_outputs && @client.supplemental_outputs.include?("Operation Log")
      conf = @client.client_output_configs.find(:last, :conditions => "report_type = 'Operation Log'")
    else
      conf = @facility.facility_output_configs.find(:last, :conditions => "report_type = 'Operation Log'")
    end
    (conf && conf.operation_log_config) ? OperationLog::Config.new(conf.operation_log_config) : nil
  end

  def segregate_checks
    #see if this can be pushed to  mysql
    @checks = get_operation_log_checks(@config.job_status_grouping, @batch_ids)
    puts "Grouping successful, returned #{@checks.length} distinct group/s"
    Output835.oplog_log.info "Grouping successful, returned #{@checks.length} distinct group/s"
  end
  
  def generate_file

    file_name,folder_name = get_file_name
    if !@client.supplemental_outputs.blank? && @client.supplemental_outputs.include?("Operation Log")
      oplog_type = @client
    else
      oplog_type = @facility
    end
    output_dir = "private/datanew/#{oplog_type.name.downcase.gsub(' ','_')}/operation_log/#{Date.today.to_s}/#{@config.format}"
    Output835.oplog_log.info "Output directory is: #{output_dir}"
    unless @checks.blank?
      unless folder_name.blank?
        output_dir = output_dir+"/#{folder_name}"
      end
      doc = OperationLog::Document.new(@batch_ids,@config)
      FileUtils.mkdir_p(output_dir)
      op_log_start_time = Time.now

      if @config.format == "xlsx"
        generate_xlsx output_dir, file_name, doc
      elsif @config.format == "xls"
        generate_xls output_dir, file_name, doc
      else
        File.open("#{output_dir}/#{file_name}", "w+") do |f|
          f << doc.generate
          op_log_end_time = Time.now
          record_activity(@checks, 'OperationLog Generated', 'Operation_Log',
            file_name, output_dir, op_log_start_time, op_log_end_time)
        end
      end
    end
  end

  def generate_xlsx dir, file, doc
    require 'simple_xlsx'
    op_log_start_time = Time.now
    FileUtils.rm  "#{dir}/#{file}", :force => true 
    SimpleXlsx::Serializer.new("#{dir}/#{file}") do |den|
      den.add_sheet("operation_log") do |sheet|
        doc.generate.split("\n").each do |row|
          sheet.add_row(row.split("\t"))

        end
      end
      record_activity(@checks, 'OperationLog Generated', 'Operation_Log',
        file, dir, op_log_start_time, Time.now)
    end    
  end

  def generate_xls dir,file,doc
    require 'spreadsheet'
    op_log_start_time = Time.now
    FileUtils.rm  "#{dir}/#{file}", :force => true 
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet :name=>"operation log"
    counter = 0
    doc.generate.split("\n").each do |row|
      sheet.row(counter).replace row.split("\t")
      counter +=1
    end
    record_activity(@checks, 'OperationLog Generated', 'Operation_Log',
      file, dir, op_log_start_time, Time.now)
    book.write "#{dir}/#{file}"
  end
  

  def get_file_name
    #reusing the old logic here
    #facility, batch_date, batch_id,check,payer_name, batch, batch_type
    begin
      facility = @facility
      Output835.oplog_log.info "Getting File Name..."
      unless @checks.blank?
        check = @checks.first
        batch = check.batch
        batchid = batch.real_batch_id

        Output835.oplog_log.info "First check_id: #{check.id}"
        batch_date = batch.date
        batch_type = (batch.correspondence == true) ? "COR" : "PAY"
        unless check.payer.blank?
          payer_name = check.payer.payer
        else
          payer_name = "-"
        end
        Output835.oplog_log.info "First check's Job status: #{check.job.job_status}"
        if check.job.job_status == JobStatus::COMPLETED
          payer_name = payer_name
        else
          checks.each do |check|
            if check.job.job_status == JobStatus::COMPLETED
              payer_name = check.payer.payer unless check.payer.blank?
              break if payer_name
            end
          end
        end

        Output835.oplog_log.info "Payer Name of check: #{payer_name}"
        filename_hash = {
          "[Client Id]" => facility.sitecode,
          "[Client Name]" => facility.client.name,
          "[Batch date(MMDDYY)]" => batch_date.strftime("%m%d%y"),
          "[Batch date(CCYYMMDD)]" => batch_date.strftime("%Y%m%d"),
          "[Batch date(MMDDCCYY)]" => batch_date.strftime("%m%d%Y"),
          "[Batch date(DDMMYY)]" => batch_date.strftime("%d%m%y"),
          "[Batch date(YYMMDD)]" => batch_date.strftime("%y%m%d"),
          "[Batch date(DD_MM_YY)]" => batch_date.strftime("%d_%m_%d"),
          "[Batch date(YMMDD)]" => batch_date.strftime("%y%m%d")[1..-1],
          "[Batch date(MMDD)]" => batch_date.strftime("%m%d"),
          "[Facility Name abbreviation]" => facility.abbr_name,
          "[Facility Abbr]" => facility.abbr_name,
          "[3-SITE]" => facility.sitecode.slice(2,3),
          "[Batch Id]" => batchid,
          "[Facility Name]" => facility.name,
          "[Check Num]" => check.check_number,
          "[Payer Name]" => payer_name,
          "[Cut]" => batch.cut,
          "[EXT]" => batch_type,
          "[Lockbox Num]" => facility.lockbox_number}
        filename = @config.file_name
        foldername = @config.folder_name

        filename_hash.each do |key,value|
          filename.gsub!("#{key}","#{value}") if (!filename.blank? && filename.include?("#{key}"))
        end
        unless foldername.blank?
          filename_hash.each do |key,value|
            foldername.gsub!("#{key}","#{value}") if foldername.include?("#{key}")
          end
          foldername = foldername.gsub(' ','_') unless foldername.blank?
        end
        filename = "#{filename}.#{@config.format}"
        return filename,foldername
      end
    rescue Exception => e
      Output835.oplog_log.info "FileName is missing"
      Output835.oplog_log.error e.message
    end
  end

  def record_activity checks, activity, format, file_name, file_location, start_time, end_time
    batchids = get_batch_ids(@client, @config, @batch_ids[0])
    formats =["Operation_Log"]
    file_location = file_location.gsub(' ','_') unless file_location.blank?

    file_path = Rails.root.to_s + "/" +  file_location.to_s +  "/" +  file_name.to_s
    
    if File.exists?(file_path)
      checksum = ` md5sum \"#{file_path}\" ` rescue nil
    end
    checksum = checksum.split(" ")[0] if checksum

    if formats.include? format
      batchids.each do |batch_id|
        OutputActivityLog.create({:batch_id => batch_id[:id], :activity => activity, :file_name => file_name,
            :file_format => format, :file_location => file_location, :start_time => start_time,
            :end_time => end_time, :user_id => @current_user.id ,
            :status => OutputActivityStatus::GENERATED, :checksum => checksum, :ack_latest_count => @ack_latest_count})
      end
    end
  end

  
end
