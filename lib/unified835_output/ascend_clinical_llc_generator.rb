class Unified835Output::AscendClinicalLlcGenerator < Unified835Output::Generator

  # Start of ISA Segment Details #

  def interchange_sender_id(*options)
    sender_id="450480357"
    return sender_id.justify(15)
  end
  
  def interchange_receiver_id(*options)
    receiver_id="943357013"
    return receiver_id.justify(15)
  end

  def repetition_separator(*options)
    is_4010_version? ? 'U' : '{'
  end

  def inter_control_number(*options)
    '000021316'
  end
  #End of ISA Segment Details #

  #Start of GS segment Details #
  def application_receiver_code(*options)
    interchange_receiver_id.strip
  end

  def group_control_number(option)
    print_constant('1')
  end
  #End of GS segment details

  #Start of BPR segment details
  def payment_format(*options)
    blank_segment
  end

  def dfi_id_no_qualifier(*options)
    blank_segment
  end

  def dfi_id_number(*options)
    blank_segment
  end

  def account_number_qualifier(*options)
    blank_segment
  end

  def account_number(*options)
    blank_segment
  end

  def originating_company_id(*options)
    blank_segment
  end

  def originating_company_code(*options)
    blank_segment
  end

  def extra_dfi_id_no_qualifier(*options)
    blank_segment
  end

  def extra_dfi_id_number(*options)
    blank_segment
  end

  def extra_account_number_qualifier(*options)
    blank_segment
  end

  def extra_account_number(*options)
    blank_segment
  end
  #End of BPR segment details

  #Start of REF_2U Segment Details
  def payer_identification_number(*options,payer)
    payid = nil
    payid= (payer.class == Payer)? get_payer_from_claim : get_payer_from_check
    payid #unless payid.blank?
  end

def get_payer_from_claim
  claim_information = @eobs.where("claim_payid is not null").group("claim_payid").order("COUNT(claim_payid) DESC,id ASC")
  payid = claim_information[0].claim_payid.to_s if claim_information && claim_information[0].present?
  payid
end

def get_payer_from_check
  check_payer = (@micr && @micr.payer && @facility.details[:micr_line_info] ? @micr.payer : @check.payer)
  payid= output_payid(check_payer)
  payid
end
#End of REF_2U Segment Details

# Start of REF_EV Segment Details #
def receiver_identification(*options)
  @check.job.initial_image_name.to_s[0...50]
end
# End of REF_EV Segment Details

#Start of REF 1L Segment
def reference_identification(*options)
  insurance_policy_number = @eob.insurance_policy_number.to_s
  (insurance_policy_number.present?)?  insurance_policy_number : nil
end

#End of REF 1L Segment

#Start of REF IG

def insurance_policy_number(*options)
      nil_segment
    end
  # End of REF_IG Segment Details

# Start of N1_PE Segment Details #
#def identification_code_qualifier(*options)
#  return 'FI' if @facility_payee && @facility_payee.payee_tin?
#  Unified835Output::BenignNull.new
#end
#
#def identification_code(*options)
#  return @facility_payee.payee_tin.strip.upcase if @facility_payee && @facility_payee.payee_tin?
#  Unified835Output::BenignNull.new
#end
# End of N1_PE Segment Details #

# Start of REF_TJ Segment Details
#def tax_payer_identification_number(*options)
#  nil_segment
#end

 
# End of REF_TJ Segment Details

#Start of DTM 050 Segment
def claim_received_date
  claim_start_date = @classified_eob.get_start_date(@claim)
  return nil if claim_start_date.nil?
end
#End of DTM 050

#Start of AMT AU Segment
def coverage_amount(*options)
  nil_segment
end
#End of AMT AU

#Start of CLP
def diagnosis_related_group_code(*options)
  Unified835Output::BenignNull.new
end
#End of CLP

#Start of NM1*82
def rendering_provider_name_suffix(*options)
  blank_segment
end
#End of NM1*82
  
end
