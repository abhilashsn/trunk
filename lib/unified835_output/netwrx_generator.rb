class Unified835Output::NetwrxGenerator < Unified835Output::Generator

  # Start of SE Segment Details #
    def transaction_set_control_number(*options)
      @check_level_details[:index].to_s.rjust(9, '0')
    end
  # End of SE Segment Details

  # Start of N3_PR Segment Details #
    def payer_address_two(*options)
      @payer.address_two.to_s.strip.upcase
    end
  # End of N3_PR Segment Details

  # Start of TRN Segment Details #
    def originating_company_id_trace(*options)
      '1000000009'
    end
  # End of TRN Segment Details

  # Start of BPR Segment Details #
    def payment_format(*options)
      @is_ach_payment ? 'CCP' : ''
    end

    def dfi_id_no_qualifier(*options)
      @is_ach_payment ? '01' : blank_segment
    end

    def dfi_id_number(*options)
      @is_ach_payment ? '999999999' : blank_segment
    end

    def account_number_qualifier(*options)
      @is_ach_payment ? 'DA' : blank_segment
    end

    def account_number(*options)
      @is_ach_payment ? '999999999' : blank_segment
    end

    def originating_company_id(*options)
      @is_ach_payment ? '999999999' : blank_segment
    end

    def originating_company_code(*options)
      @is_ach_payment ? '199999999' : blank_segment
    end

    def extra_dfi_id_no_qualifier(*options)
      @is_ach_payment ? '01' : blank_segment
    end

    def extra_dfi_id_number(*options)
      @is_ach_payment ? '999999999' : blank_segment
    end

    def extra_account_number_qualifier(*options)
      @is_ach_payment ? 'DA' : blank_segment
    end

    def extra_account_number(*options)
      @is_ach_payment ? '999999999' : blank_segment
    end
  # End of BPR Segment Details #

  # Start of REF_F8 Segment Details #
    def original_reference_number(*options)
      get_eob_image.try(:original_file_name)
    end
  # End of REF_F8 Segment Details

  # Start of CLP Segment Details #
    def claim_payment_amount(*options)
      @eob.amount('total_amount_paid_for_claim')
    end

    def payer_claim_control_number(*options)
      return @eob.claim_number.to_s if @eob.claim_number.present?
      return 'NOTPROVIDED' if @facility.name.upcase.eql?('HOT SPRINGS MEDICAL ASSOCIATE')
    end

    def diagnosis_related_group_code(*options)
      nil_segment
    end
  # End of CLP Segment Details

  # Start of NM1_82 Segment Details
    def rendering_provider_name_suffix(*options)
      blank_segment
    end
  # End of NM1_82 Segment Details

  # Start of DTM_232 Segment Details #
    def claim_statement_period_start(*options)
      claim_start_date = @classified_eob.get_date_for_netwrx(:start_date, @claim)
      return nil if claim_start_date.nil?
      return claim_start_date if @classified_eob.is_claim_eob? && claim_start_date.eql?('00000000')
      claim_start_date if can_print_service_date(claim_start_date)
    end
  # End of DTM_232 Segment Details

  # Start of DTM_233 Segment Details #
    def claim_statement_period_end(*options)
      claim_start_date = @classified_eob.get_date_for_netwrx(:end_date, @claim)
      return nil if claim_start_date.nil?
      return claim_start_date if @classified_eob.is_claim_eob? && claim_start_date.eql?('00000000')
      claim_start_date if can_print_service_date(claim_start_date)
    end
  # End of DTM_233 Segment Details

  # Client Specific Helper Methods

  # End of Client Specific Helper Methods

  #Conditions to print a Segment : Overwritten Methods
    def verify_ts3_condition
      Unified835Output::BenignNull.new
    end

    def verify_ref_f8_condition
      if get_eob_image
        yield
      else
        Unified835Output::BenignNull.new
      end
    end
  #End of Conditions to print a Segment : Overwritten Methods
end