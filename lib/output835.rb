class Hash
  #-----------------------------------------------------------------------------
  # Description : This method converts a hash into a string of hash values each is
  #               seperated by '*'.
  # Input       : hash
  # Output      : string
  #-----------------------------------------------------------------------------
  def segmentize
    self.keys.sort.collect { |k| self[k] }.flatten.compact
  end

  #-----------------------------------------------------------------------------
  # Description : This method is to convert string keys of a hash into integer
  #               keys.
  # Input       : hash
  # Output      : hash
  #-----------------------------------------------------------------------------
  def convert_keys
    result = Hash.new
    self.each{|k,v| result[k.to_i] = v}
    result
  end

end

class String

  def left_padd(total_length, length_to_padd, char)
    unless self.blank?
      padd_length = total_length - self.length
      if padd_length >= length_to_padd
        (char * length_to_padd + self).ljust(15)
      else
        char * padd_length + self
      end
    else
      ""
    end
  end
  #-----------------------------------------------------------------------------
  # Description : This method is for justifiying a string.
  # Input       : String object
  # Output      : String object
  #-----------------------------------------------------------------------------
  def justify(size, character = nil)
    if self.blank?
      ""
    elsif self.length > size
      self[0...size]
    elsif character
      self.rjust(size,character)
    else
      self.ljust(size)
    end
  end

  def to_dollar
    unless self.to_f.zero?
      "%.2f" % self rescue "0"
    else
      '0'
    end
  end

  def to_blank
    self == '0' ? '' : self
  end

  def snakecase
    self.downcase.gsub(' ', '_')
  end

end



class Array

  #-----------------------------------------------------------------------------
  # Description : This method is for converting array elements into string
  # Input       :
  # Output      : converted array
  #-----------------------------------------------------------------------------
  def to_string
    self.collect{|elem| elem.to_s}
  end

  def trim_segment
    while self.last.blank?
      self.pop
    end
    self.collect {|element| element.to_s.strip}
  end

end

class Float
  #-----------------------------------------------------------------------------
  # Description : This method is for truncating trailing zeroes from decimal
  #               part of amount
  # Input       :
  # Output      : converted array
  #-----------------------------------------------------------------------------
  def to_amount
    truncated_amount = self.truncate
    (self == truncated_amount ? truncated_amount : self)
  end

  def to_amount_for_clp
    truncated_amount = self.truncate
    (self == truncated_amount ? truncated_amount :
        (self.to_s.split(".").last.size == 1 ? self : ("%.2f" % self).to_s.chomp('0').to_f))
  end

end

