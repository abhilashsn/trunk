module Unified835Output::Adjustments
  def check_adjustment_service_lines
  	@services.detect{ |service| service.adjustment_line_is? }
  end

  def print_cas_segment_for_adjustment_lines
  	if cas_configured? && @claim_level_details[:adjustment_service_eob]
      cas_segments, @claim_level_details[:patient_amount], @crosswalked_codes = Output835.cas_adjustment_segments(@claim_level_details[:adjustment_service_eob],
      @facility.client, @facility, @payer, @facility_level_details[:element_separator], @eob, @check.batch, @check)
      return cas_segments
  	end
  end

  def print_cas_segment_for_claim_eob
  	if cas_configured? && @classified_eob.is_claim_eob?
      cas_segments, @claim_level_details[:patient_amount], @crosswalked_codes = Output835.cas_adjustment_segments(@eob,
      @facility.client, @facility, @payer, @facility_level_details[:element_separator], @eob, @check.batch, @check)
      return cas_segments
  	end
  end

  def print_claim_level_remark_codes
  	if mia_configured? && @classified_eob.is_claim_eob?
  		return Output835.claim_level_remark_code_segments(@eob, @facility_level_details[:element_separator], @crosswalked_codes)
  	end
  end

  def print_standard_industry_code_segments(entity)
  	if lq_configured? && @classified_eob.is_claim_eob?
  		if @facility.details[:rc_crosswalk_done_by_client]
  			return Output835.standard_industry_code_segments(entity, @facility.client, @facility, @payer, @facility_level_details[:element_separator])
  		end
  	else
  		return Output835.standard_industry_code_segments(entity, @facility.client, @facility, @payer, @facility_level_details[:element_separator])
  	end
  end

  def print_cas_segment_for_service_line
  	if service_cas_configured? && !@classified_eob.is_claim_eob?
  		cas_segments, patient_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, 
  			@facility.client, @facility, @payer, @facility_level_details[:element_separator], @eob, @check.batch, @check)
      @claim_level_details[:service_patient_amount_total] += patient_amount
  		return cas_segments
  	end
  end

  #Need to remove methods#
    def cas_configured?
      return true unless @facility.details[:configurable_835]
      @segments_list[:CAS][:CAS00][0].eql?('code_value') ? true : false
    end

    def lq_configured?
      return true unless @facility.details[:configurable_835]
      @segments_list[:LQ][:LQ00][0].eql?('code_value') ? true : false
    end

    def service_cas_configured?
      return true unless @facility.details[:configurable_835]
      @segments_list[:SVC_CAS][:SVC_CAS00][0].eql?('code_value') ? true : false
    end

    def plb_configured?
      return true unless @facility.details[:configurable_835]
      @segments_list[:PLB][:PLB00][0].eql?('code_value') ? true : false
    end

    def mia_configured?
      return true unless @facility.details[:configurable_835]
      @segments_list[:MIA][:MIA00][0].eql?('code_value') ? true : false
    end
  #End of Need to remove methods#

end