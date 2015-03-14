# To change this template, choose Tools | Templates
# and open the template in the editor.

class Output835::OrbTestFacilityCheck< Output835::Check

  def initialize(check, facility, index, element_seperator, check_nums)
    @check = check
    @check_nums = check_nums
    @index = index
    @element_seperator = element_seperator
    # passing check number array also to verify for patpay
    # whether the check number is repeating
    @eob_type = check.eob_type
    # Circumventing using Check <-> Payer association because of the existing
    # bug in MICR module where it does not update payer_id in check
    # after identifying the payer for a check, while loading grid
    if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end
    @facility = facility
    @facility_config = facility.facility_output_configs.first
    @flag = 0
    @client = @facility.client
    init_check_info check unless check.nil?
  end
  
  def generate
    Output835.log.info "\n\nCheck number : #{check.check_number} undergoing processing"
    Output835.log.info "Payer : #{check.payer.payer}, Check ID: #{check.id}"
    transaction_segments =[]
    transaction_segments << transaction_set_header

    transaction_segments << financial_info
    transaction_segments << reassociation_trace
    transaction_segments << payer_identification_loop
    transaction_segments << payee_identification_loop
    transaction_segments << claim_loop
    transaction_segments << provider_adjustment
    transaction_segments = transaction_segments.flatten.compact
    @se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments unless transaction_segments.blank?
  end


  def payee_identification_loop(repeat = 1)
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? || payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility #if any of the billing provider address details is missing get facility address
      end
      payee_segments = []
      repeat.times do
        payee_segments << payee_identification(payee)
        payee_segments << address(payee)
        payee_segments << geographic_location(payee)
      end
      payee_segments = payee_segments.compact
      payee_segments unless payee_segments.blank?
    end
  end


  def payer_identification_loop(repeat = 1)
    payer = get_payer
    output_version = @facility_config.details[:output_version]
    Output835.log.info "\n payer is #{payer.name}"
    if payer
      payer_segments = []
      repeat.times do
        payer_segments << payer_identification(payer)
        payer_segments << address(payer)
        payer_segments << geographic_location(payer)
      end
      payer_segments = payer_segments.compact
      payer_segments unless payer_segments.blank?
    end
  rescue NoMethodError
    raise "Payer is missing for check : #{check.check_number} id : #{check.id}"
  end


  def financial_info
    bpr_elements = []
    bpr_elements << 'BPR'
    if (@check_amount.to_f > 0 && check.payment_method == "CHK")
      bpr_elements << "C"
    elsif (@check_amount.to_f.zero?)
      bpr_elements << "H"
    elsif (@check_amount.to_f > 0 && check.payment_method == "EFT")
      bpr_elements << "I"
    elsif (check.payment_method == "OTH")
      bpr_elements << "D"
    end
    bpr_elements << @check_amount
    bpr_elements << 'C'
    bpr_elements << payment_indicator
    bpr_elements << ''
    if get_micr_condition
      bpr_elements << id_number_qualifier
      bpr_elements << (routing_number.blank? ? '': routing_number)
      bpr_elements << account_num_indicator
      bpr_elements << account_number
    else
      bpr_elements << ['', '', '', '']
    end
    bpr_elements << @payer.payid.to_s.rjust(10, '0') if @payer
    bpr_elements << '999999999'
    if @check_amount.to_f > 0 && check.payment_method != "EFT"
    bpr_elements << '01'
    bpr_elements << @facility.aba_dda_lookups.first.aba_number unless @facility.aba_dda_lookups.blank?
    bpr_elements << "DA"
    bpr_elements << @facility.aba_dda_lookups.first.dda_number unless @facility.aba_dda_lookups.blank?
     else
      bpr_elements << ['', '', '', '']
    end
      bpr_elements << effective_payment_date
    bpr_elements = bpr_elements.flatten
    bpr_elements = Output835.trim_segment(bpr_elements)
    bpr_elements.join(@element_seperator)
  end


  

  def reassociation_trace
    trn_elements = []
    trn_elements << 'TRN'
    trn_elements << '1'
    trn_elements <<  output_check_number
    trn_elements << @payer.payid.to_s.rjust(10, '0') if @payer
    trn_elements << "999999999"
    trn_elements = Output835.trim_segment(trn_elements)
    trn_elements.join(@element_seperator)
  end

  def payer_identification(payer)
    elements = []
    elements << 'N1'
    elements << 'PR'
    elements << payer.name.strip.upcase[0...60].strip
    elements << 'XV'
    elements << payer.payid.strip if payer.payid
    elements.join(@element_seperator)
  end


  def address(party)
    address_elements = []
    address_elements << 'N3'
    address_elements << (party.address_one)? party.address_one.strip.upcase : 'PO BOX 9999'
    address_elements.join(@element_seperator)
  end

  def payee_identification(payee)
    elements = []
    elements << 'N1'
    elements << 'PE'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      n1_pe_02 = @facility_config.details[:payee_name].strip.upcase
    else
      n1_pe_02 = get_payee_name(payee)
    end
    elements << n1_pe_02
    elements << 'XX'
    elements << payee.npi.strip.upcase unless payee.npi.blank?
    elements.join(@element_seperator)
  end

  def geographic_location(party)
    location_elements = []
    location_elements << 'N4'
    location_elements << ((party.city)? party.city.strip.upcase : 'UNKNOWN')
    location_elements <<  ((party.state)? party.state.strip.upcase : 'GA')
    location_elements <<  ((party.zip_code)? party.zip_code.strip : '12345')
    location_elements = Output835.trim_segment(location_elements)
    location_elements.join(@element_seperator)
  end

  def claim_loop
    segments = []
    Output835.log.info "\n\nCheck has #{eobs.length} eobs"
    eobs.each_with_index do |eob, index|
      segments << transaction_set_line_number(index + 1) if index == 0
      eob_klass = Output835.class_for("Eob", facility)
      eob_obj = eob_klass.new(eob, facility, payer, index, @element_seperator) if eob
      Output835.log.info "Applying class #{eob_klass}" if index == 0
      segments += eob_obj.generate
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end

  def transaction_set_line_number(index)
    elements = []
    elements << 'LX'
    elements << index.to_s
    elements.join(@element_seperator)
  end



  #  def trim(string, size)
  #    string.strip.ljust(size).slice(0, size)
  #  end
end
