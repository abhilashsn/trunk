require "nokogiri"
require 'digest/md5'

include Nokogiri

class XMLTransformer< XML::SAX::Document
  attr_reader :stack, :qlf, :val, :is_open, :count, :qlf_service

  def initialize
    @hl_count = 0
    @clm_count = 0
    @claim_type_identifier = 0
    @common_primary_elements_for_stack = []
    @hl_03_counter = 0
    @duplicate = false
    @extract = false
    @stack = []
    @file_header_hash = []
    @static_data_points = ["service_from_date","patient_account_number","plan_code", "payer_claim_original_reference_number", "reference_identification_code_f8","CLAIM_SERVICE","cpt_hcpcts","modifier1","revenue_code","charges","days_units", "tooth_number", "tooth_surface","date_qualifier","/legacy_provider_number_qualifier","provider_control_number","date_of_birth", "svc_provider_first_name", "svc_provider_last_name", "svc_npi_tin_82", "svc_npi_tin_qualifier_82", "svc_provider_middle_initial", "svc_provider_suffix", "svc_rendering_provider_taxonomy_code", "claim_service_from_date", "claim_date_qualifier"]
    @billing_provider_informations = []
    @svc_provider_details = ["svc_provider_last_name", "svc_provider_first_name", "svc_provider_middle_initial", "svc_provider_suffix", "svc_npi_tin_82", "svc_npi_tin_qualifier_82"]
    @ip_patient_infos = ["21", "25", "31", "32", "33", "34", "51", "55", "56", "61"]
    @op_patient_infos = ["5", "7", "17", "22", "49", "52", "53", "57", "60", "62"]
    @grp = ""
    @is_open = false
    @actv_grp = "GENERAL"
    @qlf = "GENERAL"
    @qlf_service = false
    @qlf_plan_code = false
    @total_claim_count = 0
    @loaded_claim_count = 0
    @total_svcline_count = 0
    @loaded_svcline_count = 0
    @mismatched_client_codes = []
    @mismatched_billing_provider = []
    @secondary_group_4_identifier = 0
    @group7_identifier = 0
    @plan_code_counter = 0
    @is_group4 = false
    @is_group8 = false
    @is_group11 = false
    @is_group12 = false
    @interchange_date = ""
    @interchange_time = ""
    # Variables related to ticket implementation for #27591
    @grp3_qlf85_npi_tin_qualifier_85 = ""
    @grp3_qlf85_npi_tin_85 = ""
    @grp3_qlf85_billing_provider_organization_name = ""
    @grp3_qlf85_billing_provider_address_one = ""
    @grp3_qlf85_billing_provider_city = ""
    @grp3_qlf85_billing_provider_state = ""
    @grp3_qlf85_billing_provider_zipcode = ""
    @grp3_qlf85_reference_identification_code = ""
    @grp3_qlf85_employers_identification_number = ""
    @grp3_qlf85_reference_identification_code = ""
    @grp3_qlf85_EI_number_or_LU_number = ""

    @is_push_to_stack = true
    @reference_identification_code_1 = ""
    client = Client.find_by_name($CNF['client_name'])
    @client_id= client.id
    @map_claim_on_npi = client.associate_claim_npi
    facilities_obj =  client.facilities
    if $CNF['client_name'].upcase == "NAVICURE"
      @navicure_facilities_hash = Hash.new
      @site_code_array = Array.new
      facilities_obj.each {|facility|
        @navicure_facilities_hash[facility.id] = facility.sitecode
        @site_code_array << facility.sitecode
      }
    else
      @facility_npi_hash = Hash.new
      @facility_tin_hash = Hash.new
      facility_ids = facilities_obj.collect {|p| p.id }
      facility_npi_and_tins = FacilitiesNpiAndTin.find(:all, :conditions => ["facility_id in (?)" , facility_ids])
      facility_npi_and_tins.each {|p|
        @facility_npi_hash[p.npi] = {:npi => p.npi, :tin => p.tin ,:facility_id => p.facility_id } unless p.npi.blank?
        @facility_tin_hash[p.tin] = {:npi => p.npi, :tin => p.tin ,:facility_id => p.facility_id } unless p.tin.blank?
      }
    end
  end

  def start_element(element, attributes)
    open_stack(element)
    @actv_grp = element if (element.start_with?("GROUP") and !element.start_with?("GROUP_11"))
  end

  def characters(string)
    @val = string
  end

  def end_element(element)
    if (element != "DTP" and !@is_group12)
      secure_data(element)
    end
    close_stack(element)
    if element == "GROUP_12"
      @is_group12 = false
    end
  end

  def open_stack(element)
    # Element GROUP_2 open the claim stack
    case element
    when "GROUP_2"
      @is_open = true unless is_open
      @qlf_service = false
      @is_group11 = false
      @is_group4 = false
      @is_group8 = false
      @is_group12 = false
    when "SBR01"
      @claim_type_identifier += 1
    when "HL"
      stack.push ["COMMON_INFORMATION"]
    when "GROUP_4"
      @is_group4 = true
      @service_from_date = ""
      @service_to_date = ""
      stack.push ["CLAIM_INFORMATION"]
      @secondary_group_4_identifier += 1
      @qlf_service = false if @secondary_group_4_identifier > 1
    when "DTP", "REF"
      if @is_group4 and !@qlf_service
        @previous_grp_val = @grp
        @previous_qlf_val = @qlf
        @grp = "GROUP_4"
        @actv_grp = "GROUP_4"
        if element.eql? "DTP"
          @qlf = "RD8"
        elsif element.eql? "REF"
          @qlf = "F8"
        end
      end
    when "AMT"
      if @is_group12
        @grp = "GROUP_12"
        @qlf = "EAF"
        @actv_grp = "GROUP_12"
      end
    when "GROUP_7"
      @group7_identifier += 1
    when "GROUP_8"
      @is_group8 = true
    when "GROUP_9"
      stack.push ["CLAIM_SERVICE"]
      @qlf_service = true unless @qlf_service
      reset_qualifier
      @is_group12 = false
    when "GROUP_11"
      @is_group11 = true
      @previous_grp_val = @grp
      @previous_qlf_val = @qlf
      @actv_grp = "GROUP_11"
      @grp = "GROUP_11"
      @qlf = "82"
    when "GROUP_12"
      @is_group12 = true
    end
  end

  def send_mail(file_name, client_facility, type, old_file, file_path)
    if type == "F"
      facility_name = client_facility
      facility = Facility.find_by_name(client_facility.to_s)
      client_name = facility.client.name
    elsif type == "C"
      facility_name = "-"
      client_name = client_facility
    end
    subject = "Duplicate claim file alert for claim file #{file_name}"
    body_content = "is"
    recipient = $EMR['recipient']
    RevremitMailer.notify_claim_upload(recipient,subject, file_name,
      facility_name, client_name, file_path, old_file, body_content).deliver
  end

  def secure_data(element)
    @is_push_to_stack = true
    if @val == "UCR" or @val == "6R"
      @grp = "GROUP_9"
      @qlf = @val
    end
    key = $CNF[@grp + @qlf][element] rescue return
    if (key == "extraction_start" && @val == "2" )
      @file_header_hash.push [key, @val]
      @extract = true
      count = 1
    end
    if count & count == 1
      @extract == true
    end

    if ((@extract == true || key == "extraction_end") && key != "extraction_start")
      @file_header_hash.push [key, @val]
    end

    if (element == "CLM09" && !@ss)
      @ss = 1
