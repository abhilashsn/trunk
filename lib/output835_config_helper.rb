module Output835ConfigHelper

  def initialize_segment_config


    @isa_config = {"[Payer Id]" => "payer_id.to_s","[Facility Name]" => "@facility.name.to_s",
      "[Interchange Control Number]" => "isa_counter",
      "[Tax Identification Number]" => "@facility.facility_tin.to_s.strip",
      "[Production Status]" => "production_status.to_s",
      "[Output Version]" =>"output_version.to_s.strip",
      "[Output Version Code]" =>"output_version_code.to_s.strip",
      "[Blank]"=> ""
    }

    @gs_config = {"[Payer Id]" => "payer_id.to_s","[Facility Name]" => "@facility.name.to_s.to_s.slice(0,15)",
      "[Batch Date]" => "@batch.date.strftime('%Y%m%d')",
      "[System-Generated Time]" => "Time.now().strftime('%H%M')",
      "[Tax Identification Number]" => "@facility.facility_tin.to_s.strip",
      "[System-Generated Date]" => "Time.now.strftime('%Y%m%d')",
      "[Output Version]" =>"output_version_number.to_s",
      "[Payer Id With Left Padded X's]" =>"payer_id.to_s.justify(15, 'X')"
    }

    @st_config = { "[9 Digits-Sequential Counter]" => "@check_sequence.justify(9, '0')",
      "[Sequential Counter]" => "@check_sequence.justify(4, '0')" }

    @bpr_config = { "[Transaction Handling Code]" => "bpr_01.to_s",
      "[Check Amount]" => "check_amount_truncate.to_s",
      "[Payment Method Code]" => "payment_indicator.to_s",
      "[Aba Routing Number]" => "routing_number.to_s",
      "[Payer Account Number]" => "account_number.to_s",
      "[Payer Id]" => "payer_id.to_s",
      "[Client DDA Number]" => "@facility.client_dda_number.to_s",
      "[Batch Date]" => "@batch.date.strftime('%Y%m%d')",
      "[Check Date]" => "(@is_correspndence_check  ? '' : @check.check_date.strftime('%Y%m%d'))",
      "[Check Date/Batch Date]" => "check_or_batch_date.to_s",
      "[835 Creation Date]" => "Time.now().strftime('%y%m%d')"
    }
     
   
    @trn_config = {  "[Check Number]" => "@check.check_number",  "[Batch Id]" => "@batch.batchid", "[Batch Date]" => "@batch.date.strftime('%Y%m%d')",
      "[1+Facility Tin Number]" => "facility_tin_number.to_s",
      "[1+Lockbox Specific Facility Tin Number]" => "lockbox_specific_facility_tin_number.to_s",
      "[Payer Id Left Padded With X's]" =>"payer_id.to_s.justify(10, 'X')",
      "[Payer Id Left Padded With 0's]" =>"payer_id.to_s.justify(10, '0')"}

    @refev_config = { "[Batch Id]" => "@batch.batchid.to_s",
      "[Multipage Image Name]" => "image_name.to_s",
      "[Check Image Id]" => "@check.image_file_name.to_s"
    }

    @refea_config = { "[Medical Record Id Number]" => "medical_record_id_number.to_s"
    }

    @refbb_config = {"[UID for Claim]" => "@eob.uid.to_s"}

    @dtm405_config = {"[Batch Date]" => "@batch.date.strftime('%Y%m%d')",
      "[Check Date]" => "(@is_correspndence_check  ? '' : @check.check_date.strftime('%Y%m%d'))",}


    @n1pr_config = {"[Payer Name]" => "@n1_pr_payer.name.strip.upcase[0...60].strip",
      "[Payee Name]"=> "@payee.name.to_s.strip.upcase","[Payer Id]" => "payer_id.to_s", "[Blank]" => ""}

  
    @n3pr_config = {"[Payer's Street Address]"=>"party_address(@n1_pr_payer)","[Payee's Street Address]"=>"party_address(@payee)","[Patient's Street Address]"=>"party_address(@n1_pr_payer)"}

      
    @n4pr_config = { "[Payer's City]" => "city(@n1_pr_payer)","[Payee's City]"=>"city(@payee)","[Patient's City]"=>"city(@n1_pr_payer)",
      "[Payer's State]"=>"state(@n1_pr_payer)","[Payee's State]"=>"state(@payee)","[Patient's State]"=>"state(@n1_pr_payer)",
      "[Payer's Zip]"=>"zip(@n1_pr_payer)","[Payee's Zip]"=>"zip(@payee)","[Patient's Zip]"=>"zip(@n1_pr_payer)"
    }

    @ref2u_config = { "[Payer Id]" => "find_payer_id_value.to_s",
      "[Output Payer Id]"=> "output_payer_id.to_s"
    }

    @perbl_config = {"[Payer Name]" => "@n1_pr_payer.name.strip.upcase[0...60].strip",
      "[Payee Name]"=> "@payee.name.to_s.strip.upcase[0...60].strip",
      "[Patient Name]" => "@n1_pr_payer.name.strip.upcase[0...60].strip"
    }


    @n1pe_config = {"[Payee Name]"=> "payee_name_value.to_s.strip.upcase[0...60].strip",
      "[Id Code Qualifier]"=> "payee_tin_npi_identification(@payee).first.to_s",
      "[Provider NPI/TIN]"=> "payee_tin_npi_identification(@payee).last.to_s",
      "[Provider Tin]" => "@provider_tin",
      "[Lockbox Specific Payee Name]" => "facility_lockbox.payee_name.to_s.upcase[0...60].strip",
      "[Lockbox Specific Id Code Qualifier]" =>"lockbox_id_qualifier.to_s",
      "[Lockbox Specific Provider NPI]" =>"facility_lockbox.npi.to_s.strip.upcase"
    }


    @n3pe_config = {"[Payee's Street Address]" => "party_address(@payee)",
      "[Lockbox Specific Payee's Street Address]"=>"facility_lockbox.address_one.to_s.strip.upcase"
    }

    @n4pe_config = { "[Payee's City]"=>"city(@payee)",
      "[Payee's State]"=>"state(@payee)",
      "[Payee's Zip Code]"=>"zip(@payee)",
      "[Lockbox Specific Payee's City]" =>"facility_lockbox.city.to_s.strip.upcase",
      "[Lockbox Specific Payee's State]" =>"facility_lockbox.state.to_s.strip.upcase",
      "[Lockbox Specific Payee's Zip Code]" =>"facility_lockbox.zipcode.to_s.strip"
    }

    @reftj_config = { "[Provider Tin]" => "get_provider_tin(@payee)",
      "[Lockbox Specific Provider Tin]"=>"facility_lockbox.tin.to_s.strip.upcase"
    }

    @lx_config = { "[Sequential Number]" => "@lx_index","[4digit-Sequential Number]"=>"@lx_index.to_s.rjust(4, '0')"  }

    @ts3_config = { "[Provider's Federal Tax Id]" => "@provider_tin",
      "[Facility Type Code From 837 Or Default 13]" =>"@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : '13'",
      "[Facility Type Code From 837 Or Default 11]"=>"@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : '11'",
      "[Total Submitted Charges]"=> "total_submitted_charges.to_s.to_dollar",
      "[Last Day Of Current Fiscal Period]" => "#{Date.today.year()}1231"}

    @clp_config = {"[Patient Account Number]"=>"@eob.patient_account_number.to_s",
      "[Claim Status Code]"=>"@eob.claim_type_weight.to_s",
      "[Claim Total Charge Amount]" => "total_charge.to_s",
      "[Claim Payment Amount]" => "@eob.payment_amount_for_output(@facility, @facility_output_config).to_s",
      "[Patient Responsibility Amount]" =>"patient_responsibility_amount",
      "[Plan Type]" => "plan_type.to_s",
      "[Payer's Claim Control Number]" => " @eob.claim_number.to_s",
      "[Check Number]" => "@check.check_number.to_s",
      "[Check Number + Batch Date + Sequence Number]" => "",
      "[Check Number + Batch Date]" => "@check.check_number.to_s +@batch.date.strftime('%Y%m%d').to_s",
      "[Facility Type Code From 837 Or Default 13]" => "@eob.claim_information ? @eob.claim_information.facility_type_code.to_s : '13'",
      "[Facility Type Code From 837 Or Default 11]" => "@eob.claim_information ? @eob.claim_information.facility_type_code.to_s : '11'",
      "[Facility Type Code From Mpi]" => "@eob.claim_information.facility_type_code.to_s if @eob.claim_information",
      "[Claim Frequency Indicator From Mpi]" => "claim_freq_indicator",
      "[Plan Code]" => "plan_code",
      "[Blank]" => "",
      "[Drg Code]" => "drg_code",
      "[Drg Weight]" => "@eob.drg_weight"
    }
   
    #@cas_config = {"[Hipaa Adustment Code]"=>"",
    #               "[Payer Reason Code]" =>"",
    #               "[Adjustment Amount]"=> ""}
   
    @nm1qc_config = {"[Patient Last Name]" =>"@eob.patient_last_name.to_s.strip.upcase",
      "[Patient First Name]" =>"@eob.patient_first_name.to_s.strip.upcase",
      "[Patient Middle Initial]" =>" @eob.patient_middle_initial.to_s.strip",
      "[Blank]" => "",
      "[Patient Suffix]" =>"@eob.patient_suffix",
      "[Patient Id Qualifier]" =>"patient_id_qualifier.last",
      "[Member Id Qualifier]" =>"member_id_qualifier.last",
      # "[Patient Id/Member Id]" =>"",
      "[Patient Id]" => "patient_id_qualifier.first",
      "[Member Id]" => "member_id_qualifier.first"

    }

    @nm1il_config = {"[Subscriber Last Name]"=>"@eob.subscriber_last_name",
      "[Subscriber First Name]"=>"@eob.subscriber_first_name",
      "[Subscriber Middle Initial]"=>"@eob.subscriber_middle_initial",
      "[Subscriber Suffix]" =>"@eob.subscriber_suffix",
      "[Blank]" => "",
      "[Member Id Qualifier]" =>"member_id_qualifier.last",
      "[Member Id]" => "@member_array.first"
    }

    @nm182_config = {"[Entity Type Qualifier]"=>"entity_type_qualifier",
      "[Rendering Provider Last Name]"=> "@eob.rendering_provider_last_name.to_s.upcase",
      "[Organization Name]" => "@eob.provider_organisation.to_s.upcase",
      "[Patient Last Name]" => "@eob.patient_last_name.to_s.strip.upcase",
      "[Patient First Name]" =>"@eob.patient_first_name.to_s.strip.upcase",
      "[Rendering Provider First Name]" =>"@eob.rendering_provider_first_name.to_s.upcase",
      "[Rendering Provider Middle Initial]" => "@eob.rendering_provider_middle_initial.to_s.upcase",
      "[Provider Suffix]" =>"@eob.rendering_provider_suffix.to_s.upcase",
      "[Blank]" => "",
      "[Id Code Qualifier]" =>"service_prov_identification.last",
      # "[Provider NPI/TIN]" => "@provider_qualifier_code_array.first",
      "[Provider NPI/TIN]" => "service_prov_identification.first",
      "[Provider Tin]" =>"@eob.provider_tin",
      "[Lockbox Specific Payee Name]" => "facility_lockbox.payee_name.to_s.upcase"

    }

    @nm1pr_config = {"[Repricer Payer Name]"=>"@check.alternate_payer_name.to_s",
      "[Blank]" => "",
      "[Payer Id Number]" => "payer_id.to_s"
    }


    @reff8_config ={"[Policy Number]"=>"@eob.insurance_policy_number",
      "[Eob Image Id]"=>"eob_image_id"
    }

    @refzz_config ={"[Provider UPIN Number]"=>"@eob.provider_tin",
      "[Image Name_Eob Start Page_ Eob End Page]"=>"image_page_name.to_s"
    }

    @dtm232_config = {"[Claim Level Service From Date]" => "claim_start_date.to_s"}

    @dtm233_config = {"[Claim Level Service To Date]" => "claim_end_date.to_s"}

    @dtm050_config = {"[Claim Received Date]" => ""}
  
    @amti_config = {"[Interest Amount]" => "@eob.amount('claim_interest').to_s"}

    @amtau_config = {"[Claim Level Allowed Amount]" => "@eob.claim_level_supplemental_amount.to_s"}
  
    @svc_config = {
      "[Medical Procedure Identifier]" => " !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'",
      "[Bundled Cpt Code]" => "bundled_cpt_code",
      "[Cpt Code]" => "proc_cpt_code",
      "[Revenue Code01]" => "revenue_code",
      "[Cdt Code]"=> "",
      "[Modifier-1]"=>"@service.service_modifier1.to_s unless @service.service_modifier1.blank?",
      "[Modifier-2]" => " @service.service_modifier2.to_s unless @service.service_modifier2.blank?",
      "[Modifier-3]" => "@service.service_modifier3.to_s unless @service.service_modifier3.blank?",
      "[Modifier-4]" => "@service.service_modifier4.to_s unless @service.service_modifier4.blank?",
      "[Revenue Code04]" => "svc_revenue_code.to_s",
      "[Line Item Charge Amount]" =>"@service.amount('service_procedure_charge_amount').to_s",
      "[Line Item Payment Amount]" =>"@service.amount('service_paid_amount').to_s",
      "[Blank]" =>"",
      "[Quantity]" =>"@service.service_quantity.to_f.to_amount",
      "[Product or Service ID Qualifier]" => "!@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'",
      "[Procedure Code]" =>"proc_cpt_code"
    }


    @dtm472_config = {"[Service Date]" => "service_date_at_472.to_s"}

    @dtm151_config = {"[Service To Date]" => "service_end_date.to_s"}

    @dtm150_config = {"[Service From Date]" => "service_start_date.to_s"}

    @ref6r_config = {"[Document Control Number + Service Line Number]"=>"service_line_item_control_num",
      "[Reference Number]" => "@service.service_provider_control_number.to_s",
      "[Line Item Control Number]" => "@service.service_provider_control_number.to_s",
      "[Blank]"=>"",
      "[Document Control Number]" => "@claim.xpeditor_document_number.to_s if @claim"
    }

    @amtb6_config = {"[Allowed Amount]"=>"supplemental_amount.to_s"}

    #     @plb_config = {"[Provider TIN]" => "@provider_tin", "[Provider NPI]" => "@provider_npi",  "[Patient Account Number]" => "@eob.patient_account_number",
    #      "[Check Number]" => "@check.check_number" }

    @plb_config = {"[Reference Identification]"=>"@plb_code.to_s",
      "[Provider Tin]"=> "@provider_tin",
      "[Npi Number]" => "@provider_npi",
      "[Last Day Of Current Fiscal Period]" =>"#{Date.today.year()}1231",
      "[Provider Adjustment Qualifier]" => "@plb_03_1",
      "[Account Number]"=>"@plb_03_2",
      "[Adjustment Amount With Opposite Sign]"=>"(format_amount(@plb_adjustment_amount) * -1).to_s"
    }

    @se_config = {"[Count Of Segments In The Transaction Set(ST/SE)]"=>"@transaction_count",
      "[Matches The Value In ST02]" =>"@check_sequence.justify(4, '0')"
    }
    @ge_config ={"[Count Of The Transaction Sets(ST/SE)]"=>"checks_in_functional_group(batch_id).to_s",
      "[Matches The Value Is GS06]"=>"2831"
    }
    @iea_config = {"[Count Of The Functional Groups(GS/GE)]"=>"1",
      "[Matches The Value Is ISA13]"=>"@isa_record.isa_number.to_s.rjust(9, '0')"
    }

  end

  def checks_in_functional_group(batch_id = nil)
    if batch_id
      checks_in_batch = @checks.collect {|check| check.batch.id == batch_id}
      checks_in_batch.length
    else
      @checks.length
    end
  end

  def service_line_item_control_num
    xpeditor_document_number = @claim.xpeditor_document_number if @claim
    unless xpeditor_document_number.blank? || xpeditor_document_number == "0"
      service_index_number = (@service_index + 1).to_s.rjust(4 ,'0')
      (xpeditor_document_number+service_index_number)
    end
  end

  def has_default_identification
    @facility_lockboxes.map(&:lockbox_number).include?(@batch.lockbox) #if facilities.include?(@facility_name)
  end

  def facility_lockbox
    @facility_lockboxes.where(:lockbox_number => @batch.lockbox).first if has_default_identification
  end

  def medical_record_id_number
    if @eob.medical_record_number.present?
      @eob.medical_record_number
    elsif @claim.present? && @claim.medical_record_number.present?
      @claim.medical_record_number
    end
  end
 
  def supplemental_amount
    if @eob_type == 'Patient'
      unless @service.service_paid_amount.to_f.zero?
        amount = @service.amount('service_paid_amount')
      end
    else
      unless @service.service_allowable.to_f.zero?
        amount = @service.amount('service_allowable')
      end
    end
    amount
  end

  def svc_revenue_code
    ((proc_cpt_code.present? || bundled_cpt_code.present?) and revenue_code.present?) ? revenue_code : ''
  end
  def composite_med_proc_id
    elem = nil
    if @composite_med_proc_id
      qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
      if bundled_cpt_code.present?
        elem = ["#{qualifier}:#{bundled_cpt_code}"]
      elsif proc_cpt_code.present?
        elem = ["#{qualifier}:#{proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
      elsif revenue_code.present?
        elem = ["NU:#{revenue_code}"]
      else
        elem = ["#{qualifier}:"]
      end
      elem = Output835.trim_segment(elem)
      elem.join(':')
      @composite_med_proc_id = false
    end
    return elem
  end

  def bundled_cpt_code
    @service.bundled_procedure_code.blank? ? '' : @service.bundled_procedure_code
  end

  def proc_cpt_code
    @service.service_procedure_code.blank? ? '' : @service.service_procedure_code
  end
  
  def payee_name_value
    facility_list = ["TATTNALL HOSPITAL COMPANY LLC","ORTHOPEDIC SURGEONS OF GEORGIA",
      "OPTIM HEALTHCARE"]
    if facility_list.include?(@facility_name)
      facility_payees = FacilitySpecificPayee.where(:facility_id => @facility.id,
        :payer_type => @eob_type).order("weightage desc")
      if facility_payees
        payee_name = nil
        eob = @eobs.first
        facility_payees.each do|facility_payee|
          identifier_position = eob.patient_account_number.upcase.index("#{facility_payee.db_identifier}")
          if (facility_payee.match_criteria.to_s == 'like' && identifier_position.present? && identifier_position >= 1 )
            payee_name = facility_payee.payee_name.upcase
            break
          elsif (facility_payee.match_criteria.to_s == 'start_with' && identifier_position.present? && identifier_position == 0 )
            payee_name = facility_payee.payee_name.upcase
            break
          elsif facility_payee.db_identifier == 'Other'
            payee_name = facility_payee.payee_name.upcase
            break
          end
        end
        payee_name
      end
    else
      @payee.name
    end
  end

  def lockbox_id_qualifier
    return 'XX'
  end

  def revenue_code
    revenue_code = @service.revenue_code.blank? ? '' : @service.revenue_code
    revenue_code.downcase == 'none' ? '' : revenue_code
  end

  def svc_procedure_cpt_code
    if @svc_procedure_cpt_code
      if bundled_cpt_code.present? and proc_cpt_code.present?
        qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
        elem = ["#{qualifier}:#{proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
        elem = Output835.trim_segment(elem)
        elem.join(':')
        @svc_procedure_cpt_code  = false
      end
    end
  end
  

  def claim_end_date
    #    to_date = @eob.claim_to_date
    #    if !to_date.blank? and @client_name == "QUADAX"
    #      to_date = to_date.strftime("%Y%m%d")
    #      to_date = '99999999' if (to_date == '20000101' || to_date == '99990909')
    #    else
    to_date = @eob.claim_to_date.strftime("%Y%m%d") if @eob.claim_to_date.present?
    to_date = '99999999' if (@client_name == "QUADAX" and (to_date == '20000101' || to_date == '99990909'))
    return to_date
    #    end
  end

  def get_provider_tin(payee)
    npi = (payee.class == Facility ? payee.output_npi : payee.npi)
     tin_value =  @check.payee_tin.strip.upcase if @check.payee_tin.present?
     if (@check.payee_npi.present?) && (tin_value.present?)
       tin_value
     end
#    tin_value = if @check.payee_tin.present?
#      @check.payee_tin.strip.upcase
#    elsif @claim && @claim.tin.present?
#      @claim.tin.strip.upcase
#    elsif payee.tin.present?
#      payee.tin.strip.upcase
#    elsif @facility.output_tin.present?
#      @facility.output_tin.strip.upcase
#    end
#    if (@claim && @claim.npi.present? || npi.present? || @check.payee_npi.present?) && (tin_value.present?)
#      tin_value
#    end
  end

  def facility_tin_number
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      facility_tin = @facility.facility_tin
      return (facility_tin.blank? ? nil : ('1' + facility_tin ))
    else
      return  nil
    end
  end


  def lockbox_specific_facility_tin_number
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      lockbox_specific_tin =  facility_lockbox.tin
      return (lockbox_specific_tin.blank? ? nil : ('1' + lockbox_specific_tin.to_s.strip.upcase ))
    else
      return  nil
    end
  end

  def claim_start_date
    #    from_date = @eob.claim_from_date
    #    if !from_date.blank?  and @client_name == "QUADAX"
    #      from_date = from_date.strftime("%Y%m%d")
    #      from_date = '99999999' if (from_date == '20000101' || from_date == '99990909')
    #
    #    else
    if @is_claim_eob
      from_date = @eob.claim_from_date.strftime("%Y%m%d")
      from_date = '99999999' if (@client_name == "QUADAX" and (from_date == '20000101' || from_date == '99990909'))
      return from_date
    else
      if @claim && @claim.claim_statement_period_start_date
        return @claim.claim_statement_period_start_date.strftime("%Y%m%d")
      end
    end
    #  end
  end

  def output_version_number
    return ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')
  end

  def service_start_date
    
    @service.date_of_service_from.strftime('%Y%m%d') unless @service.date_of_service_from.blank?
  end

  def service_end_date
    
    @service.date_of_service_to.strftime('%Y%m%d') unless @service.date_of_service_to.blank?
  end

  def service_date_at_472
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (from_date == to_date)
    if !from_date.nil? && (to_date.nil? || from_eqls_to_date)
      if from_date == '20000101' || from_date == '99990909'
        from_date = '99999999'
      end
    end
    from_date
  end

  def eob_image_id
    images = @job.images_for_jobs
    if images.length < 2
      eob_image = images.first
    else
      eob_image =  images.detect{|image|image.image_number == @eob.image_page_no}
    end
    eob_image.original_file_name if eob_image
  end


  def image_page_name
    image = @job.images_for_jobs.first.image_file_name
    job_start_page = @job.starting_page_number
    # image_name = 'PDS' + image.split('PDS')[1]
    image_name = image
    output_image_name = "#{image_name}#{job_start_page - 1 + @eob.image_page_no.to_i}_#{job_start_page - 1 + @eob.image_page_to_number.to_i}"
    output_image_name
  end
  
  def service_prov_identification
    @provider_qualifier_code_array = []
    code,qual = nil,nil
    if @eob && @eob.provider_npi
      code = @eob.provider_npi
      qual = 'XX'
      Output835.log.info "User entered Provider NPI is chosen"
    elsif @eob && @eob.provider_tin
      code = @eob.provider_tin
      qual = 'FI'
      Output835.log.info "User entered Provider tin is chosen"
    elsif (@claim && @claim.provider_npi.present?)
      code = @claim.provider_npi
      qual = 'XX'
      Output835.log.info "Provider NPI from the 837 is chosen"
    elsif (@claim && @claim.provider_ein.present?)
      code = @claim.provider_ein
      qual = 'FI'
      Output835.log.info "Provider TIN from 837 is chosen"
    elsif @facility.facilities_npi_and_tins.present?
      facility_npi_and_tin = @facility.facilities_npi_and_tins.first
      if facility_npi_and_tin.npi
        code = facility_npi_and_tin.npi
        qual = 'XX'
        Output835.log.info "facility NPI from FC is chosen"
      elsif facility_npi_and_tin.tin
        code = facility_npi_and_tin.tin
        qual = 'FI'
        Output835.log.info "facility TIN from FC is chosen"
      end
    end
    # return code, qual
    @provider_qualifier_code_array << code
    @provider_qualifier_code_array << qual
    return @provider_qualifier_code_array 
  end

  def entity_type_qualifier
    (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1')
  end

  def prov_last_name_or_org
    if @eob.rendering_provider_last_name.present?
      @eob.rendering_provider_last_name.upcase
    elsif @eob.provider_organisation.present?
      @eob.provider_organisation.upcase
    else
      @facility_name
    end
  end


  def member_id_qualifier
    @member_array = []
    id,qualifier =  @eob.member_id_and_qualifier
    @member_array << id
    @member_array << qualifier
    return @member_array
  end

  def patient_id_qualifier
    @patient_array = []
    patient_id, qualifier = @eob.patient_id_and_qualifier
    @patient_array << patient_id
    qualifier = nil if (@facility.name == "METROHEALTH SYSTEM" && qualifier != "MI")
    @patient_array << qualifier
    return @patient_array  
  end

  def plan_code
    @claim.plan_code.to_s[0] if @claim
  end

  def drg_code
    (@eob.drg_code if @eob.drg_code.present?)
  end
  
  def patient_responsibility_amount
    @eob.claim_type_weight == 22 ? "" : @eob.patient_responsibility_amount
  end
  
  #  def plan_type
  #    plan_type_config = @facility.plan_type.to_s.snakecase
  #    if plan_type_config == 'payer_specific_only'
  #      output_plan_type = (@payer && @payer.plan_type.present?) ?  @payer.plan_type.to_s : "ZZ"
  #    else
  #      output_plan_type = (@claim && @claim.plan_type.present?) ? @claim.plan_type : @eob.plan_type
  #    end
  #  end

  #  def claim_end_date
  #    if @config_835['dtm233_segment']
  #      @eob.claim_to_date.blank? ? nil : {0 => 'DTM', 1 => '233'}
  #   # else
  #      (@eob.claim_to_date.blank? || (@eob.claim_to_date.eql?@eob.claim_from_date)) ? nil : {0 => 'DTM', 1 => '233'}
  #    end
  #  end

  def new_batch?
    batch_id = @check.job.batch_id.to_s
    if batch_id != @prev_batchid
      @prev_batchid = batch_id
      true
    else
      false
    end
  end

  def total_submitted_charges
    @eobs.sum("total_submitted_charge_for_claim")
  end

  def total_payment_amount
    @eobs.sum('total_amount_paid_for_claim')
  end

  def facility_type_code
    @eobs.first.facility_type_code || '13'
  rescue
    '13'
  end

  def eob_facility_type_code
    if @claim && !@claim.facility_type_code.blank?
      @claim.facility_type_code
    end
  end

  def get_micr_condition
    @facility.details[:micr_line_info]
  end

  def payment_indicator
    @is_correspndence_check ? 'NON' : 'CHK'
  end

  def id_number_qualifier
    @is_correspndence_check ? '' : '01'
  end

  def correspondence_check?
    if @facility.sitecode.to_s.strip == '00549' #NYU specific logic
      @check.check_amount.zero?
    else
      @check.correspondence?
    end
  end

  def routing_number
    (@micr && !@is_correspndence_check) ? @micr.aba_routing_number.to_s.strip : ''
  end

  def account_num_indicator
    @is_correspndence_check ? '' : 'DA'
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("balance_record_type asc, image_page_no, end_time asc")
  end

  def get_ordered_patient_payment_eobs(object)
    object.patient_pay_eobs.order(:image_page_no, :end_time)
  end

  def find_other_bpr_elements
    method = "get_bpr_5_to_15"
    if self.methods.include?("#{method}_#{@facility_sym}".to_sym)
      method << "_#{@facility_sym}"
    elsif self.methods.include?("#{method}_#{@client_sym}".to_sym)
      method << "_#{@client_sym}"
    end
    bpr = send(method)
    return bpr
  end

  def get_bpr_5_to_15
    @bpr_elements = []
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      @bpr_elements = ["CCP", "01", "999999999", "DA", "999999999", "9999999999",
        "199999999", "01", "999999999", "DA", "999999999"]
    else
      @bpr_elements << ''
      if get_micr_condition
        @bpr_elements << [id_number_qualifier, routing_number.to_s, account_num_indicator, account_number]
      else
        @bpr_elements << ['', '', '', '']
      end
      @bpr_elements << ['', '', '', '', '', '']
    end

    return @bpr_elements.flatten!
  end

  def get_bpr_5_to_15_orb_test_facility
    @bpr_elements = []
    @bpr_elements << ''
    if @facility.details[:micr_line_info]
      @bpr_elements << [id_number_qualifier, routing_number, account_num_indicator, account_number]
    else
      @bpr_elements << ['', '', '', '']
    end
    @bpr_elements << @payer.payid.to_s.rjust(10, '0') if @payer
    @bpr_elements << '999999999'
    aba_dda_lookup = @facility.aba_dda_lookups.first
    if aba_dda_lookup
      aba_number = aba_dda_lookup.aba_number
      dda_number = aba_dda_lookup.dda_number
    end
    if @check_amount.to_f > 0 && @check.payment_method != "EFT"
      @bpr_elements << '01'
      aba_number = aba_number.blank? ? '' : aba_number
      @bpr_elements << aba_number
      @bpr_elements << "DA"
      dda_number = dda_number.blank? ? '' : dda_number
      @bpr_elements << dda_number
    else
      @bpr_elements << ['', '', '', '']
    end

    return @bpr_elements.flatten!
  end

  def check_amount_truncate
    amount = @check.check_amount.to_f
    check_amount = (amount == (amount.truncate)? amount.truncate : amount)
    return check_amount
  end

  def get_bpr_5_to_15_benefit_recovery
    @bpr_elements = []
    @bpr_elements << ''
    if @facility.details[:micr_line_info]
      @bpr_elements += [id_number_qualifier, routing_number, account_num_indicator, account_number]
    else
      @bpr_elements += ['', '', '', '']
    end
    @bpr_elements << @payer.payid.to_s.rjust(10, '0') if @payer
    @bpr_elements << '999999999'
    aba_dda_lookup = @facility.aba_dda_lookups.first
    if @check_amount.to_f > 0 && @check.payment_method != "EFT" && !aba_dda_lookup.blank?
      @bpr_elements << '01'
      @bpr_elements << aba_dda_lookup.aba_number
      @bpr_elements << 'DA'
      @bpr_elements << aba_dda_lookup.dda_number
    else
      @bpr_elements << ['', '', '', '']
    end
    return @bpr_elements.flatten!
  end

  def get_bpr_5_to_15_netwrx
    @bpr_elements = []
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      @bpr_elements << ["CCP", "01", "999999999", "DA", "999999999", "9999999999",
        "199999999", "01", "999999999", "DA", "999999999"]
    else
      @bpr_elements << ['', '', '', '','', '', '', '','', '', '']
    end
    return @bpr_elements.flatten!
  end

  def get_bpr_5_to_15_istreams
    @bpr_elements = []
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      @bpr_elements << ["CCP", "01", "999999999", "DA", "999999999", "9999999999",
        "199999999", "01", "999999999", "DA", "999999999"]
    else
      @bpr_elements << ['', '', '', '','', '', '', '','', '', '']
    end
    return @bpr_elements.flatten!
  end
  
  def account_number
    @is_correspndence_check ? '' : (@micr.payer_account_number.to_s.strip if @micr)
  end

  def effective_payment_date
    if @is_correspndence_check
      date_config = facility_output_config.details[:bpr_16_correspondence]
    else
      date_config = facility_output_config.details[:bpr_16]
    end
    if date_config == "Batch Date"
      check.job.batch.date.strftime("%Y%m%d")
    elsif date_config == "835 Creation Date"
      Time.now.strftime("%Y%m%d")
    elsif date_config == "Check Date"
      check.check_date.strftime("%Y%m%d")
    end
  end

  def get_facility
    claim_eob = (@eobs.detect {|eob| !eob.claim_information.blank?})
    claim = claim_eob.claim_information if claim_eob
    claim || @facility
  end

  def least_service_date
    least_date = @services.collect{|service| service.date_of_service_from}.compact.sort.first
    least_date.strftime("%Y%m%d") if !least_date.blank?
  end

  def claim_level_eob?
    @eob.category.upcase == "CLAIM"
  end

  def plan_type
    @eob.plan_type
  end

  def output_version
    return ((!@output_version || @output_version == '4010') ? '00401' : '00501')
  end

  def check_amount
    amount = @check.check_amount.to_f
    (amount == (amount.truncate)? amount.truncate : amount)
  end

  def claim_freq_indicator
    if @claim && !@claim.claim_frequency_type_code.blank?
      @claim.claim_frequency_type_code
    end
  end

  def prov_last_name_or_org
    if not @eob.rendering_provider_last_name.to_s.strip.blank?
      @eob.rendering_provider_last_name.upcase
    elsif not @eob.provider_organisation.blank?
      @eob.provider_organisation.to_s.upcase
    else
      @facility.name.upcase
    end
  end

  def bpr_01
    if (@check_amount.to_f > 0 && @check.payment_method == "CHK")
      "C"
    elsif (@check_amount.to_f.zero?)
      "H"
    elsif (@check_amount.to_f > 0 && @check.payment_method == "EFT")
      "I"
    elsif (@check.payment_method == "OTH")
      "D"
    end
  end

  def standard_industry_code_segments(entity, claim_level_eob = false)
    if claim_level_eob
      if @facility.details[:rc_crosswalk_done_by_client]
        Output835.standard_industry_code_segments(entity, @client, @facility, @payer, @element_seperator)
      end
    else
      Output835.standard_industry_code_segments(entity, @client, @facility, @payer, @element_seperator)
    end
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
    unless @clp_pr_amount.blank?
      @clp_05_amount += @clp_pr_amount
    end
    clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? @clp_05_amount.to_f.to_amount_for_clp : "")
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end

  def get_payer
    if @check.eob_type == 'Patient'
      eob = @check.insurance_payment_eobs.first
      patient = eob.patients.first if eob
      if patient
        Output835.log.info "\n Getting patient details from patients table"
        full_address = "#{patient.address_one}#{patient.city}#{patient.state}#{patient.zip_code}"
        if full_address.blank?
          output_payer = Patient.new(:last_name => patient.last_name, :first_name => patient.first_name, :address_one => @payer.address_one,
            :city => @payer.city, :state => @payer.state, :zip_code => @payer.zip_code)
        else
          output_payer = patient
        end
      else
        Output835.log.info "\n Getting patient details from payers table as patient record does not exist"
        output_payer = @payer
      end
      default_patient_name = @facility_config.details[:default_patient_name]
      unless default_patient_name.blank?
        output_payer.first_name, output_payer.last_name =  default_patient_name.strip.upcase.split
        output_payer.last_name ||= ""
      end
      output_payer
    else
      Output835.log.info "\n Getting payer details from payers table"
      @payer
    end
  end

  def production_status
    return "P"
  end
  
  def composite_med_proc_id
    qualifier = @facility.sitecode =~ /^0*00S66$/ ? 'AD' : 'HC'
    elem = []
    proc_code = (@service.service_procedure_code.blank? ? 'ZZ' + @delimiter.to_s +
        'E01' : qualifier + @delimiter.to_s + @service.service_procedure_code)
    proc_code = 'ZZ' + @delimiter.to_s + 'E01' if @service.service_procedure_code.to_s == 'ZZE01'
    modifier_condition = (@config_835['svc_segment'] && (@config_835['svc_segment']['1'].to_s == '[CPT Code + Modifiers]'))
    elem = modifier_condition ? [proc_code, @service.service_modifier1 , @service.service_modifier2 ,
      @service.service_modifier3 , @service.service_modifier4] : [proc_code]
    elem = trim_segment(elem)
    elem.join(@delimiter)
  end

  def amtb6_elements
    retention_fee = @service.amount('retention_fees')
    if @client.group_code.to_s == 'ADC' && @payer && @payer.name.to_s.upcase.include?('TUFTS') && !retention_fee.zero?
      {0 => 'AMT', 1 => 'B6', 3 => 'KH', 4 => retention_fee.to_s.dollar }
    else
      {0 => 'AMT', 1 => 'B6'}
    end
  end

  def output_payer_id
    payer = get_payer
    (@eob_type == 'Patient' ? '99999' : output_payid(payer))
  end

  def output_payid(payer)
    if payer.id
      output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(payer.id, @client.id, @facility.id)
      output_payid_record.blank? ? nil : output_payid_record.output_payid
    end
  end


  def supplemental_amount
    amount = nil
    if @check.eob_type == 'Patient'
      unless @service.service_paid_amount.blank? || @service.service_paid_amount.to_f.zero?
        amount = @service.amount('service_paid_amount')
      end
    else
      unless @service.service_allowable.blank? || @service.service_allowable.to_f.zero?
        amount = @service.amount('service_allowable')
      end
    end
    amount
  end

  #  def payer_id
  #    payid = @facility_config.details[:isa_06]
  #    (payid == 'Predefined Payer ID' ? @facility_config.predefined_payer.to_s :  payid.to_s)
  #  end

  def payer_id
    @payid = @config_835[:isa_06]
    payer = @first_check.payer
    if @payid == 'Predefined Payer ID'
      if @facility.index_file_parser_type == 'Barnabas'
        @payid = payer.output_payid(@facility) if payer
      elsif @client_name == "PACIFIC DENTAL SERVICES"
        @payid = payer.gcbs_output_payid(@facility)
      else
        @payid = payer.supply_payid if payer
      end
    else
      @payid.to_s
    end
  end

  def find_payer_id_value
    method = "payer_id"
    if self.methods.include?("#{method}_#{@facility_sym}".to_sym)
      method << "_#{@facility_sym}"
    elsif self.methods.include?("#{method}_#{@client_sym}".to_sym)
      method << "_#{@client_sym}"
    end
    payer_id_method = send(method)
    return payer_id_method
  end

  def payer_id_ascend_clinical
    payer = get_payer
    payid = nil
    if payer.class == Payer
      claim_information = @eobs.where("claim_payid is not null").group("claim_payid").order("COUNT(claim_payid) DESC,id ASC")
      if claim_information && claim_information[0].present?
        payid = claim_information[0].claim_payid.to_s
      else
        check_payer = (@micr && @micr.payer && @facility.details[:micr_line_info] ? @micr.payer : @check.payer)
        payid = output_payid(check_payer)
      end
      return payid
    end
  end

  def isa_counter
    isa_record = IsaIdentifier.first
    (isa_record ? isa_record.isa_number.to_s.justify(9, '0') : nil)
  end

  def client_specific_payerid
    facility_group_code = @client.group_code.to_s.strip
    case facility_group_code
    when 'ADC','MDR','LLU'
      payid =  @payer && @payerid ? ((@is_correspndence_check && @payer.status.upcase != 'MAPPED') ? 'U9999': @payerid ) : nil
      payid = payid.justify(10, '0')
    when 'BYH'
      payid = @payer && @payerid ? (@is_correspndence_check  ? "1999999999" :(@payer.status.upcase == 'MAPPED' ? @payerid : "00000U9999")): nil
    when 'CNS'
      payid =  @payer && @payerid ? (@is_correspndence_check  ? "1999999999" : @payerid.to_s.justify(10, '0')): nil
    when 'KOD'
      payid = @payer && @payerid ? (@payer.status.upcase == 'MAPPED' ? @payerid : "00000U9999" ): nil
    end
    return payid
  end

  def hlsc_payerid
    (@payer && @payerid ? (@payerid.to_s.strip[0] == 'U' ? 'U9999' : @payerid) : 'U9999')
  end

  def eob_type
    @payer.payid(@micr) == @facility.patient_payerid ? 'Patient' : 'Insurance'
  end

  def output_payer attribute
    begin
      if !@default_payer_address.blank?
        default_attribute = @default_payer_address[attribute.to_sym]
      end
      obtained_attribute = default_attribute || @payer.send(attribute)
      obtained_attribute.to_s.strip.upcase
    rescue
      ''
    end
  end

  def find_payee
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? ||
            payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility
      end
    end
    payee
  end

  def output_claim_type_weight
    "claim"
    #    required_claim_types = @facility_config.required_claim_types.to_s.strip.split(',')
    #    actual_claim_type_weight = claim_status_code
    #    if required_claim_types.blank?
    #      actual_claim_type_weight
    #    else
    #      (required_claim_types.include?actual_claim_type_weight.to_s) ? actual_claim_type_weight : 1
    #    end
  end

  def claim_status_code
    sitecode = @facility.sitecode.to_s.upcase
    services = @services
    sitecodes_for_custiomized_claim_type = ['00895', '00985', '00986',
      '00987', '00988', '00989', '00K22', '00K23', '00K39', '00S40']
    if sitecodes_for_custiomized_claim_type.include?(sitecode)
      claim_status_code = get_customized_claim_type(sitecode)
    else
      if services.blank?
        entity = @eob
      else
        entity = services[0].find_service_line_having_reason_codes(services)
      end
      if entity
        crosswalked_codes = find_reason_code_crosswalk_of_last_adjustment_reason(client, facility, payer)

        claim_status_code = compute_claim_status_code(facility, crosswalked_codes)
      else
        claim_status_code = '1'
      end
    end
    claim_status_code
  end

  def get_customized_claim_type(sitecode)
    copay = @eob.total_co_pay.to_f
    co_insurance = @eob.total_co_insurance.to_f
    deductable = @eob.total_deductible.to_f
    payment = @eob.total_amount_paid_for_claim.to_f
    patient_responsibility = copay + co_insurance + deductable
    if @claim
      claim_type_from_837 = @claim.claim_type.to_s
    end
    if (sitecode == '00S40') && patient_responsibility.zero? && payment.zero?
      '4'
    elsif claim_type_from_837 == 'T' && sitecode == '00895'
      '3'
    elsif !@total_primary_payer_amount.to_f.zero?
      '2'
    else
      '1'
    end
  end

  def client_specific_allowed_amount
    group_code = @client.group_code.to_s.strip
    co_insurance = @service.amount('service_co_insurance')
    paid = @service.amount('service_paid_amount')
    charge = @service.amount('service_procedure_charge_amount')
    allowed = @service.amount('service_allowable')
    denied = @service.amount('denied')
    non_covered =  @service.amount('service_no_covered')
    deductable = @service.amount('service_deductible')
    copay = @service.amount('service_co_pay')
    ppp = @service.amount('primary_payment')
    contractual = @service.amount('contractual_amount')
    case group_code
    when 'ADC'
      allowed.zero? ? ((co_insurance + paid) == charge ? charge : allowed) : allowed
    when 'ATI', 'USC'
      amount = co_insurance + deductable + paid
      (!ppp.zero? && !charge.zero?) ? charge : (amount.zero? ? '' : amount)
    when 'CCS'
      amount = charge - denied - non_covered
      allowed.zero? ? (amount <= 0 ? '' : amount  ) : allowed
    when 'CHCS'
      amount = paid + deductable + co_insurance + copay
      amount.zero? ? '' : amount
    when 'ESI'
      allowed.zero? ? (paid.zero? ? '' : paid): allowed
    when 'MAXH'
      amount = paid + deductable + co_insurance
      allowed.zero? ? (amount.zero? ? '' : amount) : allowed
    when 'MCP', 'MDQ'
      amount = paid + deductable + co_insurance
      amount.zero? ? '' : amount
    when 'NYU'
      amount = paid + deductable + co_insurance + contractual
      allowed.zero? ? (amount.zero? ? '' : amount) : allowed
    else
      allowed
    end
  end

  def trace_number
    unless @batch.index_batch_number.blank?
      site_number = @facility.sitecode.to_s[-3..-1]
      date = @batch.date
      eob_serial_number = serial_number.to_i.to_s(36).rjust(3, '0')
      date =  date.year.to_s[-1..-1] + date.month.to_s(36) +  date.day.to_s(36)
      batch_sequence_number = @batch.index_batch_number.to_i.to_s(36).rjust(2, '0')
      (site_number + date + batch_sequence_number + "0" + eob_serial_number + "0").to_s.upcase
    else
      raise "Index Batch Number missing; cannot compute Trace Number"
    end
  end

  def serial_number
    joins = "inner join check_informations c on c.id = insurance_payment_eobs.check_information_id \
              inner join jobs j on j.id = c.job_id \
              inner join batches b on b.id = j.batch_id \
              inner join facilities f on f.id = b.facility_id"
    ids_of_eobs_with_same_batch_date_and_facility = InsurancePaymentEob.find(:all,
      :joins => joins,
      :select => "insurance_payment_eobs.id",
      :conditions => ["b.date = ? and f.id = ?", batch_date, facility_id])
    ids_of_eobs_with_same_batch_date_and_facility.index(self) + 1
  end

  def service_payee_identification
    code, qual = nil, nil
    claim = @eob.claim_information
    if (claim && !claim.payee_npi.blank?)
      code = claim.payee_npi
      qual = 'XX'
    elsif (claim && !claim.payee_tin.blank?)
      code = claim.payee_tin
      qual = 'FI'
    elsif !@facility.facility_npi.blank?
      code = @facility.facility_npi
      qual = 'XX'
    elsif !@facility.facility_tin.blank?
      code = @facility.facility_tin
      qual = 'FI'
    end

    return code, qual
  end

  def format_amount(amount)
    amount = amount.to_f
    (amount == amount.truncate) ? amount.truncate : amount
  end

  def payment_indicator
    payment_method = @check.payment_method
    if payment_method == "CHK" || payment_method == "OTH"
      "CHK"
    elsif @check_amount.to_f.zero?
      "NON"
    elsif (@check_amount.to_f > 0 && payment_method == "EFT")
      "ACH"
    end
  end

  def routing_number
    (@micr &&  !@is_correspndence_check) ? @micr.aba_routing_number.to_s.strip : ''
  end

  def account_number
    @is_correspndence_check ? '' : (@micr.payer_account_number.to_s.strip if @micr)
  end

  def check_or_batch_date
    (@check.check_date.blank?)? @batch.date.strftime('%Y%m%d'): @check.check_date.strftime('%Y%m%d')
  end

  def image_name
    img_name = @check.image_file_name
    base_name=img_name.split(".")
    new_file_name = base_name[0].chomp!(base_name[0][-2,2])+"."+base_name[1]
    return new_file_name
  end

  def party_address(party)
    party.address_one.strip.upcase if party && party.address_one
  end

  def city(party)
    party.city.strip.upcase if party && party.city
  end

  def state(party)
    party.state.strip.upcase if party && party.state
  end

  def zip(party)
    party.zip_code.strip if party && party.zip_code
  end



  def payee_tin_npi_identification(payee)
    # elements = ['N1', 'PE']
    payee_array = []
    # elements << (@config_835[:payee_name].present? ? @config_835[:payee_name].strip.upcase : get_payee_name(payee))
#    if @claim && @claim.npi.present?
#      qualifier = 'XX'
#      npi_tin = @claim.npi.strip.upcase
#    els
    if payee.npi.present?
      qualifier = 'XX'
      npi_tin = payee.npi.strip.upcase
#    elsif @claim && @claim.tin.present?
#      qualifier = 'FI'
#      npi_tin = @claim.tin.strip.upcase
    elsif payee.tin.present?
      qualifier = 'FI'
      npi_tin = payee.tin.strip.upcase
#    elsif @facility.tin.present?
#      qualifier = 'FI'
#      npi_tin = @facility.tin.strip.upcase
    end
    payee_array << qualifier
    payee_array << npi_tin
    return payee_array
  end

  def to_amount_for_clp
    truncated_amount = self.truncate
    (self == truncated_amount ? truncated_amount :
        (self.to_s.split(".").last.size == 1 ? self : ("%.2f" % self).to_s.chomp('0').to_f))
  end

  #  def get_payee_name(payee)
  #    payee.name.strip.upcase
  #  end

  def output_version_code
    return ((!@output_version || @output_version == '4010') ? 'U' : '^')
  end

  def total_charge
    if is_discount_more?(@eob.total_contractual_amount.to_f)
      return @check.check_amount.to_f.to_amount
    else
      return @eob.amount('total_submitted_charge_for_claim')
    end
  end

  def is_discount_more?(discount)
    @facility_name == 'AVITA HEALTH SYSTEMS' && @eob.multiple_statement_applied == false &&
      @check.check_amount < discount && @payer.payer_type == 'PatPay'
  end

end
