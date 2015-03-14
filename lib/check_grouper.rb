class Hash
  #-----------------------------------------------------------------------------
  # Description : This method converts a hash into a string of hash values each is
  #               seperated by '*'.
  # Input       : hash
  # Output      : string
  #-----------------------------------------------------------------------------
  def segmentize
    self.keys.sort.collect { |k| self[k].to_s }.flatten.compact
  end
end

INDEXED_IMAGE_PATH = "#{Rails.root}/private/data"
CHOC_BATCH_PATH = "#{Rails.root}/BatchFor835Zip/childrens_hospital_of_orange_county"

class CheckGrouper
  include Output835Helper
  attr_accessor :last_check, :last_eob, :current_user
  def initialize batch_groups, ack_latest_count, current_user = nil, unified_output
    #Rails.logger "================= starting CheckGrouper initialize"
    
    @batches = batch_groups
    @first_batch = @batches.first
    @facility = @first_batch.facility
    @client = @facility.client
    @facility_name = @facility.name.upcase
    @client_name = @client.name.upcase
    @insurance_eob_output_config = @facility.output_configuration 'Insurance Eob'
    @patient_eob_output_config = @facility.output_configuration 'Patient Payment'
    @file_name_hash = file_name_hash
    @supplemental_output_type = @facility.supplemental_outputs.to_s
    @ack_latest_count = ack_latest_count
    @current_user = (current_user || User.find(:first,:conditions=>["login='admin'"]))
    @unified_output = unified_output
    #Rails.logger "================= end of CheckGrouper initialize"
  end

  def segregate_checks
    batch_ids = @batches.collect(&:id)
    puts "Batches #{batch_ids.join(',')} qualify for output generation"
    if @client_name == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
      generate_upmc_indexed_image_file(batch_ids) if @supplemental_output_type.include?("Indexed Image O/P")
      generate_upmc_exception_report(batch_ids)
    else
      if @supplemental_output_type.include?("Indexed Image O/P")
        generate_indexed_image_file(batch_ids)
        convert_tiff_to_jpeg if @insurance_eob_output_config.details[:convert_tiff_to_jpeg]
      end
    end

    if @insurance_eob_output_config
      Batch.where("id in (?)", batch_ids).update_all(:status => BatchStatus::OUTPUT_GENERATING)
      @ins_pay_grouping = @insurance_eob_output_config.grouping
      @pat_pay_grouping = @patient_eob_output_config.grouping if @patient_eob_output_config
      cut_groupings = ["SITE SPECIFIC","SINGLE DAILY MERGED CUT","SEQUENCE CUT"]

      if cut_groupings.include?(@ins_pay_grouping.upcase)
        #TODO: need to refactor
        if @ins_pay_grouping.upcase == "SINGLE DAILY MERGED CUT"
          batches = Batch.find(:all,:conditions => {:date => @first_batch.date, :facility_id => @first_batch.facility_id, :status => BatchStatus::OUTPUT_READY})
          batch_ids = batches.collect(&:id).join(",")
        end
        if @ins_pay_grouping.upcase == "SEQUENCE CUT"
          batches = Batch.find(:all,:conditions => {:date => @first_batch.date, :cut => @first_batch.cut, :facility_id => @first_batch.facility_id, :status => BatchStatus::OUTPUT_READY})
          batch_ids = batches.collect(&:id).join(",")
        end
        @eob_segregator = EobSegregator.new(@ins_pay_grouping, @pat_pay_grouping)
        eobs = InsurancePaymentEob.by_eob(batch_ids)
        check_eob_groups = @eob_segregator.segregate(batch_ids,eobs)
        puts "Grouping successful, returned #{check_eob_groups.length} distinct group/s"
        Output835.log.info "Grouping successful, returned #{check_eob_groups.length} distinct group/s"
        check =  eobs.first.check_information
        batch = check.batch
        check_payer = check.payer
        @batch_date = batch.date.strftime("%d%m%Y")
        @batch_id = batch.batchid
        if check_payer
          @payer = check_payer.payer
          @output_config = (check_payer.payer_type == 'PatPay' &&
              !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
              !@insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file) ?
            @patient_eob_output_config : @insurance_eob_output_config
        end
        check_eob_groups.each do |key, value|
          check_eob_hash = value
          checks = CheckInformation.find(:all,:conditions=>["id in (?)",check_eob_hash.keys])
          @client_id = @facility.sitecode
          @lockbox_number = @facility.lockbox_number
          puts "Generating 835 Output.."
          Output835.log.info "Generating 835 Output.."
          @key = key
          generate_output(@key,checks,check_eob_hash)
        end
      else        
        check_groups = ((@client_name == "GOODMAN CAMPBELL") ? group_checks_gcbs : group_checks)
        puts "Grouping successful, returned #{check_groups.length} distinct group/s"
        Output835.log.info "Grouping successful, returned #{check_groups.length} distinct group/s"
        if condition_to_generate_all_types_of_checks_in_multiple_outputs
          generate_all_types_of_checks_in_multiple_outputs(check_groups)
        else
          check_groups.each do |group, checks|
            @nextgen =  group.include?("goodman_nextgen")
            @first_check = checks.first

            array_length = 10
            first_index = 0
            @file_index = 0
            @payer = @first_check.payer
            @batch = @first_check.batch
            if @payer
              @payer_name = @payer.payer
            end
            @output_config = (@first_check.job.payer_group == 'PatPay' &&
                !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
                !@insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file) ?
              @patient_eob_output_config : @insurance_eob_output_config
          
            puts "Generating Output.."
            if @client_name == "GOODMAN CAMPBELL" && !group.include?("notapplicable")
              check_length = checks.length
              remaining_checks = check_length % array_length
              total_number_of_files = (remaining_checks==0)? (check_length / array_length):((check_length / array_length)+1)
              file_number=0
              while(file_number < total_number_of_files)
                checks_new = checks[first_index,array_length]
                unless checks_new.blank?
                  file_number += 1
                  first_index = array_length*file_number
                  generate_output(checks_new, group)
                  @file_index += 1
                end
              end
            else
              generate_output(checks, group)
            end

          end
        end
      end
    else
      raise "Cannot generate output without Output Configuration. Please configure output and try again."
    end
  end
  
  def condition_to_generate_all_types_of_checks_in_multiple_outputs
    @insurance_eob_output_config.format.to_s.downcase == "835_and_xml" &&
      @insurance_eob_output_config.payment_corres_patpay_in_one_file &&
      @insurance_eob_output_config.grouping.to_s.downcase == "by batch"
  end

  def generate_all_types_of_checks_in_multiple_outputs(check_groups)
    insurance_checks, nextgen_checks, correspondence_checks = segreggate_into_insurance_and_patpay_and_correspondence(check_groups)
    @output_config = @insurance_eob_output_config
    check_array_of_arrays = check_groups.values
    @first_check = check_array_of_arrays.first.first if check_array_of_arrays && check_array_of_arrays.first
    @batch = @first_check.batch if @first_check
    generate_output([insurance_checks, nextgen_checks, correspondence_checks], nil)
    checks = combine_checks(correspondence_checks)
    insurance_checks, nextgen_checks, correspondence_checks = separate_checks_into_insurance_and_patpay_and_correspondence(checks)
    create_xml_file(insurance_checks, true, "ORBO_INS", "_INS_version2.11") if insurance_checks && insurance_checks.length > 0
    create_xml_file(correspondence_checks, true, "ORBO_CORR", "_CORR_version2.11") if correspondence_checks.length > 0
  end

  def segreggate_into_insurance_and_patpay_and_correspondence(check_groups)
    insurance_checks, nextgen_checks, correspondence_checks = [], [], []
    check_groups.each do |group_name, grouped_checks|
      if group_name.to_s.include?("payment")
        grouped_checks.each do |check|
          if check.job.is_correspondence
            correspondence_checks << check
          else
            insurance_checks << check
          end
        end
      elsif group_name.to_s.include?("notapplicable")
        nextgen_checks << grouped_checks
      end
    end
    return insurance_checks.flatten, nextgen_checks.flatten, correspondence_checks.flatten
  end

  def separate_checks_into_insurance_and_patpay_and_correspondence(checks)
    insurance_checks, nextgen_checks, correspondence_checks = [], [], []
    checks = checks.flatten
    checks.each do |check|
      job = check.job
      if job.is_correspondence
        correspondence_checks << check
      elsif job.payer_group == "Insurance"
        insurance_checks << check
      else
        nextgen_checks << check
      end
    end
    return insurance_checks, nextgen_checks, correspondence_checks
  end

  def orbo_checks_all
    completed_jobs = @batches.first.completed_jobs_without_exclusion
    if condition_to_generate_all_types_of_checks_in_multiple_outputs &&
        completed_jobs && completed_jobs.length == 0
      @output_needed = "xml_only"
    end
  end

  def create_multipage_image_for_medassets(checks)
    batch_path = "#{Rails.root}/private/data/#{@facility.name.downcase.gsub(' ','_')}/835s/#{Date.today.to_s}"
    unidentified_acc_no_of_facility = @facility.unidentified_account_number
    checks.each do |check|
      medasset_eobs = []
      medasset_eobs = check.insurance_payment_eobs
      merge_and_split_images_for_medassets(check, nil, batch_path, nil, unidentified_acc_no_of_facility, medasset_eobs, "check_level" )
      if !unidentified_acc_no_of_facility.blank?
        medasset_eobs = medasset_eobs.select {|medasset_eob| !unidentified_acc_no_of_facility.include?(medasset_eob.patient_account_number)}
      end
      account_nos = medasset_eobs.collect(&:patient_account_number)
      acc_num_str = []
      create_eob_wise_multipage_image_for_medassets(batch_path, unidentified_acc_no_of_facility, check, medasset_eobs, acc_num_str, account_nos)
    end
  end

  def create_eob_wise_multipage_image_for_medassets(batch_path, unidentified_acc_no_of_facility, check, medasset_eobs, acc_num_str, account_nos)
    medasset_eobs.each do |eob|
      actual_acc_num = get_exact_account_number(eob, acc_num_str, account_nos)
      merge_and_split_images_for_medassets(check, eob, batch_path, actual_acc_num, unidentified_acc_no_of_facility, medasset_eobs, "eob_level")
    end
  end

  def group_checks
    @output_needed = "yes"
    checks = @batches.collect(&:completed_checks_without_exclusion).flatten
    create_multipage_image_for_medassets(checks) if @client.name.upcase == "MEDASSETS" or @client.name.upcase == "BARNABAS"
    @incompleted_checks = @batches.collect(&:incompleted_checks_without_exclusion).flatten
    @whole_checks = checks + @incompleted_checks
    orbo_checks_all

    xml_output_config_format = @insurance_eob_output_config.format.to_s.upcase == 'XML'
    checks.group_by do |check|
      @batch = check.batch
      @current_payer = check.payer
      @payer_type = payer_type check

      if !xml_output_config_format
        if @insurance_eob_output_config.payment_corres_patpay_in_one_file ||
            @insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
          patient_pay_group_name(check, @ins_pay_grouping)
        else
          case @payer_type
          when 'insurancepay'
            group_name(check, @ins_pay_grouping)
          when 'patpay'
            if @pat_pay_grouping
              if @client.name.upcase == "BARNABAS"
                group_name(check, @pat_pay_grouping)
              else
                patient_pay_group_name(check, @pat_pay_grouping)
              end
            else
              raise "Patient Pay output configuration must be present to generate Patient Pay output."
            end
          when 'notapplicable'
            if @pat_pay_grouping
              group_name(check, @pat_pay_grouping)
            else
              raise "Patient Pay output configuration must be present to generate Patient Pay output."
            end
          end
        end
      else
        case @payer_type
        when 'insurancepay'
          group_name(check, @ins_pay_grouping )
        when 'patpay'
          if @pat_pay_grouping
            group_name(check, @pat_pay_grouping)
          else
            raise "Patient Pay output configuration must be present to generate Patient Pay output."
          end
        end
      end
    end
  end

  def payer_type(check)
    if nextgen_check?(check)
      'notapplicable'
    elsif @current_payer && check.job.payer_group == 'PatPay'
      'patpay'
    else
      'insurancepay'
    end
  end

  def group_checks_gcbs
    checks = @batches.collect(&:completed_checks_without_exclusion).flatten
    check_group = group_gcbs_checks(checks)
    output_group = []
    check_group.each_with_index do |checks, index|
      @nextgen = (index == 0)
      output_group << checks.group_by do |check|
        @batch = check.batch
        @current_payer = check.payer
        @payer_type = payer_type check
        case @payer_type
        when 'insurancepay'
          group_name(check, @ins_pay_grouping)
        when 'patpay', 'notapplicable'
          if @pat_pay_grouping
            group_name(check, @pat_pay_grouping)
          else
            raise "Patient Pay output configuration must be present to generate Patient Pay output."
          end
        end
      end
    end
    output_group[0].merge(output_group[1])
  end

  def group_name(check, grouping)
    case grouping.to_file
    when 'by_batch_date'
      "date_#{@first_batch.date}_#{correspondence_facet(check)}"
    when 'by_lockbox_cut'
      "lockbox_cut_#{@batch.lockbox}_#{@batch.cut}_#{correspondence_facet(check)}"
    when 'by_payer_by_batch'
      if @current_payer
        "payer_#{@batch.id}_#{@current_payer.payer}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end
    when 'by_payer_id_by_batch'
      if @current_payer
        "payerid_#{@current_payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end
    when 'by_cut_and_payerid'
      if @current_payer
        "by_cut_and_payerid_#{@current_payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end
    when 'by_check'
      "check_#{check.id}_#{check.check_number}_#{correspondence_facet(check)}"
    when 'by_cut'
      "cut_#{@batch.cut }_#{correspondence_facet(check)}"
    when 'by_payer_by_batch_date'
      "date_#{@batch.date}_payer_#{@current_payer.payer}#{correspondence_facet(check)}_#{check.payment_type}"
    when 'by_payer_id_by_batch_date'
      payid = @current_payer ? @current_payer.supply_payid : nil
      "date_#{@batch.date}_payer_#{payid}_#{correspondence_facet(check)}_#{check.payment_type}"
    when 'by_output_payer_id_by_batch_date'
      output_payid = @current_payer.output_payid(@facility)
      if @client.name.upcase == "BARNABAS" && @current_payer.payer_type == "PatPay"
        "date_#{@batch.date}_payer_#{output_payid}#{correspondence_facet(check)}_"
      else
        "date_#{@batch.date}_payer_#{output_payid}#{correspondence_facet(check)}_#{check.payment_type}"
      end
    when 'by_cut_and_extension'
      "cut_ext_#{@batch.cut}_#{@batch.correspondence}"
    when 'by_batch'
      "batch_#{@batch.id }_#{@batch.batchid}_#{correspondence_facet(check)}_#{check.payment_type}"
    when "nextgen_grouping"
      "payerid_#{gcbs_payid(check)}_#{correspondence_facet(check)}_#{check.payment_type}"
    when "by_lockbox_and_date"
      "date_#{@batch.date}_lockbox_#{@batch.facility_id}_#{correspondence_facet(check)}"
    else
      raise "Feature for grouping #{grouping} has not been done. Please contact Revremit support"
    end
  end

  def gcbs_payid check
    if @payer_type == "notapplicable"
      "notapplicable"
    elsif @current_payer
      (@nextgen ? "goodman_nextgen_#{@current_payer.gcbs_output_payid(@facility)}" : @current_payer.output_payid(@facility))
    else
      nil
    end
  end

  def nextgen_check?(check)
    # EOBs processed in nextgen grid will have no payer
    # they will be stored in patient_pay_eobs table
    # nextgen grid is rendered only when specified so, thru FC UI
    (check.patient_pay_eobs.present? &&
        @facility.patient_pay_format == 'Nextgen Format')
  end


  # Returns the check type as string, if
  # Combine correspondence and payment is unchecked in FC UI
  # else returns nil.
  # Returns 'notapplicable' for nextgen checks, since those are not configured in FCUI
  def correspondence_facet(check)
    if @payer_type != "notapplicable"
      if @insurance_eob_output_config.payment_corres_patpay_in_one_file ||
          @insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file ||
          @insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
        output_config = @insurance_eob_output_config
      else
        type = 'PatPay' if @payer_type == 'patpay'
        output_config = @facility.output_config(type)
      end
      if output_config.payment_corres_patpay_in_one_file
        'payment'
      elsif output_config.payment_corres_in_one_patpay_in_separate_file
        "#{@payer_type}"
      elsif output_config.payment_patpay_in_one_corres_in_separate_file
        (check.correspondence?  and @payer_type != 'patpay')? 'correspondence' : 'payment'
      elsif !output_config.payment_corres_patpay_in_one_file &&
          !output_config.payment_corres_in_one_patpay_in_separate_file &&
          !output_config.payment_patpay_in_one_corres_in_separate_file
        if @payer_type == 'patpay'
          if @client.name.upcase == "BARNABAS"
            'payment'
          else
            "#{@payer_type}"
          end
        elsif @payer_type == 'insurancepay'
          check.correspondence? ? 'correspondence' : 'payment'
        end
      end
    else
      'notapplicable'
    end
  end

  def generate_output checks, group, check_eob_hash = nil
    format = @insurance_eob_output_config.format.to_s.downcase
    format = "delimited" if group.to_s.split('_').include?('notapplicable')
    chks = checks.flatten if checks
    @config_835_type = get_835_type_for_group(group, chks)
    case format
    when 'pc_print'
      create_pc_print_file(checks)
    when "835"
      create_835_file(checks, check_eob_hash,false)
    when "xml"
      create_xml_file(checks)
    when "csv"
      create_csv_file(checks)
    when "txt", "text"
      create_txt_file(checks)
    when 'delimited'
      create_nextgen_file(checks)
    when "835_and_xml"
      create_xml_and_associated_files(checks, check_eob_hash = nil)
    end
  end

  def create_xml_and_associated_files(checks, check_eob_hash = nil)
    insurance_checks, nextgen_checks, correspondence_checks = checks[0], checks[1], checks[2]
    nextgen_and_correspondence_checks = []
    nextgen_and_correspondence_checks << nextgen_checks if nextgen_checks && nextgen_checks.length > 0
    nextgen_and_correspondence_checks << correspondence_checks if correspondence_checks && correspondence_checks.length > 0
    if @output_needed != "xml_only"
      create_nextgen_file(nextgen_checks) if nextgen_checks && nextgen_checks.length > 0
      create_835_file(insurance_checks, check_eob_hash, true) if insurance_checks && insurance_checks.length > 0
    end
    create_xml_with_associated_checks(nextgen_and_correspondence_checks)
  end

  def create_xml_with_associated_checks(nextgen_and_correspondence_checks)
    checks = combine_checks(nextgen_and_correspondence_checks)
    create_xml_file(checks.flatten, true) if checks
  end

  def combine_checks(checks_to_add)
    checks = []
    checks << @xml_checks if @xml_checks && @xml_checks.length > 0
    checks << checks_to_add if checks_to_add && checks_to_add.length > 0
    if @incompleted_checks && @incompleted_checks.length > 0
      checks << @incompleted_checks
      if @first_check.blank?
        @first_check = @incompleted_checks.first
        @batch = @first_check.batch if @first_check && @batch.blank?
      end
    end
    checks
  end


  def create_835_file checks, check_eob_hash,xml_output
    batch_type = (@batch.correspondence) ? "COR" : "PAY"
    batch_id = @batch.real_batch_id
    @xml_output = xml_output
    if @client.name == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' || @client.name == 'CHILDRENS HOSPITAL OF ORANGE COUNTY'
      #Update the transaction count to make it unique accorss 835 files
      #The number will be unique even if multiple users tries to generate output at same time
      @client.custom_fields[:transaction_count] += checks.size if @client.custom_fields[:transaction_count]
      @client.save!
      @total_jobs = Job.where(:batch_id => @batches.map(&:id))
    end
    
    if @output_config.details[:output_folder]
      folder_name =  build_folder_name(@first_check, batch_id, @batch.date, batch_type)
    end

    @output_dir_835 = "private/data/#{@facility.name.to_file}/835s/#{Date.today.to_s}"

    if check_eob_hash.present?
      groupings = ["SITE SPECIFIC","SINGLE DAILY MERGED CUT","SEQUENCE CUT"]
      file_name = (groupings.include?(@ins_pay_grouping.upcase) ? "#{@key}" : "#{@key}.835")
    else
      file_name = build_file_name(@first_check, @batch, batch_type)
    end

    multi_st =  @output_config.multi_transaction
    class_type = multi_st ? 'multi' : 'single'
    
    if @unified_output
      output_generator_class = Unified835Output.find_class(@facility, class_type,@output_config)
    else
      output_generator_class = Output835.find_class(@facility, class_type,@output_config)
    end

    if @facility_name == "HORIZON LABORATORY LLC" || @facility_name == "STANFORD UNIVERSITY MEDICAL CENTER"
      if @first_check.insurance_payment_eobs.present?
        correspondence_835 = !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
          !@insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file &&
          @first_check.correspondence? && @first_check.job.payer_group != 'PatPay'
        output_generator_class = "Output835::CorrespondenceTemplate".constantize if correspondence_835
      end
    end

    zip_file_name = build_zip_file_name(@first_check, batch_id, @batch.date, batch_type) if @output_config.details[:zip_output]



    Output835.log.info "Applying class #{output_generator_class}"
    
    if @unified_output
      generator =  output_generator_class.new(checks, @facility, @insurance_eob_output_config, get_config_835_values,@total_jobs)
    else
      generator =  output_generator_class.new(checks, @facility, @insurance_eob_output_config, self, {}, nil, @total_jobs)
    end

    version = @insurance_eob_output_config.details[:output_version]
    dir_name = version ? ( version == '4010') ? '4010' : '5010' : ''
    @output_dir_835 += "/#{dir_name}"

    if @client_name == "GOODMAN CAMPBELL"
      nextgen_folder = @nextgen ? 'nextgen' : ''
      @output_dir_835 += "/#{nextgen_folder}"
      generator.instance_variable_set("@nextgen", @nextgen)
    end

    @output_dir_835 += "/#{folder_name}"
    FileUtils.mkdir_p(@output_dir_835)

    activity_logs = record_835_activity_start(checks, file_name, @output_dir_835, zip_file_name)

    plb_excel_sheet = create_excel_sheet if @client_name == 'AHN' || @client_name == 'ORBOGRAPH' || @client_name == 'ORB TEST FACILITY'
    
    generator.instance_variable_set("@plb_excel_sheet", plb_excel_sheet)
    generator.instance_variable_set("@whole_checks", @whole_checks)
    output_string = generator.generate
    file_name = file_name+".835" if @xml_output
    File.open("#{@output_dir_835}/#{file_name}", 'w+') do |file|
      file.write(output_string.force_encoding("UTF-8"))
    end

    if @client_name.gsub("'", "") == "CHILDRENS HOSPITAL OF ORANGE COUNTY"
      batch_file_directory_name = @batch.file_name.chomp(".zip").chomp(".ZIP")
      choc_batch_loc = "#{CHOC_BATCH_PATH}/#{batch_file_directory_name}"
      Dir.glob("#{choc_batch_loc}/*.*").each do |file|
        FileUtils.cp_r("#{file}","#{@output_dir_835}")
      end
    end
 
    if (@client_name == "ORB TEST FACILITY" || @client_name == "ORBOGRAPH")
      @book.write "private/data/#{@facility.name.to_file}/835s/#{Date.today.to_s}/#{@batch.batchid}_prov_adj_summary.xls" if @book
    else
      @book.write "private/data/#{@facility.name.to_file}/835s/#{Date.today.to_s}/#{@batch.date.strftime("%m%d%y")}_prov_adj_summary.xls" if @book
    end
    if version == 'both'
      directory = @output_dir_835.gsub('/5010', '/4010')
      FileUtils.mkdir_p(directory)
      File.open("#{directory}/#{file_name}", 'w+') do |file|
        file << make_4010_output(output_string)
      end
    end

    output_835_end_time = Time.now
    OutputActivityLog.mark_generated_with_checksum(activity_logs, output_835_end_time,@ack_latest_count)

    if @output_config.details[:zip_output]
      puts "zipping output files"
      create_zip_file_from_output(@output_dir_835,zip_file_name,file_name)
      create_zip_file_from_output(directory,zip_file_name,file_name) if version == 'both'
      OutputActivityLog.create_entry_for_zipped_835(activity_logs, zip_file_name,@ack_latest_count)
    end

    @xml_checks = checks.collect{|c| c.reload} if @xml_output
    
    puts "Output 835 generated sucessfully, file is written to:"
    puts "#{@output_dir_835}"

  end


  def create_xml_file(checks,xml_output_with_835=nil, check_type = nil, append_to_file_name = nil)
    begin
      batch_id = @batch.real_batch_id
      batch_type = (@batch.correspondence) ? "COR" : "PAY"
      file_name = build_file_name(@first_check, @batch, batch_type)
      if append_to_file_name.present?
        file_name = file_name + append_to_file_name
      end
      puts "Output XML file name - " + file_name.to_s
      output_dir_xml = "private/data/#{@facility.name.to_file}/xml/#{Date.today.to_s}"
      folder_name = xml_folder_name(batch_id, @batch.date, batch_type)
      output_dir_xml += "/#{folder_name.to_s}"
      puts "Output XML file creation directory - " + output_dir_xml.to_s
      if file_name
        FileUtils.mkdir_p(output_dir_xml)
        puts "Directory creation successful"
      end
      file_name = file_name+".xml" if xml_output_with_835
      write_to_xml(checks, file_name, output_dir_xml, check_type)
    rescue Exception => e
      OutputXML.log.error "Exception  => " + e.message
      OutputXML.log.error e.backtrace.join("\n")
    end
  end

  def xml_folder_name(batch_id, date, batch_type)
    folder_name = ''
    if @insurance_eob_output_config.details[:output_folder]
      if (@client_name == "ORB TEST FACILITY" || @client_name == "ORBOGRAPH")
        folder_name = "ORBXML"
      else
        folder_name =  build_folder_name(@first_check, batch_id, date, batch_type)
      end
    end
    folder_name
  end

  def write_to_xml(checks, file_name, output_dir_xml, check_type = nil)
    output_xml_start_time = Time.now
    config = {:check_type => check_type}
    File.open("#{output_dir_xml}/#{file_name}", 'w+') do |file|
      if checks && checks.length > 0
        file << OutputXml::Document.new(checks, config).generate.gsub!(/\s+$/, '')
        output_xml_end_time = Time.now
        record_activity(checks, 'Output Generated', 'XML', file_name, output_dir_xml, output_xml_start_time, output_xml_end_time)
        puts "Output generated sucessfully, file is written to:"
        puts "#{output_dir_xml}/#{file_name}"
      end
    end
  end


  def build_file_name check, batch, batch_type
    batch_date = batch.date
    batchid = batch.real_batch_id

    if condition_to_generate_all_types_of_checks_in_multiple_outputs
      filename = @insurance_eob_output_config.file_name.to_s
      name_format = @insurance_eob_output_config.format.to_s
    else
      if !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
          !@insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file
        correspondence_835 = @first_check.correspondence? && @first_check.job.payer_group != 'PatPay'
      end
      if @facility_name == "GOODMAN CAMPBELL BRAIN AND SPINE"
        batchid = batch.real_batch_id
        payer_name = get_gcbs_payername(check)
        @file_name_hash['[Payer Name]'] = 'payer_name'
        payer_id_grouping = ((@insurance_eob_output_config.grouping == 'By Payer Id By Batch' || @insurance_eob_output_config.grouping == 'By Payer Id By Batch Date')  &&
            @payer.supply_payid == @facility.commercial_payerid )
      elsif @facility_name == "HORIZON LABORATORY LLC" || @facility_name == "STANFORD UNIVERSITY MEDICAL CENTER"
        batchid = batch.real_batch_id
      else
        facilities_list =['SOUTH COAST','HORIZON EYE','SAVANNAH PRIMARY CARE','ORTHOPAEDIC FOOT AND ANKLE CTR','SAVANNAH SURGICAL ONCOLOGY','CHATHAM HOSPITALISTS','GEORGIA EAR ASSOCIATES','DAYTON PHYSICIANS LLC UROLOGY']
        if facilities_list.include?(@facility_name)
          batchid = batch.batchid.split('_').fetch(-2)
        else
          batchid = batch.real_batch_id
        end
        payerid = @payer.supply_payid rescue ""
      end

      payid = payer_id(check)
      check_payer = check.payer
      output_payid = check_payer ? check_payer.output_payid(@facility) : nil
      check_micr = check.micr_line_information
      aba_routing_number = (check_micr.blank?)? "" : (check_micr.aba_routing_number)
      payer_account_number = (check_micr.blank?)? "" : (check_micr.payer_account_number)


      if check.job.payer_group == 'PatPay' &&
          !@insurance_eob_output_config.payment_corres_patpay_in_one_file &&
          !@insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
        filename = @patient_eob_output_config.file_name.to_s
        name_format = @patient_eob_output_config.format.to_s
      else
        filename = @insurance_eob_output_config.file_name.to_s
        name_format = @insurance_eob_output_config.format.to_s
      end
      if payer_id_grouping
        filename = file_name_for_payer_id_grouping
      end
      if correspondence_835 && @insurance_eob_output_config.file_name_corr.present?
        filename = @insurance_eob_output_config.file_name_corr.strip
      end
    end
    output_file_name = filename.gsub(/\[[^\[\]]+\]/){|match| eval(@file_name_hash[match].to_s).to_s}

    if @client_name == "GOODMAN CAMPBELL"
      gcbs_835_file_name = output_file_name
      if gcbs_835_file_name.include?(".835")
        gcbs_835_file_name.gsub!(".835","")
      end
      @gcbs_file =  gcbs_835_file_name if @file_index==0
      output_file_name = (@file_index>0)? "#{@gcbs_file}_#{@file_index}.835":"#{@gcbs_file}.835"
    else
      output_file_name
    end

  end

  def get_gcbs_payername(check)
    if @payer
      payid = @payer.output_payid(@facility)
      if payid == "REVMED"
        payer_name = "MISCPAYER"
      else
        payer_name = @payer_name.gsub(' ','').slice(0,15).upcase rescue ""
      end
    end
    payer_name
  end


  def build_folder_name check, batchid, batch_date, batch_type
    folder_format = @output_config.folder_name.to_s
    if folder_format.include?("[EXT]")
      if @insurance_eob_output_config.payment_corres_patpay_in_one_file
        folder_ext =  "ALL"
      elsif @insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file
        folder_ext = (@payer.payer_type == 'PatPay') ? "PATPAY" : "INS"
      elsif @insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
        folder_ext = (@first_check.correspondence? and @payer.payer_type != 'PatPay')? "COR" : "INS"
      else
        folder_ext = (@first_check.correspondence? and @payer.payer_type != 'PatPay') ? "COR" :  (@payer.payer_type == 'PatPay') ? "PATPAY" : "INS"
      end
      folder_format.gsub!("[EXT]",folder_ext)
    end
    folder_format.gsub(/\[[^\[\]]+\]/){|match| eval(@file_name_hash[match].to_s).to_s}
  end

  def build_zip_file_name check, batchid, batch_date, batch_type
    zip_filename = @output_config.zip_file_name.to_s

    zip_ext = ".ZIP"
    if zip_filename.include?("[EXT]") && !@separate_payment_and_correspondence
      zip_filename = zip_filename.gsub("[EXT]","")
      zip_ext =  find_zip_extension
    end
    zip_filename = zip_filename.gsub(/\[[^\[\]]+\]/){|match| eval(@file_name_hash[match].to_s).to_s}

    (@separate_payment_and_correspondence ? "#{zip_filename}" :  "#{zip_filename}#{zip_ext}")
  end

  def find_zip_extension
    check_types = @checks.collect(&:correspondence?).uniq
    if check_types.length == 2
      ".ZIP"
    elsif check_types[0]
      "COR"
    else
      "PAY"
    end
  end

  def make_4010_output(output_string)
    output_array = @insurance_eob_output_config.details[:content_835_no_wrap] ? output_string.split('~') : output_string.split("\n")
    output_array.delete_if{|x| x =~ /^PER\*BL\*.*$/}
    isa  = output_array[0].split('*')
    gs = output_array[1].split('*')
    isa[11] = 'U'
    isa[12] = '00401'
    gs[8] = @insurance_eob_output_config.details[:content_835_no_wrap] ? '004010X091A1' : '004010X091A1~'
    if @client_name == "GOODMAN CAMPBELL"
      isa[8] = @facility.name.upcase.justify(15, ' ')
      gs[3] = gs[2].to_s.justify(14, 'X') if @nextgen
      gs[2] = 'REVMED'
    end
    output_array[0] = isa.join('*')
    output_array[1] = gs.join('*')
    output_array = output_array.collect do |segment|
      if segment =~ /^SE\*.*$/
        segment_array = segment.split('*')
        segment_array[1] = segment_array[1].to_i - 1 unless (@client_name == 'ORBOGRAPH' || @client_name == 'ORB TEST FACILITY')
        segment_array.join('*')
      else
        segment
      end
    end
    output_835_string = @insurance_eob_output_config.details[:content_835_no_wrap] ? output_array.join('~') : output_array.join("\n")
    output_835_string =  output_array.join.scan(/.{1,80}/).join("\n") if @output_config.details[:wrap_835_lines]
    return output_835_string
  end

  def file_name_hash
    filename_hash = { "[Client Id]" => "@facility.sitecode",
      "[Batch date(MMDDYY)]" => "batch_date.strftime('%m%d%y')",
      "[Batch date(CCYYMMDD)]" => "batch_date.strftime('%Y%m%d')",
      "[Batch date(MMDDCCYY)]" => "batch_date.strftime('%m%d%Y')",
      "[Batch date(DDMMYY)]" => "batch_date.strftime('%d%m%y')",
      "[Batch date(YYMMDD)]" => "batch_date.strftime('%y%m%d')",
      "[Batch date(YMMDD)]" => "batch_date.strftime('%y%m%d')[1..-1]",
      "[Batch date(MMDD)]" => "batch_date.strftime('%m%d')",
      "[Facility Abbr]" => "@facility.abbr_name",
      "[3-SITE]" => "@facility.sitecode.slice(2,3)",
      "[Batch Id]" => "batchid",
      "[Facility Name]" => "@facility.name",
      "[Check Num]" => "check.check_number",
      "[Payer Name]" => "@payer_name",
      "[Payer Group]" => "payer_group(check.payer ? check.payer.output_payid(@facility) : nil )",
      "[EXT]" => "batch_type",
      "[Lockbox Num]" => "@facility.lockbox_number",
      "[Check Amount]" => "check.check_amount.to_s",
      "[Cut]" => "batch.cut",
      "[ABA Routing Num]" => "aba_routing_number",
      "[Image File Name]" => "image_name(check.image_file_name)",
      "[Payer Account Num]"=> "payer_account_number",
      "[Payer ID]" => "payid",
      "[Output Payid]" => "output_payid",
      "[Lockbox ID]" => "@batch.lockbox"
    }
  end

  def create_zip_file_from_output(output_dir,zip_name,file_name)
    begin
      system("rm -rf #{output_dir}/#{zip_name}")
      if @client_name.gsub("'", "") == "CHILDRENS HOSPITAL OF ORANGE COUNTY"
        Zip::ZipFile.open("#{output_dir}/#{zip_name}", Zip::ZipFile::CREATE) do |file|
          Dir.glob("#{output_dir}/*.*").each do |output_file|
            file_name = File.basename(output_file)
            if File.extname(output_file).downcase != ".zip"
              file.add(file_name, "#{output_dir}/#{file_name}")
            end
          end
        end
      else
        Zip::ZipFile.open("#{output_dir}/#{zip_name}", Zip::ZipFile::CREATE) do |file|
          file.add(file_name, "#{output_dir}/#{file_name}")
        end
      end
    rescue Exception => e
      Output835.log.error "Exception  => " + e.message
      Output835.log.error e.backtrace.join("\n")
    ensure
      if @client_name.gsub("'", "") == "CHILDRENS HOSPITAL OF ORANGE COUNTY"
        Dir.glob("#{output_dir}/*.*").each do |output_file|
          file_name = File.basename(output_file)
          if File.extname(output_file).downcase != ".zip"
            FileUtils.rm "#{output_dir}/#{file_name}",  :force => true if File.exists?("#{output_dir}/#{zip_name}")
          end
        end
      else
        FileUtils.rm "#{output_dir}/#{file_name}",  :force => true if File.exists?("#{output_dir}/#{zip_name}")
      end
    end
  end

  def record_835_activity_start checks, file_name, file_location, zip_file_name=nil
    batchids = CheckInformation.checks_batch_ids(checks)
    payers_to_exclude = @facility.excluded_payers.collect(&:id)
    eob_ids = []
    pob_ids = []
    activity_logs = []
    total_output_charge = 0
    total_excluded_amount = 0
    total_payment_charge = 0
    activity_logs = []
    checks.each do |check|
      total_output_charge += check.check_amount
      check_payer_id = check.get_payer.id unless check.get_payer.blank?
      if payers_to_exclude.include?(check_payer_id)
        total_excluded_amount += check.check_amount
      end

      unless check.insurance_payment_eobs.blank?
        begin
          sum_of_total_amount_paid_for_claim = check.insurance_payment_eobs.map(&:total_amount_paid_for_claim).map(&:to_f).inject(:+)
          sum_of_claim_interests = check.insurance_payment_eobs.map(&:claim_interest).map(&:to_f).inject(:+)
          total_payment_charge += sum_of_total_amount_paid_for_claim + sum_of_claim_interests
          eob_ids = check.insurance_payment_eobs.collect(&:id)
          pob_ids = check.patient_pay_eobs.collect(&:id)
        rescue
          Output835.log.info "Inside output activity log writing function"
          Output835.log.info "Check number =#{check.check_number}"
        end
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
          :user_id => current_user.id , :status => OutputActivityStatus::GENERATING, :ack_latest_count => @ack_latest_count})

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

  # Returns the computed group name for a patpay check
  # by applying the grouping passed to it
  # group name also depends on certain other parameters
  # configured for a facility
  def patient_pay_group_name(check, grouping)
    case grouping.downcase.gsub(' ','_')
    when 'by_batch_date'
      "date_#{@batch.date}_#{correspondence_facet(check)}"
    when 'by_lockbox_cut'
      "lockbox_cut_#{@batch.lockbox}_#{@batch.cut}_#{correspondence_facet(check)}"
    when 'by_payer_by_batch'
      if @current_payer
        "payer_#{@batch.id}_#{@current_payer.payer}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end
    when 'by_payer_id_by_batch'
      if @current_payer
        "payerid_#{@current_payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end

    when 'by_cut_and_payerid'
      if @current_payer
        "by_cut_and_payerid_#{@current_payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end

    when 'by_check'
      "check_#{check.id}_#{check.check_number}_#{correspondence_facet(check)}"
    when 'by_batch'
      "batch_#{@batch.id }_#{@batch.batchid}_#{correspondence_facet(check)}"
    when 'by_cut'
      "cut_#{@batch.cut }_#{correspondence_facet(check)}"
    when 'by_payer_by_batch_date'
      "date_#{@batch.date}_payer_#{@current_payer.payer}#{correspondence_facet(check)}"
    when 'by_payer_id_by_batch_date'
      payid = @current_payer ? @current_payer.supply_payid : nil
      "date_#{@batch.date}_payer_#{payid}_#{correspondence_facet(check)}"
    when 'by_output_payer_id_by_batch_date'
      output_payid = @current_payer.output_payid(@facility)
      "date_#{@batch.date}_payer_#{output_payid}#{correspondence_facet(check)}"
    when 'by_cut_and_extension'
      "cut_ext_#{@batch.cut}_#{@batch.correspondence}"
    when "nextgen_grouping"
      "payerid_#{gcbs_payid(check)}_#{correspondence_facet(check)}"
    when "by_lockbox_and_date"
      "date_#{@batch.date}_lockbox_#{@batch.facility_id}_#{correspondence_facet(check)}"
    end

  end

  def group_gcbs_checks(checks)
    nextgen_checks = checks.select do |check|
      unless check.payer_type == 'patient_pay'
        eobs = check.insurance_payment_eobs
        eobs.any?{|eob| !eob.old_eob_of_goodman?}
      end
    end

    old_checks = checks.select do |check|
      eobs = check.insurance_payment_eobs
      eobs.any?{|eob| eob.old_eob_of_goodman?} || nextgen_check?(check) || check.payer_type == 'patient_pay'
    end
    [nextgen_checks, old_checks]
  end

  def create_excel_sheet
    require 'spreadsheet'
    @book = Spreadsheet::Workbook.new
    sheet = @book.create_worksheet
    sheet.row(0).replace ['Batch Date', 'Batch id', 'Check Number',	'PLB Qualifier', 'PLB Account number', 'PLB Amount' ]
    sheet
  end

  def payer_id(check)
    if check.micr_line_information && check.micr_line_information.payer && @facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end

    unless @payer.blank?
      if @client_name == "GOODMAN CAMPBELL"
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

  #TODO Need to refactor(OLD RAKE)
  def create_nextgen_file(checks)
    begin
      OutputNextgen.log.debug "Nextgen Output is generating...."
      file_name = format_nextgen_specific_names(checks, @patient_eob_output_config.nextgen_file_name, "file")
      OutputNextgen.log.debug "File Name: #{file_name}"
      output_dir = "private/data/#{@facility_name.downcase.gsub(' ','_')}/nextgen/#{Date.today.to_s}"

      if @patient_eob_output_config.details[:nextgen_output_folder] && !@patient_eob_output_config.nextgen_folder_name.blank?
        folder_name = format_nextgen_specific_names(checks, @patient_eob_output_config.nextgen_folder_name, "folder")
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

      if @patient_eob_output_config.details[:zip_nextgen_output] && !@patient_eob_output_config.nextgen_zip_file_name.blank?
        zip_file_name = format_nextgen_specific_names(checks, @patient_eob_output_config.nextgen_zip_file_name, "zip")
        OutputNextgen.log.debug "Zip File Name: #{zip_file_name}"
        create_zip_file_from_output(output_dir , zip_file_name, file_name)
      end
    rescue Exception => e
      OutputNextgen.log.error "Exception  => " + e.message
      OutputNextgen.log.error e.backtrace.join("\n")
    end
  end

  #TODO Need to refactor(OLD RAKE)
  def format_nextgen_specific_names(checks, name, type)
    batch_date = @batch.date
    batchid = @batch.batchid
    @file_name_hash.each do |key,value|
      name.gsub!("#{key}", eval(value).to_s) if name.include?("#{key}")
    end

    if type == "file"
      name.gsub!(".txt","") if name.include?(".txt")
      name.gsub!(".TXT","") if name.include?(".TXT")
      "#{name}.txt"
    elsif type == "folder"
      name.gsub!("[EXT]","NXGN") if name.include?("[EXT]")
      "/" + name
    elsif type == "xml"
      name.gsub!(".xml","") if name.include?(".xml")
      name.gsub!(".XML","") if name.include?(".XML")
      "#{name}.xml"
    else
      name.gsub!(".zip","") if name.include?(".zip")
      name.gsub!(".ZIP","") if name.include?(".ZIP")
      "#{name}.ZIP"
    end
  end

  #TODO Need to refactor(OLD RAKE)
  def record_activity checks, activity, format, file_name, file_location, output_start_time, output_end_time, batch_ids = []
    if batch_ids.present?
      batchids = batch_ids
    else
      batchids = CheckInformation.checks_batch_ids(checks)
    end
    formats =["PC_Print", "NextGen", "XML", "Indexed_Image_File", "Exception_Report"]
    file_path = Rails.root.to_s + "/" +  file_location.to_s +  "/" +  file_name.to_s

    if File.exists?(file_path)
      checksum = ` md5sum \"#{file_path}\" ` rescue nil
    end
    checksum = checksum.split(" ")[0] if checksum

    if formats.include? format
      OutputActivityLog.purge_all(batchids, format, file_name)
      batchids.each do |batch_id|
        OutputActivityLog.create({:batch_id => batch_id, :activity => activity, :file_name => file_name,
            :file_format => format, :file_location => file_location, :start_time => output_start_time,
            :end_time => output_end_time, :user_id => current_user.id ,
            :status => OutputActivityStatus::GENERATED, :checksum => checksum, :ack_latest_count => @ack_latest_count})
      end
    end
  end

  #TODO Need to refactor(OLD RAKE)
  def generate_indexed_image_file(batch_ids)
    begin
      batch_date = Batch.find(batch_ids[0]).date
      batch_path = "#{INDEXED_IMAGE_PATH}/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/#{batch_date}" unless batch_date.nil?
      batch_path_for_rejected_images = "#{INDEXED_IMAGE_PATH}/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/#{batch_date}" unless batch_date.blank?
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

  def generate_upmc_indexed_image_file(batch_ids)
    IndexedImageFile.log.info "Generating UMPC indexed image file"
    file_type = 'indexed_image'
    begin
      index_file_paths = []
      batch = Batch.find(batch_ids[0])
      batch_date = batch.date
      lockbox = batch.lockbox
      batch_path = "#{INDEXED_IMAGE_PATH}/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/#{lockbox}/#{batch_date}" unless batch_date.nil?
      system("rm -r #{batch_path}")
      FileUtils.mkdir_p(batch_path)
      IndexedImageFile.log.info "batch_path : #{batch_path}"
      checks = CheckInformation.get_completed_checks(batch_ids)
      if checks.length > 0
        check_groups = group_upmc_indexed_image_file_checks(checks)
        puts "Grouping successful, returned #{check_groups.length} distinct group/s"

        destination_of_zip_file = "#{Rails.root}/private/data/#{@facility_name.downcase.gsub(' ','_')}/#{file_type}/#{Date.today.to_s}/#{lockbox}"
        directory_to_keep_files_to_zip = "#{destination_of_zip_file}/directory_to_keep_files_to_zip"

        #Removing old folder structure
        system("rm -r #{destination_of_zip_file}")
        FileUtils.mkdir_p(destination_of_zip_file)

        IndexedImageFile.log.info "directory_to_keep_files_to_zip : #{directory_to_keep_files_to_zip}"
        FileUtils.mkdir_p(directory_to_keep_files_to_zip)
        
        check_groups.each do |group, check_group|
          index_file_paths << create_upmc_indexed_image_file(check_group, batch_path, directory_to_keep_files_to_zip)
        end
        puts "Zipping indexed image file and generated multi page image files"
        create_indexed_image_zip_file(batch, lockbox, file_type, index_file_paths, destination_of_zip_file, directory_to_keep_files_to_zip)
      else
        puts "Unable to generate Indexed Image O/p as no checks are eligible "
      end
      system("rm -r private/data/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/txt")
      system("rm -r private/data/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/#{lockbox}")
    rescue Exception => e
      IndexedImageFile.log.error "Exception  => " + e.message
      IndexedImageFile.log.error e.backtrace.join("\n")
    end
  end

  def group_upmc_indexed_image_file_checks(checks)
    grouping =  @insurance_eob_output_config.grouping
    checks.group_by do |check|
      "date_#{check.batch.date}_lockbox_#{check.batch.facility_id}"
    end
  end
  #For Zipping indexed image file with its images or exception report with its images
  def create_indexed_image_zip_file(batch, lockbox, file_type, index_file_paths, destination_of_zip_file, directory_to_keep_files_to_zip)
    IndexedImageFile.log.info "In method create_indexed_image_zip_file"
    IndexedImageFile.log.info "destination_of_zip_file : #{destination_of_zip_file}"
    IndexedImageFile.log.info "directory_to_keep_files_to_zip : #{directory_to_keep_files_to_zip}"
    get_upmc_batch_attributes(batch)
    deposit_date_formatted = (@upmc_deposit_date.blank? ? '' : @upmc_deposit_date.strftime("%m%d%Y")) if file_type == 'indexed_image'
    deposit_date_formatted = (@upmc_deposit_date.blank? ? '' : @upmc_deposit_date.strftime("%Y%m%d")) if file_type == 'exception_report'
    indexed_image_zip_file_name = "LBX#{lockbox}#{deposit_date_formatted}_00IMAGEFILE.ZIP" if file_type == 'indexed_image'
    indexed_image_zip_file_name = "LBX#{@upmc_batch_lockbox}#{deposit_date_formatted}_ExceptionsBNY.ZIP" if file_type == 'exception_report'
    destination_dir = "#{destination_of_zip_file}/#{indexed_image_zip_file_name}"

    IndexedImageFile.log.info "destination_of_zip_file : #{destination_of_zip_file}"
    IndexedImageFile.log.info "destination_dir : #{destination_dir}"
    IndexedImageFile.log.info "index_file_paths : #{index_file_paths}"

    index_file_paths.each do |path|
      FileUtils.cp_r Dir.glob("#{path}/*"), directory_to_keep_files_to_zip
    end
    Zipper.zip(directory_to_keep_files_to_zip, destination_dir)
    system("rm -r #{directory_to_keep_files_to_zip}")
  end

  def merge_and_split_images_for_upmc(check, batch_path, directory_to_keep_files_to_zip)
    IndexedImageFile.log.info "Inside merge_and_split_images_for_upmc}"
    batch = check.batch
    batch_id = batch.id
    batchid = batch.batchid
    batch_path = batch_path
    FileUtils.mkdir_p(batch_path)
    image_path = batch_path + "/image"
    FileUtils.mkdir_p(image_path)
    IndexedImageFile.log.info "batch_path : #{batch_path}"
    IndexedImageFile.log.info "image_path : #{image_path}"
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

      create_multi_page_image_for_upmc(check, batch_path, image_names_for_job, image_path, directory_to_keep_files_to_zip)

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

          create_multi_page_image_for_upmc(check, batch_path, image_names_for_job, image_path, directory_to_keep_files_to_zip)

        end
      end
    end
    system("rm -r #{image_path}")
  end

  def create_multi_page_image_for_upmc(check, batch_path, image_names_for_job, image_path, directory_to_keep_files_to_zip)
    single_page_files = Dir.glob("#{image_path}/*.tif").sort
    unless image_names_for_job.nil?
      batch = check.batch
      get_upmc_batch_attributes(batch)
      job = check.job
      job_image_name = job.initial_image_name
      job_image_name_formatted = job_image_name.gsub(/^[0]*/,"")
      deposit_date_formatted = (@upmc_deposit_date.blank? ? '' : @upmc_deposit_date.strftime("%Y%m%d"))
      multi_page_image_name = @upmc_batch_lockbox + deposit_date_formatted + job_image_name_formatted
      IndexedImageFile.log.info "single_page_files : #{single_page_files}"
      IndexedImageFile.log.info "directory_to_keep_files_to_zip : #{directory_to_keep_files_to_zip}/#{multi_page_image_name}"
      system("cd #{directory_to_keep_files_to_zip}; tiffcp #{single_page_files.join(' ')} #{directory_to_keep_files_to_zip}/#{multi_page_image_name}")
    end
  end

  def get_upmc_batch_attributes(batch)
    batchid_array = batch.batchid.split('_') unless batch.batchid.blank?
    @upmc_deposit_date = Date.strptime batchid_array[1], "%y%m%d" unless batchid_array.blank?
    @upmc_batch_lockbox = batch.lockbox
    @upmc_bank_batch_number = batchid_array[2]
  end

  def generate_upmc_exception_report(batch_ids)
    IndexedImageFile.log.info "Generating UPMC Exception Report"
    file_type = 'exception_report'
    begin
      checks = CheckInformation.get_exception_checks(batch_ids)
      sorted_checks = checks.sort_by {|check| [ check.batch.batchid.split('_')[2], check.job.initial_image_name]}
      batch = Batch.find(batch_ids[0])
      batch_date = batch.date
      lockbox = batch.lockbox
      batch_path = "#{INDEXED_IMAGE_PATH}/#{@facility_name.downcase.gsub(' ','_')}/exception_report/#{lockbox}/#{batch_date}" unless batch_date.nil?
      get_upmc_batch_attributes(batch)
      deposit_date_formatted = @upmc_deposit_date.strftime("%Y%m%d")
      path_for_message = "private/data/#{@facility_name.downcase.gsub(' ','_')}/exception_report/pdf/#{Date.today.to_s}/#{@upmc_batch_lockbox}"
      exception_file_path = "#{Rails.root}/private/data/#{@facility_name.downcase.gsub(' ','_')}/exception_report/pdf/#{Date.today.to_s}/#{@upmc_batch_lockbox}"
      exception_filename = "LBX#{@upmc_batch_lockbox}#{deposit_date_formatted}_ExceptionsBNY.pdf"

      IndexedImageFile.log.info "batch_path : #{batch_path}"
      IndexedImageFile.log.info "exception_file_path : #{exception_file_path}"

      FileUtils.mkdir_p(batch_path)
      FileUtils.mkdir_p(exception_file_path)
      pdf = ""
      exception_report_start_time = Time.now
      Prawn::Document.generate "#{exception_file_path}/#{exception_filename}" do
        pdf
      end
      pdf = ExceptionCheckPdf.new(batch, sorted_checks)
      puts "Exception Report generated sucessfully, file is written to:"
      puts "#{path_for_message}/#{exception_filename}"
      pdf.render_file("#{exception_file_path}/#{exception_filename}")

      destination_of_zip_file = "#{Rails.root}/private/data/#{@facility_name.downcase.gsub(' ','_')}/#{file_type}/#{Date.today.to_s}/#{lockbox}"
      directory_to_keep_files_to_zip = "#{destination_of_zip_file}/directory_to_keep_files_to_zip"

      #Removing old folder structure
      system("rm -r #{destination_of_zip_file}")
      FileUtils.mkdir_p(destination_of_zip_file)

      IndexedImageFile.log.info "directory_to_keep_files_to_zip : #{directory_to_keep_files_to_zip}"
      FileUtils.mkdir_p(directory_to_keep_files_to_zip)
        
      #Method to create multi-page image for UPMC
      sorted_checks.each do |check|
        merge_and_split_images_for_upmc(check, batch_path, directory_to_keep_files_to_zip )
      end
      index_image_path = batch_path
      IndexedImageFile.log.info "index_image_path : #{index_image_path}"
      create_indexed_image_zip_file(batch, lockbox, file_type, [exception_file_path], destination_of_zip_file, directory_to_keep_files_to_zip)
      exception_report_end_time = Time.now
      
      record_activity(sorted_checks, 'Exception Report Generated', 'Exception_Report',
        exception_filename, path_for_message, exception_report_start_time, exception_report_end_time, batch_ids)
      
      system("rm -r private/data/#{@facility_name.downcase.gsub(' ','_')}/exception_report/pdf")
      system("rm -r private/data/#{@facility_name.downcase.gsub(' ','_')}/exception_report/#{lockbox}")
    rescue Exception => e
      "Exception  => " + e.message
      e.backtrace.join("\n")
    end
  end

  #TODO Need to refactor(OLD RAKE)
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

  #TODO Need to refactor(OLD RAKE)
  def create_indexed_image_file(check_group, batch_path, batch_path_for_rejected_images)
    begin
      check_segregator = CheckSegregator.new
      check_group_batch = check_group.first.batch
      batch_date = check_group_batch.bank_deposit_date.strftime("%m%d%Y")
      check_group.each do |check|
        merge_and_split_images_for_gcbs(check, batch_path ) if @facility.name.upcase == 'GOODMAN CAMPBELL BRAIN AND SPINE'
      end
      # Creating separate Indexed Image files for Patpays and Insurance payment EOBs
      check_type = check_segregator.payer_group_indexed_image(check_group.first)
      file_name = "#{batch_date}_#{check_type.upcase}_INDEXEDIMAGE.csv"
      output_dir_indexed_image = "private/data/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/csv/#{Date.today.to_s}"
      if check_type == "corr"
        @corr_flag = 1
        merge_corr_images_for_gcbs(check_group, batch_path_for_rejected_images) if @facility.name.upcase == 'GOODMAN CAMPBELL BRAIN AND SPINE'
      end

      if file_name
        doc_klass = IndexedImageFile.class_for("Document", @facility)
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

  #TODO Need to refactor(OLD RAKE)
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

  #TODO Need to refactor(OLD RAKE)
  def create_multi_page_image_for_GCBS(batch_path, image_names_for_job, image_path)
    single_page_files = Dir.glob("#{image_path}/*.tif").sort
    unless image_names_for_job.nil?
      first_image_name = image_names_for_job[0]
      multi_page_image_name = first_image_name.chomp(".tif") + "_T.tif"
      system("cd #{batch_path}; tiffcp #{single_page_files.join(' ')} #{batch_path}/#{multi_page_image_name}")
    end
  end

  #TODO Need to refactor(OLD RAKE)
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

  #TODO Need to refactor(OLD RAKE)
  def merge_corr_images_for_gcbs(check_group, batch_path_for_rejected_images)
    check_group_corr = image_group_checks(check_group)
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

  #TODO Need to refactor(OLD RAKE)
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

  #TODO Need to refactor(OLD RAKE)
  def create_non_eob_images_for_gcbs(check, image_path_for_rejected_images, non_eob_images)
    all_rejected_jobs = Job.find(:all, :conditions => ["batch_id = ? and job_status = ?", @batch_id, JobStatus::INCOMPLETED])
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

  #TODO Need to refactor(OLD RAKE)
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

  def create_upmc_indexed_image_file(check_group, batch_path, directory_to_keep_files_to_zip)
    index_file_path = nil
    begin
      check_group_batch = check_group.first.batch
      get_upmc_batch_attributes(check_group_batch)
      deposit_date_formatted = (@upmc_deposit_date.blank? ? '' : @upmc_deposit_date.strftime("%Y%m%d"))
      batch_date = check_group_batch.bank_deposit_date.strftime("%Y%m%d")
      lockbox = check_group_batch.lockbox
      sorted_check_group = check_group.sort_by {|check| [ check.batch.batchid.split('_')[2], check.job.initial_image_name]}
      sorted_check_group.each do |check|
        merge_and_split_images_for_upmc(check, batch_path, directory_to_keep_files_to_zip )
      end
      file_name = "#{lockbox}#{deposit_date_formatted}index.idx"
      output_dir_indexed_image = "private/data/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/txt/#{Date.today.to_s}/#{lockbox}"
      index_file_path = "#{output_dir_indexed_image}"
      if file_name
        doc_klass = IndexedImageFile.class_for("Document", @facility)
        doc = doc_klass.new(sorted_check_group)
        FileUtils.mkdir_p(output_dir_indexed_image)

        indexed_img_file_start_time = Time.now
        File.open("#{output_dir_indexed_image}/#{file_name}", 'w+') do |file|
          file << doc.generate
          indexed_img_file_end_time = Time.now

          record_activity(sorted_check_group, 'IndexedImageFile Generated', 'Indexed_Image_File',
            file_name, output_dir_indexed_image, indexed_img_file_start_time, indexed_img_file_end_time)
          puts "Indexed Image file for generated sucessfully, file is written to:"
          puts "#{output_dir_indexed_image}/#{file_name}"
        end
      end
    rescue Exception => e
      IndexedImageFile.log.error "Exception  => " + e.message
      IndexedImageFile.log.error e.backtrace.join("\n")
    end
    index_file_path
  end

  #TODO Need to refactor(OLD RAKE)
  def image_group_checks(checks)
    check_segregator = CheckSegregator.new('by_payer', 'by_payer_type')
    checks.group_by do |check|
      check_segregator.group_name_supplemental_output(check, 'by_payer')
    end
  end

  #TODO Need to refactor(OLD RAKE)
  def convert_tiff_to_jpeg
    Dir.glob("#{INDEXED_IMAGE_PATH}/#{@facility_name.downcase.gsub(' ','_')}/indexed_image/**/*.tif", File::FNM_CASEFOLD).each do |image|
      file_name = "#{File.dirname(image)}/#{File.basename(image, File.extname(image))}.jpg"
      system("convert #{image} #{file_name}")
      File.delete(image)
    end
  end

  def image_name(img_name)
    img_file_ext = File.extname(img_name)
    splited_image_number = img_name.index("_0#{img_file_ext}")
    if splited_image_number and splited_image_number > 0
      base_name=img_name.chomp("_0#{img_file_ext}")
      new_file_name = base_name
    else
      new_file_name = img_name.chomp("#{img_file_ext}")
    end
    return new_file_name
  end

  def get_835_type_for_group(group_name, checks)
    return 'Denials' if group_name && group_name.split('_').include?('correspondence')
    check = checks.first if checks
    (check && check.is_patpay_check?) ? 'PatPay' : 'Insurance'
  end

  def get_config_835_values
    config_type = @config_835_type
    {
      :facility_level =>  @facility.config_settings.where(:output_type => config_type).first.try(:details) || {},
      :client_level =>  @client.config_settings.where(:output_type => config_type).first.try(:details) || {},
      :partner_level =>  @client.partner.config_settings.where(:output_type => config_type).first.try(:details) || {}
    }
  end

end