module Output835
  require 'adjustment_reason'
  include AdjustmentReason
  require 'logger'

  #Checksif there's a custom class to be applied for a given organization
  #organization can be facility/client/partner
  #searches for custom class in that order.
  #Where there's no custom class, returns the base class
  def self.class_for(type, organization = nil,config = nil)
    detect_class(type, organization) ||
      detect_class(type, organization.index_file_parser_type) ||
      detect_class(type, organization.client) ||
      detect_class(type, organization.client.partner) ||
      "Output835::#{type}".constantize
  end

  def self.find_class facility, class_type, facility_config = nil
    if !facility_config.blank? and facility_config.details[:configurable_835]
      if class_type == "single"
        "Output835::ConfigSingleStTemplate".constantize  rescue nil
      else
        "Output835::ConfigTemplate".constantize
      end
    else
      client_name = facility.client.name.downcase.gsub("'", "")
      facility_name = facility.name.gsub("-","_")
      class_name(facility_name.to_file, class_type) || class_name(client_name.to_file, class_type) || "Output835::Template".constantize
    end
  end

  def self.class_name type, class_type
    type = type.camelize
    if class_type == "single"
      "Output835::#{type}SingleStTemplate".constantize  rescue nil
    else
      "Output835::#{type}Template".constantize  rescue nil
    end
  end

  def self.detect_class(type, organization)
    "Output835::#{name_for(type,organization)}".constantize if organization rescue nil
  end

  #Takes in the facility/client/partner name and the type of 835 subclass
  #and returns the name of the custom class for that organization
  #ex: organization = 'HLSC' and Type = 'Check'
  #returns 'HlscCheck'
  def self.name_for(type,organization)
    name = (organization.class == String ? organization : organization.name)
    name = 'SHEPHERD EYE SURGICENTER' if name == 'SHEPHERD EYE CENTER'
    custom_class_for_facility = name.downcase.gsub(' ','_').camelize
    "#{custom_class_for_facility}#{type}"
  end

  def self.log
    require 'utils/rr_logger'
    return RevRemitLogger.new_logger(LogLocation::OP835LOG)
    #Logger.new('output_logs/835Generation.log', 'daily')
  end

  def self.oplog_log
    require 'utils/rr_logger'
    return RevRemitLogger.new_logger(LogLocation::OPERATIONLOG)
  end

  # Removes the trailing blank elements from an array
  def self.trim_segment(array)
    while array.last.blank?
      array.pop
    end
    array.collect {|element| (element.class == String) ? element.strip : element}
  end

  def self.remove_blank(array)
    while array.last.blank?
      array.pop
    end
    array
  end

  # Returns whether particular element has been duplicated in an array
  def self.element_duplicates?(elem, array)
    first_occurrence = array.index(elem)
    last_occurrence = array.rindex(elem)
    first_occurrence != last_occurrence
  end

  # Returns an array of all the indexes where an element is found, in the given array
  def self.all_indices(elem, array)
    indices = []
    array.each_with_index do |element, index|
      (indices << index) if element == elem
    end
    indices
  end

  # return the occurnece of elemnet in the array passed
  def self.all_occurence(element, array)
    occurence = []
    i=0
    array.each do |ele|
      if (ele== element)
        occurence <<  i+=1
      else
        occurence << 0
      end
    end
    occurence
  end

  def self.get_adjustment_code_elements(entity, client, facility, payer, ins_eob = nil)
    @client = client
    @facility = facility
    log.info 'Printing CAS Adjustment Segments'

    @cas_01_config = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    @cas_02_config = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    log.info "CAS 01 is configured in FC to contain : #{@cas_01_config}"
    log.info "CAS 02 is configured in FC to contain : #{@cas_02_config}"
    @reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, entity, client, facility)
    @is_partner_bac = $IS_PARTNER_BAC
    associated_codes_for_adjustment_elements = adjustment_reason_elements
    cas_pr_elements, cas_elements = [], []
    patient_responsibility_amount = 0

    @remark_codes = []
    @code_187_found = false
    @count = -1
    associated_codes_for_adjustment_elements.each do |adjustment_reason|
      parameters = {}
      parameters[:entity] = entity
      parameters[:client] = client
      parameters[:facility] = facility
      parameters[:payer] = payer
      parameters[:cas_01_config] = @cas_01_config
      parameters[:cas_02_config] = @cas_02_config
      parameters[:adjustment_reason] = adjustment_reason
      array_of_cas_segments, parameters = cas_elements(parameters, ins_eob)
      break if @code_187_found
      array_of_cas_segments.each do |cas_segment_array|
        cas_element_array, cas_pr_element_array, pr_amount = get_cas_segments(adjustment_reason, payer, cas_segment_array)
        cas_elements << cas_element_array if cas_element_array.present?
        cas_pr_elements << cas_pr_element_array if cas_pr_element_array.present?
        patient_responsibility_amount += pr_amount.to_f
      end
    end
    return cas_elements, cas_pr_elements, patient_responsibility_amount
  end

  # Returns the CAS adjustment segments for all adjustment reasons.
  #
  # Input :
  # entity : This can be an object of ServicePaymentEob for service level EOBs or
  #  InsurancePaymentEob for claim level EOBs.
  # client : Client object of the claim in process.
  # facility : Facility object of the claim in process.
  # payer : Payer object of the claim in process.
  # element_seperator : The separater used in between the segment data elements.
  #
  # Output :
  # cas_segments : The complete CAS segemnts in a service line for
  #   all adjustment reasons.
  # patient_responsibility_amount : Total amount of patient responsibility(PR)adjustment fields
  #   This needs to be printed in CLP05 segment.
  #   crosswalked_codes_in_all_adjustment_reasons : A hash containing the remark_codes for now. \
  #   This has to be expanded for all the crosswalk codes for LQHE segment.
  #
  # Invokes the following methods :
  # adjustment_reason_elements in InsurancePaymentEob & ServicePaymentEob.
  # Output835.cas_elements : provides the data elemets for
  #   the CAS segment of each adjustment reason.
  # Output835.get_pr_cas_elements : provides the cas elements of PR fields
  # Output835.combined_cas_segments : Provides the CAS segments when the
  #   configuration for CAS to be printed as a combined segment
  # Output835.separate_cas_segments : Provides the CAS segments when the
  #   configuration for CAS to be printed as a separate expanded segment
  #
  # pr_elements is an array of data elements for Patient Responsibility CAS segment.
  def self.cas_adjustment_segments(entity, client, facility, payer, element_seperator, ins_eob = nil, batch = nil, check = nil)

    cas_elements, cas_pr_elements, patient_responsibility_amount = get_adjustment_code_elements(entity, client, facility, payer, ins_eob)
    cas_segments = []
    crosswalked_codes_in_all_adjustment_reasons = {}
    if @code_187_found
      cas_segments =  ["CAS*CO*187*0"]
    else
      if !cas_elements.blank? || !cas_pr_elements.blank?
        if facility.details[:combine_cas_segment]
          cas_elements = cas_elements + cas_pr_elements
          cas_segments = combined_cas_segments(cas_elements, element_seperator)
        else
          cas_segments, grouped_elements_with_crosswalk_flag = separate_cas_segments(cas_elements, cas_pr_elements.compact, element_seperator)
        end
      end

      crosswalked_codes_in_all_adjustment_reasons[:remark_codes] = @remark_codes
      cas_segments.each_with_index do |segment, index|
        if @cas_02_config == 'hipaa_code' && !(/\*CO\*137\*/.match(segment)).blank?
          cas_segments[index] = segment + '*1'
        end
      end
      if @facility.details[:patpay_statement_fields] and payer.payer_type == 'PatPay' &&
          ins_eob.statement_receiver.upcase == 'HOSPITAL' && ins_eob.payee_type_format == 'A'
        cas_segments = patpay_statement_cas(batch, check, ins_eob, entity)
      end
    end
    return cas_segments, patient_responsibility_amount, crosswalked_codes_in_all_adjustment_reasons
  end

  def self.order_cas_segments(cas_segments)
    segments = []
    if cas_segments.present?
      cas_segments.each do |elements|
        if elements.class == Array
          segment = elements[0]
          count = elements[1]
          if count.present?
            segments[count] = segment
          else
            segments << segment
          end
        else
          segments << elements
        end
      end
    end
    segments.compact
  end

  def self.order_grouped_elements(grouped_elements_with_crosswalk_flag)
    segments = []
    if grouped_elements_with_crosswalk_flag.present?
      grouped_elements_with_crosswalk_flag.each do |elements|
        count = elements[4]
        if count.present?
          segments[count] = elements
        else
          segments << elements
        end
      end
    end
    segments.compact
  end

  # Returns the three data elements for the CAS segment.
  #
  # Input :
  # parameters : A hash containing the below parameters.
  # entity : This can be an object of ServicePaymentEob for service level EOBs or
  #  InsurancePaymentEob for claim level EOBs.
  # facility : Facility object of the claim in process.
  # payer : Payer object of the claim in process.
  # cas_01_config : The config for what needs to be printed in CAS01.
  # cas_02_config : The config for what needs to be printed in CAS02.
  # adjustment_reason : The name of dollar amount fields like discount, etc.
  #
  # Output:
  # amount : Dollar amount of the adjustment reason.
  # cas_01_code : Code to be printed in CAS01 segment.
  # cas_02_code : Code to be printed in CAS02 segment.
  # parameters
  #
  # Invokes the following methods :
  # amount_field_for_adjustment_reason in InsurancePaymentEob & ServicePaymentEob
  #   provides the DB column name for the adjustment reason amoount field.
  # amount in InsurancePaymentEob & ServicePaymentEob
  #   provides the value for the adjustment reason amoount field.
  # associated_codes_for_adjustment_reason in InsurancePaymentEob & ServicePaymentEob
  #   provides the associated codes wrt the level of mapping and FC configs.
  def self.cas_elements(parameters = {}, insurance_eob)
    orphan_adjustment_code_condition = parameters[:entity].is_orphan_adjustment_code?(@facility, parameters[:adjustment_reason])
    amount = get_amount(parameters, orphan_adjustment_code_condition)
    array_of_cas_segments = []
    if !amount.blank?
      crosswalked_codes = @reason_code_crosswalk.get_crosswalked_codes_for_adjustment_reason(parameters[:adjustment_reason])
      log.info "CAS01 contains : #{parameters[:cas_01_config]}"
      log.info "CAS02 contains : #{parameters[:cas_02_config]}"
      log.info "is reason code crosswalked condition : #{crosswalked_codes[:is_reason_code_crosswalked]}"

      # Crosswalked codes should come before the default codes

      params = { :amount => amount,
        :crosswalked_codes => crosswalked_codes, :parameters => parameters,
        :orphan_adjustment_code_condition => orphan_adjustment_code_condition,
        :insurance_eob => insurance_eob }
      codes_from_reason_code(array_of_cas_segments, params)
    end
    return array_of_cas_segments, parameters
  end

  def self.get_amount(parameters, orphan_adjustment_code_condition)
    log.info "orphan adjustment code condition : #{orphan_adjustment_code_condition}"
    amount = parameters[:entity].send("#{parameters[:adjustment_reason]}_amount")
    if orphan_adjustment_code_condition
      amount = 0
    end
    amount
  end

  def self.codes_from_reason_code(array_of_cas_segments, params = {})
    amount = params[:amount]
    crosswalked_codes = params[:crosswalked_codes]
    parameters = params[:parameters]
    insurance_eob = params[:insurance_eob]
    orphan_adjustment_code_condition = params[:orphan_adjustment_code_condition]
    cas_01_code, cas_02_code = nil, nil
    cas_01_code = cas_01_element(crosswalked_codes)
    cas_02_code = cas_02_element(crosswalked_codes)
    secondary_cas_02_code = secondary_cas_02_element(crosswalked_codes)
    secondary_cas_01_code = secondary_cas_01_element(crosswalked_codes)

    condition_for_denial = condition_for_denial_with_zero_amount(insurance_eob, parameters[:entity])
    log.info "condition for denial : #{condition_for_denial}"
    presence_of_code_187(cas_02_code)

    code_params = { :cas_01_code => cas_01_code, :secondary_cas_01_code => secondary_cas_01_code,
      :cas_02_code => cas_02_code, :secondary_cas_02_code => secondary_cas_02_code,
      :amount => amount, :crosswalked_codes => crosswalked_codes,
      :condition_for_denial => condition_for_denial,
      :orphan_adjustment_code_condition => orphan_adjustment_code_condition }
    if secondary_cas_02_code.present? && secondary_cas_01_code.present?
      print_secondary_cas_related_codes(array_of_cas_segments, code_params)
    else
      print_non_secondary_cas_related_codes(array_of_cas_segments, parameters, code_params)
    end
    log.info "#{parameters[:adjustment_reason]} amount : #{amount},
        CAS01 code : #{cas_01_code}, CAS02 code : #{cas_02_code}, secondary CAS02 code : #{secondary_cas_02_code}"

    @remark_codes << crosswalked_codes[:remark_codes] if !crosswalked_codes[:remark_codes].blank?

    array_of_cas_segments
  end

  def self.presence_of_code_187(cas_02_code)
    if @facility.details[:hra_processing] && cas_02_code == '187'
      @code_187_found = true
      log.info "HIPAA Code 187 is found"
    end
  end

  def self.codes_from_secondary_reason_codes(array_of_cas_segments, amount, crosswalked_codes, parameters)
    if crosswalked_codes[:secondary_codes].present?
      crosswalked_codes[:secondary_codes].each do |secondary_code_hash|
        @count += 1
        if secondary_code_hash[:cas_01].present? && secondary_code_hash[:cas_02].present? &&
            secondary_code_hash[:is_reason_code_crosswalked]
          array_of_cas_segments << [secondary_code_hash[:cas_01], secondary_code_hash[:cas_02],
            0, secondary_code_hash[:is_reason_code_crosswalked], @count]
        end
      end
    end
  end

  def self.print_secondary_cas_related_codes(array_of_cas_segments, code_params = {})
    cas_01_code = code_params[:cas_01_code]
    cas_02_code = code_params[:cas_02_code]
    secondary_cas_01_code = code_params[:secondary_cas_01_code]
    secondary_cas_02_code = code_params[:secondary_cas_02_code]
    amount = code_params[:amount]
    crosswalked_codes = code_params[:crosswalked_codes]
    condition_for_denial = code_params[:condition_for_denial]
    orphan_adjustment_code_condition = code_params[:orphan_adjustment_code_condition]
    @count += 1
    array_of_cas_segments << [cas_01_code, cas_02_code, 0, crosswalked_codes[:is_reason_code_crosswalked], @count]
    codes_from_secondary_reason_codes(array_of_cas_segments, amount, crosswalked_codes, code_params)
    if !condition_for_denial && !orphan_adjustment_code_condition
      log.info "Printing secondary codes"
      @count += 1
      array_of_cas_segments << [secondary_cas_01_code, secondary_cas_02_code, amount, false, @count]
    end
    array_of_cas_segments
  end

  def self.print_non_secondary_cas_related_codes(array_of_cas_segments, parameters = {}, code_params = {})
    cas_01_code = code_params[:cas_01_code]
    cas_02_code = code_params[:cas_02_code]
    amount = code_params[:amount]
    crosswalked_codes = code_params[:crosswalked_codes]
    condition_for_denial = code_params[:condition_for_denial]
    orphan_adjustment_code_condition = code_params[:orphan_adjustment_code_condition]
    if (!orphan_adjustment_code_condition && !condition_for_denial) ||
        (orphan_adjustment_code_condition && crosswalked_codes[:is_crosswalked])
      log.info "Printing single cas segments, with no secondary"
      @count += 1
      array_of_cas_segments << [cas_01_code, cas_02_code,
        set_adjustment_amount(amount, parameters, crosswalked_codes), crosswalked_codes[:is_reason_code_crosswalked], @count]
      codes_from_secondary_reason_codes(array_of_cas_segments, amount, crosswalked_codes, parameters)
    end
  end

  def self.condition_for_denial_with_zero_amount(insurance_eob, entity)
    if @facility.details[:cas_segments_for_denial_with_zero_amount] && entity

      claim_amount_condition = insurance_eob && insurance_eob.total_amount_paid_for_claim.to_f.zero? &&
        insurance_eob.total_submitted_charge_for_claim.to_f > 0
      entity_amount_condition = entity.paid_amount.to_f.zero? && entity.submitted_charge_amount.to_f > 0
      entity_charge_amount_in_one_of_adjustments =
        (entity.coinsurance_amount.to_f.round(2) == entity.submitted_charge_amount.to_f.round(2) ||
          entity.discount_amount.to_f.round(2) == entity.submitted_charge_amount.to_f.round(2) ||
          entity.noncovered_amount.to_f.round(2) == entity.submitted_charge_amount.to_f.round(2))
      found_atleast_one_adjustment_code = false
      adjustment_reason_elements.each do |adjustment_reason_element|
        if entity.send("#{adjustment_reason_element}_reason_code_id").present? ||
            entity.send("#{adjustment_reason_element}_hipaa_code_id").present?
          found_atleast_one_adjustment_code = true
          break
        end
      end

      claim_amount_condition && entity_amount_condition &&
        entity_charge_amount_in_one_of_adjustments && found_atleast_one_adjustment_code
    end
  end

  def self.set_adjustment_amount(amount, parameters, crosswalked_codes = {})
    if @client.name.upcase.eql?("UNIVERSITY OF PITTSBURGH MEDICAL CENTER") &&
        ['miscellaneous_one', 'miscellaneous_two'].include?(parameters[:adjustment_reason])
      crosswalked_codes[:is_crosswalked].blank? ? amount : 0
    else
      amount
    end
  end

  # Provides CAS01 element.
  #
  # Input :
  # crosswalked_codes : A hash containing all codes for the reasoncode.
  # Output :
  # cas_01_element : CAS01 element
  def self.cas_01_element(crosswalked_codes)
    cas_01_element = crosswalked_codes[:cas_01]
    log.info "cas_01_element is #{cas_01_element}"
    cas_01_element
  end

  # Provides CAS02 element.
  #
  # Input :
  # crosswalked_codes : A hash containing all codes for the reasoncode.
  # parameters : A hash containing the below parameters.
  # Output :
  # cas_02_code and parameters
  def self.cas_02_element(crosswalked_codes)
    cas_02_code = crosswalked_codes[:cas_02]
    log.info "cas_02_element is #{cas_02_code}"
    cas_02_code
  end

  def self.secondary_cas_01_element(crosswalked_codes)
    secondary_cas_01_code = crosswalked_codes[:secondary_cas_01]
    log.info "secondary_cas_01_code is #{secondary_cas_01_code}"
    secondary_cas_01_code
  end

  def self.secondary_cas_02_element(crosswalked_codes)
    secondary_cas_02_code = crosswalked_codes[:secondary_cas_02]
    log.info "secondary_cas_02_code is #{secondary_cas_02_code}"
    secondary_cas_02_code
  end

  def self.get_cas_segments(adjustment_reason, payer, cas_segment_array)
    cas_01_code = cas_segment_array[0]
    cas_02_code = cas_segment_array[1]
    amount = cas_segment_array[2]
    is_crosswalked = cas_segment_array[3]
    count = cas_segment_array[4]
    cas_elements_array, cas_pr_elements_array = [], []
    if !cas_01_code.blank? && !cas_02_code.blank? && !amount.blank?
      cas_elements = [cas_01_code, cas_02_code, amount, is_crosswalked, count]
      if cas_01_code == 'PR' && payer && payer.payer_type != 'PatPay'
        patient_responsibility_amount = amount.to_f
      end
      if pr_adjustment_reason_elements.include?(adjustment_reason) && @client.name != "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
        pr_elements = get_pr_cas_elements(adjustment_reason, cas_elements)
      else
        cas_elements_array = cas_elements
      end
      cas_pr_elements_array = pr_elements if pr_elements.present?
    end
    return cas_elements_array, cas_pr_elements_array, patient_responsibility_amount
  end

  # Returns the cas elements of Patient Responsibility(PR) fields
  # Obtain the cas elements for the PR fields in an array and sum up the PR field amount
  # Input :
  #  adjustment_reason : adjustment reason
  #  cas_element : cas element obtained for the adjustment reason
  # Output:
  #  cas_pr_elements : cas elements for PR fields
  # Invokes the following methods :
  # pr_adjustment_reason_elements in InsurancePaymentEob & ServicePaymentEob.
  def self.get_pr_cas_elements(adjustment_reason, cas_element)
    if pr_adjustment_reason_elements.include?(adjustment_reason)
      cas_01_code = cas_element[0]
      cas_02_code = cas_element[1]
      amount = cas_element[2]
      is_crosswalked = cas_element[3]
      count = cas_element[4]
      if !amount.blank? && !cas_01_code.blank? && !cas_02_code.blank?
        cas_pr_elements = []
        cas_pr_elements << cas_01_code
        cas_pr_elements << cas_02_code
        cas_pr_elements << format_amount(amount)
        cas_pr_elements << is_crosswalked
        cas_pr_elements << count
      end
    end
    cas_pr_elements
  end

  # Returns the CAS segments when the configuration for CAS to be printed
  #  as a separate segment
  # Eg : Scenario 1
  #  cas_elements = [['HR', '45', 10], ['OA', '45', 10], ['PR', '11', 5],
  #      ['HR', '45', 20], ['PR', '22', 3], ['HR', '45', 30], ['HR', '46', 30], ['HR', '47', 30],
  #      ['PR', '33', 20]
  #    ]
  # combined_cas_segments = ["CAS*HR*45*60.00", "CAS*HR*46*30.00",
  #   "CAS*HR*47*30.00", "CAS*OA*45*10.00", "CAS*PR*11*5.00**22*3.00**33*20.00"]
  # Eg : Scenario 2
  #  cas_elements = [['HR', '45', 10], ['PR', '11', 20], ['OA', '45', 10],
  #      ['HR', '45', 20], ['HR', '45', 30], ['PR', '11', 3],
  #      ['HR', '46', 30], ['HR', '47', 30], ['PR', '11', 5]
  #    ]
  # combined_cas_segments = ["CAS*HR*45*60.00", "CAS*HR*46*30.00",
  #      "CAS*HR*47*30.00", "CAS*OA*45*10.00", "CAS*PR*11*28.00"]
  #
  # Steps :
  # 1) Invokes Output835.group_cas_elements_with_same_cas_01_and_cas_02
  #     to obtain the cas elements first grouped by cas01 elements and then by cas02 elements in a hash.
  # 2) Invokes Output835.normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02
  #     to obtain the cas elements having same cas01 and cas02 elements as a single element
  #     by replacing the those elements in the hash and
  #     in the place of adjustment amount, their total sum of amount is stored in the hash.
  # 3) Those elements are deleted from the hash to avoid printing them again.
  # 4) Invokes Output835.normalize_cas_segment_for_different_cas01_and_cas02
  #     to obtain the cas segments for elements having different cas01 and
  #     different cas02 are made as separate form of CAS with minimum elements.
  # 5) Invokes combined_cas_segments for PR fields
  # 6) All of the formatted CAS segments are obtained in an array and is returned.
  #
  # Input :
  #  cas_elements : All the cas elements from all the adjustment reason fields of a claim in an array.
  #  This includes PR elements
  #  cas_pr_elements : All the PR elements from the PR adjustment reason fields
  #  element_seperator : The separater used in between the segment data elements.
  # Output :
  # cas_segments : Formatted cas segments
  def self.separate_cas_segments(cas_elements, cas_pr_elements, element_seperator, facility = nil)
    cas_segments = []
    if !cas_elements.blank?
      grouped_elements = group_cas_elements_with_same_cas_01_and_cas_02(cas_elements)
      grouped_elements = normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02(grouped_elements, true)
      non_pr_segments, grouped_elements_with_crosswalk_flag = normalize_cas_segment_for_different_cas01_and_cas02(grouped_elements, element_seperator, true)
    end
    if !cas_pr_elements.blank?
      pr_segments = combined_cas_segments(cas_pr_elements, element_seperator)
    end
    combined_pr_and_non_pr_segment = combine_pr_and_non_pr_segments(non_pr_segments, pr_segments, element_seperator)
    if !combined_pr_and_non_pr_segment.blank?
      combined_pr_and_non_pr_segment.each {|element| cas_segments << element}
    else
      non_pr_segments.each {|element| cas_segments << element} if !non_pr_segments.blank?
      pr_segments.each {|element| cas_segments << element} if !pr_segments.blank?
    end
    cas_segments = order_cas_segments(cas_segments)
    grouped_elements_with_crosswalk_flag = order_grouped_elements(grouped_elements_with_crosswalk_flag)
    facility = @facility || facility
    if facility.details[:combine_cas_segment]
      grouped_elements_with_crosswalk_flag = combine_segments_with_same_cas01(grouped_elements_with_crosswalk_flag)
    end
    normalize_grouped_elements_with_crosswalk_flag_for_code_co137(grouped_elements_with_crosswalk_flag)
    return cas_segments, grouped_elements_with_crosswalk_flag
  end

  def self.normalize_grouped_elements_with_crosswalk_flag_for_code_co137(grouped_elements_with_crosswalk_flag)
    grouped_elements_with_crosswalk_flag.each_with_index do |segment, index|
      if @cas_02_config == 'hipaa_code' && segment[0] == 'CO' && segment[1] == '137'
        grouped_elements_with_crosswalk_flag[index] = segment << 1
      end
    end
  end

  def self.combine_segments_with_same_cas01(grouped_elements_with_crosswalk_flag)
    element_hash = {}
    grouped_elements, ordered_group_code_array = [], []
    if grouped_elements_with_crosswalk_flag
      grouped_elements_with_crosswalk_flag.each do |element_array|
        group_code = element_array[0]
        ordered_group_code_array << group_code
        element_hash[group_code] = [] if element_hash[group_code].blank?
        element_hash[group_code] << element_array
      end
    end
    ordered_group_code_array = ordered_group_code_array.uniq
    ordered_group_code_array.each do |ordered_group_code|
      if element_hash[ordered_group_code]
        element_hash[ordered_group_code].each do |element_array|
          grouped_elements << element_array
        end
      end
    end
    grouped_elements
  end

  # Combine the PR segments and NON PR segments if all of them have the same cas01 and cas02 code
  # Input :
  # non_pr_segments : CAS segment of NON PR elements
  # pr_segments : CAS segment of PR elements
  # element_seperator : The separater used in between the segment data elements.
  # Output :
  # combined_pr_and_non_pr_segment : combined CAS segment of PR and NON PR elements
  def self.combine_pr_and_non_pr_segments(non_pr_segments, pr_segments, element_seperator)
    combined_pr_and_non_pr_segment = nil
    if non_pr_segments && non_pr_segments.length == 1 && pr_segments && pr_segments.length == 1
      non_pr_segment_elements = non_pr_segments[0].split(element_seperator)
      non_pr_cas01 = non_pr_segment_elements[1]
      non_pr_cas02 = non_pr_segment_elements[2]
      non_pr_amount = non_pr_segment_elements[3]
      pr_segment_elements = pr_segments[0].split(element_seperator)
      pr_cas01 = pr_segment_elements[1]
      pr_cas02 = pr_segment_elements[2]
      pr_amount = pr_segment_elements[3]
      if non_pr_cas01 == pr_cas01 && non_pr_cas02 == pr_cas02
        pr_and_non_pr_amount = non_pr_amount.to_f + pr_amount.to_f
        combined_pr_and_non_pr_segment = ['CAS', non_pr_cas01, non_pr_cas02,
          format_amount(pr_and_non_pr_amount)].join(element_seperator)
      end
    end
    combined_pr_and_non_pr_segment
  end

  # Returns the CAS segments when the configuration for CAS to be printed
  #  as a combined segment
  # Eg : Scenario 1
  #  cas_elements = [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30],
  #   ['HR', '46', 30], ['HR', '47', 30], ['OA', '45', 10],
  #   ['PR', '11', 5], ['PR', '22', 3], ['PR', '33', 20]]
  # combined_cas_segments = ["CAS*HR*45*60.00**46*30.00**47*30.00",
  #   "CAS*OA*45*10.00", "CAS*PR*11*5.00**22*3.00**33*20.00"]
  # Eg : Scenario 2
  #  cas_elements = [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30],
  #   ['HR', '46', 30], ['HR', '47', 30], ['OA', '45', 10],
  #   ['PR', '11', 5], ['PR', '11', 3], ['PR', '11', 20]]
  # combined_cas_segments = ["CAS*HR*45*60.00**46*30.00**47*30.00",
  #   "CAS*PR*11*28.00", "CAS*OA*45*10.00"]
  #
  # Steps :
  # 1) Invokes Output835.group_cas_elements_with_same_cas_01_and_cas_02
  #     to obtain the cas elements first grouped by cas01 elements and then by cas02 elements in a hash.
  # 2) Invokes Output835.normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02
  #     to obtain the cas elements having same cas01 and cas02 elements as a single element
  #     by replacing the those elements in the hash and
  #     in the place of adjustment amount, their total sum of amount is stored in the hash.
  # 3) Invokes Output835.normalize_cas_segment_for_same_cas01_and_different_cas02
  #     to obtain cas elements for elements having same cas01 but
  #     different cas02 are made as a single expanded form of CAS with maximum elements.
  # 4) Those elements are deleted from the hash to avoid printing them again.
  # 5) Invokes Output835.normalize_cas_segment_for_different_cas01_and_cas02
  #     to obtain the cas segments for elements having different cas01 and
  #     different cas02 are made as separate form of CAS with minimum elements.
  # 6) All of the formatted CAS segments are obtained in an array and is returned.
  #
  # Input :
  #  cas_elements : All the cas elements from all the adjustment reason fields of a claim in an array
  #  element_seperator : The separater used in between the segment data elements.
  # Output :
  # cas_segments : Formatted cas segments
  def self.combined_cas_segments(cas_elements, element_seperator)
    cas_segments = []
    grouped_elements = normalize_grouping_elements(cas_elements)
    grouped_elements, segments = normalize_cas_segment_for_same_cas01_and_different_cas02(grouped_elements, element_seperator)
    cas_segments << segments if !segments.blank?
    segments, grouped_elements_with_crosswalk_flag = normalize_cas_segment_for_different_cas01_and_cas02(grouped_elements, element_seperator)
    cas_segments << segments if !segments.blank?
    cas_segments.flatten.compact
  end

  def self.normalize_grouping_elements(cas_elements)
    grouped_elements = group_cas_elements_with_same_cas_01_and_cas_02(cas_elements)
    grouped_elements = normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02(grouped_elements)
    grouped_elements
  end


  # Returns the elements having same cas01 and cas02 elements as a single element
  #     by replacing the those elements in the hash and
  #     in the place of adjustment amount, their total sum of amount is stored in the hash.
  # Input :
  #  grouped_elements = A hash of elements grouped by cas_01 and cas_02
  # Output :
  # grouped_elements : The modified input grouped_elements hash
  # Eg : cas_elements = [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30],
  #       ['HR', '46', 30], ['HR', '47', 5]]
  # Input grouped_elements = {
  #      'HR' => {
  #        '45' => [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30]],
  #        '46' => [['HR', '46', 30]],
  #        '47' => [['HR', '47', 5]],
  #      }
  # Output grouped_elements = {
  #      'HR' => {
  #        '45' => [['HR', '45', 30]],
  #        '46' => [['HR', '46', 30]],
  #        '47' => [['HR', '47', 5]],
  #      }
  def self.normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02(grouped_elements, count = false)
    grouped_elements.each do |cas01_key, grouped_elements_on_cas_02|
      grouped_elements_on_cas_02.each do |cas02_key, elements|
        count_of_same_elements = elements.length
        if count_of_same_elements > 0
          if elements.length > 1
            amount = elements.inject(0) {|sum, e| sum = sum + e[2].to_f}
            array = [[cas01_key, cas02_key, amount]]
            array[0][3] = elements[0][4] if count
            grouped_elements_on_cas_02[cas02_key] = array
          end
        end
      end
    end
    grouped_elements
  end

  # Returns cas elements for elements having same cas01 but
  #     different cas02 are made as a single expanded form of CAS with maximum elements.
  #
  # Steps :
  #  1) Input grouped_elements = {
  #       'HR' => {
  #         '45' => [['HR', '45', 30]],
  #         '46' => [['HR', '46', 30]],
  #         '47' => [['HR', '47', 5]],
  #       },
  #       'OA' => {
  #         '45' => [['OA', '45', 10.0]]
  #       }
  #     }
  #  2) Invokes expanded_cas_segment for the elements having the
  #       same cas01 are joined to have the CAS as follows:
  #     [["CAS*HR*45*60.00**46*30.00**47*30.00"]]
  #  3) Then these elements of cas02 is deleted from the hash to avoid printing them again.
  #  4) Output grouped_elements = {
  #       'HR' => {},
  #       'OA' => {
  #         '45' => [['OA', '45', 10.0]]
  #       }
  #      }
  # Input :
  #  grouped_elements : A hash having same cas01 and cas02 elements as a single element
  #     by replacing the those elements in the hash and
  #     in the place of adjustment amount, their total sum of amount is stored in the hash.
  #  element_seperator : The separater used in between the segment data elements.
  # Output :
  #  grouped_elements : The modified input grouped_elements hash
  #  cas_segments : CAS segments joined by the elements of the hash
  def self.normalize_cas_segment_for_same_cas01_and_different_cas02(grouped_elements, element_seperator)
    cas_segments = []
    grouped_elements.each do |cas01_key, grouped_elements_on_cas_02|
      cas_02_elements = grouped_elements_on_cas_02.keys
      if cas_02_elements.length > 1
        combined_elements = grouped_elements_on_cas_02.values
        cas_segments << expanded_cas_segment(combined_elements, element_seperator)
        grouped_elements_on_cas_02.delete_if {|key, value| cas_02_elements.include?(key) }
      end
    end
    return grouped_elements, cas_segments
  end

  # Returns the cas segments for elements having different cas01 and
  #     different cas02 are made as separate form of CAS with minimum elements.
  # Steps:
  #  1) Input grouped_elements =>  {
  #       'OA' => {
  #          '45' => [['OA', '45', 10]]
  #         }
  #       }
  # 2) Invokes Output835.cas_with_minimum_elements to print CAS segment containing only 3 elements.
  # cas_segments = CAS*OA*45*10.00
  # Input :
  #  grouped_elements : A hash having elements with different cas01 and cas02
  # element_seperator : The separater used in between the segment data elements.
  # Output :
  #  cas_segments : CAS segments joined by the elements of the hash
  def self.normalize_cas_segment_for_different_cas01_and_cas02(grouped_elements, element_seperator, insert_count = false)
    cas_segments, grouped_elements_with_crosswalk_flag = [], []
    grouped_elements.each do |cas01_key, grouped_elements_on_cas_02|
      if grouped_elements_on_cas_02
        combined_elements = grouped_elements_on_cas_02.values
        combined_elements.each do |combined_element|
          combined_element.each do |element|
            cas_01_code = element[0]
            cas_02_code = element[1]
            amount = element[2]
            is_crosswalk_flag = element[3]
            count = element[4]
            if !cas_01_code.blank? && !cas_02_code.blank? && !amount.blank?
              grouped_elements_with_crosswalk_flag << [cas_01_code, cas_02_code, format_amount(amount), is_crosswalk_flag, count]
              cas_segments << cas_with_minimum_elements(element, element_seperator, insert_count)
            end
          end
        end
      end
    end
    return cas_segments, grouped_elements_with_crosswalk_flag
  end

  # Returns the cas elements first grouped by cas01 elements and then by cas02 elements in a hash.
  # Input :
  #  cas_elements : All the cas elements from all the adjustment reason fields of a claim in an array
  # Eg : cas_elements = [['HR', '47', 5], ['HR', '45', 10], ['OA', '45', 10],  ['HR', '45', 20],
  #   ['HR', '45', 30], ['HR', '46', 30]]
  # Output :
  #  grouped_cas_elements : cas elements first grouped by cas01 elements and then by cas02 elements in a hash.
  # Eg : grouped_cas_elements = {
  #      'HR' => {
  #        '45' => [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30]],
  #        '46' => [['HR', '46', 30]],
  #        '47' => [['HR', '47', 5]],
  #      },
  #      'OA' => {
  #        '45' => [['OA', '45', 10]]
  #      }
  #    }
  def self.group_cas_elements_with_same_cas_01_and_cas_02(cas_elements)
    grouped_cas_elements_on_cas_01 = group_cas_elements_on_cas_01(cas_elements)
    group_cas_elements_on_cas_02(grouped_cas_elements_on_cas_01)
  end

  # Returns the cas elements first grouped by cas01 elements in a hash.
  # Input :
  #  cas_elements : All the cas elements from all the adjustment reason fields of a claim in an array
  # Eg : cas_elements = [['HR', '47', 5], ['HR', '45', 10], ['OA', '45', 10],  ['HR', '45', 20],
  #   ['HR', '45', 30], ['HR', '46', 30]]
  # Output :
  #  grouped_cas_elements : cas elements first grouped by cas01 elements and then by cas02 elements in a hash.
  # Eg : grouped_cas_elements =  {
  #          "HR" => [ ["HR", "47", 5], ["HR", "45", 10], ["HR", "45", 20], ["HR", "45", 30], ["HR", "46", 30] ],
  #          "OA" => [ ["OA", "45", 10] ] }
  def self.group_cas_elements_on_cas_01(cas_elements)
    grouped_segments = {}
    cas_elements.each do |element|
      if !element.blank?
        if grouped_segments[element[0]].blank?
          grouped_segments[element[0]] = [element]
        else
          grouped_segments[element[0]] << element
        end
      end
    end
    grouped_segments
  end

  # Returns the cas elements which was first grouped by cas01 elements in a hash
  #  is grouped by cas02 elements in a hash.
  # Input :
  #  grouped_cas_elements_on_cas_01 : All the cas elements from all the adjustment reason fields of a claim in an array
  # Eg : grouped_cas_elements_on_cas_01 = {
  #          "HR" => [ ["HR", "47", 5], ["HR", "45", 10], ["HR", "45", 20], ["HR", "45", 30], ["HR", "46", 30] ],
  #          "OA" => [ ["OA", "45", 10] ] }
  # Output :
  #  grouped_segments : cas elements first grouped by cas01 elements and then by cas02 elements in a hash.
  # Eg : grouped_segments = {
  #      'HR' => {
  #        '45' => [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30]],
  #        '46' => [['HR', '46', 30]],
  #        '47' => [['HR', '47', 5]],
  #      },
  #      'OA' => {
  #        '45' => [['OA', '45', 10]]
  #      }
  #    }
  def self.group_cas_elements_on_cas_02(grouped_cas_elements_on_cas_01)
    grouped_segments = {}
    grouped_cas_elements_on_cas_01.each do |key, elements|
      elements.each do |element|
        if grouped_segments[key].blank?
          grouped_segments[key] = {}
        end
        if grouped_segments[key][element[1]].blank?
          grouped_segments[key][element[1]] = [element]
        else
          grouped_segments[key][element[1]] << element
        end
      end
    end
    grouped_segments
  end

  # Provides the CAS segment in a format of expanded form with elements
  #  with same cas01 and cas02 are clubbed together to form a single CAS segment.
  # Prints the CAS segment as :
  # CAS*cas01*field1_cas02*field1_amount*
  #   *field2_cas02*field2_amount**field3_cas02*field3_amount
  # here, cas01 will be similar to all the three fields.
  #
  # Steps :
  # all_cas_elements_unformatted : [[[field1_cas01, field1_cas02, field1_amount],
  #  [field1_cas01, field2_cas02, field2_amount], [field1_cas01, field3_cas02, field3_amount]]]
  # all_cas_elements : [[field1_cas01, field1_cas02, field1_amount],
  #  [field1_cas01, field2_cas02, field2_amount], [field1_cas01, field3_cas02, field3_amount]]
  # cas_02_and_03_elements : The cas_02_code and cas_03(amount) elements from  all_cas_elements are made into an array.
  # Invokes cas_with_maximum_elements to join the elements by element_seperator to get as follows :
  #  "CAS*cas01*field1_cas02*field1_amount*
  #   *field2_cas02*field2_amount**field3_cas02*field3_amount"
  #
  # Input:
  # all_cas_elements_unformatted : An array of cas01_code, cas02_code, amount for
  #   each PR field in the sequence.
  #   Eg : all_cas_elements_unformatted = [[['PR', 'H1', 1], ['PR', 'H2', 2], ['PR', 'H3', 3]]]
  # element_seperator : the separater used in between the segment data elements.
  #
  # Output :
  # CAS segment for all the three Patient Responsibility Fields.
  # cas_segment =   "CAS*cas01*field1_cas02*field1_amount*
  #   *field2_cas02*field2_amount**field3_cas02*field3_amount"
  # Eg : 'CAS*PR*H1*1.00**H2*2.00**H3*3.00'
  def self.expanded_cas_segment(all_cas_elements_unformatted, element_seperator)
    all_cas_elements, cas_02_and_03_elements = [], []
    all_cas_elements_unformatted.each do |cas_elements|
      all_cas_elements += cas_elements
    end
    if !all_cas_elements[0].blank?
      cas_01_code = all_cas_elements[0][0]
    end
    all_cas_elements.each do |all_cas_element|
      if all_cas_element[0] == cas_01_code
        cas_02_and_03_elements << [all_cas_element[1], format_amount(all_cas_element[2])]
      end
    end
    if !cas_02_and_03_elements.blank? && !cas_01_code.blank?
      cas_with_maximum_elements(cas_01_code, cas_02_and_03_elements, element_seperator)
    end
  end


  # Provides the CAS segment containing only 3 elements.
  # Prints the CAS segment as : CAS*cas01*cas02*amount
  #
  # Input :
  # element : [cas01, cas02, amount]
  # element_seperator : the separater used in between the segment data elements.
  #
  # Output :
  # CAS segment : CAS*cas01*cas02*amount
  def self.cas_with_minimum_elements(element, element_seperator, count = false)
    cas_01_code = element[0]
    cas_02_code = element[1]
    amount = element[2]
    if !cas_01_code.blank? && !cas_02_code.blank? && !amount.blank?
      cas_elements = []
      cas_elements << 'CAS'
      cas_elements << cas_01_code
      cas_elements << cas_02_code
      cas_elements << format_amount(amount)
      elements = cas_elements.join(element_seperator)
      if count
        cas_segment = [elements, element[-1]]
      else
        cas_segment = elements
      end
      cas_segment
    end
  end

  # Provides the CAS segment containing elements having same cas01
  #  clubbed together in a single CAS segment as follows:
  # cas_elements = "CAS*cas01*field1_cas02*field1_amount*
  #   *field2_cas02*field2_amount**field3_cas02*field3_amount"
  #
  #  Steps :
  #  1) cas_02_and_03_elements = [[field1_cas02, field1_amount], [field2_cas02,field2_amount ],
  #   [field3_cas02, field3_amount]]
  #  2) cas_02_and_03_elements = Join the inner array with element_seperator(*) as:
  #    [[field1_cas02*field1_amount], [field2_cas02*field2_amount], [field3_cas02*field3_amount]]
  #  3) Fetch first 6 of the elements in cas_02_and_03_elements and rest of the elements are
  #     joined by two element_seperators to get as follows :
  #     field1_cas02*field1_amount**field2_cas02*field2_amount**field3_cas02*field3_amount
  #  4) Then they are joined by two element_seperators to get as follows :
  #  field1_cas02*field1_amount**field2_cas02*field2_amount**field3_cas02*field3_amount
  #
  # Input :
  # cas_01_code : the common cas01
  # cas_02_and_03_elements : The cas_02_code and cas_03(amount) elements
  #  from all_cas_elements are made into an array.
  #  Inner array of cas element data points are joined by element_seperator to get as follows :
  #  [[field1_cas02*field1_amount], [field2_cas02*field2_amount], [field3_cas02*field3_amount]]
  # element_seperator : the separater used in between the segment data elements.
  #
  # Output :
  # CAS segment : CAS*cas01*field1_cas02*field1_amount**field2_cas02*field2_amount**field3_cas02*field3_amount
  #
  # cas_with_maximum_elements joins the outer array of cas elements by two element_seperators to get as follows :
  # field1_cas02*field1_amount**field2_cas02*field2_amount**field3_cas02*field3_amount
  # This is merged with CAS and cas_01 to get the segment.
  def self.cas_with_maximum_elements(cas_01_code, cas_02_and_03_elements, element_seperator)
    element_seperators = element_seperator + element_seperator
    cas_segments = []
    cas_02_and_03_elements.collect! do |element|
      element = element.compact.join(element_seperator) unless element.blank?
    end
    [cas_02_and_03_elements[0..5], cas_02_and_03_elements[6..-1]].each do |cas_02_and_03_elements |
      if !cas_02_and_03_elements.blank?
        cas_02_and_03_elements = cas_02_and_03_elements.compact.join(element_seperators)
        cas_elements = 'CAS'
        cas_elements += element_seperator
        cas_elements += cas_01_code
        cas_elements += element_seperator
        cas_elements += cas_02_and_03_elements
        cas_segments << cas_elements
      end
    end
    cas_segments.flatten
  end

  # Identifies standard industry codes for LQ*HE segment.
  #
  # Input :
  # entity : This can be an object of ServicePaymentEob for service level EOBs or
  #  InsurancePaymentEob for claim level EOBs.
  # facility : Facility object of the claim in process.
  # payer : Payer object of the claim in process.
  # cas_02_elements : The data elements in all the CAS02 segment for
  #   all the adjustment reasons is returned to be matched up with
  #   the LQ*HE codes to avoid duplication of codes in both segments.
  # element_seperator : the separater used in between the segment data elements.
  #
  # Output :
  # The LQ*HE segments for all adjustment reasons.
  #
  # Invokes the following methods :
  # adjustment_reason_elements in InsurancePaymentEob & ServicePaymentEob.
  # associated_codes_for_adjustment_reason in InsurancePaymentEob & ServicePaymentEob
  #   provides the associated codes wrt the level of mapping and FC configs.
  # Output835.not_printing_lqhe_code_if_it_is_same_as_cas_02 :
  # LQ*HE is not printed if its code is same as in CAS02
  def self.standard_industry_code_segments(entity, client, facility, payer, element_seperator)
    @payer = payer
    @client = client
    log.info 'Printing Standard Industry Code Segments'
    lqhe_codes, codes_with_crosswalked_flag_array = get_standard_industry_codes(payer, entity, client, facility)
    print_lqhe_codes(entity, client, payer, lqhe_codes, element_seperator)
  end

  def self.get_standard_industry_codes(payer, entity, client, facility)
    @payer ||= payer
    @client ||= client
    @facility ||= facility
    associated_codes_for_adjustment_elements = adjustment_reason_elements
    lq_he_config = facility.details[:lq_he]
    lq_he_config = [] if lq_he_config.blank?
    lqhe_codes, codes, codes_with_crosswalked_flag_array = [], [], []
    code_with_crosswalked_flag_array_1, code_with_crosswalked_flag_array_2 = [], []
    if @facility.details[:rc_crosswalk_done_by_client]
      lq_he_config << 'Reason Code' unless lq_he_config.include?('Reason Code')
    end
    unless lq_he_config.blank?
      lq_he_config1 = lq_he_config[0].to_s.downcase.gsub(' ', '_') if lq_he_config[0]
      lq_he_config2 = lq_he_config[1].to_s.downcase.gsub(' ', '_') if lq_he_config[1]
      reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, entity, client, facility)
      associated_codes_for_adjustment_elements.each do |adjustment_reason|
        crosswalked_codes = reason_code_crosswalk.get_crosswalked_codes_for_adjustment_reason(adjustment_reason)
        codes = []
        unless lq_he_config1.blank?
          codes_array, code_with_crosswalked_flag_array_1 = get_industry_codes(entity, lq_he_config1, crosswalked_codes)
          codes << codes_array
          log.info "LQ*HE : #{lq_he_config1}: #{adjustment_reason} : #{codes}"
        end
        unless lq_he_config2.blank?
          codes_array, code_with_crosswalked_flag_array_2 = get_industry_codes(entity, lq_he_config2, crosswalked_codes)
          codes << codes_array
          log.info "LQ*HE : #{lq_he_config2} : #{adjustment_reason} : #{codes}"
        end
        lqhe_codes << codes.flatten.compact.uniq unless codes.blank?
        if code_with_crosswalked_flag_array_1.present?
          codes_with_crosswalked_flag_array += code_with_crosswalked_flag_array_1
        end
        if code_with_crosswalked_flag_array_2.present?
          codes_with_crosswalked_flag_array += code_with_crosswalked_flag_array_2
        end
      end
    end
    lqhe_codes = lqhe_codes.flatten.compact.uniq
    return lqhe_codes, codes_with_crosswalked_flag_array.compact.uniq
  end

  def self.print_lqhe_codes(entity, client, payer, lqhe_codes, element_seperator)
    segments = []
    if !lqhe_codes.empty? && client.group_code.to_s == 'ADC'
      segments = "LQ*HE*#{lqhe_codes[0]}"
      retention_fee = entity.amount('retention_fees') if entity.class == ServicePaymentEob
      segments += "*HE*104" if payer && payer.name.to_s.upcase.include?('TUFTS') && !retention_fee.to_f.zero?
    else
      lqhe_codes.each do |code|
        if !code.blank?
          elements = []
          elements << 'LQ'
          elements << 'HE'
          elements << code
          segments << elements.join(element_seperator) unless elements.blank?
        end
      end
    end
    segments
  end

  # Return the codes to be printed in LQ*HE which is different from that of the CAS02.
  #
  # Input :
  # entity : This can be an object of ServicePaymentEob for service level EOBs or
  #  InsurancePaymentEob for claim level EOBs.
  # lq_he_config : The config for what needs to be printed in LQ*HE.
  # crosswalked_codes : A hash containing all the codes related to the reason code
  # Output :
  # The codes to be printed in the LQ*HE which are not same as CAS02
  def self.get_industry_codes(entity, lq_he_config, crosswalked_codes)
    lqhe_codes, lqhe_codes_with_crosswalked_flag = [], []
    if lq_he_config
      if lq_he_config == 'remark_code'
        codes, lqhe_codes_with_crosswalked_flag = get_remark_codes(crosswalked_codes, entity, lqhe_codes_with_crosswalked_flag)
        lqhe_codes << codes
      elsif lq_he_config == 'reason_code'
        lqhe_codes << get_reason_codes(crosswalked_codes)
      else
        lqhe_codes << crosswalked_codes[lq_he_config.to_sym]
      end
    end
    return lqhe_codes.flatten.compact.uniq, lqhe_codes_with_crosswalked_flag.compact.uniq
  end

  def self.get_remark_codes(crosswalked_codes, entity, lqhe_codes_with_crosswalked_flag)
    crosswalked_remark_codes, crosswalked_codes_with_crosswalked_flag = get_crosswalked_remark_codes(crosswalked_codes, lqhe_codes_with_crosswalked_flag)
    stand_alone_codes, stand_alone_codes_with_crosswalked_flag = get_stand_alone_remark_codes(entity, lqhe_codes_with_crosswalked_flag)
    lqhe_code = crosswalked_remark_codes + stand_alone_codes
    lqhe_code = lqhe_code.flatten.compact.uniq
    codes_with_crosswalked_flag = crosswalked_codes_with_crosswalked_flag + stand_alone_codes_with_crosswalked_flag
    codes_with_crosswalked_flag.each do |code|
      lqhe_codes_with_crosswalked_flag << code if code.present?
    end
    return lqhe_code, lqhe_codes_with_crosswalked_flag
  end

  def self.get_crosswalked_remark_codes(crosswalked_codes, lqhe_codes_with_crosswalked_flag)
    codes = []
    if crosswalked_codes[:remark_codes].present?
      codes << crosswalked_codes[:remark_codes]
      crosswalked_codes[:remark_codes].each do |code|
        lqhe_codes_with_crosswalked_flag << [code, true]
      end
    end
    return codes, lqhe_codes_with_crosswalked_flag
  end

  def self.get_stand_alone_remark_codes(entity, lqhe_codes_with_crosswalked_flag)
    codes = []
    stand_alone_remark_codes = entity.get_remark_codes if entity.class == ServicePaymentEob
    if !stand_alone_remark_codes.blank?
      codes << stand_alone_remark_codes
      if stand_alone_remark_codes.each do |code|
          lqhe_codes_with_crosswalked_flag << [code, false]
        end
      end
    end
    return codes, lqhe_codes_with_crosswalked_flag
  end

  def self.get_reason_codes(crosswalked_codes)
    reason_codes = []
    all_reason_codes = crosswalked_codes[:all_reason_codes]
    if all_reason_codes
      all_reason_codes.each do |reason_code|
        reason_codes << reason_code[0]
      end
    end
    reason_codes
  end

  # Returns the segments MIA and MOA for remark codes in claim level EOBs.
  # MIA segment is printed with remark codes when the patient_type is Inpatient.
  # MOA segment is printed with remark codes when the patient_type is Outpatient.
  # Input :
  # eob : Object of InsurancePaymentEob
  # element_seperator : separator of elements in 835 segment
  # crosswalked_codes : A hash containing  all the crosswalked codes for reason codes depending on the facility configuration.
  # This is to come from the method Output835.cas_adjustment_segments where it collects all the crosswalked codes
  # ** This method is to call only after the method call of Output835.cas_adjustment_segments.
  # ** If this method is to call without Output835.cas_adjustment_segments then,
  #  it has to fetch the crosswalked remark codes for all the adjustment reasonsons.
  #
  # Output :
  # An array containing MIA segments OR MOA segements.
  def self.claim_level_remark_code_segments(eob, element_seperator = '*', crosswalked_codes = {})
    crosswalked_codes ||= {}
    @element_seperator = element_seperator || '*'
    patient_type = eob.patient_type.to_s.upcase
    if !patient_type.blank?
      remark_codes = []
      remark_codes << crosswalked_codes[:remark_codes]
      remark_codes << eob.ansi_remark_codes.map(&:adjustment_code)
      remark_codes = remark_codes.flatten.compact.uniq
      if !remark_codes.blank?
        if patient_type == 'INPATIENT'
          self.remark_codes_in_mia_segment(remark_codes)
        elsif patient_type == 'OUTPATIENT'
          self.remark_codes_in_moa_segment(remark_codes)
        end
      end
    end
  end

  # This returns an array containing MIA segments.
  # A MIA segment contains 5 remark codes in the following format.
  # The first remark code in MIA should be at the position MIA-05. Then at the positions 20, 21, 22, and 23.
  # MIA*****R1***************R2*R3*R4*R5~
  # MIA*****R1~
  # star_count variables (first_occurence_star_count, second_occurence_star_count) are given for,
  # inserting the count of element_separator or '*' in the segment to fill up the count of stars needed in the 835 format.
  # Input :
  # remark_codes : Array of adjustment codes of remark codes
  # Output :
  # An array containing MIA segments.
  def self.remark_codes_in_mia_segment(remark_codes)
    first_occurence_star_count = 2
    second_occurence_star_count = 7
    star_count = [first_occurence_star_count, second_occurence_star_count]
    format_remark_codes('MIA', remark_codes, star_count)
  end

  # This returns an array containing MIA segments.
  # A MOA segment contains 5 remark codes in the following format.
  # The first remark code in MOA should be at the position MOA-03. Then at the positions 04, 05, 06, and 07.
  # MOA***R1*R2*R3*R4*R5~
  # MIA***R1~
  # star_count variables (first_occurence_star_count, second_occurence_star_count) are given for,
  # inserting the count of element_separator or '*' in the segment to fill up the count of stars needed in the 835 format.
  # Input :
  # remark_codes : Array of adjustment codes of remark codes
  # Output :
  # An array containing MOA segments.
  def self.remark_codes_in_moa_segment(remark_codes)
    first_occurence_star_count = 1
    second_occurence_star_count = 0
    star_count = [first_occurence_star_count, second_occurence_star_count]
    format_remark_codes('MOA', remark_codes, star_count)
  end

  # This returns the formatted remark codes in MIA or MOA segment
  # MIA & MOA have remark codes in different format.
  # Input :
  # segment_name : 'MIA' or 'MOA'
  # remark_codes : Array of remark_codes
  # star_count : Array of first_occurence_star_count, second_occurence_star_count
  #  variables first_occurence_star_count, second_occurence_star_count are given for,
  #  inserting the count of element_separator or '*' in the segment to fill up the count of stars needed in the 835 format.
  # Output :
  # An array containing MIA segments OR MOA segements.
  def self.format_remark_codes(segment_name, remark_codes, star_count)
    if !segment_name.blank? && !remark_codes.blank?
      first_occurence_star_count = star_count[0]
      second_occurence_star_count = star_count[1]
      code_segment_string, segment_string, code_segments = [], [], []
      maximum_remark_codes_in_segment = 5
      @element_seperator ||= '*'

      # Obtain the segment name and 5 maximum remark_codes in each array
      remark_codes.each_slice(maximum_remark_codes_in_segment) do |remark_code|
        segments = []
        segments << segment_name
        segments << remark_code
        segments = segments.flatten
        code_segments << segments
      end

      # Initializing the arrays containing element_separator (*) to be inserted to fill up the elements in the required format.
      first_occurence_star_array = Array.new(first_occurence_star_count, @element_seperator)
      second_occurence_star_array = Array.new(second_occurence_star_count, @element_seperator)

      # Insert the arrays containing element_separator (*) at particular position
      #  to have the segment in required format.
      # And join the array with the element_separator (*) to get strings of segment
      code_segments.each do |segments|
        segments.insert(1, first_occurence_star_array)
        segments.insert(3, second_occurence_star_array) if !second_occurence_star_array.blank?
        segment_string << segments.join(@element_seperator)
      end

      # Till now the arrays containing remark codes less than maximum_remark_codes_in_segment,
      # contain extra element separator at the end. It is removed by substitution.
      segment_string.each do |segment|
        if segment[-1] == @element_seperator
          reversed_segement = segment.reverse
          reversed_segement = reversed_segement.sub(/[\*]+/, '')
          code_segment_string << reversed_segement.reverse
        else
          code_segment_string << segment
        end
      end
      code_segment_string = nil if code_segment_string.blank?
      code_segment_string
    end
  end

  def self.format_amount(amount)
    amount.to_s.to_dollar.to_f.to_amount
  end

  def self.patpay_statement_cas(batch, check, ins_eob, eob)
    #If Service Level Eob, get details from service_payment_eobs table
    if eob.class.name == 'ServicePaymentEob'
      payment_amount, charge_amount = eob.service_paid_amount.to_f, eob.service_procedure_charge_amount.to_f
      discount = eob.contractual_amount.to_f
      service_end_date = eob.date_of_service_to
    else # if claim level eob, get details from claim_payment_eobs table
      payment_amount, charge_amount = eob.total_amount_paid_for_claim.to_f, eob.total_submitted_charge_for_claim.to_f
      discount = eob.total_contractual_amount.to_f
      service_end_date = eob.claim_to_date
    end
    check_amount = check.check_amount.to_f

    if  service_end_date && batch.date
      days_lapsed = (batch.date - service_end_date).to_i
    end

    charge_amt_after_discount = charge_amount-discount
    cas_oa_segment_amount = charge_amount-payment_amount-charge_amt_after_discount
    if days_lapsed && discount > 0 and days_lapsed <= 37
      cas_oa_segment_amount_is_applicable = cas_oa_segment_amount.to_f.round(2) != 0
      if ins_eob.multiple_statement_applied
        if payment_amount == discount and charge_amt_after_discount > 0
          ["CAS*CO*44*#{format_amount(charge_amt_after_discount)}"]
        elsif payment_amount > discount
          cas_co_segment = ["CAS*CO*44*#{format_amount(charge_amt_after_discount)}"] if charge_amt_after_discount > 0
          cas_oa_segment = ["CAS*OA*A0*#{format_amount(cas_oa_segment_amount)}"] if cas_oa_segment_amount_is_applicable
          return cas_co_segment, cas_oa_segment
        end
      elsif ins_eob.multiple_statement_applied == false
        if check_amount == discount and charge_amt_after_discount > 0
          ["CAS*CO*44*#{format_amount(charge_amt_after_discount)}"]
        elsif check_amount > discount
          cas_co_segment = ["CAS*CO*44*#{format_amount(charge_amt_after_discount)}"] if charge_amt_after_discount > 0
          cas_oa_segment = ["CAS*OA*A0*#{format_amount(cas_oa_segment_amount)}"] if cas_oa_segment_amount_is_applicable
          return cas_co_segment, cas_oa_segment
        end
      end
    end
  end

end
