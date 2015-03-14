class Unified835Output::BarnabasGenerator < Unified835Output::Generator
  #Start of REF 2U
  def payer_identification_number(*options)
    output_payid = @payer.output_payid(@facility) #if payer.class == Payer
    output_payid
  end

  def verify_ref_2u_condition

    ( @payer.output_payid(@facility).present?) ? yield : Unified835Output::BenignNull.new
    end
  #End of REF 2U

  #Start of TS3 Segment
  def provider_summary_info_header(*options)
    "TS3"
  end

  def provider_identifier(*options)
    provider_tin = (@claim && @claim.tin.present?)? @claim.tin : @facility.output_tin
    provider_tin
  end

  def provider_summary_facility_code_value(*options)
    first_claim = @eobs.first.claim_information
    facility_type_code = (first_claim ? first_claim.facility_type_code.to_s : "")
    facility_type_code = "13" if facility_type_code.blank?
    facility_type_code
  end

  def fiscal_period_date(*options)
    "#{Date.today.year()}1231"
  end

  def total_claim_count(*options)
    @eobs.length.to_s
  end

  def total_claim_charge_amount_summary(*options)
    total_submitted_charges.to_s.to_dollar
  end
  # End of TS3 Segment Details

  # Start of REF_EV Segment Details
  def receiver_identification(*options)
    @batch.batchid.split('_').first[0...50]
  end
  # End of REF_EV Segment Details

  # Start of N1_PR Segment Details
  def payer_name(*options)
    payid = @payer.output_payid(@facility) if @payer.class == Payer
    payer_group(payid).upcase
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
  # End of N1_PR Segment Details

  #Start of DTM 405
  def production_date(*options)
    return (@check_level_details[:is_correspondent] ? @batch.date.strftime("%Y%m%d") : @check.check_date.strftime("%Y%m%d"))
  end

  #End of DTM 405

  #Start of CLP
  def plan_code(*options)
    @claim.plan_code.to_s[0] if @claim
  end

  def diagnosis_related_weight(*options)
    @eob.drg_weight
  end
  #End of CLP
  
  #Start of NM1 PR
  def corrected_priority_payer_name(*options)
    return  @eob.alternate_payer_name.to_s.strip if @facility.details['re_pricer_info'] && @eob.alternate_payer_name.present?
  end

  #End of NM1 PR

  #Start of REF 1L
   def verify_ref_1l_condition
       Unified835Output::BenignNull.new
    end

  #End of REF 1L
end
