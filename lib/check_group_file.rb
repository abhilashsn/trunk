# Groups checks into distinct groups and sends of output file generation
# logs output generation success to output_activity_logs table
require 'zip/zip'
require 'facility_name'
include FacilityName

INDEXED_IMAGE_PATH = "#{Rails.root}/private/data"
MULTI_TIFF_PATH = "#{Rails.root}/private"

class CheckGroupFile
  attr_accessor :facility_name, :facility, :client_name,
    :insurance_eob_output_config, :patient_eob_output_config,
    :operation_log_config, :supplemental_output_type, 
    :client_id, :batch_id, :lockbox_number, :payer

  def initialize(facility, current_user = nil)
    @current_user = (current_user || User.find(:first,:conditions=>["login='admin'"]))
    @facility = facility
    @client = @facility.client.name
    @facility_name = facility.name.downcase.gsub(' ', '_')
    @client_name = facility.client.name.downcase.gsub(' ', '_')
    @supplemental_output_type = facility.supplemental_outputs
Rails.logger.info "============== starting FacilityOutputConfig.insurance_eob"
    if FacilityOutputConfig.insurance_eob(facility.id) &&
        FacilityOutputConfig.insurance_eob(facility.id).length > 0
      @insurance_eob_output_config = FacilityOutputConfig.insurance_eob(facility.id).first
    end
Rails.logger.info "============== starting FacilityOutputConfig.patient_eob"    
    if FacilityOutputConfig.patient_eob(facility.id) && 
        FacilityOutputConfig.patient_eob(facility.id).length > 0
      @patient_eob_output_config = FacilityOutputConfig.patient_eob(facility.id).first
    end
Rails.logger.info "============== starting FacilityOutputConfig.operation_log"    
    if FacilityOutputConfig.operation_log(facility.id) &&
        FacilityOutputConfig.operation_log(facility.id).length > 0
      @operation_log_config = FacilityOutputConfig.operation_log(facility.id).first
    end
Rails.logger.info "============== starting end of initialize"    
  end

  def convert_tiff_to_jpeg
    Dir.glob("#{INDEXED_IMAGE_PATH}/#{facility_name}/indexed_image/**/*.tif", File::FNM_CASEFOLD).each do |image|
      file_name = "#{File.dirname(image)}/#{File.basename(image, File.extname(image))}.jpg"
      system("convert #{image} #{file_name}")
      File.delete(image)
    end
  end

  # Recieves batch ids and applies grouping logic on them by calling check segregator
  def process_batch_ids(batch_ids, batch_ids_for_supplemental_output)
    puts "Batches #{batch_ids.join(',')} qualify for output generation"
    if supplemental_output_type && supplemental_output_type.include?("Operation Log")
      generate_operation_log(batch_ids_for_supplemental_output)
    end
    if supplemental_output_type && supplemental_output_type.include?("Indexed Image O/P")
      generate_indexed_image_file(batch_ids_for_supplemental_output)
      convert_tiff_to_jpeg if @insurance_eob_output_config.details[:convert_tiff_to_jpeg]
    end
    begin
      if insurance_eob_output_config
        Batch.where("id in (?)", batch_ids).update_all(:status => BatchStatus::OUTPUT_GENERATING)
Rails.logger.info "============== batch updated to OUTPUT_GENERATING"
        ins_pay_grouping = insurance_eob_output_config.grouping
        pat_pay_grouping = patient_eob_output_config.grouping if patient_eob_output_config
        @facility_output_group = ins_pay_grouping.upcase
Rails.logger.info "============== After pat_pay_grouping"
        first_batch = Batch.find(batch_ids.first)
        groupings = ["SITE SPECIFIC","SINGLE DAILY MERGED CUT","SEQUENCE CUT"]
        if groupings.include?(ins_pay_grouping.upcase)
          if ins_pay_grouping.upcase == "SINGLE DAILY MERGED CUT"
            batches = Batch.find(:all,:conditions => {:date => first_batch.date, :facility_id => first_batch.facility_id, :status => BatchStatus::OUTPUT_READY})
            batch_ids = batches.collect(&:id).join(",")
          end
          if ins_pay_grouping.upcase == "SEQUENCE CUT"
            batches = Batch.find(:all,:conditions => {:date => first_batch.date, :cut => first_batch.cut, :facility_id => first_batch.facility_id, :status => BatchStatus::OUTPUT_READY})
            batch_ids = batches.collect(&:id).join(",")
          end
Rails.logger.info "============== After groupings"          
          @eob_segregator = EobSegregator.new(ins_pay_grouping, pat_pay_grouping)
Rails.logger.info "============== After EobSegregator.new"                    
          eobs = InsurancePaymentEob.by_eob(batch_ids)
Rails.logger.info "============== After InsurancePaymentEob.by_eob"
          check_eob_groups = @eob_segregator.segregate(batch_ids,eobs)
Rails.logger.info "============== After @eob_segregator.segregate"
          puts "Grouping successful, returned #{check_eob_groups.length} distinct group/s"
          Output835.log.info "Grouping successful, returned #{check_eob_groups.length} distinct group/s"
          check =  eobs.first.check_information
          batch = check.batch
          job = check.job
          check_payer = check.payer
          @batch_date = batch.date.strftime("%d%m%Y")
          @batch_id = batch.batchid
          if check_payer
            @payer = check_payer.payer
            @output_config = (job.payer_group == 'PatPay' &&
                !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
                !@insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file) ?
              @patient_eob_output_config : @insurance_eob_output_config
          end
          check_eob_groups.each do |key, value|
            check_eob_hash = value
            checks = CheckInformation.find(:all,:conditions=>["id in (?)",check_eob_hash.keys])
            @client_id = facility.sitecode
            @lockbox_number = facility.lockbox_number
            puts "Generating Output.."
            Output835.log.info "Generating Output.."
            @key = key
            generate_output(@key,checks,check_eob_hash)
          end
        
        else
Rails.logger.info "============== B4 CheckSegregator.new"        
          @check_segregator = CheckSegregator.new(ins_pay_grouping, pat_pay_grouping)
Rails.logger.info "============== after CheckSegregator.new"                  
          puts "Applying '#{first_batch.widest_grouping("Output")}' grouping on batches.."
          if @client.upcase == "GOODMAN CAMPBELL"
            check_groups = @check_segregator.segregate_gcbs_checks(batch_ids)
          else
            check_groups = @check_segregator.segregate(batch_ids)
          end
Rails.logger.info "============== after check_segregator.segregate"                            
          checks = CheckInformation.by_batch(batch_ids)
          @type = checks.collect(&:batch).collect(&:correspondence).uniq
          puts "Grouping successful, returned #{check_groups.length} distinct group/s"
          Output835.log.info "Grouping successful, returned #{check_groups.length} distinct group/s"