#      file_header_hash = @file_header_hash.to_s
#      md5_file_header_hash = Digest::MD5.hexdigest(file_header_hash)
#      claim_file_information = ClaimFileInformation.all(:conditions => "file_header_hash = '#{md5_file_header_hash}' AND deleted = #{0}")
#      if claim_file_information.blank?
#        @claim_file_information.update_attributes(:file_header_hash => md5_file_header_hash)
#      else
#        @duplicate = true
#        @old_file = claim_file_information.first.name.to_s
#        send_mail($CNF['file_name'], $CNF['client_facility'], $CNF['type'], @old_file, $CNF['file_path'])
#        puts "The file #{$CNF['file_name']} has failed to load since it is a duplicate of a previously processed claim file #{@old_file} that arrived on #{@claim_file_information.arrival_time}. The hash key matches the key of the file #{@old_file}"
#        puts "Old filename - #{@old_file}"
#        puts "Old filename's hashkey - #{claim_file_information.first.file_header_hash}"
#        ClaimFileInformation.find(@claim_file_information.id).destroy
#      end
    end
      # --------- end --------------

    if key.eql?("bill_print_date")
      @stack.push [key, @val]
    end
    return unless is_open
    return if key.nil?
      if (key.eql?("/qualifier") or key.eql?("/xpeditor_qualifier") or key.eql?("/date_of_birth_qualifier") and !@is_group11)
        @qlf = @val
        @grp = @actv_grp
      else
        if key == "xpeditor_document_number"
          @stack.push [key, @val] if((@val=~/^\d*[a-zA-Z][a-zA-Z0-9]*$/) == 0)
        else
          case key
          when "reference_identification_code_ei, reference_identification_code_lu"
            if @val == "LU"
              key = "reference_identification_code_lu"
              @reference_identification_code_1 = "LU"
            elsif @val == "EI"
              key = "reference_identification_code_ei"
              @reference_identification_code_1 = "EI"
            else
              @reference_identification_code_1 = ""
              @is_push_to_stack = false
            end
            # #27591 - Set a value to a variable when @qlf is 85. Later on for qualifier 87, this value is checked,
            # if the variable contains value, then no need to take value from qualifier 87 related tag,
            # so value is not pushed to stack
            if @qlf == "85"
              @grp3_qlf85_reference_identification_code = @val
            end
            if @qlf == "87"
              unless @grp3_qlf85_reference_identification_code.blank?
                @is_push_to_stack = false
              end
              @grp3_qlf85_reference_identification_code = ""
            end
          when "employers_identification_number, legacy_provider_number"
            if @reference_identification_code_1 == "LU"
              key = "legacy_provider_number"
            elsif @reference_identification_code_1 == "EI"
              key = "employers_identification_number"
            else
              @is_push_to_stack = false
            end
            # #27591 - Set a value to a variable when @qlf is 85. Later on for qualifier 87, this value is checked,
            # if the variable contains value, then no need to take value from qualifier 87 related tag,
            # so value is not pushed to stack
            if @qlf == "85"
              @grp3_qlf85_EI_number_or_LU_number = @val
            end
            if @qlf == "87"
              unless @grp3_qlf85_EI_number_or_LU_number.blank?
                @is_push_to_stack = false
              end
              @grp3_qlf85_EI_number_or_LU_number = ""
            end
          when "billing_provider_organization_name", "npi_tin_qualifier_85", "npi_tin_85","billing_provider_address_one", "billing_provider_city", "billing_provider_state","billing_provider_zipcode"
            # #27591 - Set a value to a variable when @qlf is 85. Later on for qualifier 87, this value is checked,
            # if the variable contains value, then no need to take value from qualifier 87 related tag,
            # so value is not pushed to stack
            if @qlf == "85"
              instance_variable_set("@grp3_qlf85_#{key}", @val)
            end
            if @qlf == "87"
              eval "unless @grp3_qlf85_#{key}.blank?; @is_push_to_stack = false; end"
              instance_variable_set("@grp3_qlf85_#{key}", "")
            end
          end
          @stack.push [key, @val] if @is_push_to_stack
        end
      end
    end

  def close_stack(element)
    unless @duplicate
      # Element GROUP_2 close the claim stack
      case element
      when "HL03"
        @hl03_segment_value = @val.to_i
        if @hl03_segment_value == 23
          @hl_03_counter += 1
        else
          @hl_03_counter = 0
        end
      when "HL04"
        @hl04_segment_value = @val.to_i
      when "DTP", "REF"
        if @is_group4 and !@qlf_service
          @grp = @previous_grp_val
          @qlf = @previous_qlf_val
          @actv_grp = @previous_grp_val
          @previous_grp_val = nil
          @previous_qlf_val = nil
        end
      when "GROUP_11"
         @is_group11 = false
         @grp = @previous_grp_val
         @qlf = @previous_qlf_val
      when "GS08", "ISA09", "ISA10"
        @stack.push [element, @val]
        store_the_claim_file_type(@stack)
      when "GROUP_3", "GROUP_4", "GROUP_6", "GROUP_8", "DMG"
        reset_qualifier
      when "GROUP_2"
        if @hl03_segment_value == 20
          @billing_provider_informations = []
          stack.each do |elem|
            @billing_provider_informations.push elem
          end
          stack.clear
        end
        if @qlf_service
          if @hl_03_counter == 1
            @common_primary_elements_for_stack = sort_out_common_primary_elements
          end
          if @hl_03_counter == 2
            @stack = @common_primary_elements_for_stack + @stack
            @common_primary_elements_for_stack = []
          end
          if @secondary_group_4_identifier > 1 and @claim_type_identifier > 4
            stacks = rearrage_stack_on_multi_group_4_and_multi_claim_type
            stacks.each do |stack|
              @stack = stack
              stacks = rearrange_stacks
              stacks.each do |stack|
              @stack = stack
              transform
              end
            end
          elsif @secondary_group_4_identifier > 1
            stacks = create_multiple_claim_stacks
            stacks.each do |stack|
              @stack = stack
              transform
            end
          elsif @group7_identifier > 1
            stacks = rearrange_stacks
            stacks.each do |stack|
              @stack = stack
              transform
            end
          else
            transform
          end
          stack.clear if @hl04_segment_value == 0
          @group7_identifier = 0
          @secondary_group_4_identifier = 0
          @plan_code_counter = 0
          @claim_type_identifier = 0 if @hl04_segment_value == 0
        end
      when "X12"
        create_csv_and_log_file
      end
    end
  end

  def sort_out_common_primary_elements
    common_primary_elements = ["claim_type", "plan_type", "policy_number" ,"patient_first_name", "patient_last_name","patient_address_line","patient_zip_code", "patient_city_name", "patient_state_code" ,"subscriber_suffix", "subscriber_middle_initial", "subscriber_last_name", "subscriber_first_name","subscriber_address_line","subscriber_city_name", "subscriber_state_code", "subscriber_zip_code", "insured_id", "payer_name", "payer_address", "payer_city", "payer_state", "payer_zipcode","payid", "date_of_birth"]
    required_primary_element_stack = []
    sbr_counter = 0
    @stack.each_with_index do |elem, index|
      if common_primary_elements.include? elem.first
        sbr_counter += 1 if elem.first == "claim_type"
        unless sbr_counter > 1
          required_primary_element_stack << elem
        end
      end
    end
    return required_primary_element_stack
  end

  def rearrage_stack_on_multi_group_4_and_multi_claim_type
    # Identifying the common elements for a claim..
    @common_primary_elements_for_stack = sort_out_common_primary_elements
    common_elements = []
    @stack.each_with_index do |s, index|
      unless ["CLAIM_INFORMATION"].include? s[0]
      common_elements << s
      @stack[index] = nil
      end
      break if s[0] == "CLAIM_INFORMATION"
    end
    @stack = @stack.compact
    # Differentiating the stacks for different claims..
    stacks = []
    temp_array = []
    claim_service_identifier = false
    @stack.each do |element|
      claim_service_identifier = true if element[0] == "CLAIM_SERVICE"
      if claim_service_identifier and element[0] == "CLAIM_INFORMATION"
        stacks << common_elements + temp_array unless temp_array.empty?
        temp_array = []
      else
        temp_array << element
      end
    end
    stacks << @common_primary_elements_for_stack + temp_array unless temp_array.empty?
    @common_primary_elements_for_stack = []
    # Returning the separated stacks for the claims processing..
    return stacks
  end

  def create_multiple_claim_stacks
    # Identifying the common elements for a claim..
    common_elements = []
    @stack.each do |s|
      common_elements << s unless ["CLAIM_INFORMATION"].include? s[0]
      break if s[0] == "CLAIM_INFORMATION"
    end
    # Differentiating the stacks for different claims..
    stacks = []
    @stack = @stack - common_elements
    temp_array = []
    @stack.each do |element|
      if element[0] == "CLAIM_INFORMATION"
        stacks << common_elements + temp_array unless temp_array.empty?
        temp_array = []
      else
        temp_array << element
      end
    end
    stacks << common_elements + temp_array
    # Returning the seperated stacks for the claims processing..
    return stacks
  end

 def rearrange_stacks
    common_group7_elements = ["claim_type", "plan_type", "policy_number", "xpeditor_document_number", "subscriber_last_name", "subscriber_first_name", "insured_id", "payer_name", "payer_address", "payer_city", "payer_state", "payer_zipcode","payid"]
    required_group7_elements = []
    stacks = []
    @stack.each_with_index do |elem, index|
      if common_group7_elements.include? elem.first
        required_group7_elements << elem
        @stack[index] = nil
      end
    end
    hash_of_elems = process_ele required_group7_elements
    @stack = @stack.compact
    for i in 0..hash_of_elems.length - 1
      stacks << hash_of_elems[i] + @stack
    end
    return stacks
  end

  def process_ele required_group7_elements
    hash_of_elems = {}
    index = 0
    arr = []
    required_group7_elements.each do |ele|
      if ele.first == "claim_type"
        arr = Array.new
        hash_of_elems[index] = arr
        index += 1
      end
      arr << ele
    end
    return hash_of_elems
  end


 def create_csv_and_log_file
    if $CNF['facility_level']
      fac =  Facility.find(@claim_file_information.facility_id)
      facility = fac.name
      if @claim_information.patient_account_number
        unless @claim_information.patient_account_number.slice(0,2) == fac.sitecode
          @mismatched_client_codes << @claim_information.patient_account_number.slice(0,2)
          @mismatched_billing_provider << @claim_information.billing_provider_organization_name
        end
      end
    end

    log_file = "#{Rails.root}/837/#{facility}/log"
    FileUtils.mkdir_p("#{log_file}") unless File.exists? "#{log_file}"

    csv_file_name = @claim_file_information.name
    csv_file_name = @claim_file_information.name.split(".")[0] unless csv_file_name.blank?
    csv_file_name = csv_file_name = Time.now.strftime('%m%d%Y%H%M%S') if csv_file_name.blank?

    #creates log file
    logger_file = "#{log_file}/#{csv_file_name}.txt"
    log = Logger.new(logger_file)
    log.debug "billing_provider_organization_name = #{@claim_information.billing_provider_organization_name}"
    log.debug "patient_account_number = #{@claim_information.patient_account_number}"
    log.debug "patient_last_name = #{@claim_information.patient_last_name}"
    log.debug "subscriber_last_name = #{@claim_information.subscriber_last_name}"
    log.debug "plan_type = #{@claim_information.plan_type}"
    log.debug "policy_number = #{@claim_information.policy_number}"
    log.debug "claim_type = #{@claim_information.claim_type}"
    log.debug "insured_id = #{@claim_information.insured_id}"
    log.debug "payer_address = #{@claim_information.payer_address}"
    log.debug "payer_state = #{@claim_information.payer_state}"
    log.debug "payer_zipcode = #{@claim_information.payer_zipcode}"
    log.debug "legacy_provider_number = #{@claim_information.legacy_provider_number}"
    log.debug "iplan = #{@claim_information.iplan}"
    log.debug "claim_type = #{@claim_information.claim_type}"
    log.debug "claim_statement_period_start_date = #{@claim_information.claim_statement_period_start_date}"
    log.debug "claim_statement_period_end_date = #{@claim_information.claim_statement_period_end_date}"
    log.debug "provider_last_name = #{@claim_information.provider_last_name}"
    log.debug "provider_first_name = #{@claim_information.provider_first_name}"
    log.debug "provider_npi = #{@claim_information.provider_npi}"




    #creates csv report file
    if $CNF['client_name'].upcase == "QUADAX"
      FileUtils.mkdir_p("#{log_file}/#{facility}") unless File.exists? "#{log_file}/#{facility}"
      alert_csv_fields = ["FILENAME","TOTAL COUNT OF CLAIMS","NO OF CLAIMS REJECTED",
        "LIST OF MISMATCH CLIENT CODES IN THE FILE","LIST OF MISMATCHED BILLING PROVIDER DETAILS"]
      rejected_claims = @claim_file_information.total_claim_count - @claim_file_information.loaded_claim_count
      CSV.open("#{log_file}/#{facility}.csv",'w+') do |out|
        out << alert_csv_fields
        out << [@claim_file_information.name, @claim_file_information.total_claim_count, rejected_claims, @mismatched_client_codes, @mismatched_billing_provider]
      end
    else
      csv_fields = ["Client","Facility","Zip file name","File Arrival_time","File Name","File Size","File Load Start Time","File Load End Time",
        "Number of claims in file","Number of claims loaded successfully","Number of service lines in file",
        "Number of service lines loaded successfully","Loading Status"]
      CSV.open("#{log_file}/#{csv_file_name}.csv",'w+') do |out|
        out << csv_fields
        out << [$CNF['client_name'],facility,@claim_file_information.zip_file_name,@claim_file_information.arrival_time,@claim_file_information.name,@claim_file_information.size,@claim_file_information.load_start_time,
          @claim_file_information.load_end_time, @claim_file_information.total_claim_count ,@claim_file_information.loaded_claim_count ,@claim_file_information.total_svcline_count,@claim_file_information.loaded_svcline_count,@claim_file_information.status]
      end
    end
  end


  def transform
    begin
      facility_id, client_id = find_facility_and_client
      #     return if facility_id.blank?
      pos = 0
      first_claim_type = ''
      multiple_claim_identifier = 0
      @claim_information = ClaimInformation.new
      @claim_information.facility_id = facility_id
      @claim_information.client_id = client_id
      @stack = @billing_provider_informations + @stack
      ClaimInformation.transaction do
        #  @total_claim_count +=1
        @claim_information = process_claim
        @claim_information.active = true
        update_facility_id if @map_claim_on_npi
        claim_type_count = 0
        @provider_data = []
        @provider_infos = []
        @stack.each do |cs|
          pos +=1
          if cs[0] == "claim_type"
            @claim_information["claim_adjudication_sequence"] = cs[1].to_s
            claim_type_count += 1
            first_claim_type = cs[1].to_s if claim_type_count == 1
            multiple_claim_identifier += 1
          end

          if cs[0].eql?("CLAIM_SERVICE")
            @provider_data << @provider_infos
            @provider_infos = []
            @claim_information.claim_service_informations << process_claim_service_information(pos)
            @provider_data << @provider_infos
            #set the claim end date to maximum service date of the claim
            # Rajesh, 14 Dec 2012, Added '.select(&:service_to_date)' as fix for #23577
            claim_service_informations = @claim_information.claim_service_informations
            unless claim_service_informations.blank?
              sorted_service_to_dates = claim_service_informations.select(&:service_to_date).sort_by(&:service_to_date)
              sorted_service_from_dates = claim_service_informations.select(&:service_from_date).sort_by(&:service_from_date)
              @claim_information.claim_end_date = sorted_service_to_dates.last.service_to_date.to_formatted_s(:db) unless sorted_service_to_dates.blank?
              @claim_information.claim_start_date = sorted_service_from_dates.first.service_from_date.to_formatted_s(:db) unless sorted_service_from_dates.blank?
            end
          end
        end
        @claim_information.claim_start_date = @claim_information.claim_statement_period_start_date unless @claim_information.claim_start_date
        @claim_information.claim_end_date = @claim_information.claim_statement_period_end_date unless @claim_information.claim_end_date
        process_provider_details @provider_data
        # Set claim id hash for claim identification rake task
        set_claim_id_hash false
        set_patient_details

        unless @claim_information.patient_account_number.blank?
          if @claim_information.save!
            @loaded_claim_count +=1
            @total_claim_count +=1
          end
        end
        if multiple_claim_identifier > 1
          process_the_additional_claim facility_id, first_claim_type, @claim_information.id
        end
        @claim_information.claim_start_date = @claim_information.claim_statement_period_start_date unless @claim_information.claim_start_date
        @claim_information.claim_end_date = @claim_information.claim_statement_period_end_date unless @claim_information.claim_end_date
      end
      stack.clear if @hl04_segment_value == 0
      @is_open = false
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
      raise err
    end
  end

  def process_provider_details provider_data
    provider_data = provider_data.reject { |ele| ele.join.strip.length == 0 }.uniq
    if provider_data.length == 1 and @claim_information.provider_first_name.nil?
      provider_data.first.each do |prv_data|
        if prv_data[0] == "svc_npi_tin_qualifier_82"
          @npi_tin_qualifier_82 = prv_data[1]
        elsif prv_data[0] == "svc_npi_tin_82"
          process_tin_npi(prv_data, "svc_npi_tin_82", @npi_tin_qualifier_82)
        else
          @claim_information[prv_data[0].sub("svc_","")] = prv_data[1]
        end
      end
    end
  end


  def set_claim_id_hash is_additional_claim

    patient_account_number = (@claim_information.patient_account_number.blank?) ? "" : @claim_information.patient_account_number
    patient_last_name = (@claim_information.patient_last_name.blank?) ? "" : @claim_information.patient_last_name
    patient_first_name = (@claim_information.patient_first_name.blank?) ? "" : @claim_information.patient_first_name
    payid = (@claim_information.payid.blank?) ? "" : @claim_information.payid

    unless is_additional_claim
      claim_adjudication_sequence = (@claim_information.claim_adjudication_sequence.blank?) ? "" : @claim_information.claim_adjudication_sequence
    else
      claim_adjudication_sequence = ""
    end

    claim_id_hash = patient_account_number + "_" + patient_last_name + "_" + patient_first_name + "_" + payid + "_" + claim_adjudication_sequence

    # creating an MD5 hash for the claim id hash for data security purpose
    md5_claim_id_hash = Digest::MD5.hexdigest(claim_id_hash)

    @claim_information.claim_id_hash = md5_claim_id_hash

  end

  def set_service_id_hash claim_service_information

    charges = (claim_service_information.charges.blank?) ? "" : claim_service_information.charges.to_s
    cpt_hcpcts = (claim_service_information.cpt_hcpcts.blank?) ? "" :claim_service_information.cpt_hcpcts.to_s
    service_from_date = (claim_service_information.service_from_date.blank?) ? "" : claim_service_information.service_from_date.to_s

    service_id_hash = charges + "_" + cpt_hcpcts + "_" + service_from_date

    # creating an MD5 hash for the service id hash for data security purpose
    md5_service_id_hash = Digest::MD5.hexdigest(service_id_hash)

    claim_service_information.service_id_hash = md5_service_id_hash

  end


  def reset_qualifier
    @grp = ""
    @qlf = "GENERAL"
    @actv_grp = "GENERAL"
  end


  def claim_file_information_start(size,file_837_name,load_start_time,zip_file_name,file_arrival_time, file_meta_hash, *args)
    begin
      @claim_file_information = ClaimFileInformation.new
      @claim_file_information.size = size
      @claim_file_information.file_meta_hash = file_meta_hash
      @claim_file_information.zip_file_name = zip_file_name
      @claim_file_information.arrival_time = file_arrival_time
      @claim_file_information.name = file_837_name
      @claim_file_information.load_start_time = load_start_time
      @claim_file_information.inbound_file_information_id = args[0] # An optional field...Which will be used only for the BAC clients..
      #  @claim_file_information.facility_id = facility_id
      @claim_file_information.save!
    rescue => err
      raise err
      puts err.message
      LogManager.log_ror_exception(err,"message")
    end
  end


  def claim_file_information_end(load_end_time, total_claim_count, total_svcline_count, file, failed_location)
    begin
      puts "Load End Time : #{load_end_time}"

      #Old Method Commented out
      #puts "Total Claim Count : #{@total_claim_count}"
      #puts "Total Service Line : #{@total_svcline_count}"

      puts "Total Claim Count : #{total_claim_count}"
      puts "Total Service Line : #{total_svcline_count}"
      puts "Loaded Claim Count : #{@loaded_claim_count}"
      puts "Loaded Service Line : #{@loaded_svcline_count}"
      status = (((total_claim_count.to_i + total_svcline_count.to_i) - (@loaded_claim_count.to_i + @loaded_svcline_count.to_i)).eql?(0) ? "SUCCESS" : "FAILURE")
      # puts "Status : #{status}"
      bill_print_date = get_bill_print_date

      unless @duplicate
        @claim_file_information.update_attributes(:deleted => 0, :status => status,:total_claim_count => total_claim_count,:loaded_claim_count => @loaded_claim_count,:total_svcline_count => total_svcline_count,
          :loaded_svcline_count => @loaded_svcline_count,:load_end_time => load_end_time,:facility_id => @claim_information.facility_id,:client_id => @client_id,:bill_print_date => bill_print_date)
        @claim_file_information.save!

        #Notify supervisors that file has been uploaded (with status)
        RevremitMailer.notify_claim_file_loaded(@claim_file_information.name, @claim_file_information.status, failed_location, $CNF['client_facility'], @loaded_claim_count, @loaded_svcline_count, @claim_file_information.zip_file_name, @claim_file_information.load_start_time.strftime("%m/%d/%y")).deliver
        system "mv #{file.gsub(".xml","")} #{failed_location}" if @claim_file_information.status == "FAILURE"

        #Notify supervisors if Billing Provider NPI is not matched for the given Facility
        if Client.find_by_name($CNF['client_name']).associate_claim_npi
          inactive_claim_records = @claim_file_information.claim_informations.where(:active => false).collect{|ci| [ci.patient_account_number, ci.billing_provider_npi, ci.billing_provider_organization_name]}
          if inactive_claim_records.present?
            RevremitMailer.notify_inactive_claims(File.basename(file).to_s, inactive_claim_records, @claim_file_information).deliver
          end
        end

        return status
      else
        #deleting to avoid the claim duplication
        @claim_file_information.destroy
        return "DUPLICATE"
      end

      @total_claim_count = 0
      @loaded_claim_count = 0
      @total_svcline_count = 0
      @loaded_svcline_count = 0


    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
      return "Exception"
    end
  end

  def find_facility_and_client
    stack_hash = Hash.new
    stack.each {|s|
      stack_hash["#{s[0]}"] = s[1]
    }

    facility_id = ''
    facility_id = Facility.find_by_name($CNF['facility_name']).id unless $CNF['facility_name'].blank?
    client_id = Client.find_by_name($CNF['client_name']).id unless $CNF['client_name'].blank?
    if facility_id.blank?
      if $CNF['client_name'].upcase == "NAVICURE"
        unless stack_hash['legacy_provider_no'].blank?
          facility_id = @navicure_facilities_hash[stack_hash['legacy_provider_number']] if @site_code_array.include?(stack_hash['legacy_provider_number'])
        end
      else
        if $CNF['facility_level']
          facility_id = @facility_npi_hash[@claim_information.billing_provider_npi]['facility_id'] unless @claim_information.billing_provider_npi.blank?
          facility_id = @facility_tin_hash[@claim_information.billing_provider_tin]['facility_id'] unless @claim_information.billing_provider_tin.blank?
        else
          facility_id = nil
        end
      end
    end
    return facility_id, client_id
  end

  def process_the_additional_claim facility_id, claim_adjudication_sequence, prev_claim_information_id
    @claim_information = ClaimInformation.new
    @total_claim_count += 1
    @claim_information.facility_id = facility_id
    @claim_information.client_id = @client_id
    @claim_information.claim_file_information_id = @claim_file_information.id
    bill_print_date = get_bill_print_date
    @claim_information.bill_print_date = bill_print_date
    @claim_information.claim_adjudication_sequence = claim_adjudication_sequence.to_s

    # Setting claim adjudication sequence value for previous claim to blank, that comes in same TS_837 tag
    ClaimInformation.find(prev_claim_information_id).update_attributes(:claim_adjudication_sequence => "") if prev_claim_information_id

    pos = 0
    reset_stack_data
    @provider_data = []
    @provider_infos = []
    @stack = @billing_provider_informations + @stack
    @stack.each do |data_point|
      pos += 1
      save_the_claim_informations_based_on_keys(data_point)
      if data_point[0].eql?("CLAIM_SERVICE")
        @provider_data << @provider_infos
        @provider_infos = []
        @claim_information.claim_service_informations << process_claim_service_information(pos)
        @provider_data << @provider_infos
        #set the claim end date to maximum service date of the claim
        # Rajesh, 14 Dec 2012, Added '.select(&:service_to_date)' as fix for #23577
        claim_service_informations = @claim_information.claim_service_informations
        unless claim_service_informations.blank?
          sorted_service_to_dates = claim_service_informations.select(&:service_to_date).sort_by(&:service_to_date)
          @claim_information.claim_end_date = sorted_service_to_dates.last.service_to_date.to_formatted_s(:db) unless sorted_service_to_dates.blank?
          sorted_service_from_dates = claim_service_informations.select(&:service_from_date).sort_by(&:service_from_date)
          @claim_information.claim_start_date = sorted_service_from_dates.first.service_from_date.to_formatted_s(:db) unless sorted_service_from_dates.blank?
        end
      end
     end
    process_provider_details @provider_data
    set_patient_details

    unless @claim_information.patient_account_number.blank?
      # Set claim id hash for claim identification rake task
      set_claim_id_hash true
      @claim_information.active = true
      update_facility_id if @map_claim_on_npi

      if @claim_information.save!
        @loaded_claim_count +=1
      end
    end
    @qlf_plan_code = false
  end

  def set_patient_details
    if @claim_information.patient_last_name.blank?
      @claim_information["patient_last_name"] = @claim_information.subscriber_last_name
      @claim_information["patient_first_name"] = @claim_information.subscriber_first_name
      @claim_information["patient_middle_initial"] = @claim_information.subscriber_middle_initial
      @claim_information["patient_suffix"] = @claim_information.subscriber_suffix
    end
  end

  def reset_stack_data
    container_hash = {}
    @stack.each_with_index do |element, index|
      if container_hash.keys.include? element.first
        @stack[index] = nil unless @static_data_points.include? element.first
      end
      container_hash[element.first] = 0
    end
    @stack = @stack.compact
  end

  def get_bill_print_date
    date_value = Date.parse(@interchange_date)
    bill_print_date = date_value.to_s + " " + @file_interchange_time

    bill_print_date.to_s
  end


  # This method processes the claims.
  def process_claim
    begin
      @claim_file_information.update_attributes(:facility_id => @claim_information.facility_id)
      @claim_file_information.save!
      @claim_information.claim_file_information_id = @claim_file_information.id
      bill_print_date = get_bill_print_date
      @claim_information.bill_print_date = bill_print_date

      @stack.each do |c|
        return @claim_information if c[0].eql?("CLAIM_SERVICE")
        save_the_claim_informations_based_on_keys(c)
      end

      return @claim_information #Return stack doesn't contain CLAIM_SERVICE
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
    end
  end


  def process_claim_service_information(position)
    begin
      clm_items = ClaimServiceInformation.new
      pos = position
      @total_svcline_count +=1
      @loaded_svcline_count += 1
      if !@service_from_date.blank? && !@service_to_date.blank?
        clm_items["service_from_date"] = @service_from_date
        clm_items["service_to_date"] = @service_to_date
      end
      @tooth_code = nil
      for i in pos..@stack.length-1

        if @stack[i][0] == "tooth_number"
          stack_content = @stack[i][1].split(":")
          @stack[i][1] = stack_content.first if stack_content.length > 1
          if @tooth_code
            @tooth_code << "," + @stack[i][1]
          else
            @tooth_code = @stack[i][1]
          end
        elsif @stack[i][0] == "tooth_surface"
          @tooth_code << ":" + @stack[i][1]
        end

        if @stack[i][0].eql?("CLAIM_SERVICE")
          clm_items["tooth_code"] = @tooth_code
          @tooth_code = nil
          set_service_id_hash clm_items
          return clm_items
        elsif @stack[i][0] == "tooth_surface" or @stack[i][0] == "tooth_number"
          clm_items["tooth_code"] = @tooth_code
        end
        if @svc_provider_details.include? @stack[i][0]
           @provider_infos << [@stack[i][0], @stack[i][1]]
        end

        pos +=1

        if @stack[i][0] == "date_qualifier"
          @date_qualifier = @stack[i][1]
        elsif @stack[i][0] == "service_from_date"
          process_service_start_and_end_dates(@stack[i],@date_qualifier) unless @date_qualifier.blank?
        end

        clm_items[@stack[i][0]] = @stack[i][1]
        if !clm_items["service_from_date"].nil? && clm_items["service_to_date"].nil?
          clm_items["service_to_date"] = @service_to_date
        end
        clm_items.service_from_date = @claim_information.claim_statement_period_start_date unless clm_items.service_from_date
        clm_items.service_to_date = @claim_information.claim_statement_period_end_date unless clm_items.service_to_date
      end
      set_service_id_hash clm_items
      if !@service_from_date.blank? && !@service_to_date.blank?
        clm_items["service_from_date"] = @service_from_date
        clm_items["service_to_date"] = @service_to_date
      end
      return clm_items
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
      raise err
    end
  end

  def get_claim_status(s_time,e_time,file)
    claim_status = Hash.new
    claim_status['load start time'] = s_time
    claim_status['file_name'] = file
    claim_status['load end time'] = e_time
    claim_status
  end

  def save_the_claim_informations_based_on_keys(c)
    if c[0] == "subscriber_last_name"
      process_subscriber_and_patient_last_name(c)
    elsif c[0] == "subscriber_first_name"
      process_subscriber_and_patient_first_name(c)
    elsif c[0] == "subscriber_middle_initial"
      process_subscriber_and_patient_middle_initial(c)
    elsif c[0] == "subscriber_suffix"
      process_subscriber_and_patient_suffix(c)
    elsif c[0] == "patient_last_name"
      process_patient_last_name(c)
    elsif c[0] == "patient_first_name"
      process_patient_first_name(c)
    elsif c[0] == "npi_tin_qualifier_85"
      @npi_tin_qualifier_85 = c[1]
    elsif c[0] == "npi_tin_85"
      process_tin_npi(c, "npi_tin_85", @npi_tin_qualifier_85)
    elsif c[0] == "npi_tin_qualifier_82"
      @npi_tin_qualifier_82 = c[1]
    elsif c[0] == "payid"
      process_payid(c)
    elsif c[0] == "npi_tin_82"
      process_tin_npi(c, "npi_tin_82", @npi_tin_qualifier_82)
    elsif c[0] == "payee_address_one"
      process_payee_address_one_and_business_unit_indicator(c)
    elsif c[0] == "npi_tin_qualifier_71"
      @npi_tin_qualifier_71 = c[1]
    elsif c[0] == "npi_tin_71"
      process_tin_npi(c, "npi_tin_71", @npi_tin_qualifier_71)
    elsif c[0] == "npi_tin_qualifier_FA"
      @npi_tin_qualifier_FA = c[1]
    elsif c[0] == "npi_tin_FA"
      process_tin_npi(c, "npi_tin_FA", @npi_tin_qualifier_FA)
    elsif c[0] == "date_qualifier"
      @date_qualifier = c[1]
    elsif c[0] == "service_from_date"
      process_service_start_and_end_dates(c, @date_qualifier) unless @date_qualifier.blank?
    elsif c[0] == "claim_date_qualifier"
      @claim_date_qualifier = c[1]
    elsif c[0] == "claim_service_from_date"
      process_claim_start_and_end_dates(c,@claim_date_qualifier) unless @claim_date_qualifier.blank?
    elsif c[0] == "plan_code"
      process_plan_code(c)
    elsif c[0] == "reference_identification_code_ei"
      @reference_identification_code = c[1]
    elsif c[0] == "reference_identification_code_f8"
      @reference_identification_code = c[1]
    elsif c[0] == "reference_identification_code_lu"
      @reference_identification_code = c[1]
    elsif c[0] == "employers_identification_number"
      process_reference_identification_code(c,@reference_identification_code)
    elsif c[0] == "payer_claim_original_reference_number"
      process_reference_identification_code(c,@reference_identification_code)
    elsif c[0] == "legacy_provider_number"
      process_reference_identification_code(c,@reference_identification_code)
    elsif c[0] == "date_time_period_format_qualifier"
      @date_time_period_format_qualifier = c[1]
    elsif c[0] == "facility_type_code"
      @claim_information["facility_type_code"] = c[1]
      identify_patient_type(c[1], @claim_file_information.claim_file_type)
    else
      @claim_information[c[0]] = c[1]
    end
  end

  def identify_patient_type patient_type_info, claim_file_type_info
    if claim_file_type_info == "837I"
      patient_type_info = patient_type_info.split("")
      if patient_type_info[1] == "1"
        patient_type_data = "INPATIENT"
      elsif patient_type_info[1] == "3"
        patient_type_data = "OUTPATIENT"
      end
    else
      if @ip_patient_infos.include? patient_type_info
        patient_type_data = "INPATIENT"
      elsif @op_patient_infos.include? patient_type_info
        patient_type_data = "OUTPATIENT"
      end
    end
    @claim_information["patient_type"] = patient_type_data
  end

  def process_subscriber_and_patient_last_name(c)
    @claim_information["patient_last_name"] = c[1] unless @is_group8
    @claim_information["subscriber_last_name"] = c[1]
  end

  def process_subscriber_and_patient_first_name(c)
    @claim_information["patient_first_name"] = c[1] unless @is_group8
    @claim_information["subscriber_first_name"] = c[1]
  end

  def process_subscriber_and_patient_middle_initial(c)
    @claim_information["patient_middle_initial"] = c[1] unless @is_group8
    @claim_information["subscriber_middle_initial"] = c[1]
  end

  def process_subscriber_and_patient_suffix(c)
    @claim_information["patient_suffix"] = c[1] unless @is_group8
    @claim_information["subscriber_suffix"] = c[1]
  end

  def process_patient_last_name(c)
    @claim_information["patient_last_name"] = c[1]
  end

  def process_patient_first_name(c)
    @claim_information["patient_first_name"] = c[1]
  end

  def process_payid(c)
    @claim_information["payid"] = c[1]
  end

  def process_tin_npi(c, npi_tin_qualifier, npi_tin_qualifier_value)
    if npi_tin_qualifier == "npi_tin_85"
      # billing provider tin and billing provider npi extraction
      if npi_tin_qualifier_value == "24" or npi_tin_qualifier_value == "34" or npi_tin_qualifier_value == "FI"
        @claim_information["billing_provider_tin"] = c[1]
      else
        @claim_information["billing_provider_npi"] = c[1]
      end
    elsif npi_tin_qualifier == "npi_tin_82" || npi_tin_qualifier == "svc_npi_tin_82"
      # rendering provider tin and rendering provider npi extraction
      if npi_tin_qualifier_value == "24" or npi_tin_qualifier_value == "34" or npi_tin_qualifier_value == "FI"
        @claim_information["provider_ein"] = c[1]
      else
        @claim_information["provider_npi"] = c[1]
      end
    elsif npi_tin_qualifier == "npi_tin_71"
      if npi_tin_qualifier_value == "24" or npi_tin_qualifier_value == "34" or npi_tin_qualifier_value == "FI"
        @claim_information["provider_ein"] = c[1]
      else
        @claim_information["provider_npi"] = c[1]
      end
    elsif  npi_tin_qualifier == "npi_tin_FA"
      if npi_tin_qualifier_value == "24" or npi_tin_qualifier_value == "34" or npi_tin_qualifier_value == "FI"
        @claim_information["payee_tin"] = c[1]
      else
        @claim_information["payee_npi"] = c[1]
      end
    end
  end

  def process_payee_address_one_and_business_unit_indicator(c)
    @claim_information["payee_address_one"] = c[1]
    @claim_information["business_unit_indicator"] = c[1].split.first.slice(0,3).to_i rescue nil
  end

  def process_reference_identification_code(c,reference_identification_code)
    if reference_identification_code == "EI"
      @claim_information["employers_identification_number"] = c[1]
      @claim_information["billing_provider_tin"] = c[1]
      @claim_information["provider_ein"] = c[1]
    elsif reference_identification_code == "SY"
      @claim_information["social_security_number"] = c[1]
    elsif reference_identification_code == "F8"
      @claim_information["payer_claim_original_reference_number"] = c[1]
    elsif reference_identification_code == "D9"
      @claim_information["xpeditor_document_number"] = c[1]
    elsif reference_identification_code == "EA"
      @claim_information["medical_record_number"] = c[1]
    elsif reference_identification_code == "LU"
      @claim_information["legacy_provider_number"] = c[1]
    end
  end

