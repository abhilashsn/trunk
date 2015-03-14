class Output835::IstreamsCheck < Output835::ShepherdEyeSurgicenterCheck

  #This is copied from Shepherd Eye file as the logic for Shepherd got changed..
  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
      if payer
        trn_elements = []
        trn_elements << 'TRN'
        trn_elements << '1'
        trn_elements <<  ref_number
        trn_elements <<  '1000000009'
        trn_elements.join(@element_seperator)
      end
  end

  
  def financial_info
    bpr_elements = []
    bpr_elements = []
    bpr_elements << 'BPR'
    if (check_amount.to_f > 0 && check.payment_method == "CHK")
      bpr_elements << "C"
    elsif (check_amount.to_f.zero?)
      bpr_elements << "H"
    elsif (check_amount.to_f > 0 && check.payment_method == "EFT")
      bpr_elements << "I"
    elsif (check.payment_method == "OTH")
      bpr_elements << "D"
    end
    bpr_elements << check_amount
    bpr_elements << 'C'
    bpr_elements << payment_indicator
    if check_amount.to_f > 0 && check.payment_method == "EFT"
      bpr_elements << "CCP"
      bpr_elements << "01"
      bpr_elements << "999999999"
      bpr_elements << "DA"
      bpr_elements << "999999999"
      bpr_elements << "9999999999"
      bpr_elements << "199999999"
      bpr_elements << "01"
      bpr_elements << "999999999"
      bpr_elements << "DA"
      bpr_elements << "999999999"
    else
      bpr_elements << (' ' * 11).split('')
    end
    bpr_elements << effective_payment_date
    bpr_elements = bpr_elements.flatten
    bpr_elements = Output835.trim_segment(bpr_elements)
    bpr_elements.join(@element_seperator)
  end

  def reciever_id
    ref_elements = []
    ref_elements << 'REF' << 'EV' << check.image_file_name.to_s[0...50]
    ref_elements = Output835.trim_segment(ref_elements)
    ref_elements.join(@element_seperator)
  end

  def transaction_set_line_number(index)
    elements = []
    elements << 'LX'
    elements << index.to_s.rjust(4, '0')
    elements.join(@element_seperator)
  end

  def claim_loop
    segments = []
    Output835.log.info "\n\nCheck has #{eobs.length} eobs"
    eobs.each_with_index do |eob, index|
      segments << transaction_set_line_number(index + 1)
      segments << transaction_statistics([eob])
      eob_klass = Output835.class_for("Eob", facility)
      eob_obj = eob_klass.new(eob, facility, payer, index, @element_seperator) if eob
      Output835.log.info "Applying class #{eob_klass}" if index == 0
      segments += eob_obj.generate
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end


end