Rails.logger.info "============== before check_groups.each"                                      
          check_groups.each do |group, checks|
            @nextgen =  group.include?("goodman_nextgen")
            first_index = 0
            array_length = 10
            @file_index = 0
            @batch_date = checks.first.batch.date.strftime("%d%m%Y")
            @client_id = facility.sitecode
            @batch_id = checks.first.batch.batchid
            @lockbox_number = facility.lockbox_number
            payer = checks.first.payer
             job = checks.first.job
            if payer
              @payer = payer.payer
              @output_config = (job.payer_group == 'PatPay' &&
                  !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
                  !@insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file) ?
                @patient_eob_output_config : @insurance_eob_output_config
            end
Rails.logger.info "============== before Generating Output.."                                                  
            puts "Generating Output.."
            Output835.log.info "Generating Output.."
            if @client.upcase == "GOODMAN CAMPBELL" && !group.include?("notapplicable")
              check_length = checks.length
              remaining_checks = check_length % array_length
              total_number_of_files = (remaining_checks==0)? (check_length / array_length):((check_length / array_length)+1)
              file_number=0
              while(file_number < total_number_of_files)
                checks_new = checks[first_index,array_length]
                unless checks_new.blank?
                  file_number += 1
                  first_index = array_length*file_number
Rails.logger.info "============== before if generate_output"                   
                  generate_output(group, checks_new)
Rails.logger.info "============== after if generate_output"                                 
                  @file_index += 1
                end
              end
            else
Rails.logger.info "============== before else generate_output"                                                              
              generate_output(group, checks)
Rails.logger.info "============== after else generate_output"               
              end
            end
          end
     
      else
        puts "Cannot generate output without Output Configuration"
        Output835.log.info "Cannot generate output without Output Configuration"
        puts "Please create Output Configuration for #{facility}"
        Output835.log.info "Please create Output Configuration for #{facility}"
      end
      Batch.update_all(["output_835_posting_time = ?", Time.now ], " id in (#{batch_ids.join(",")})") if batch_ids.present?
    rescue Exception => e
      Batch.update_all(["status = ?", BatchStatus::OUTPUT_EXCEPTION], " id in (#{batch_ids.join(",")})") if batch_ids.present?
      Batch.update_all(["status = ?", BatchStatus::OUTPUT_EXCEPTION], " id in (#{batch_ids_for_supplemental_output.join(",")})") if batch_ids_for_supplemental_output.present?
      puts e.message
      Output835.log.error e.message
    else
      Batch.where("id in (?)", batch_ids).update_all({:status => BatchStatus::OUTPUT_GENERATED, :output_835_generated_time => Time.now})
    end
    
  end
 
  # Accesses the output config object, extracts the format and
  # deelegates the task of calling the right method,
  # based on the format to "apply_format"
  # for nextgen checks identified by having
  # 'notapplicable' as the value of their
  # 'correspondence_facet' attibute of the 'group' string,
  # format is assumed to be 'delimited' (= fixed length text)
  def generate_output(group, checks,check_hash=nil)
    nextgen = group.split('_').include?('notapplicable')
    if nextgen
      apply_format('delimited', checks,check_hash)
    else
      apply_format(insurance_eob_output_config.format.downcase, checks,check_hash)
    end
  end

  # Calls the method responsible for generating output,
  # corresponding to the format of the output desired,
  # passing the checks to it
  # for example if the format oif 835, it calls create_835_file
  def apply_format(format, checks,check_hash=nil)
Rails.logger.info "============== before format #{format}"                                                                
    case format
    when 'pc_print'
      create_pc_print_file(checks)
    when "835"
      create_835_file(checks,check_hash)
    when "xml"
      create_xml_file(checks)
    when "csv"
      create_csv_file(checks)
    when "txt", "text"
      create_txt_file(checks)
    when 'delimited'
      create_nextgen_file(checks)
    end
  end

  def generate_operation_log(batch_ids)
    if operation_log_config
      check_segregator = CheckSegregator.new
      checks = check_segregator.segregate_supplemental_output(batch_ids)
      puts "Grouping successful, returned #{checks.length} distinct group/s"
      if checks.length > 0
        extension = operation_log_config.format.downcase
        create_operation_log_file(batch_ids, checks, extension)
      else
        puts "Unable to generate Operation Log as no checks are eligible."
      end
    end
  end
  
  # Returns checkgroups of the checks to 
  # be displayed in indexed image file
  # by applying the group_name.
  def group_supplemental_output_checks(checks)
    check_segregator = CheckSegregator.new
    checks.group_by do |check|
      case check_segregator.payer_group_indexed_image(check)
      when 'corr'
        check_segregator.group_name_supplemental_output(check, 'by_correspondence')
      when 'insurance'
        check_segregator.group_name_supplemental_output(check, 'by_insurance')
      when 'patpay'
        check_segregator.group_name_supplemental_output(check, 'by_pat_pay')
      end
    end
  end
  
  # Generates separate indexed image file
  # for Patpays and Insurance payment EOBs.
  def generate_indexed_image_file(batch_ids)
    begin
      batch_date = Batch.find(batch_ids[0]).date
      batch_path = "#{INDEXED_IMAGE_PATH}/#{facility_name}/indexed_image/#{batch_date}" unless batch_date.nil?
      batch_path_for_rejected_images = "#{INDEXED_IMAGE_PATH}/#{facility_name}/indexed_image/#{batch_date}" unless batch_date.blank?
      system("rm -r #{batch_path}")
      system("mkdir -p #{batch_path}")
      system("rm -r #{batch_path_for_rejected_images}")
      system("mkdir -p #{batch_path_for_rejected_images}")
      checks = CheckInformation.get_qualified_checks(batch_ids)
      if checks.length > 0
        check_groups = group_supplemental_output_checks(checks)
        puts "Grouping successful, returned #{check_groups.length} distinct group/s"
        @corr_flag = 0
        check_groups.each do |group, check_group|
          create_indexed_image_file(check_group, batch_path, batch_path_for_rejected_images)
        end
        system("rm -r #{batch_path_for_rejected_images}/image")
      else
        puts "Unable to generate Indexed Image O/p as no checks are eligible "
      end
    rescue Exception => e
      IndexedImageFile.log.error "Exception  => " + e.message
      IndexedImageFile.log.error e.backtrace.join("\n")
    end 
  end

  def create_pc_print_file(checks)
    begin
      method_to_call = "file_name_#{client_name}_pc_print"
      file_name = send(method_to_call, checks)
      output_dir_pc_print = "private/data/#{facility_name}/pc_print/#{Date.today.to_s}"
      if file_name
        FileUtils.mkdir_p(output_dir_pc_print)
      end

      checks.each do |check|
        check.insurance_payment_eobs.each do |eob|
          output_pc_start_time = Time.now
          File.open("#{output_dir_pc_print}/#{eob.patient_account_number}__#{file_name}", 'w+') do |file|
            file << OutputPcPrint::Document.new(eob).generate
            output_pc_end_time = Time.now            
            record_activity(checks, 'Output Generated', 'PC_Print', file_name, output_dir_pc_print, output_pc_start_time, output_pc_end_time)            
            puts "Output generated sucessfully, file is written to:"
            puts "#{output_dir_pc_print}/#{eob.id}__#{file_name}"
          end
        end
      end
    rescue Exception => e
      OutputPcPrint.log.error "Exception  => " + e.message
      OutputPcPrint.log.error e.backtrace.join("\n")
    end 
  end

  def create_nextgen_file(checks)
    begin
      OutputNextgen.log.debug "Nextgen Output is generating...."
      file_name = format_nextgen_specific_names(checks, patient_eob_output_config.nextgen_file_name, "file")
      OutputNextgen.log.debug "File Name: #{file_name}"
      output_dir = "private/data/#{facility_name}/nextgen/#{Date.today.to_s}"
      
      if patient_eob_output_config.details[:nextgen_output_folder] && !patient_eob_output_config.nextgen_folder_name.blank?
        folder_name = format_nextgen_specific_names(checks, patient_eob_output_config.nextgen_folder_name, "folder")
        output_dir += folder_name
      end
      OutputNextgen.log.debug "Output Folder Name: #{output_dir}"
      
      if file_name
        FileUtils.mkdir_p(output_dir)
      end

      output_nextgen_start_time = Time.now
      File.open("#{output_dir}/#{file_name}", 'w+') do |file|
        file << OutputNextgen::Document.new(checks).generate
        output_nextgen_end_time = Time.now

        record_activity(checks, 'Output Generated', 'NextGen', file_name, output_dir, output_nextgen_start_time, output_nextgen_end_time)            

        puts "Output generated sucessfully, file is written to:"
        puts "#{output_dir}/#{file_name}"
      end
      
      if patient_eob_output_config.details[:zip_nextgen_output] && !patient_eob_output_config.nextgen_zip_file_name.blank?
        zip_file_name = format_nextgen_specific_names(checks, patient_eob_output_config.nextgen_zip_file_name, "zip")
        OutputNextgen.log.debug "Zip File Name: #{zip_file_name}"
        create_zip_file_from_output(output_dir , zip_file_name, file_name)
      end
    rescue Exception => e
      OutputNextgen.log.error "Exception  => " + e.message
      OutputNextgen.log.error e.backtrace.join("\n")
    end  
  end
  
  def create_xml_file(checks)
    begin
      file_name = file_name_generic(checks)
      puts "Output XML file name - " + file_name.to_s
      output_dir_xml = "private/data/#{facility_name}/xml/#{Date.today.to_s}"
      puts "Output XML file creation directory - " + output_dir_xml.to_s
      if file_name
        FileUtils.mkdir_p(output_dir_xml)
        puts "Directory creation successful"
      end
      output_xml_start_time = Time.now
      File.open("#{output_dir_xml}/#{file_name}", 'w+') do |file|
        file << OutputXml::Document.new(checks).generate
        output_xml_end_time = Time.now        
        record_activity(checks, 'Output Generated', 'XML', file_name, output_dir_xml, output_xml_start_time, output_xml_end_time)            
        puts "Output generated sucessfully, file is written to:"
        puts "#{output_dir_xml}/#{file_name}"
      end
    rescue Exception => e
      OutputXML.log.error "Exception  => " + e.message
      OutputXML.log.error e.backtrace.join("\n")
    end  
  end

  # Creates the directory structure and the 835 file
  # after looking up the file naming format for
  # the client or the lockbox
  def create_835_file(checks,check_hash=nil)