#  def process_claim_start_and_end_dates(c,date_qualifier)
#    if date_qualifier == "435"
#      @claim_information["claim_statement_period_start_date"] = c[1]
#    elsif date_qualifier == "096"
#      @claim_information["claim_statement_period_end_date"] = c[1]
#    end
#  end

  def process_claim_start_and_end_dates(c,date_qualifier)
    if date_qualifier == "434" or date_qualifier == "472"
      service_dates = c[1].split("-")
      @claim_information["claim_statement_period_start_date"] = service_dates[0].to_s if @claim_information.claim_statement_period_start_date.nil?
      @claim_information["claim_statement_period_end_date"] = service_dates.length == 2 ? service_dates[1].to_s : service_dates[0].to_s if @claim_information.claim_statement_period_end_date.nil?
    elsif date_qualifier == "435" or date_qualifier == "096"
      if date_qualifier == "435"
        @claim_information["claim_statement_period_start_date"] = c[1] if @claim_information.claim_statement_period_start_date.nil?
        @service_from_date = @claim_information.claim_statement_period_start_date
      else
        @claim_information["claim_statement_period_end_date"] = c[1] if @claim_information.claim_statement_period_end_date.nil?
        @service_to_date = @claim_information.claim_statement_period_end_date
      end
    end
  end


  def process_service_start_and_end_dates(c,date_qualifier)
      if date_qualifier == "472" or date_qualifier == "434"
        service_dates = c[1].split("-")
        @service_from_date = service_dates[0].to_s
        @service_to_date = service_dates.length == 2 ? service_dates[1].to_s : service_dates[0].to_s
      end
  end

  def process_plan_code(c)
    if c[1].include? "|||"
      plan_code ||= c[1].split("|||").first
      @claim_information["plan_code"] = plan_code
    elsif c[1].include? "||"
      plan_code = c[1].split("||").first.split("|")
      if plan_code.length > 2
        if @claim_information["claim_type"] == "P"
          @claim_information["plan_code"] = plan_code[0]
        elsif @claim_information["claim_type"] == "S"
          @claim_information["plan_code"] = plan_code[1]
        elsif @claim_information["claim_type"] == "T"
          @claim_information["plan_code"] = plan_code[2]
        end
      else
        if @plan_code_counter == 0
          @claim_information["plan_code"] = plan_code[1]
        elsif @plan_code_counter == 1
          @claim_information["plan_code"] = plan_code[0]
        end
      end
    end
    @plan_code_counter += 1
  end

  def store_the_claim_file_type(c)
    c.each do |element|
      case element[0]
      when "GS08"
        save_the_file_type(element[1])
      when "bill_print_date"
        save_bill_print_date(element[1])
      when "ISA09"
        unless element[1].blank?
          @interchange_date = element[1].to_s
          file_interchange_date = Date.parse(@interchange_date).strftime("%Y-%m-%d")
          @claim_file_information.update_attributes(:file_interchange_date => file_interchange_date)
        end
      when "ISA10"
        unless element[1].blank?
          @interchange_time = element[1].to_s
          @file_interchange_time = "#{@interchange_time[0]}#{@interchange_time[1]}:#{@interchange_time[2]}#{@interchange_time[3]}:00.00"
          @claim_file_information.update_attributes(:file_interchange_time => @file_interchange_time)
        end
      end
    end
  end

  def save_the_file_type(data)
    case data.strip
    when "004010X096A1", "005010X223A2"
      claim_file_type = "837I"
    when "004010X098A1", "005010X222A1"
      claim_file_type = "837P"
    when "004010X097A1", "005010X224A2"
      claim_file_type = "837D"
    else
      claim_file_type = "837"
    end

    @claim_file_information.update_attributes(:claim_file_type => claim_file_type.upcase)
  end

  def save_bill_print_date(data)
    @claim_file_information.update_attributes(:bill_print_date => data)
  end

  # Set facility id for claims based on Billing Provider NPI
  def update_facility_id
    if @claim_information.billing_provider_npi && @facility_npi_hash[@claim_information.billing_provider_npi]
      @claim_information.facility_id = @facility_npi_hash[@claim_information.billing_provider_npi][:facility_id]
      @claim_information.active = @claim_information.facility_id?
    elsif @claim_information.facility_id.nil?
      @claim_information.active = false
    end
  end

end