Rails.logger.info "============== entered create_835_file"  
    begin
      format = "835"
      @new_output_folder = nil
      folder_ext = nil
      if @output_config.details[:output_folder]
        batch_id = checks.first.batch.real_batch_id
        payer = checks.first.payer
        job = checks.first.job
        payer_name = payer.payer rescue ""
        #Gets the file name fields which are used to create file name string.
Rails.logger.info "============== before create_filename_hash"          
        filename_hash = create_filename_hash(checks,batch_id,payer_name)
Rails.logger.info "============== after create_filename_hash"        
        @new_output_folder = "#{@output_config.folder_name}"
        folder_ext = nil
        
        filename_hash.each do |key,value|
          if @new_output_folder.include?("[EXT]") 
            if insurance_eob_output_config.payment_corres_patpay_in_one_file
              folder_ext =  "ALL"
            elsif insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file
              folder_ext = (job.payer_group == 'PatPay') ? "PATPAY" : "INS"
            elsif insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
              folder_ext = checks.first.correspondence? ? "COR" : "INS"
            else
              folder_ext = checks.first.correspondence? ? "COR" :  (job.payer_group == 'PatPay') ? "PATPAY" : "INS"
            end
          end
          if @new_output_folder.include?("#{key}")
            if key == "[EXT]" and !folder_ext.blank?
              @new_output_folder.gsub!("#{key}","#{folder_ext}")
            else
              @new_output_folder.gsub!("#{key}","#{value}")
            end
          end
        end
      end
  Rails.logger.info "============== before @output_dir_835"        
      @output_dir_835 = "private/data/#{facility_name}/835s/#{Date.today.to_s}"

     # payer_of_first_check = checks.first.payer
      payer_type = checks.first.job.payer_group if !checks.first.job.blank?
      if (insurance_eob_output_config.payment_corres_patpay_in_one_file ||
            insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file)
        facility_output_config = insurance_eob_output_config
      else
        facility_output_config = facility.output_config(payer_type)
      end
      multi_st = facility_output_config.multi_transaction
      document_class = multi_st ? 'Document' : 'SingleStDocument'

      if !check_hash.blank?
        groupings = ["SITE SPECIFIC","SINGLE DAILY MERGED CUT","SEQUENCE CUT"]
        file_name = (groupings.include?(@facility_output_group))? ("#{@key}") : ("#{@key}.#{format}")
      else
        file_name = file_name_generic(checks)

        if facility.name.upcase == "HORIZON LABORATORY LLC" || facility.name.upcase == "STANFORD UNIVERSITY MEDICAL CENTER"
          if !checks.first.insurance_payment_eobs.blank?
            correspondence_835 = !facility_output_config.payment_corres_patpay_in_one_file &&
              !facility_output_config.payment_corres_in_one_patpay_in_separate_file &&
              checks.first.correspondence?
            if multi_st
              document_class = correspondence_835 ? 'CorrespondenceDocument' : 'Document'
            else
              document_class = correspondence_835 ? 'CorrespondenceDocument' : 'SingleStDocument'
            end
          end
        end
      end
      if @output_config.details[:zip_output]
        zip_file_name = zip_file_name_generic(checks)
      end
      if file_name
        doc_klass = Output835.class_for(document_class, facility)
        Output835.log.info "Applying class #{doc_klass}"
        doc = doc_klass.new(checks, {}, check_hash)
        version = @insurance_eob_output_config.details[:output_version]
        dir_name = version ? ( version == '4010') ? '4010' : '5010' : ''
        @output_dir_835 = @output_dir_835 + "/#{dir_name}"
        
        if client_name == "goodman_campbell"
          nextgen_folder = @nextgen ? 'nextgen' : ''
          @output_dir_835 += "/#{nextgen_folder}"
          doc.instance_variable_set("@nextgen", @nextgen)
        end
        unless  @new_output_folder.blank?
          @output_dir_835 += "/#{@new_output_folder}"
        end
        FileUtils.mkdir_p(@output_dir_835)
        output_835_start_time = Time.now
        output_pc_start_time = Time.now
        output_pc_end_time = Time.now
        op_file_name = file_name
        activity_logs = record_835_activity_start(checks, op_file_name, @output_dir_835, zip_file_name)
        plb_excel_sheet = create_excel_sheet if client_name == 'ahn'
        doc.instance_variable_set("@plb_excel_sheet", plb_excel_sheet)
        output_string = doc.generate
        File.open("#{@output_dir_835}/#{file_name}", 'w+') do |file|
          file << output_string.force_encoding("UTF-8")
        end
        batch_date = checks.first.batch.date.strftime("%m%d%y")
        if !insurance_eob_output_config.payment_corres_patpay_in_one_file &&
            !insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file
          type = checks.first.correspondence? ? 'COR_' : 'INS_'
        end
        @book.write "private/data/#{facility_name}/835s/#{Date.today.to_s}/#{batch_date}_#{type}prov_adj_summary.xls" if @book
        if version == 'both'
          directory = @output_dir_835.gsub('/5010', '/4010')
          FileUtils.mkdir_p(directory)
          File.open("#{directory}/#{file_name}", 'w+') do |file|
            file << make_4010_output(output_string)
          end
          if @output_config.details[:zip_output]
            puts "zipping output file"
            create_zip_file_from_output(directory ,zip_file_name,file_name)
          end
        end
        
        output_835_end_time = Time.now
        OutputActivityLog.mark_generated_with_checksum(activity_logs, output_835_end_time);
        if @output_config.details[:zip_output]
          puts "zipping output file"
          create_zip_file_from_output(@output_dir_835,zip_file_name,file_name)
          OutputActivityLog.create_entry_for_zipped_835(activity_logs, zip_file_name)
        end
        puts "Output generated sucessfully, file is written to:"
        puts "#{@output_dir_835}"
      end
    rescue Exception => e
      Output835.log.error "Exception  => " + e.message
      Output835.log.error e.backtrace.join("\n")
    end  
  end

  #-----------------------------------------------------------------------------
  # Description : This method creates zipped version of output file.                   
  # Input       : output directory path, output filename
  # Output      : None
  #-----------------------------------------------------------------------------  
 
  def create_zip_file_from_output(output_dir,zip_name,file_name)
    begin

      Zip::ZipFile.open("#{output_dir}/#{zip_name}", Zip::ZipFile::CREATE) do |file|
        file.add(file_name, "#{output_dir}/#{file_name}")
      end
    rescue Exception => e
      Output835.log.error "Exception  => " + e.message
      Output835.log.error e.backtrace.join("\n")
    ensure
      #FileUtils.rm "#{output_dir}/#{file_name}",  :force => true if File.exists?("#{output_dir}/#{zip_name}")
    end
  end 
  
  # Creates the directory structure and the csv file
  # after looking up the file naming format for
  # the client or the lockbox
  def create_csv_file(checks)
    begin
      file_name = file_name_generic(checks)
      output_dir_indexed_image = "private/data/#{facility_name}/csv/#{Date.today.to_s}"
      if file_name
        FileUtils.mkdir_p(output_dir_indexed_image)
      end
      File.open("#{output_dir_indexed_image}/#{file_name}", 'w+') do |file|
        file << OutputCsv::Document.new(checks).generate
        puts "Output generated sucessfully, file is written to:"
        puts "#{output_dir_indexed_image}/#{file_name}"
      end
    rescue Exception => e
      OutputCSV.log.error "Exception  => " + e.message
      OutputCSV.log.error e.backtrace.join("\n")
    end  
  end

  # Creates the directory structure and the txt file
  # after looking up the file naming format for
  # the client or the lockbox
  def create_txt_file(checks)
    begin
      method_to_call = "file_name_#{client_name}_txt"
      file_name = send(method_to_call, checks)
      output_dir_indexed_image = "private/data/#{facility_name}/#{Date.today.to_s}/txt"
      if file_name
        FileUtils.mkdir_p(output_dir_indexed_image)
      end
      File.open("#{output_dir_indexed_image}/#{file_name}", 'w+') do |file|
        file << OutputText::Document.new(checks).generate
        puts "Output generated sucessfully, file is written to:"
        puts "#{output_dir_indexed_image}/#{file_name}"
      end
    rescue Exception => e
      OutputText.log.error "Exception  => " + e.message
      OutputText.log.error e.backtrace.join("\n")
    end  
  end

  # Creates the directory structure and the csv file
  # after looking up the file naming format for
  # the client or the lockbox
  def create_operation_log_file(batch_ids, checks,extension)
    begin
      #Gets the file name for operation log.
      file_name = "#{file_name_operation_log(checks)}"
      output_dir_indexed_image = "private/data/#{facility_name}/operation_log/#{Date.today.to_s}/#{extension}"
      if client_name == "quadax"
        output_dir_indexed_image = folder_structure( checks, "operation_log", extension)
      end
      if file_name
        doc_klass = OperationLogCsv.class_for("Document", facility)
        doc = doc_klass.new(facility, batch_ids, checks, extension)
        FileUtils.mkdir_p(output_dir_indexed_image)
        File.open("#{output_dir_indexed_image}/#{file_name}", 'w+') do |file|
          file << doc.generate
          puts "Operation log generated sucessfully, file is written to:"
          puts "#{output_dir_indexed_image}/#{file_name}"
        end
      end
    rescue Exception => e
      OperationLogCsv.log.error "Exception  => " + e.message
      OperationLogCsv.log.error e.backtrace.join("\n")
    end
  end

  def create_indexed_image_file(check_group, batch_path, batch_path_for_rejected_images)
    begin
      check_segregator = CheckSegregator.new
      check_group_batch = check_group.first.batch
      batch_date = check_group_batch.bank_deposit_date.strftime("%m%d%Y")
      check_group.each do |check|
        merge_and_split_images_for_gcbs(check, batch_path ) if facility.name.upcase == FACILITY_GOODMAN
      end
      # Creating separate Indexed Image files for Patpays and Insurance payment EOBs
      check_type = check_segregator.payer_group_indexed_image(check_group.first)
      file_name = "#{batch_date}_#{check_type.upcase}_INDEXEDIMAGE.csv"
      output_dir_indexed_image = "private/data/#{facility_name}/indexed_image/csv/#{Date.today.to_s}"
      if check_type == "corr"
        @corr_flag = 1
        merge_corr_images_for_gcbs(check_group, batch_path_for_rejected_images) if facility.name.upcase == FACILITY_GOODMAN
      end
      
      if file_name
        doc_klass = IndexedImageFile.class_for("Document", facility)
        doc = doc_klass.new(check_group)
        FileUtils.mkdir_p(output_dir_indexed_image)

        indexed_img_file_start_time = Time.now
        File.open("#{output_dir_indexed_image}/#{file_name}", 'w+') do |file|
          file << doc.generate
          indexed_img_file_end_time = Time.now
          
          record_activity(check_group, 'IndexedImageFile Generated', 'Indexed_Image_File',
            file_name, output_dir_indexed_image, indexed_img_file_start_time, indexed_img_file_end_time)
          puts "Indexed Image file for #{check_type} generated sucessfully, file is written to:"
          puts "#{output_dir_indexed_image}/#{file_name}"
        end
      end
    rescue Exception => e
      IndexedImageFile.log.error "Exception  => " + e.message
      IndexedImageFile.log.error e.backtrace.join("\n")
    end
  end
  
  #Saves a record in output_activity_logs table
  #corresponding to each batch in the group of check that it recieves
  # def save_output_activity(checks, user_id, activity, file_name, format, file_location,output_start_time,output_end_time,output_status=nil)
  #   batchids = checks.collect{|check| check.batch.id}
  #   total_output_charge = 0
  #   total_excluded_amount = 0
  #   batchids = batchids.uniq
  #   batchids.each do |batch_id|
  #     batch = Batch.find(batch_id)
  #     payers_to_exclude = batch.facility.excluded_payers.collect(&:id)
  #     batch.update_attributes({:output_835_generated_time => output_end_time}) if batch
  #     ouput_log_record = OutputActivityLog.find_by_batch_id_and_file_format_and_file_name(batch_id, format, file_name)
  #     if not ouput_log_record
  #       ouput_log_record = OutputActivityLog.new({:batch_id => batchid, :activity => activity, :file_name => file_name, file_format => format})
  #     end      
  #     ouput_log_record.start_time = output_start_time if output_start_time
  #     ouput_log_record.end_time = output_end_time   if output_end_time
  #     ouput_log_record.estimated_end_time = output_end_time + 10  unless output_end_time.blank? #this have to caculated
  #     ouput_log_record.user_id = user_id
  #     ouput_log_record.file_location = file_location
  #     ouput_log_record.file_size = File.size?("#{file_location}/#{file_name}").to_i
  #     ouput_log_
  #     ouput_log_record.status = output_status
  #     ouput_log_record.save
  #     unless output_end_time.blank?
  #     checks.each do |check|
  #       total_output_charge += check.check_amount
  #       check_payer_id = check.get_payer.id unless check.get_payer.blank?
  #       if payers_to_exclude.include?(check_payer_id)
  #         total_excluded_amount += check.check_amount
  #       end
  #       check.insurance_payment_eobs.each do |eob|
  #         EobsOutputActivityLog.create({:insurance_payment_eob_id=>eob.id, :output_activity_log_id=>ouput_log_record.id}) 
  #       end
  #       check.patient_pay_eobs.each do |pob|
  #         EobsOutputActivityLog.create({:patient_pay_eob_id=>pob.id, :output_activity_log_id=>ouput_log_record.id}) 
  #       end        
  #     end
  #     ouput_log_record.update_attributes(:total_charge=>total_output_charge,:total_excluded_charge=>total_excluded_amount)
  #     end
  #   end
  # end


  def record_activity checks, activity, format, file_name, file_location, output_start_time, output_end_time
    batchids = CheckInformation.checks_batch_ids(checks)
    formats =["PC_Print", "NextGen", "XML", "Indexed_Image_File"]

    file_path = Rails.root.to_s + "/" +  file_location.to_s +  "/" +  file_name.to_s
    
    if File.exists?(file_path)
      checksum = ` md5sum \"#{file_path}\" ` rescue nil
    end
    checksum = checksum.split(" ")[0] if checksum

    if formats.include? format
      batchids.each do |batch_id|
        OutputActivityLog.create({:batch_id => batch_id, :activity => activity, :file_name => file_name,
            :file_format => format, :file_location => file_location, :start_time => output_start_time,
            :end_time => output_end_time, :user_id => @current_user.id ,
            :status => OutputActivityStatus::GENERATED, :checksum => checksum})
      end
    end
  end

  def record_835_activity_start checks, file_name, file_location, zip_file_name=nil
    batchids = CheckInformation.checks_batch_ids(checks)
    payers_to_exclude = Batch.find(batchids.first).facility.excluded_payers.collect(&:id)
    eob_ids = []
    pob_ids = []
    activity_logs = []
    total_output_charge = 0
    total_excluded_amount = 0
    total_payment_charge = 0
    activity_logs = []
    checks.each do |check|
      total_output_charge += check.check_amount.to_f
      check_payer_id = check.get_payer.id unless check.get_payer.blank?
      if payers_to_exclude.include?(check_payer_id)
        total_excluded_amount += check.check_amount.to_f
      end
      check.insurance_payment_eobs.each do |eob|          
        total_payment_charge += (eob.total_amount_paid_for_claim.to_f + eob.claim_interest.to_f)
        eob_ids << eob.id
      end
      check.patient_pay_eobs.each do |pob|
        pob_ids << pob.id
      end        
    end


    start = Time.now
    estimated_end_time = start + ((eob_ids.size + pob_ids.size) * 2).second
    file_format = '835'
    file_format = '835_source'  if zip_file_name
    batchids.each do |batch_id|
      activity_logs << OutputActivityLog.create({:batch_id => batch_id, :activity => '835 Output Generated', :file_name => file_name,
          :file_format => file_format, :file_location => file_location, :start_time => start,
          :estimated_end_time => estimated_end_time, :total_charge => total_output_charge,
          :total_excluded_charge => total_excluded_amount,
          :total_payment_charge => total_payment_charge,
          :user_id => @current_user.id , :status => OutputActivityStatus::GENERATING})

    end
    eoals_eob = []
    eoals_pob = []
    activity_logs.each do | ouput_log_record|
      eob_ids.each do |eob|
        eoals_eob << EobsOutputActivityLog.new({:insurance_payment_eob_id=>eob, :output_activity_log_id=>ouput_log_record.id}) 
      end

      pob_ids.each do |pob|
        eoals_pob << EobsOutputActivityLog.new({:patient_pay_eob_id=>pob, :output_activity_log_id=>ouput_log_record.id})         
      end
    end

    EobsOutputActivityLog.import eoals_eob
    EobsOutputActivityLog.import eoals_pob
    return activity_logs
  end

  def record_835_activity_end
    
  end


  # Gets the file name for Operation Log
  def file_name_operation_log(checks)
    if checks && checks.length > 0
      batch_id = checks.first.batch.real_batch_id
      unless checks.first.payer.blank?
        payer_name = checks.first.payer.payer
      else
        payer_name = "-"   
      end
      if checks.first.job.job_status == JobStatus::COMPLETED
        payer_name = payer_name
      else
        checks.each do |check|
          if check.job.job_status == JobStatus::COMPLETED
            payer_name = check.payer.payer unless check.payer.blank?
            break if payer_name
          end
        end
      end
      #Gets the file name fields which are used to create file name string.
      filename_hash = create_filename_hash(checks, batch_id, payer_name)
      filename = "#{operation_log_config.file_name}"
      name_format = "#{operation_log_config.format}"
      filename_hash.each do |key,value|
        filename.gsub!("#{key}","#{value}") if filename.include?("#{key}")
      end
      filename = "#{filename}.#{name_format}"
    end
  end

  # Gets the file name for client_g's pc_print output
  def file_name_client_g_pc_print(checks)
    extension = 'txt'
    date = Date.today.strftime("%Y%m%d")
    "#{facility.lockbox_number}.#{date}.#{extension}"
  end

  # Gets the file name for .txt
  def file_name_client_h_txt(checks)
    extension = 'txt'
    lockbox_number = facility.lockbox_number
    file_name = "ERA_#{lockbox_number}.#{Date.today.to_s}.#{extension}"
    file_name
  end

  # Gets the file name for 835,xml,csv of any client,
  def file_name_generic(checks)
    if !insurance_eob_output_config.payment_corres_patpay_in_one_file &&
        !insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file
      correspondence_835 = checks.first.correspondence?
    end
    payerid = nil
    if facility.name.upcase == FACILITY_GOODMAN
      first_check = checks.first
      batch_id = first_check.batch.real_batch_id
      payer_name = get_gcbs_filename(first_check)
      payer_id_grouping = ((insurance_eob_output_config.grouping == 'By Payer Id By Batch' || insurance_eob_output_config.grouping == 'By Payer Id By Batch Date')  &&
          first_check.payer.supply_payid == facility.commercial_payerid )
    elsif facility.name.upcase == "HORIZON LABORATORY LLC" or facility.name.upcase == "STANFORD UNIVERSITY MEDICAL CENTER" 
      batch_id = checks.first.batch.real_batch_id
      payer_name = checks.first.payer.payer rescue ""
    else
      facilities_list =['SOUTH COAST','HORIZON EYE','SAVANNAH PRIMARY CARE','ORTHOPAEDIC FOOT AND ANKLE CTR','SAVANNAH SURGICAL ONCOLOGY','CHATHAM HOSPITALISTS','GEORGIA EAR ASSOCIATES','DAYTON PHYSICIANS LLC UROLOGY']
      if facilities_list.include?(facility.name.upcase)
        batch_id = checks.first.batch.batchid.split('_').fetch(-2)
      else  
        batch_id = checks.first.batch.real_batch_id
      end
      payer_name = checks.first.payer.payer rescue ""
      payerid = checks.first.payer.supply_payid rescue ""
    end
    #Gets the file name fields which are used to create file name string.

    filename_hash = create_filename_hash(checks,batch_id,payer_name, payerid)
    if checks.first.job.payer_group == 'PatPay' &&
        !insurance_eob_output_config.payment_corres_patpay_in_one_file &&
        !insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
      filename = "#{patient_eob_output_config.file_name}"
      name_format = "#{patient_eob_output_config.format}"
    else
      filename = "#{insurance_eob_output_config.file_name}"
      name_format = "#{insurance_eob_output_config.format}"
    end
    if payer_id_grouping
      filename = file_name_for_payer_id_grouping
    end
    if correspondence_835 && !insurance_eob_output_config.file_name_corr.blank?
      filename = "#{insurance_eob_output_config.file_name_corr.strip}" 
    end
    filename_hash.each do |key,value|
      filename.gsub!("#{key}","#{value}") if filename.include?("#{key}")
    end
    if @client.upcase == "GOODMAN CAMPBELL"
      gcbs_835_file_name = "#{filename}"
      if gcbs_835_file_name.include?(".835")
        gcbs_835_file_name.gsub!(".835","")
      end
      @gcbs_file =  gcbs_835_file_name if @file_index==0
      filename = (@file_index>0)? "#{@gcbs_file}_#{@file_index}.835":"#{@gcbs_file}.835"
    else
      filename = "#{filename}"
    end
  end

  def get_gcbs_filename(first_check)
    payer_name = ""
    first_check_payer = first_check.payer
    unless first_check_payer.blank?
      payid = first_check_payer.output_payid(facility)
      if payid == "REVMED"
        payer_name = "MISCPAYER"
      else
        payer_name = first_check_payer.payer.gsub(' ','').slice(0,15).upcase rescue ""
      end
    end
    payer_name
  end

  def zip_file_name_generic(checks)
    batch_id = checks.first.batch.real_batch_id
    payer_name = checks.first.payer.payer rescue ""
    #Gets the file name fields which are used to create file name string.
    filename_hash = create_filename_hash(checks,batch_id,payer_name)
    if checks.first.job.payer_group == 'PatPay'
      zip_filename = "#{patient_eob_output_config.zip_file_name}"
    else
      zip_filename = "#{insurance_eob_output_config.zip_file_name}"
    end
    zip_ext = ".ZIP"
    filename_hash.each do |key,value|
      if zip_filename.include?("[EXT]") and (insurance_eob_output_config.payment_corres_patpay_in_one_file ||
            insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file ||
            insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file)
        zip_ext =  (@check_segregator.blank?)? (@eob_segregator.zip_type) :  (@check_segregator.zip_type)
      end
      if zip_filename.include?("#{key}")
        if key == "[EXT]" and (insurance_eob_output_config.payment_corres_patpay_in_one_file ||
              insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file ||
              insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file)
          zip_filename.gsub!("#{key}","")
        else
          zip_filename.gsub!("#{key}","#{value}")
        end
      end
    end
    zip_file_name = (!insurance_eob_output_config.payment_corres_patpay_in_one_file &&
        !insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file &&
        !insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file) ?
      "#{zip_filename}" :  "#{zip_filename}#{zip_ext}"
    return zip_file_name
  end

  def format_nextgen_specific_names(checks, name, type)
    name_hash = create_filename_hash(checks, batch_id, payer)

    name_hash.each do |key,value|
      name.gsub!("#{key}","#{value}") if name.include?("#{key}")
    end
    
    if type == "file"
      name.gsub!(".txt","") if name.include?(".txt")
      name.gsub!(".TXT","") if name.include?(".TXT")
      "#{name}.txt"
    elsif type == "folder"
      name.gsub!("[EXT]","NXGN") if name.include?("[EXT]")
      "/" + name
    else
      name.gsub!(".zip","") if name.include?(".zip")
      name.gsub!(".ZIP","") if name.include?(".ZIP")
      "#{name}.ZIP"
    end
  end

  def file_name_for_payer_id_grouping
    "#{batch_date_format}_RX_MISCPAYER"
  end
  
  def batch_date_format
    date_format = nil
    unless insurance_eob_output_config.file_name.blank?
      format_components = insurance_eob_output_config.file_name.split(']')
      format_components.each do |component|
        contain_batch_date = ( component.scan( 'Batch date' ) )[0]
        if contain_batch_date && component.include?(contain_batch_date)
          date_format = component.insert(component.length, ']')
        end
      end      
    else
      raise "Please Configure the Insurance Payment Output File Name Format.
             The Miscellaneous Payer file is expecting Batch date in the Output file name"
    end
    if date_format.blank?
      raise "Please Configure the Batch date to be in Insurance Payment Output File Name Format.
             The Miscellaneous Payer file is expecting Batch date in the Output file name"
    end
    date_format
  end
  
  def folder_structure( checks, output_type, extension, version = nil)
    first_check = checks.first
    batch = first_check.batch
    deposit_date = batch.bank_deposit_date.strftime("%Y%m%d")
    batch_name = batch.batchid
    
    if output_type != '835'
      folder_name = "private/data/#{facility_name}/operation_log/#{extension}/#{Date.today.to_s}/#{batch_name}_Supplemental_Output"
    end
    folder_name
  end

  def generate_null_835 batch, type
    puts "Generating null files"
    filename = "#{Time.now.strftime("%m%d")}#{batch.cut}#{batch.index_batch_number}.#{type[0..2]}_Exception_#{Time.now.strftime("%m%d%Y")}.txt"
    FileUtils.mkdir_p(@output_dir_835) unless File.directory?(@output_dir_835)
    File.open("#{@output_dir_835}/#{filename}", "w") do |file|
      file << "NO #{type} BATCHES IN LOCKBOX FILE"
    end
  end

  private
  #1. A multipage file which contains all the images in a transaction.
  #   It will include check image, EOB images, BOPs, Envelops and OTHs.
  #2. Copy Single page images ,that are related to EOBs, into directory
  #    where the indexed image files generated that client had originally sent.
  #3. Combines all single page image into multi page image.
  #4. Combines spanning_eob images into multipage.
  def merge_and_split_images_for_gcbs(check, batch_path)

    batch = check.batch
    batch_id = batch.id
    batchid = batch.batchid
    batch_path = batch_path + "/#{batchid}"
    system("mkdir -p #{batch_path}")
    image_path = batch_path + "/image"
    system("mkdir -p #{image_path}")
    
    all_jobs = Job.find(:all, :conditions => ["batch_id =?", batch_id])
    job = check.job
    image_names_for_job = []
    images = job.images_for_jobs

    if job.parent_job_id.nil?
      images.each do |image|
        image_name = File.basename(image.public_filename_url())
        original_path =  image.public_filename_url()
        system("cd #{image_path};cp #{original_path} #{image_path}")
        image_names_for_job << image_name
      end
        
      create_multi_page_image_for_GCBS(batch_path, image_names_for_job, image_path)
        
      insurance_payment_eobs = check.insurance_payment_eobs
      patient_pay_eobs = check.patient_pay_eobs
      if !insurance_payment_eobs.blank?
        insurance_payment_eobs.each do |eob|
          create_spanning_eob_multi_page_image(eob, image_names_for_job, batch_path, image_path)
        end
      elsif !patient_pay_eobs.blank?
        patient_pay_eobs.each do |eob|
          create_spanning_eob_multi_page_image(eob, image_names_for_job, batch_path, image_path)
        end
      end
    else
      all_jobs.each do |single_job|
        if single_job.parent_id == job.id
          images.each do |image|
            if image.sub_job_id == single_job.id
              image_name = File.basename(image.public_filename_url())
              original_path =  image.public_filename_url()
              system("cd #{image_path};cp #{original_path} #{image_path}")
              image_names_for_job << image_name
            end
          end
           
          create_multi_page_image_for_GCBS(batch_path, image_names_for_job, image_path)
            
          insurance_payment_eobs = check.insurance_payment_eobs
          unless insurance_payment_eobs.nil?
            insurance_payment_eobs.each do |eob|
              if eob.sub_job_id == single_job.id
                create_spanning_eob_multi_page_image(eob, image_names_for_job, batch_path, image_path)
              end
            end
          end
        end
      end
    end
    system("rm -r #{image_path}")
  end
  
  # This is for creating a multi page image in the indexed_image/batch_id folder,
  # using tiff cp command and named it as "<first_file_name>_T.tif" 
  def create_multi_page_image_for_GCBS(batch_path, image_names_for_job, image_path)
    single_page_files = Dir.glob("#{image_path}/*.tif").sort
    unless image_names_for_job.nil?
      first_image_name = image_names_for_job[0]
      multi_page_image_name = first_image_name.chomp(".tif") + "_T.tif"
      system("cd #{batch_path}; tiffcp #{single_page_files.join(' ')} #{batch_path}/#{multi_page_image_name}")
    end
  end
  
  #  Loop over the eobs and identify eobs that are spanning pages.
  #  Creating an array with the file name of these eobs by checking the values of   
  #  pages_from and pages_to.Take out the images that correspond to page from and to, and
  #  created new multipage images in the indexed_image/batchid/check_number folder,
  #  naming them as <first_file_name>_M.tif
  #  Copy all single pages that are related to EOBS, not to spanning EOBs.
  def create_spanning_eob_multi_page_image(eob, image_names_for_job, batch_path, image_path)
    page_from = eob.image_page_no - 1
    if eob.class == InsurancePaymentEob
      images_with_spanning_eobs = []
      page_to = eob.image_page_to_number - 1

      if page_from != page_to && page_to > page_from
        page_from.upto(page_to) { |i|
          images_with_spanning_eobs << image_path + "/"+ image_names_for_job[i]
        }
        fist_image_name_with_spanning_eob = image_names_for_job[page_from]
      end

      if images_with_spanning_eobs.length > 1
        resultant_image_name = fist_image_name_with_spanning_eob.chomp(".tif") + "_M.tif"
        system("cd #{batch_path}; tiffcp #{images_with_spanning_eobs.join(' ')} #{batch_path}/#{resultant_image_name}")
      end

      if page_from == page_to
        copy_image_path = image_path + "/"+ image_names_for_job[page_from]
        system("cd #{batch_path};cp #{copy_image_path} #{batch_path}")
      end
    elsif eob.class == PatientPayEob
      copy_image_path = image_path + "/"+ image_names_for_job[page_from]
      system("cd #{batch_path};cp #{copy_image_path} #{batch_path}")
    end
  end
  #File name hash which are used to create file name string for both output and
  # supplemental output. 
  def create_filename_hash(checks,batch_id,payer_name, payerid = nil )
    check = checks.first
    payid = payer_id(check)

    output_payid = check.payer ? check.payer.output_payid(facility) : nil
    batch = checks.first.batch
    batch_date = batch.date
    aba_routing_number = (check.micr_line_information.blank?)? "" : (check.micr_line_information.aba_routing_number)
    payer_account_number = (check.micr_line_information.blank?)? "" : (check.micr_line_information.payer_account_number)
    batch_type = (batch.correspondence == true) ? "COR" : "PAY"
    filename_hash = { "[Client Id]" => facility.sitecode,
      "[Batch date(MMDDYY)]" => batch_date.strftime("%m%d%y"),
      "[Batch date(CCYYMMDD)]" => batch_date.strftime("%Y%m%d"),
      "[Batch date(MMDDCCYY)]" => batch_date.strftime("%m%d%Y"),
      "[Batch date(DDMMYY)]" => batch_date.strftime("%d%m%y"),
      "[Batch date(YYMMDD)]" => batch_date.strftime("%y%m%d"),
      "[Batch date(YMMDD)]" => batch_date.strftime("%y%m%d")[1..-1],
      "[Batch date(MMDD)]" => batch_date.strftime("%m%d"),
      "[Facility Abbr]" => facility.abbr_name,
      "[3-SITE]" => facility.sitecode.slice(2,3),
      "[Batch Id]" => batch_id,
      "[Facility Name]" => facility.name,
      "[Check Num]" => check.check_number,
      "[Payer Name]" => payer_name,
      "[Cut]" => batch.cut,
      "[EXT]" => batch_type,
      "[Lockbox Num]" => facility.lockbox_number,
      "[ABA Routing Num]" => aba_routing_number,
      "[Image File Name]" => check.image_file_name,
      "[Payer Account Num]"=>payer_account_number,
      "[Check Amount]" =>check.check_amount.to_s,
      "[Payer ID]" => payid,
      "[Payer Group]" => payer_group(output_payid),
      "[Output Payid]" => output_payid
    }
  end

  def payer_id(check)
    if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end
    
    unless @payer.blank?
      if @client.upcase == "GOODMAN CAMPBELL"
        (@nextgen ? @payer.gcbs_output_payid(@facility) : @payer.output_payid(@facility))
      else
        @payer.supply_payid
      end
    else
      ""
    end
  end
  
  def payer_group payerid
    case payerid
    when 'WC001'
      'WorkersComp'
    when 'NF001'
      'NoFault'
    when 'CO001'
      'Commercial'
    when 'D9998'
      'Default'
    else
      'Unidentified'
    end
  end
  
  def merge_corr_images_for_gcbs(check_group, batch_path_for_rejected_images)
    check_group_corr = group_checks(check_group)
    puts "Correspondence payer wise grouping successful, returned #{check_group_corr.length} distinct group/s"
    check_group_corr.each do |group, check_grp|
      non_eob_corr_images = []
      non_eob_payer_images = []
      incomplete_checks = []
      check_grp.each do |check|
        image_path_for_rejected_images = batch_path_for_rejected_images + "/image"
        system("mkdir -p #{image_path_for_rejected_images}")
        create_non_eob_corr_and_payer_images_for_gcbs(batch_path_for_rejected_images, check, image_path_for_rejected_images, non_eob_corr_images, non_eob_payer_images, incomplete_checks)
      end
    end
  end
  
  def create_non_eob_corr_and_payer_images_for_gcbs(batch_path_for_rejected_images, check, image_path_for_rejected_images, non_eob_corr_images, non_eob_payer_images, incomplete_checks)
    
    check.insurance_payment_eobs.each do |eob|
      if eob.patient_account_number && eob.patient_account_number.upcase == "CORR" && check.job.job_status == JobStatus::INCOMPLETED
        incomplete_checks << check
      end
      if incomplete_checks.length >= 1 && check.job.job_status == JobStatus::INCOMPLETED && check.payer && check.payer.payer.upcase == "CORR"
        non_eob_corr_images = create_non_eob_images_for_gcbs(check, image_path_for_rejected_images, non_eob_corr_images)
        create_multi_page_rejected_images_for_gcbs(check, batch_path_for_rejected_images, non_eob_corr_images)
      elsif incomplete_checks.length >= 1 && check.job.job_status == JobStatus::INCOMPLETED && check.payer && check.payer.payer.upcase != "CORR"
        non_eob_payer_images = create_non_eob_images_for_gcbs(check, image_path_for_rejected_images, non_eob_payer_images)
        create_multi_page_rejected_images_for_gcbs(check, batch_path_for_rejected_images, non_eob_payer_images)
      end
    end
  end
  
  def create_non_eob_images_for_gcbs(check, image_path_for_rejected_images, non_eob_images)
    all_rejected_jobs = Job.find(:all, :conditions => ["batch_id = ? and job_status = ?", batch_id, JobStatus::INCOMPLETED])
    job = check.job
    images = job.images_for_jobs
    if job.parent_job_id.nil? 
      images.each do |image|
        image_name = File.basename(image.public_filename_url())
        original_path =  image.public_filename_url()
        system("cd #{image_path_for_rejected_images};cp #{original_path} #{image_path_for_rejected_images}")
        non_eob_images << image_path_for_rejected_images + "/" + image.filename
      end
    else
      all_rejected_jobs.each do |single_job|
        if single_job.parent_id == job.id
          images.each do |image|
            if image.sub_job_id == single_job.id
              image_name = File.basename(image.public_filename_url())
              original_path = image.public_filename_url()
              system("cd #{image_path_for_rejected_images};cp #{original_path} #{image_path_for_rejected_images}")
              non_eob_images << image_path_for_rejected_images + "/" + image.filename
            end
          end
        end
      end
    end
    non_eob_images
  end    
  
  def create_multi_page_rejected_images_for_gcbs(check, batch_path_for_rejected_images, non_eob_images)
    payer = "-"
    batch = check.batch
    payer = check.payer.payer unless check.payer.blank?
    deposit_date = batch.bank_deposit_date.strftime("%m%d%Y")
    if non_eob_images.length >= 1
      multi_page_payer_image_name = "#{deposit_date}_#{payer.gsub(' ','_').upcase}.tif"
      system("cd #{batch_path_for_rejected_images}; tiffcp #{non_eob_images.join(' ')} #{batch_path_for_rejected_images}/#{multi_page_payer_image_name}")
    end
  end
  
  def group_checks(checks)
    check_segregator = CheckSegregator.new('by_payer', 'by_payer_type')
    checks.group_by do |check|
      check_segregator.group_name_supplemental_output(check, 'by_payer')
    end
  end


  def make_4010_output(output_string)
    output_array = output_string.split("\n")
    output_array.delete_if{|x| x =~ /^PER\*BL\*.*$/}
    isa  = output_array[0].split('*')
    gs = output_array[1].split('*')
    isa[11] = 'U'
    isa[12] = '00401'
    gs[8] = '004010X091A1~'
    if client_name == "goodman_campbell"
      isa[8] = facility.name.upcase.justify(15, ' ')
      gs[3] = gs[2].to_s.justify(14, 'X') if @nextgen
      gs[2] = 'REVMED'
    end
    output_array[0] = isa.join('*')
    output_array[1] = gs.join('*')
    output_array = output_array.collect do |segment|
      if segment =~ /^SE\*.*$/ and (facility.name.upcase!= 'ORB TEST FACILITY' || facility.name.upcase!= 'ORBOGRAPH')
        segment_array = segment.split('*')
        segment_array[1] = segment_array[1].to_i - 1
        segment_array.join('*')
      else
        segment
      end
    end
    output_835_string = output_array.join("\n")
    output_835_string =  output_array.join.scan(/.{1,80}/).join("\n") if @output_config.details[:wrap_835_lines]
    
    return output_835_string
  end

  def create_excel_sheet
    require 'spreadsheet'
    @book = Spreadsheet::Workbook.new
    sheet = @book.create_worksheet
    sheet.row(0).replace ['Batch Date', 'Batch id', 'Check Number',	'PLB Qualifier', 'PLB Account number', 'PLB Amount' ]
    sheet
  end

end

