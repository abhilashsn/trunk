require 'yaml'

class Unified835Output::Generator

	include Unified835Output::ConfigGenerator
  include Unified835Output::GeneratorHelper
  include Unified835Output::Adjustments
  include Unified835Output::ExtendedBaseClass
  include Unified835Output::PlbSegment
  include CustomException
 

	def initialize(checks, facility, config, config_values,total_jobs=nil)
    @checks = checks
    @facility = facility
    @client = facility.client
    @output_config = config
    @basic_batch = @checks.first.batch
    @config_835_values = config_values
    default_segments_list = HashWithIndifferentAccess.new(YAML.load(File.read('lib/unified835_output/default_segments.yml')))
    @segments_list = HashWithIndifferentAccess.new(set_all_segment_methods(default_segments_list))
    @facility_level_details = get_default_facility_level_details
    @total_jobs = total_jobs
 	end

	def set_all_segment_methods(default_segments_list)
    return default_segments_list unless @facility.details[:configurable_835]
		segments_list = default_segments_list
		segments_list.each_pair do |segment_name, elements|
      # next unless @output_config.details[:configurable_segments][segment_name]
      elements.each_pair do |element_name, method_name|
		    element_method_name = get_config_segment_method_name(element_name, method_name)
		    segments_list[segment_name][element_name] = element_method_name
      end
		end
		segments_list
	end

  # 835 Formation #
  	def generate
  		segments = [
        print_isa_segment, 
        print_gs_segment, 
        transaction_sets,
        print_ge_segment, 
        print_iea_segment
      ].flatten.compact.remove_empty_segments
      update_isa_identifier_count(@facility_level_details[:isa_number])
      get_formatted_content(segments)
  	end

    def transaction_sets
      segments = []
      @checks.each_with_index do |check, index|
        @check = check
        @micr = check.micr_line_information
        @payment_classified_check = create_payment_classified_check
        @payer_classified_check = create_payer_classified_check
        @payer = check.payer
        @batch = check.batch
        @eobs = get_ordered_insurance_payment_eobs(@check)
        @payee = get_facility
        @check_level_details = get_default_check_level_details(index)
        segments << [print_st_segment]
        segments << [print_bpr_segment]
        segments << [print_trn_segment]
        segments << [print_ref_ev_segment]
        segments << [print_ref_f2_segment]
        segments << [print_dtm_405_segment]
        segments << payer_identification_loop
        segments << payee_identification_loop
        segments << print_ref_tj_segment
        segments << print_ref_zz_segment
        segments << print_rdm_segment
        segments << claim_loop
        segments << [print_plb_segment] #if plb_configured?
        segments = segments.flatten.compact
        @check_level_details[:segments_count] = segments.length + 1
        segments << print_se_segment
      end
      segments
    end

    def payer_identification_loop
      @payer = get_payer
      if @payer
        payer_segments = [
          print_n1_pr_segment,
          print_n3_pr_segment,
          print_n4_pr_segment,
          print_ref_2u_segment,
          print_per_cx_segment,
          print_per_bl_segment,
          print_per_ic_segment
        ]
        return payer_segments
      end
    end

    def payee_identification_loop
     
      payee_segments = [
        print_n1_pe_segment,
        print_n3_pe_segment,
        print_n4_pe_segment
      ]
      payee_segments
    end

    def claim_loop
      verify_claim_loop_condition{
        segments = []
        @eobs.each_with_index do |eob, index|
          @eob = eob
          @claim = eob.claim_information

          @services = eob.service_payment_eobs
          @claim_level_details = get_default_claim_level_details(index)
          @classified_eob = create_classified_eob

          segments << [print_lx_segment]
          segments << [print_ts3_segment]
          segments << [print_ts2_segment]
          segments << [print_clp_segment]
          segments << print_cas_segment_for_adjustment_lines #TODO: Old CAS Segment Code
          segments << print_cas_segment_for_claim_eob #TODO: Old CAS Segment Code
          segments << [print_nm1_qc_segment]
          segments << [print_nm1_il_segment]
          segments << [print_nm1_74_segment]
          segments << [print_nm1_82_segment]
          segments << [print_nm1_tt_segment]
          segments << [print_nm1_pr_segment]
          segments << [print_nm1_gb_segment]
          segments << print_claim_level_remark_codes #TODO: Old CAS Segment Code
          segments << [print_ref_zz_segment]
          segments << [print_ref_ea_segment]
          segments << [print_ref_bb_segment]
          segments << [print_ref_ig_segment]
          segments << [print_ref_f8_segment]
          segments << [print_dtm_232_segment]
          segments << [print_dtm_233_segment]
          segments << [print_dtm_036_segment]
          segments << [print_dtm_050_segment]
          segments << [print_per_cx2_segment]
          segments << [print_amt_i_segment]
          segments << [print_amt_au_segment]
          segments << [print_qty_ca_segment]
          segments << print_standard_industry_code_segments(@eob) #TODO: Old CAS Segment Code
          segments << service_payment_loop
          update_patient_responsibility_amount(segments.flatten!)
        end
        segments
      }
    end
  # End of 835 Formation #

  def service_payment_loop
    verify_service_payment_loop_condition{
      segments = []
      @services.each_with_index do |service, index|
        @service = service
         @service_index = index
        @service_level_details = get_default_service_level_details(index)

        segments << [print_svc_segment]
        segments << [print_dtm_472_segment]
        segments << [print_dtm_150_segment]
        segments << [print_dtm_151_segment]
        segments << print_cas_segment_for_service_line #TODO: Old CAS Segment Code
        segments << [print_ref_lu_segment]
        segments << [print_ref_6r_segment]
        segments << [print_ref_hpi_segment]
        segments << [print_ref_0k_segment]
        segments << [print_amt_b6_segment]
        segments << [print_qty_zk_segment]
        segments << [print_lq_rx_segment]
        segments << print_standard_industry_code_segments(@service) #TODO: Old CAS Segment Code
      end
      segments.compact.flatten
    }
  end

 def print_plb_segment
    provider_adjustment if plb_configured?
  end

  protected
  
  def get_default_facility_level_details
    {
      :isa_number => IsaIdentifier.first.try(:isa_number),
      :element_separator => '*',
      :segment_separator => '~',
      :look_ahead => "\n"
    }
  end

  def get_default_check_level_details(index)
    {
      :index => index + 1,
      :eob_type => @check.eob_type,
      :is_correspondent => @check.correspondence?,
      :address_payee => get_payee_for_address_details,
      :segments_count => 0
    }
  end

  def get_default_claim_level_details(index)
    patient_id, patient_code_qualifier = @eob.patient_id_and_qualifier
    subscriber_id, subscriber_code_qualifier = @eob.member_id_and_qualifier
    rendering_provider_id, rendering_provider_qualifier = *service_provider_information
    {
      :index => index + 1,
      :adjustment_service_eob => check_adjustment_service_lines,
      :patient_code_qualifier => patient_code_qualifier,
      :patient_id => patient_id,
      :subscriber_id => subscriber_id,
      :subscriber_code_qualifier => subscriber_code_qualifier,
      :rendering_provider_id => rendering_provider_id,
      :rendering_provider_qualifier => rendering_provider_qualifier,
      :patient_amount => 0,
      :service_patient_amount_total => 0
    }
  end

  def get_default_service_level_details(index)
    {
      :index => index + 1,
      :from_date => get_service_start_date,
      :to_date => get_service_end_date,
      :service_in_one_day => is_service_ends_in_one_day?,
      :supplemental_amount => @payer_classified_check.get_supplemental_amount(@service),
      :is_adjustment_line => @service.adjustment_line_is?
    }
  end

  def create_payment_classified_check
    check_types = {
      'EFT' => Unified835Output::EftCheck.new(@check.attributes.delete_if{|k,v| k == 'id'}),
      'CHK' => Unified835Output::ChkCheck.new(@check.attributes.delete_if{|k,v| k == 'id'}),
      'OTH' => Unified835Output::OthCheck.new(@check.attributes.delete_if{|k,v| k == 'id'}),
      'COR' => Unified835Output::CorCheck.new(@check.attributes.delete_if{|k,v| k == 'id'})
    }
    @check.payment_method ? check_types[@check.payment_method] : @check
  end

  def create_payer_classified_check
    check_types = {
      'Patient' => Unified835Output::PatientCheck.new(@check.attributes.delete_if{|k,v| k == 'id'}),
      'Insurance' => Unified835Output::InsuranceCheck.new(@check.attributes.delete_if{|k,v| k == 'id'})
    }
    check_types[@check.eob_type]
  end

  def create_classified_eob
    eob_types = {
      'ClaimEob' => Unified835Output::ClaimEob.new(@eob.attributes.delete_if{|k,v| k == 'id'}),
      'ServiceEob' => Unified835Output::ServiceEob.new(@eob.attributes.delete_if{|k,v| k == 'id'})
    }
    @eob.category.upcase == 'CLAIM' ? eob_types['ClaimEob'] : eob_types['ServiceEob']
  end
  # Individual Segment Details #

  #Start of ISA Segment Details #
    def print_isa_segment
      isa_element_methods = @segments_list[:ISA]
      @isa_elements = [
        send(isa_element_methods[:ISA00][0].to_sym, isa_element_methods[:ISA00][1]), #['segment_name', 'ISA']
        send(isa_element_methods[:ISA01][0].to_sym, isa_element_methods[:ISA01][1]), #['print_constant', '00']
        send(isa_element_methods[:ISA02][0].to_sym, isa_element_methods[:ISA02][1]), #['print_fixed_empty_space', 10]
        send(isa_element_methods[:ISA03][0].to_sym, isa_element_methods[:ISA03][1]), #['print_constant', '00']
        send(isa_element_methods[:ISA04][0].to_sym, isa_element_methods[:ISA04][1]), #['print_fixed_empty_space', 10]
        send(isa_element_methods[:ISA05][0].to_sym, isa_element_methods[:ISA05][1]), #['print_constant', 'ZZ']
        send(isa_element_methods[:ISA06][0].to_sym, isa_element_methods[:ISA06][1]), #interchange_sender_id
        send(isa_element_methods[:ISA07][0].to_sym, isa_element_methods[:ISA07][1]), #['print_constant', 'ZZ']
        send(isa_element_methods[:ISA08][0].to_sym, isa_element_methods[:ISA08][1]), #interchange_receiver_id
        send(isa_element_methods[:ISA09][0].to_sym, isa_element_methods[:ISA09][1]), #['print_current_time', '%y%m%d']
        send(isa_element_methods[:ISA10][0].to_sym, isa_element_methods[:ISA10][1]), #['print_current_time', '%H%M']
        send(isa_element_methods[:ISA11][0].to_sym, isa_element_methods[:ISA11][1]), #repetition_separator
        send(isa_element_methods[:ISA12][0].to_sym, isa_element_methods[:ISA12][1]), #inter_control_version_number
        send(isa_element_methods[:ISA13][0].to_sym, isa_element_methods[:ISA13][1]), #inter_control_number
        send(isa_element_methods[:ISA14][0].to_sym, isa_element_methods[:ISA14][1]), #['print_constant', '0']
        send(isa_element_methods[:ISA15][0].to_sym, isa_element_methods[:ISA15][1]), #['print_constant', 'P']
        send(isa_element_methods[:ISA16][0].to_sym, isa_element_methods[:ISA16][1]) #['print_constant', ':']
      ]
      @isa_elements.flatten.trim_empty_segments_in_end.join(@facility_level_details[:element_separator])
    end

    def interchange_sender_id(*options)
      payid = @output_config.details[:isa_06].to_s.strip
      payer = @checks.first.payer
      raise "Payer Not Found to create Interchange Sender ID - ISA08 Segment" unless payer
      (payid == 'Predefined Payer ID') ? payer.get_sender_id(@facility) : payid.to_s.justify(15)
    end

    def interchange_receiver_id(*options)
      @output_config.get_receiver_id
    end

    def repetition_separator(*options)
      is_4010_version? ? 'U' : '^'
    end

    def inter_control_version_number(*options)
      is_4010_version? ? '00401' : '00501'
    end

    def inter_control_number(*options)
      return nil unless @facility_level_details[:isa_number]
      @facility_level_details[:isa_number].to_s.justify(9, '0')
    end
  # End of ISA Segment Details #

  #Start of GS Segment Details #
    def print_gs_segment
      gs_element_methods = @segments_list[:GS]
      @gs_elements = [
        send(gs_element_methods[:GS00][0].to_sym, gs_element_methods[:GS00][1]), #['segment_name', 'GS']
        send(gs_element_methods[:GS01][0].to_sym, gs_element_methods[:GS01][1]), #['print_constant', 'HP']
        send(gs_element_methods[:GS02][0].to_sym, gs_element_methods[:GS02][1]), #application_sender_code
        send(gs_element_methods[:GS03][0].to_sym, gs_element_methods[:GS03][1]), #application_receiver_code
        send(gs_element_methods[:GS04][0].to_sym, gs_element_methods[:GS04][1]), #group_date
        send(gs_element_methods[:GS05][0].to_sym, gs_element_methods[:GS05][1]), #['print_current_time', '%H%M']
        send(gs_element_methods[:GS06][0].to_sym, gs_element_methods[:GS06][1]), #['group_control_number', '2831']
        send(gs_element_methods[:GS07][0].to_sym, gs_element_methods[:GS07][1]), #['print_constant', 'X']
        send(gs_element_methods[:GS08][0].to_sym, gs_element_methods[:GS08][1]) #version_code
      ]
      @gs_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def application_sender_code(*options)
      interchange_sender_id.strip
    end

    def application_receiver_code(*options)
      interchange_receiver_id
    end

    def group_date(*options)
      @facility.use_barnabas_parser? ? @basic_batch.get_batch_date("%Y%m%d") : print_current_time("%Y%m%d")
    end

    def group_control_number(option)
      print_constant('2831')
    end

    def version_code(*options)
      is_4010_version? ? '004010X091A1' : '005010X221A1'
    end
  #End of GS Segment Details #

  #Start of ST Segment Details #

    def print_st_segment
      st_element_methods = @segments_list[:ST]
      @st_elements = [
        send(st_element_methods[:ST00][0].to_sym, st_element_methods[:ST00][1]), #['segment_name', 'ST']
        send(st_element_methods[:ST01][0].to_sym, st_element_methods[:ST01][1].to_s), #['print_constant', '835']
        send(st_element_methods[:ST02][0].to_sym, st_element_methods[:ST02][1]) #transaction_set_control_number
      ]
      @st_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def transaction_set_control_number(*options)
      @check_level_details[:index].to_s.rjust(4, '0')
    end
  #End of ST Segment Details #

  # Start of BPR Segment Details #
    def print_bpr_segment
      bpr_element_methods = @segments_list[:BPR]
      @is_ach_payment = (payment_method == 'ACH')
      @bpr_elements = [
        send(bpr_element_methods[:BPR00][0].to_sym, bpr_element_methods[:BPR00][1]), #segment_name
        send(bpr_element_methods[:BPR01][0].to_sym, bpr_element_methods[:BPR01][1]), #transaction_handle_code
        send(bpr_element_methods[:BPR02][0].to_sym, bpr_element_methods[:BPR02][1]), #payment_amount
        send(bpr_element_methods[:BPR03][0].to_sym, bpr_element_methods[:BPR03][1]), #credit_debit_flag
        send(bpr_element_methods[:BPR04][0].to_sym, bpr_element_methods[:BPR04][1]), #payment_method
        send(bpr_element_methods[:BPR05][0].to_sym, bpr_element_methods[:BPR05][1]), #payment_format
        send(bpr_element_methods[:BPR06][0].to_sym, bpr_element_methods[:BPR06][1]), #dfi_id_no_qualifier
        send(bpr_element_methods[:BPR07][0].to_sym, bpr_element_methods[:BPR07][1]), #dfi_id_number
        send(bpr_element_methods[:BPR08][0].to_sym, bpr_element_methods[:BPR08][1]), #account_number_qualifier
        send(bpr_element_methods[:BPR09][0].to_sym, bpr_element_methods[:BPR09][1]), #account_number
        send(bpr_element_methods[:BPR10][0].to_sym, bpr_element_methods[:BPR10][1]), #originating_company_id
        send(bpr_element_methods[:BPR11][0].to_sym, bpr_element_methods[:BPR11][1]), #originating_company_code
        send(bpr_element_methods[:BPR12][0].to_sym, bpr_element_methods[:BPR12][1]), #extra_dfi_id_no_qualifier
        send(bpr_element_methods[:BPR13][0].to_sym, bpr_element_methods[:BPR13][1]), #extra_dfi_id_number
        send(bpr_element_methods[:BPR14][0].to_sym, bpr_element_methods[:BPR14][1]), #extra_account_number_qualifier
        send(bpr_element_methods[:BPR15][0].to_sym, bpr_element_methods[:BPR15][1]), #extra_account_number
        send(bpr_element_methods[:BPR16][0].to_sym, bpr_element_methods[:BPR16][1]), #payment_effective_date
        send(bpr_element_methods[:BPR17][0].to_sym, bpr_element_methods[:BPR17][1]), #business_function_code
        send(bpr_element_methods[:BPR18][0].to_sym, bpr_element_methods[:BPR18][1]), #dfi_id_number_qualifier
        send(bpr_element_methods[:BPR19][0].to_sym, bpr_element_methods[:BPR19][1]), #dfi_identification_number
        send(bpr_element_methods[:BPR20][0].to_sym, bpr_element_methods[:BPR20][1]), #blp_account_number_qualifier
        send(bpr_element_methods[:BPR21][0].to_sym, bpr_element_methods[:BPR21][1])  #blp_account_number
      ]
      @bpr_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def transaction_handle_code(*options)
    	code_types_list = {
    		:payment_accompanies_remittance_advice => 'C',
    		:make_payment_only => 'D',
    		:notification_only => 'H',
    		:remittance_information_only => 'I'
    	}
    	code_types_list[@check.get_code_type.to_sym]
    end

    def payment_amount(*options)
    	@check.formatted_check_amount.to_s
    end

    def credit_debit_flag(*options)
    	'C'
    end

    def payment_method(*options)
    	payment_methods_list = {
    		:automated_clearing_house => 'ACH',
    		:check => 'CHK',
    		:non_payment_data => 'NON'
    	}
    	payment_methods_list[@check.get_payment_method.to_sym]
    end

    def payment_format(*options)
    	@is_ach_payment ? 'CCP' : ''
    end

    def dfi_id_no_qualifier(*options)
    	if @is_ach_payment
    		'01'
    	elsif @facility.details[:micr_line_info]
    		@check_level_details[:is_correspondent] ? '' : '01'
    	else
    		blank_segment
    	end
    end

    def dfi_id_number(*options)
    	if @is_ach_payment
    		'999999999'
    	elsif @facility.details[:micr_line_info]
    		(@micr && !@check_level_details[:is_correspondent]) ? @micr.aba_routing_number.to_s.strip : ''
    	else
    		blank_segment
    	end
    end

    def account_number_qualifier(*options)
    	if @is_ach_payment
    		'DA'
    	elsif @facility.details[:micr_line_info]
    		@check_level_details[:is_correspondent] ? '' : 'DA'
    	else
    		blank_segment
    	end
    end

    def account_number(*options)
    	if @is_ach_payment
    		'999999999'
    	elsif @facility.details[:micr_line_info]
    		@check_level_details[:is_correspondent] ? '' : (@micr.payer_account_number.to_s.strip if @micr)
    	else
    		blank_segment
    	end
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

     def payment_effective_date(*options)
     payment_effective_date_for_basic_facility(*options)
    end

    def business_function_code(*options)
    end

    def dfi_id_number_qualifier(*options)
    end

    def dfi_identification_number(*options)
    end

    def blp_account_number_qualifier(*options)
    end

    def blp_account_number(*options)
    end
  # End of BPR Segment Details #

  # Start of TRN Segment Details #
    def print_trn_segment
      trn_element_methods = @segments_list[:TRN]
      @trn_elements = [
        send(trn_element_methods[:TRN00][0].to_sym, trn_element_methods[:TRN00][1]), #['segment_name', 'TRN']
        send(trn_element_methods[:TRN01][0].to_sym, trn_element_methods[:TRN01][1].to_s), #['print_constant', '1']
        send(trn_element_methods[:TRN02][0].to_sym, trn_element_methods[:TRN02][1]), #check_or_eft_trace_number
        send(trn_element_methods[:TRN03][0].to_sym, trn_element_methods[:TRN03][1]) #originating_company_id_trace
      ]
      @trn_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def check_or_eft_trace_number(*options)
      if @facility.custom_check_or_eft_trace_facilities.include?(@facility.name.upcase)
        file_number = @check.batch.file_name.split('_')[0][3..-1] rescue "0"
        date = @check.batch.date.strftime("%Y%m%d")
        "#{date}_#{file_number}"
      else
        @check.check_number || '0'
      end
    end

    def originating_company_id_trace(*options)
      return '1000000009' if @client.trn_03_exception_clients
      return @payment_classified_check.get_trn_03 if @payment_classified_check.is_non_zero_eft_check?
      return '1999999999'
    end
  # End of TRN Segment Details

  # Start of REF_EV Segment Details #
    def print_ref_ev_segment
      ref_ev_element_methods = @segments_list[:REF_EV]
      ref_ev_elements = verify_ref_ev_condition{
        [
          send(ref_ev_element_methods[:REF_EV00][0].to_sym, ref_ev_element_methods[:REF_EV00][1]), #['segment_name', 'REF']
          send(ref_ev_element_methods[:REF_EV01][0].to_sym, ref_ev_element_methods[:REF_EV01][1].to_s), #['print_constant', 'EV']
          send(ref_ev_element_methods[:REF_EV02][0].to_sym, ref_ev_element_methods[:REF_EV02][1]), #receiver_identification
          send(ref_ev_element_methods[:REF_EV03][0].to_sym, ref_ev_element_methods[:REF_EV03][1]), #ref_ev_description
          send(ref_ev_element_methods[:REF_EV04][0].to_sym, ref_ev_element_methods[:REF_EV04][1]), #ref_ev_reference_identifier
        ]
      }
      ref_ev_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def receiver_identification(*options)
      @check.batch.get_batchid(50)
    end

    def ref_ev_description(*options)
    end

    def ref_ev_reference_identifier(*options)
    end
  # End of REF_EV Segment Details

  # Start of REF_F2 Segment Details #
    def print_ref_f2_segment
      ref_f2_element_methods = @segments_list[:REF_F2]
      ref_f2_elements = verify_ref_f2_condition{
        [
          send(ref_f2_element_methods[:REF_F200][0].to_sym, ref_f2_element_methods[:REF_F200][1]), #nil_segment
          send(ref_f2_element_methods[:REF_F201][0].to_sym, ref_f2_element_methods[:REF_F201][1]), #nil_segment
          send(ref_f2_element_methods[:REF_F202][0].to_sym, ref_f2_element_methods[:REF_F202][1]), #nil_segment
          send(ref_f2_element_methods[:REF_F203][0].to_sym, ref_f2_element_methods[:REF_F203][1]), #ref_f2_description
          send(ref_f2_element_methods[:REF_F204][0].to_sym, ref_f2_element_methods[:REF_F204][1]) #ref_f2_reference_identifier
        ]
      }
      ref_f2_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def ref_f2_description(*options)
    end

    def ref_f2_reference_identifier(*options)
    end
  # End of REF_F2 Segment Details

  # Start of DTM_405 Segment Details #
    def print_dtm_405_segment
      dtm_405_element_methods = @segments_list[:DTM_405]
      dtm_405_elements = [
        send(dtm_405_element_methods[:DTM_40500][0].to_sym, dtm_405_element_methods[:DTM_40500][1]), #['segment_name', 'DTM']
        send(dtm_405_element_methods[:DTM_40501][0].to_sym, dtm_405_element_methods[:DTM_40501][1].to_s), #['print_constant', '405']
        send(dtm_405_element_methods[:DTM_40502][0].to_sym, dtm_405_element_methods[:DTM_40502][1]) #production_date
      ]
      dtm_405_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def production_date(*options)
      @check.batch.get_batch_date("%Y%m%d")
    end     
  # End of REF_F2 Segment Details

  # Start of N1_PR Segment Details #
    def print_n1_pr_segment
      n1_pr_element_methods = @segments_list[:N1_PR]
      n1_pr_elements = [
        send(n1_pr_element_methods[:N1_PR00][0].to_sym, n1_pr_element_methods[:N1_PR00][1]), #['segment_name', 'N1']
        send(n1_pr_element_methods[:N1_PR01][0].to_sym, n1_pr_element_methods[:N1_PR01][1].to_s), #['print_constant', 'PR']
        send(n1_pr_element_methods[:N1_PR02][0].to_sym, n1_pr_element_methods[:N1_PR02][1]) #payer_name
      ]
      n1_pr_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payer_name(*options)
      @payer.name.to_s.strip.upcase[0...60]
    end
  # End of N1_PR Segment Details

  # Start of N3_PR Segment Details #
    def print_n3_pr_segment
      n3_pr_element_methods = @segments_list[:N3_PR]
      n3_pr_elements = [
        send(n3_pr_element_methods[:N3_PR00][0].to_sym, n3_pr_element_methods[:N3_PR00][1]), #['segment_name', 'N3']
        send(n3_pr_element_methods[:N3_PR01][0].to_sym, n3_pr_element_methods[:N3_PR01][1]), #payer_address_one
        send(n3_pr_element_methods[:N3_PR02][0].to_sym, n3_pr_element_methods[:N3_PR02][1]) #payer_address_two
      ]
      n3_pr_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payer_address_one(*options)
      @payer.address_one.to_s.strip.upcase
    end

    def payer_address_two(*options)
    end
  # End of N3_PR Segment Details

  # Start of N4_PR Segment Details #
    def print_n4_pr_segment
      n4_pr_element_methods = @segments_list[:N4_PR]
      n4_pr_elements = [
        send(n4_pr_element_methods[:N4_PR00][0].to_sym, n4_pr_element_methods[:N4_PR00][1]), #['segment_name', 'N4']
        send(n4_pr_element_methods[:N4_PR01][0].to_sym, n4_pr_element_methods[:N4_PR01][1]), #payer_city
        send(n4_pr_element_methods[:N4_PR02][0].to_sym, n4_pr_element_methods[:N4_PR02][1]), #payer_state
        send(n4_pr_element_methods[:N4_PR03][0].to_sym, n4_pr_element_methods[:N4_PR03][1]) #payer_zip_code
      ]
      n4_pr_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payer_city(*options)
      @payer.city.to_s.strip.upcase
    end

    def payer_state(*options)
      @payer.state.to_s.strip.upcase
    end

    def payer_zip_code(*options)
      @payer.zip_code.to_s.strip.upcase
    end
  # End of N4_PR Segment Details

  # Start of REF_2U Segment Details #
    def print_ref_2u_segment
      ref_2u_element_methods = @segments_list[:REF_2U]
      ref_2u_elements = verify_ref_2u_condition{
        [
          send(ref_2u_element_methods[:REF_2U00][0].to_sym, ref_2u_element_methods[:REF_2U00][1]), #['segment_name', 'REF']
          send(ref_2u_element_methods[:REF_2U01][0].to_sym, ref_2u_element_methods[:REF_2U01][1]), #['print_constant', '2U']
          send(ref_2u_element_methods[:REF_2U02][0].to_sym, ref_2u_element_methods[:REF_2U02][1]) #payer_identification_number
        ]
      }
        ref_2u_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payer_identification_number(*options)
      nil
    end
  # End of REF_2U Segment Details

  # Start of PER_CX Segment Details #
    def print_per_cx_segment
      per_cx_element_methods = @segments_list[:PER_CX]
      per_cx_elements = verify_per_cx_condition{
        [
          send(per_cx_element_methods[:PER_CX00][0].to_sym, per_cx_element_methods[:PER_CX00][1]), #["payer_business_contact_information"]
          send(per_cx_element_methods[:PER_CX01][0].to_sym, per_cx_element_methods[:PER_CX01][1]), #["contact_function_code"]
          send(per_cx_element_methods[:PER_CX02][0].to_sym, per_cx_element_methods[:PER_CX02][1]), #payer_contact_name
          send(per_cx_element_methods[:PER_CX03][0].to_sym, per_cx_element_methods[:PER_CX03][1]), #payer_communication_qualifier
          send(per_cx_element_methods[:PER_CX04][0].to_sym, per_cx_element_methods[:PER_CX04][1]), #payer_contact_communication
          send(per_cx_element_methods[:PER_CX05][0].to_sym, per_cx_element_methods[:PER_CX05][1]), #payer_communication_number_qualifier_2
          send(per_cx_element_methods[:PER_CX06][0].to_sym, per_cx_element_methods[:PER_CX06][1]), #payer_contact_communication_2
          send(per_cx_element_methods[:PER_CX07][0].to_sym, per_cx_element_methods[:PER_CX07][1]), #payer_communication_number_qualifier_3
          send(per_cx_element_methods[:PER_CX08][0].to_sym, per_cx_element_methods[:PER_CX08][1]) #payer_contact_communication_3
        ]
      }
      per_cx_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payer_business_contact_information(*options)
    end

    def contact_function_code(*options)
    end
    
    def payer_contact_name(*options)
    end

    def payer_communication_qualifier(*options)
    end

    def payer_contact_communication(*options)
    end

    def payer_communication_number_qualifier_2(*options)
    end

    def payer_contact_communication_2(*options)
    end

    def payer_communication_number_qualifier_3(*options)
    end

    def payer_contact_communication_3(*options)
    end
  # End of REF_CX Segment Details

  # Start of PER_BL Segment Details #
    def print_per_bl_segment
      per_bl_element_methods = @segments_list[:PER_BL]
      per_bl_elements = verify_per_bl_condition{
        [
          send(per_bl_element_methods[:PER_BL00][0].to_sym, per_bl_element_methods[:PER_BL00][1]), #['segment_name', 'PER']
          send(per_bl_element_methods[:PER_BL01][0].to_sym, per_bl_element_methods[:PER_BL01][1]), #['print_constant', 'BL']
          send(per_bl_element_methods[:PER_BL02][0].to_sym, per_bl_element_methods[:PER_BL02][1]), #technical_department
          send(per_bl_element_methods[:PER_BL03][0].to_sym, per_bl_element_methods[:PER_BL03][1]), #tech_dept_communication_qualifier
          send(per_bl_element_methods[:PER_BL04][0].to_sym, per_bl_element_methods[:PER_BL04][1]), #tech_dept_contact_communication
          send(per_bl_element_methods[:PER_BL05][0].to_sym, per_bl_element_methods[:PER_BL05][1]), #tech_dept_communication_number_qualifier_2
          send(per_bl_element_methods[:PER_BL06][0].to_sym, per_bl_element_methods[:PER_BL06][1]), #tech_dept_contact_communication_2
          send(per_bl_element_methods[:PER_BL07][0].to_sym, per_bl_element_methods[:PER_BL07][1]), #tech_dept_communication_number_qualifier_3
          send(per_bl_element_methods[:PER_BL08][0].to_sym, per_bl_element_methods[:PER_BL08][1]) #tech_dept_contact_communication_3
        ]
      }
      per_bl_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def technical_department(*options)
      payer_name
    end

    def tech_dept_communication_qualifier(*options)
    end

    def tech_dept_contact_communication(*options)
    end

    def tech_dept_communication_number_qualifier_2(*options)
    end

    def tech_dept_contact_communication_2(*options)
    end

    def tech_dept_communication_number_qualifier_3(*options)
    end

    def tech_dept_contact_communication_3(*options)
    end
  # End of REF_BL Segment Details

  # Start of PER_IC Segment Details #
    def print_per_ic_segment
      per_ic_element_methods = @segments_list[:PER_IC]
      per_ic_elements = verify_per_ic_condition{
        [
          send(per_ic_element_methods[:PER_IC00][0].to_sym, per_ic_element_methods[:PER_IC00][1]), #["payer_web_site"]
          send(per_ic_element_methods[:PER_IC01][0].to_sym, per_ic_element_methods[:PER_IC01][1]), #["payer_web_site_function_code"]
          send(per_ic_element_methods[:PER_IC02][0].to_sym, per_ic_element_methods[:PER_IC02][1]), #payer_web_site_name
          send(per_ic_element_methods[:PER_IC03][0].to_sym, per_ic_element_methods[:PER_IC03][1]), #payer_web_site_communication_qualifier
          send(per_ic_element_methods[:PER_IC04][0].to_sym, per_ic_element_methods[:PER_IC04][1]), #payer_web_site_contact_communication
          send(per_ic_element_methods[:PER_IC05][0].to_sym, per_ic_element_methods[:PER_IC05][1]), #payer_web_site_communication_number_qualifier_2
          send(per_ic_element_methods[:PER_IC06][0].to_sym, per_ic_element_methods[:PER_IC06][1]), #payer_web_site_contact_communication_2
          send(per_ic_element_methods[:PER_IC07][0].to_sym, per_ic_element_methods[:PER_IC07][1]), #payer_web_site_communication_number_qualifier_3
          send(per_ic_element_methods[:PER_IC08][0].to_sym, per_ic_element_methods[:PER_IC08][1]) #payer_web_site_contact_communication_3
        ]
      }
      per_ic_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payer_web_site(*options)
    end

    def payer_web_site_function_code(*options)
    end
    
    def payer_web_site_name(*options)
    end

    def payer_web_site_communication_qualifier(*options)
    end

    def payer_web_site_contact_communication(*options)
    end

    def payer_web_site_communication_number_qualifier_2(*options)
    end

    def payer_web_site_contact_communication_2(*options)
    end

    def payer_web_site_communication_number_qualifier_3(*options)
    end

    def payer_web_site_contact_communication_3(*options)
    end
  # End of REF_IC Segment Details

  # Start of N1_PE Segment Details #
    def print_n1_pe_segment
      n1_pe_element_methods = @segments_list[:N1_PE]
      n1_pe_elements = [
        send(n1_pe_element_methods[:N1_PE00][0].to_sym, n1_pe_element_methods[:N1_PE00][1]), #['segment_name', 'N1']
        send(n1_pe_element_methods[:N1_PE01][0].to_sym, n1_pe_element_methods[:N1_PE01][1].to_s), #['print_constant', 'PE']
        send(n1_pe_element_methods[:N1_PE02][0].to_sym, n1_pe_element_methods[:N1_PE02][1]), #payee_name
        send(n1_pe_element_methods[:N1_PE03][0].to_sym, n1_pe_element_methods[:N1_PE03][1]), #identification_code_qualifier
        send(n1_pe_element_methods[:N1_PE04][0].to_sym, n1_pe_element_methods[:N1_PE04][1]) #identification_code
      ]
      n1_pe_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payee_name(*options)
      payee_name = get_payee_name || Unified835Output::BenignNull.new
      payee_name.strip.upcase
    end

    def identification_code_qualifier(*options)
      return 'XX' if @check.payee_npi?
      return 'FI' if @check.payee_tin?
      Unified835Output::BenignNull.new
    end

    def identification_code(*options)
      id_code = @check.payee_npi || @check.payee_tin
      id_code.to_s.strip.upcase
    end
  # End of N1_PE Segment Details

  # Start of N3_PE Segment Details #
    def print_n3_pe_segment
      n3_pe_element_methods = @segments_list[:N3_PE]
      n3_pe_elements = [
        send(n3_pe_element_methods[:N3_PE00][0].to_sym, n3_pe_element_methods[:N3_PE00][1]), #['segment_name', 'N3']
        send(n3_pe_element_methods[:N3_PE01][0].to_sym, n3_pe_element_methods[:N3_PE01][1]) #payee_address_one
      ]
      n3_pe_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payee_address_one(*options)
      @check_level_details[:address_payee].address_one.to_s.strip.upcase
    end
  # End of N3_PE Segment Details

  # Start of N4_PE Segment Details #
    def print_n4_pe_segment
      n4_pe_element_methods = @segments_list[:N4_PE]
      n4_pe_elements = [
        send(n4_pe_element_methods[:N4_PE00][0].to_sym, n4_pe_element_methods[:N4_PE00][1]), #['segment_name', 'N4']
        send(n4_pe_element_methods[:N4_PE01][0].to_sym, n4_pe_element_methods[:N4_PE01][1]), #payee_city
        send(n4_pe_element_methods[:N4_PE02][0].to_sym, n4_pe_element_methods[:N4_PE02][1]), #payee_state
        send(n4_pe_element_methods[:N4_PE03][0].to_sym, n4_pe_element_methods[:N4_PE03][1]) #payee_zip_code
      ]
      n4_pe_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def payee_city(*options)
      @check_level_details[:address_payee].city.to_s.strip.upcase
    end

    def payee_state(*options)
      @check_level_details[:address_payee].state.to_s.strip.upcase
    end

    def payee_zip_code(*options)
      @check_level_details[:address_payee].zip_code.to_s.strip.upcase      
    end
  # End of N4_PR Segment Details

  # Start of REF_TJ Segment Details #
    def print_ref_tj_segment
      ref_tj_element_methods = @segments_list[:REF_TJ]
      ref_tj_elements = verify_ref_tj_condition{
        [
          send(ref_tj_element_methods[:REF_TJ00][0].to_sym, ref_tj_element_methods[:REF_TJ00][1]), #['segment_name', 'REF']
          send(ref_tj_element_methods[:REF_TJ01][0].to_sym, ref_tj_element_methods[:REF_TJ01][1]), #['print_constant', 'TJ']
          send(ref_tj_element_methods[:REF_TJ02][0].to_sym, ref_tj_element_methods[:REF_TJ02][1]) #tax_payer_identification_number
        ]
      }
      ref_tj_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def tax_payer_identification_number(*options)
      tax_payer_id = has_default_lockbox_identification? ? facility_lockbix.tin : @check.payee_tin
      tax_payer_id.to_s.strip.upcase
    end  
  # End of REF_TJ Segment Details

  # Start of RDM Segment Details #
    def print_rdm_segment
      rdm_element_methods = @segments_list[:RDM]
      rdm_elements = verify_rdm_condition{
        [
          send(rdm_element_methods[:RDM00][0].to_sym, rdm_element_methods[:RDM00][1]), #remittance_delivery_method
          send(rdm_element_methods[:RDM01][0].to_sym, rdm_element_methods[:RDM01][1]), #report_transmission_code
          send(rdm_element_methods[:RDM02][0].to_sym, rdm_element_methods[:RDM02][1]), #report_name
          send(rdm_element_methods[:RDM03][0].to_sym, rdm_element_methods[:RDM03][1]) #report_communication_number
        ]
      }
      rdm_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def remittance_delivery_method(*options)
    end

    def report_transmission_code(*options)
    end

    def report_name(*options)
    end

    def report_communication_number(*options)
    end
  # End of RDM Segment Details

  #Start of LX Segment Details #
    def print_lx_segment
      lx_element_methods = @segments_list[:LX]
      lx_elements = [
        send(lx_element_methods[:LX00][0].to_sym, lx_element_methods[:LX00][1]), #['segment_name', 'LX']
        send(lx_element_methods[:LX01][0].to_sym, lx_element_methods[:LX01][1]) #assigned_number
      ]
      lx_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def assigned_number(*options)
      @claim_level_details[:index].to_s.rjust(4, '0')  
    end
  #End of LX Segment Details #

  # Start of TS3 Segment Details #
    def print_ts3_segment
      ts3_element_methods = @segments_list[:TS3]
      ts3_elements = verify_ts3_condition{
        [
          send(ts3_element_methods[:TS300][0].to_sym, ts3_element_methods[:TS300][1]), #provider_summary_info_header
          send(ts3_element_methods[:TS301][0].to_sym, ts3_element_methods[:TS301][1]), #provider_identifier
          send(ts3_element_methods[:TS302][0].to_sym, ts3_element_methods[:TS302][1]), #provider_summary_facility_code_value
          send(ts3_element_methods[:TS303][0].to_sym, ts3_element_methods[:TS303][1]), #fiscal_period_date
          send(ts3_element_methods[:TS304][0].to_sym, ts3_element_methods[:TS304][1]), #total_claim_count
          send(ts3_element_methods[:TS305][0].to_sym, ts3_element_methods[:TS305][1]) #total_claim_charge_amount_summary
        ]
      }
      ts3_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def provider_summary_info_header(*options)
      Unified835Output::BenignNull.new
    end

    def provider_identifier(*options)
      Unified835Output::BenignNull.new
    end

    def provider_summary_facility_code_value(*options)
      Unified835Output::BenignNull.new
    end

    def fiscal_period_date(*options)
      Unified835Output::BenignNull.new
    end

    def total_claim_count(*options)
      Unified835Output::BenignNull.new
    end

    def total_claim_charge_amount_summary(*options)
      Unified835Output::BenignNull.new
    end
  # End of TS3 Segment Details

  # Start of TS2 Segment Details #
    def print_ts2_segment
      ts2_element_methods = @segments_list[:TS2]
      ts2_elements = verify_ts2_condition{
        [
          send(ts2_element_methods[:TS200][0].to_sym, ts2_element_methods[:TS200][1]), #provider_supplemental_summary_info
          send(ts2_element_methods[:TS201][0].to_sym, ts2_element_methods[:TS201][1]), #total_drg_amount
          send(ts2_element_methods[:TS202][0].to_sym, ts2_element_methods[:TS202][1]), #total_federal_specific_amount
          send(ts2_element_methods[:TS203][0].to_sym, ts2_element_methods[:TS203][1]), #total_hospital_specific_amount
          send(ts2_element_methods[:TS204][0].to_sym, ts2_element_methods[:TS204][1]), #toal_disproportionate_amount
          send(ts2_element_methods[:TS205][0].to_sym, ts2_element_methods[:TS205][1]), #total_capital_amount
          send(ts2_element_methods[:TS206][0].to_sym, ts2_element_methods[:TS206][1]), #total_indirect_medical_education_amount
          send(ts2_element_methods[:TS207][0].to_sym, ts2_element_methods[:TS207][1]), #total_outlier_day_count
          send(ts2_element_methods[:TS208][0].to_sym, ts2_element_methods[:TS208][1]), #total_day_outlier_amount
          send(ts2_element_methods[:TS209][0].to_sym, ts2_element_methods[:TS209][1]), #total_cost_outlier_amount
          send(ts2_element_methods[:TS210][0].to_sym, ts2_element_methods[:TS210][1]), #average_drg_length_of_stay
          send(ts2_element_methods[:TS211][0].to_sym, ts2_element_methods[:TS211][1]), #total_discharge_count
          send(ts2_element_methods[:TS212][0].to_sym, ts2_element_methods[:TS212][1]), #total_cost_report_day_count
          send(ts2_element_methods[:TS213][0].to_sym, ts2_element_methods[:TS213][1]), #total_covered_day_count
          send(ts2_element_methods[:TS214][0].to_sym, ts2_element_methods[:TS214][1]), #total_noncovered_day_count
          send(ts2_element_methods[:TS215][0].to_sym, ts2_element_methods[:TS215][1]), #total_msp_pass_through_amount
          send(ts2_element_methods[:TS216][0].to_sym, ts2_element_methods[:TS216][1]), #average_drg_weight
          send(ts2_element_methods[:TS217][0].to_sym, ts2_element_methods[:TS217][1]), #total_pps_capital_fsp_drg_amount
          send(ts2_element_methods[:TS218][0].to_sym, ts2_element_methods[:TS218][1]), #total_psp_capital_hsp_drg_amount
          send(ts2_element_methods[:TS219][0].to_sym, ts2_element_methods[:TS219][1]) #total_pps_dsh_drg_amount
        ]
      }
      ts2_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def provider_supplemental_summary_info(*options)
    end

    def total_drg_amount(*options)
    end

    def total_federal_specific_amount(*options)
    end

    def total_hospital_specific_amount(*options)
    end

    def toal_disproportionate_amount(*options)
    end

    def total_capital_amount(*options)
    end

    def total_indirect_medical_education_amount(*options)
    end

    def total_outlier_day_count(*options)
    end

    def total_day_outlier_amount(*options)
    end

    def total_cost_outlier_amount(*options)
    end

    def average_drg_length_of_stay(*options)
    end

    def total_discharge_count(*options)
    end

    def total_cost_report_day_count(*options)
    end

    def total_covered_day_count(*options)
    end

    def total_noncovered_day_count(*options)
    end

    def total_msp_pass_through_amount(*options)
    end

    def average_drg_weight(*options)
    end

    def total_pps_capital_fsp_drg_amount(*options)
    end

    def total_psp_capital_hsp_drg_amount(*options)
    end

    def total_pps_dsh_drg_amount(*options)
    end
  # End of TS2 Segment Details

  # Start of CLP Segment Details #
    def print_clp_segment
      clp_element_methods = @segments_list[:CLP]
      clp_elements = [
        send(clp_element_methods[:CLP00][0].to_sym, clp_element_methods[:CLP00][1]), #['segment_name', 'CLP']
        send(clp_element_methods[:CLP01][0].to_sym, clp_element_methods[:CLP01][1]), #claim_submitter_identifier
        send(clp_element_methods[:CLP02][0].to_sym, clp_element_methods[:CLP02][1]), #claim_status_code
        send(clp_element_methods[:CLP03][0].to_sym, clp_element_methods[:CLP03][1]), #total_claim_charge_amount
        send(clp_element_methods[:CLP04][0].to_sym, clp_element_methods[:CLP04][1]), #claim_payment_amount
        send(clp_element_methods[:CLP05][0].to_sym, clp_element_methods[:CLP05][1]), #patient_responsibility_amount
        send(clp_element_methods[:CLP06][0].to_sym, clp_element_methods[:CLP06][1]), #claim_filing_indicator_code
        send(clp_element_methods[:CLP07][0].to_sym, clp_element_methods[:CLP07][1]), #payer_claim_control_number
        send(clp_element_methods[:CLP08][0].to_sym, clp_element_methods[:CLP08][1]), #facility_code_value
        send(clp_element_methods[:CLP09][0].to_sym, clp_element_methods[:CLP09][1]), #claim_frequency_type_code
        send(clp_element_methods[:CLP10][0].to_sym, clp_element_methods[:CLP10][1]), #patient_status_code
        send(clp_element_methods[:CLP11][0].to_sym, clp_element_methods[:CLP11][1]), #diagnosis_related_group_code
        send(clp_element_methods[:CLP12][0].to_sym, clp_element_methods[:CLP12][1]) #diagnosis_related_weight
      ]
      clp_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def claim_submitter_identifier(*options)
      captured_or_blank_value(:patient_account_number_default_match, @eob.patient_account_number)
    end

    def claim_status_code(*options)
      @eob.claim_type_weight
    end

    def total_claim_charge_amount(*options)
      @eob.amount('total_submitted_charge_for_claim')
    end

    def claim_payment_amount(*options)
      @eob.payment_amount_for_output(@facility, @output_config)
    end

    def patient_responsibility_amount(*options)
      # patient_responsibility_amount = (@eob.claim_type_weight == 22) ? "" : @eob.patient_responsibility_amount
      # zero_formatted_amount(patient_responsibility_amount)
      "PATIENT_RESPONSIBILITY_AMOUNT"
    end

    def claim_filing_indicator_code(*options)
      @eob.plan_type
    end

    def payer_claim_control_number(*options)
      @eob.claim_number.to_s
    end

    def facility_code_value(*options)
      return @eob.get_place_of_service_for_orbo_client if @facility.client.is_orbo_client?
      @claim.try(:facility_type_code)
    end

    def claim_frequency_type_code(*options)
      @claim.try(:claim_frequency_type_code)
    end

    def patient_status_code(*options)
      nil_segment
    end

    def diagnosis_related_group_code(*options)
      @eob.drg_code if @eob.drg_code.present?
    end

     def diagnosis_related_weight(*options)
      nil_segment
    end
  # End of CLP Segment Details

  # Start of NM1_QC Segment Details #
    def print_nm1_qc_segment
      nm1_qc_element_methods = @segments_list[:NM1_QC]
      nm1_qc_elements = [
        send(nm1_qc_element_methods[:NM1_QC00][0].to_sym, nm1_qc_element_methods[:NM1_QC00][1]), #['segment_name', 'NM1']
        send(nm1_qc_element_methods[:NM1_QC01][0].to_sym, nm1_qc_element_methods[:NM1_QC01][1]), #['print_constant', 'QC']
        send(nm1_qc_element_methods[:NM1_QC02][0].to_sym, nm1_qc_element_methods[:NM1_QC02][1]), #['print_constant', '1']
        send(nm1_qc_element_methods[:NM1_QC03][0].to_sym, nm1_qc_element_methods[:NM1_QC03][1]), #patient_last_name
        send(nm1_qc_element_methods[:NM1_QC04][0].to_sym, nm1_qc_element_methods[:NM1_QC04][1]), #patient_first_name
        send(nm1_qc_element_methods[:NM1_QC05][0].to_sym, nm1_qc_element_methods[:NM1_QC05][1]), #patient_middle_name_or_initial
        send(nm1_qc_element_methods[:NM1_QC06][0].to_sym, nm1_qc_element_methods[:NM1_QC06][1]), #blank_segment
        send(nm1_qc_element_methods[:NM1_QC07][0].to_sym, nm1_qc_element_methods[:NM1_QC07][1]), #patient_name_suffix
        send(nm1_qc_element_methods[:NM1_QC08][0].to_sym, nm1_qc_element_methods[:NM1_QC08][1]), #patient_identification_code_qualifier
        send(nm1_qc_element_methods[:NM1_QC09][0].to_sym, nm1_qc_element_methods[:NM1_QC09][1]) #patient_identifier
      ]
      nm1_qc_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def patient_last_name(*options)
      captured_or_blank_value(:patient_last_name_default_match, @eob.patient_last_name)
    end

    def patient_first_name(*options)
      captured_or_blank_value(:patient_first_name_default_match, @eob.patient_first_name)
    end

    def patient_middle_name_or_initial(*options)
      @eob.patient_middle_initial.to_s.strip
    end

    def patient_name_suffix(*options)
      @eob.patient_suffix
    end

    def patient_identification_code_qualifier(*options)
      @claim_level_details[:patient_code_qualifier]
    end

    def patient_identifier(*options)
      @claim_level_details[:patient_id]
    end
  # End of NM1_QC Segment Details

  # Start of NM1_IL Segment Details #
    def print_nm1_il_segment
      nm1_il_element_methods = @segments_list[:NM1_IL]
      nm1_il_elements = verify_nm1_il_condition{
        [
          send(nm1_il_element_methods[:NM1_IL00][0].to_sym, nm1_il_element_methods[:NM1_IL00][1]), #['segment_name', 'NM1']
          send(nm1_il_element_methods[:NM1_IL01][0].to_sym, nm1_il_element_methods[:NM1_IL01][1]), #['print_constant', 'IL']
          send(nm1_il_element_methods[:NM1_IL02][0].to_sym, nm1_il_element_methods[:NM1_IL02][1]), #['print_constant', '1']
          send(nm1_il_element_methods[:NM1_IL03][0].to_sym, nm1_il_element_methods[:NM1_IL03][1]), #subscriber_last_name
          send(nm1_il_element_methods[:NM1_IL04][0].to_sym, nm1_il_element_methods[:NM1_IL04][1]), #subscriber_first_name
          send(nm1_il_element_methods[:NM1_IL05][0].to_sym, nm1_il_element_methods[:NM1_IL05][1]), #subscriber_middle_name_or_initial
          send(nm1_il_element_methods[:NM1_IL06][0].to_sym, nm1_il_element_methods[:NM1_IL06][1]), #blank_segment
          send(nm1_il_element_methods[:NM1_IL07][0].to_sym, nm1_il_element_methods[:NM1_IL07][1]), #subscriber_name_suffix
          send(nm1_il_element_methods[:NM1_IL08][0].to_sym, nm1_il_element_methods[:NM1_IL08][1]), #subscriber_identification_code_qualifier
          send(nm1_il_element_methods[:NM1_IL09][0].to_sym, nm1_il_element_methods[:NM1_IL09][1]) #subscriber_identifier
        ]
      }
      nm1_il_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def subscriber_last_name(*options)
      @eob.subscriber_last_name
    end

    def subscriber_first_name(*options)
      @eob.subscriber_first_name
    end

    def subscriber_middle_name_or_initial(*options)
      @eob.subscriber_middle_initial
    end

    def subscriber_name_suffix(*options)
      @eob.subscriber_suffix
    end

    def subscriber_identification_code_qualifier(*options)
       @claim_level_details[:subscriber_code_qualifier]
    end

    def subscriber_identifier(*options)
       @claim_level_details[:subscriber_id]
    end
  # End of NM1_IL Segment Details

  # Start of NM1_74 Segment Details #
    def print_nm1_74_segment
      nm1_74_element_methods = @segments_list[:NM1_74]
      nm1_74_elements = [
        send(nm1_74_element_methods[:NM1_7400][0].to_sym, nm1_74_element_methods[:NM1_7400][1]), #corrected_patient_or_insured_name
        send(nm1_74_element_methods[:NM1_7401][0].to_sym, nm1_74_element_methods[:NM1_7401][1]), #corrected_patient_entity_identifier_code
        send(nm1_74_element_methods[:NM1_7402][0].to_sym, nm1_74_element_methods[:NM1_7402][1]), #corrected_patient_entity_type_qualifier
        send(nm1_74_element_methods[:NM1_7403][0].to_sym, nm1_74_element_methods[:NM1_7403][1]), #corrected_patient_or_insurer_last_name
        send(nm1_74_element_methods[:NM1_7404][0].to_sym, nm1_74_element_methods[:NM1_7404][1]), #corrected_patient_or_insurer_first_name
        send(nm1_74_element_methods[:NM1_7405][0].to_sym, nm1_74_element_methods[:NM1_7405][1]), #corrected_patient_or_insurer_middle_name
        send(nm1_74_element_methods[:NM1_7406][0].to_sym, nm1_74_element_methods[:NM1_7406][1]), #corrected_patient_or_insurer_name_prefix
        send(nm1_74_element_methods[:NM1_7407][0].to_sym, nm1_74_element_methods[:NM1_7407][1]), #corrected_patient_name_suffix
        send(nm1_74_element_methods[:NM1_7408][0].to_sym, nm1_74_element_methods[:NM1_7408][1]), #corrected_patient_identification_code_qualifier
        send(nm1_74_element_methods[:NM1_7409][0].to_sym, nm1_74_element_methods[:NM1_7409][1]), #corrected_insurer_identification_indicator
        send(nm1_74_element_methods[:NM1_7410][0].to_sym, nm1_74_element_methods[:NM1_7410][1])  #entity_relationship_code
      ]
      nm1_74_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def corrected_patient_or_insured_name(*options)
    end

    def corrected_patient_entity_identifier_code(*options)
    end

    def corrected_patient_entity_type_qualifier(*options)
    end

    def corrected_patient_or_insurer_last_name(*options)
    end

    def corrected_patient_or_insurer_first_name(*options)
    end

    def corrected_patient_or_insurer_middle_name(*options)
    end

    def corrected_patient_or_insurer_name_prefix(*options)
    end

    def corrected_patient_name_suffix(*options)
    end

    def corrected_patient_identification_code_qualifier(*options)
    end

    def corrected_insurer_identification_indicator(*options)
    end

    def entity_relationship_code(*options)
    end
  # End of NM1_74 Segment Details

  # Start of NM1_82 Segment Details #
    def print_nm1_82_segment
      nm1_82_element_methods = @segments_list[:NM1_82]
      nm1_82_elements = [
        send(nm1_82_element_methods[:NM1_8200][0].to_sym, nm1_82_element_methods[:NM1_8200][1]), #['segment_name', 'NM1']
        send(nm1_82_element_methods[:NM1_8201][0].to_sym, nm1_82_element_methods[:NM1_8201][1]), #['print_constant', '82']
        send(nm1_82_element_methods[:NM1_8202][0].to_sym, nm1_82_element_methods[:NM1_8202][1]), #entity_type_qualifier
        send(nm1_82_element_methods[:NM1_8203][0].to_sym, nm1_82_element_methods[:NM1_8203][1]), #rendering_provider_last_or_organization_name
        send(nm1_82_element_methods[:NM1_8204][0].to_sym, nm1_82_element_methods[:NM1_8204][1]), #rendering_provider_first_name
        send(nm1_82_element_methods[:NM1_8205][0].to_sym, nm1_82_element_methods[:NM1_8205][1]), #rendering_provider_middle_name_or_initial
        send(nm1_82_element_methods[:NM1_8206][0].to_sym, nm1_82_element_methods[:NM1_8206][1]), #blank_segment
        send(nm1_82_element_methods[:NM1_8207][0].to_sym, nm1_82_element_methods[:NM1_8207][1]), #rendering_provider_name_suffix
        send(nm1_82_element_methods[:NM1_8208][0].to_sym, nm1_82_element_methods[:NM1_8208][1]), #rendering_provider_identification_code_qualifier
        send(nm1_82_element_methods[:NM1_8209][0].to_sym, nm1_82_element_methods[:NM1_8209][1]) #rendering_provider_identifier
      ]
      nm1_82_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def entity_type_qualifier(*options)
      @eob.rendering_provider_last_name.to_s.blank? ? '2' : '1'
    end

    def rendering_provider_last_or_organization_name(*options)
      names_list = [@eob.rendering_provider_last_name, @eob.provider_organisation, @facility.name]
      names_list.each do |name|
        return name.to_s.upcase if name.present?
      end
    end

    def rendering_provider_first_name(*options)
      @eob.rendering_provider_first_name.upcase
    end

    def rendering_provider_middle_name_or_initial(*options)
      @eob.rendering_provider_middle_initial
    end

    def rendering_provider_name_suffix(*options)
      @eob.rendering_provider_suffix
    end

    def rendering_provider_identification_code_qualifier(*options)
      @claim_level_details[:rendering_provider_qualifier]
    end

    def rendering_provider_identifier(*options)
      @claim_level_details[:rendering_provider_id]
    end
  # End of NM1_82 Segment Details

  # Start of NM1_TT Segment Details #
    def print_nm1_tt_segment
      nm1_tt_element_methods = @segments_list[:NM1_TT]
      nm1_tt_elements = [
        send(nm1_tt_element_methods[:NM1_TT00][0].to_sym, nm1_tt_element_methods[:NM1_TT00][1]), #crossover_carrier_name
        send(nm1_tt_element_methods[:NM1_TT01][0].to_sym, nm1_tt_element_methods[:NM1_TT01][1]), #carrier_name_entity_identifier_code
        send(nm1_tt_element_methods[:NM1_TT02][0].to_sym, nm1_tt_element_methods[:NM1_TT02][1]), #coordination_of_benefits_carrier_name
        send(nm1_tt_element_methods[:NM1_TT03][0].to_sym, nm1_tt_element_methods[:NM1_TT03][1]), #carrier_last_or_organization_name
        send(nm1_tt_element_methods[:NM1_TT04][0].to_sym, nm1_tt_element_methods[:NM1_TT04][1]), #carrier_first_name
        send(nm1_tt_element_methods[:NM1_TT05][0].to_sym, nm1_tt_element_methods[:NM1_TT05][1]), #carrier_middle_name
        send(nm1_tt_element_methods[:NM1_TT06][0].to_sym, nm1_tt_element_methods[:NM1_TT06][1]), #carrier_name_prefix
        send(nm1_tt_element_methods[:NM1_TT07][0].to_sym, nm1_tt_element_methods[:NM1_TT07][1]), #carrier_name_suffix
        send(nm1_tt_element_methods[:NM1_TT08][0].to_sym, nm1_tt_element_methods[:NM1_TT08][1]), #carrier_identification_code_qualifier
        send(nm1_tt_element_methods[:NM1_TT09][0].to_sym, nm1_tt_element_methods[:NM1_TT09][1])  #coordination_of_benefits_carrier_identifier
      ]
      nm1_tt_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def crossover_carrier_name(*options)
    end

    def carrier_name_entity_identifier_code(*options)
    end

    def coordination_of_benefits_carrier_name(*options)
    end

    def carrier_last_or_organization_name(*options)
    end

    def carrier_first_name(*options)
    end

    def carrier_middle_name(*options)
    end

    def carrier_name_prefix(*options)
    end

    def carrier_name_suffix(*options)
    end

    def carrier_identification_code_qualifier(*options)
    end

    def coordination_of_benefits_carrier_identifier(*options)
    end
  # End of NM1_TT Segment Details

  # Start of NM1_PR Segment Details #
    def print_nm1_pr_segment
      nm1_pr_element_methods = @segments_list[:NM1_PR]
      nm1_pr_elements = verify_nm1_pr_condition{
        [
          send(nm1_pr_element_methods[:NM1_PR00][0].to_sym, nm1_pr_element_methods[:NM1_PR00][1]), #['segment_name', 'NM1']
          send(nm1_pr_element_methods[:NM1_PR01][0].to_sym, nm1_pr_element_methods[:NM1_PR01][1]), #['print_constant', 'PR']
          send(nm1_pr_element_methods[:NM1_PR02][0].to_sym, nm1_pr_element_methods[:NM1_PR02][1]), #['print_constant', '2']
          send(nm1_pr_element_methods[:NM1_PR03][0].to_sym, nm1_pr_element_methods[:NM1_PR03][1]) #corrected_priority_payer_name
        ]
      }
      nm1_pr_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def corrected_priority_payer_name(*options)
      @check.alternate_payer_name.to_s.strip
    end
  # End of NM1_PR Segment Details

  # Start of NM1_GB Segment Details #
    def print_nm1_gb_segment
      nm1_gb_element_methods = @segments_list[:NM1_GB]
      nm1_gb_elements = [
        send(nm1_gb_element_methods[:NM1_GB00][0].to_sym, nm1_gb_element_methods[:NM1_GB00][1]), #other_subscriber_name
        send(nm1_gb_element_methods[:NM1_GB01][0].to_sym, nm1_gb_element_methods[:NM1_GB01][1]), #other_subscriber_entity_identifier_code
        send(nm1_gb_element_methods[:NM1_GB02][0].to_sym, nm1_gb_element_methods[:NM1_GB02][1]), #other_subscriber_entity_type_qualifier
        send(nm1_gb_element_methods[:NM1_GB03][0].to_sym, nm1_gb_element_methods[:NM1_GB03][1]), #other_subscriber_last_name
        send(nm1_gb_element_methods[:NM1_GB04][0].to_sym, nm1_gb_element_methods[:NM1_GB04][1]), #other_subscriber_first_name
        send(nm1_gb_element_methods[:NM1_GB05][0].to_sym, nm1_gb_element_methods[:NM1_GB05][1]), #other_subscriber_middle_name
        send(nm1_gb_element_methods[:NM1_GB06][0].to_sym, nm1_gb_element_methods[:NM1_GB06][1]), #other_subscriber_name_prefix
        send(nm1_gb_element_methods[:NM1_GB07][0].to_sym, nm1_gb_element_methods[:NM1_GB07][1]), #other_subscriber_name_suffix
        send(nm1_gb_element_methods[:NM1_GB08][0].to_sym, nm1_gb_element_methods[:NM1_GB08][1]), #other_subscriber_code_qualifier
        send(nm1_gb_element_methods[:NM1_GB09][0].to_sym, nm1_gb_element_methods[:NM1_GB09][1])  #other_subscriber_indicator
      ]
      nm1_gb_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def other_subscriber_name(*options)
    end

    def other_subscriber_entity_identifier_code(*options)
    end

    def other_subscriber_entity_type_qualifier(*options)
    end

    def other_subscriber_last_name(*options)
    end

    def other_subscriber_first_name(*options)
    end

    def other_subscriber_middle_name(*options)
    end

    def other_subscriber_name_prefix(*options)
    end

    def other_subscriber_name_suffix(*options)
    end

    def other_subscriber_code_qualifier(*options)
    end

    def other_subscriber_indicator(*options)
    end
  # End of NM1_GB Segment Details

  # Start of REF_1L Segment Details #
    def print_ref_1l_reference_identification
      ref_1l_element_methods = @segments_list[:REF_1L]
      ref_1l_elements = verify_ref_1l_condition{
        [
          send(ref_1l_element_methods[:REF_1L00][0].to_sym, ref_1l_element_methods[:REF_1L00][1]), #['segment_name', 'REF']
          send(ref_1l_element_methods[:REF_1L01][0].to_sym, ref_1l_element_methods[:REF_1L01][1].to_s), #['print_constant', '1L']
          send(ref_1l_element_methods[:REF_1L02][0].to_sym, ref_1l_element_methods[:REF_1L02][1]) #reference_identification
        ]
      }
      ref_1l_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

      def reference_identification(*options)
      nil_segment
    end
  # End of REF_1L Segment Details

  # Start of REF_ZZ Segment Details #
    def print_ref_zz_segment
      ref_zz_element_methods = @segments_list[:REF_ZZ]
      ref_zz_elements = verify_ref_zz_condition{
        [
          send(ref_zz_element_methods[:REF_ZZ00][0].to_sym, ref_zz_element_methods[:REF_ZZ00][1]), #['segment_name', 'REF']
          send(ref_zz_element_methods[:REF_ZZ01][0].to_sym, ref_zz_element_methods[:REF_ZZ01][1].to_s), #['print_constant', 'ZZ']
          send(ref_zz_element_methods[:REF_ZZ02][0].to_sym, ref_zz_element_methods[:REF_ZZ02][1]) #original_image_name
        ]
      }
      ref_zz_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def original_image_name(*options)
      nil_segment
    end
  # End of REF_ZZ Segment Details

  # Start of REF_EA Segment Details #
    def print_ref_ea_segment
      ref_ea_element_methods = @segments_list[:REF_EA]
      ref_ea_elements = verify_ref_ea_condition{
        [
          send(ref_ea_element_methods[:REF_EA00][0].to_sym, ref_ea_element_methods[:REF_EA00][1]), #['segment_name', 'REF']
          send(ref_ea_element_methods[:REF_EA01][0].to_sym, ref_ea_element_methods[:REF_EA01][1].to_s), #['print_constant', 'EA']
          send(ref_ea_element_methods[:REF_EA02][0].to_sym, ref_ea_element_methods[:REF_EA02][1]) #medical_record_number
        ]
      }
      ref_ea_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def medical_record_number(*options)
      @eob.medical_record_number || @claim.try(:medical_record_number)
    end
  # End of REF_EA Segment Details

  # Start of REF_BB Segment Details #
    def print_ref_bb_segment
      ref_bb_element_methods = @segments_list[:REF_BB]
      ref_bb_elements = verify_ref_bb_condition{
        [
          send(ref_bb_element_methods[:REF_BB00][0].to_sym, ref_bb_element_methods[:REF_BB00][1]), #['segment_name', 'REF']
          send(ref_bb_element_methods[:REF_BB01][0].to_sym, ref_bb_element_methods[:REF_BB01][1].to_s), #['print_constant', 'BB']
          send(ref_bb_element_methods[:REF_BB02][0].to_sym, ref_bb_element_methods[:REF_BB02][1]) #authorization_number
        ]
      }
      ref_bb_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def authorization_number(*options)
      nil_segment
    end
  # End of REF_BB Segment Details

  # Start of REF_IG Segment Details #
    def print_ref_ig_segment
      ref_ig_element_methods = @segments_list[:REF_IG]
      ref_ig_elements = verify_ref_ig_condition{
        [
          send(ref_ig_element_methods[:REF_IG00][0].to_sym, ref_ig_element_methods[:REF_IG00][1]), #['segment_name', 'REF']
          send(ref_ig_element_methods[:REF_IG01][0].to_sym, ref_ig_element_methods[:REF_IG01][1].to_s), #['print_constant', 'IG']
          send(ref_ig_element_methods[:REF_IG02][0].to_sym, ref_ig_element_methods[:REF_IG02][1]) #insurance_policy_number
        ]
      }
      ref_ig_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def insurance_policy_number(*options)
      @eob.insurance_policy_number
    end
  # End of REF_IG Segment Details

  # Start of REF_F8 Segment Details #
    def print_ref_f8_segment
      ref_f8_element_methods = @segments_list[:REF_F8]
      ref_f8_elements = verify_ref_f8_condition{
        [
          send(ref_f8_element_methods[:REF_F800][0].to_sym, ref_f8_element_methods[:REF_F800][1]), #['segment_name', 'REF']
          send(ref_f8_element_methods[:REF_F801][0].to_sym, ref_f8_element_methods[:REF_F801][1].to_s), #['print_constant', 'F8']
          send(ref_f8_element_methods[:REF_F802][0].to_sym, ref_f8_element_methods[:REF_F802][1]) #original_reference_number
        ]
      }
      ref_f8_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def original_reference_number(*options)
    end
  # End of REF_F8 Segment Details

  # Start of DTM_232 Segment Details #
    def print_dtm_232_segment
      dtm_232_element_methods = @segments_list[:DTM_232]
      dtm_232_elements = verify_dtm_232_condition{
        [
          send(dtm_232_element_methods[:DTM_23200][0].to_sym, dtm_232_element_methods[:DTM_23200][1]), #['segment_name', 'DTM']
          send(dtm_232_element_methods[:DTM_23201][0].to_sym, dtm_232_element_methods[:DTM_23201][1].to_s), #['print_constant', '232']
          send(dtm_232_element_methods[:DTM_23202][0].to_sym, dtm_232_element_methods[:DTM_23202][1]) #claim_statement_period_start
        ]
      }
      dtm_232_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def claim_statement_period_start(*options)
      claim_start_date = @classified_eob.get_start_date(@claim)
      return nil if claim_start_date.nil?
      claim_start_date if can_print_service_date(claim_start_date)
    end
  # End of DTM_232 Segment Details

  # Start of DTM_233 Segment Details #
    def print_dtm_233_segment
      dtm_233_element_methods = @segments_list[:DTM_233]
      dtm_233_elements = verify_dtm_233_condition{
        [
          send(dtm_233_element_methods[:DTM_23300][0].to_sym, dtm_233_element_methods[:DTM_23300][1]), #['segment_name', 'DTM']
          send(dtm_233_element_methods[:DTM_23301][0].to_sym, dtm_233_element_methods[:DTM_23301][1].to_s), #['print_constant', '233']
          send(dtm_233_element_methods[:DTM_23302][0].to_sym, dtm_233_element_methods[:DTM_23302][1]) #claim_statement_period_end
        ]
      }
      dtm_233_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def claim_statement_period_end(*options)
      claim_end_date = @classified_eob.get_end_date(@claim)
      return nil if claim_end_date.nil?
      claim_end_date if can_print_service_date(claim_end_date)
    end
  # End of DTM_233 Segment Details

  # Start of DTM_036 Segment Details #
    def print_dtm_036_segment
      dtm_036_element_methods = @segments_list[:DTM_036]
      dtm_036_elements = verify_dtm_036_condition{
        [
          send(dtm_036_element_methods[:DTM_03600][0].to_sym, dtm_036_element_methods[:DTM_03600][1]), #coverage_expiration_date
          send(dtm_036_element_methods[:DTM_03601][0].to_sym, dtm_036_element_methods[:DTM_03601][1].to_s), #coverage_date_qualifier
          send(dtm_036_element_methods[:DTM_03602][0].to_sym, dtm_036_element_methods[:DTM_03602][1]) #expiration_date
        ]
      }
      dtm_036_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def coverage_expiration_date(*options)
    end

    def coverage_date_qualifier(*options)
    end

    def expiration_date(*options)
    end
  # End of DTM_036 Segment Details

  # Start of DTM_050 Segment Details #
    def print_dtm_050_segment
      dtm_050_element_methods = @segments_list[:DTM_050]
      dtm_050_elements = verify_dtm_050_condition{
        [
          send(dtm_050_element_methods[:DTM_05000][0].to_sym, dtm_050_element_methods[:DTM_05000][1]), #claim_received_date
          send(dtm_050_element_methods[:DTM_05001][0].to_sym, dtm_050_element_methods[:DTM_05001][1].to_s), #claim_date_qualifier
          send(dtm_050_element_methods[:DTM_05002][0].to_sym, dtm_050_element_methods[:DTM_05002][1]) #received_date
        ]
      }
      dtm_050_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def claim_received_date(*options)
      nil_segment
    end
  # End of DTM_050 Segment Details

  # Start of PER_CX2 Segment Details #
    def print_per_cx2_segment
      per_cx2_element_methods = @segments_list[:PER_CX2]
      per_cx2_elements = verify_per_cx2_condition{
        [
          send(per_cx2_element_methods[:PER_CX200][0].to_sym, per_cx2_element_methods[:PER_CX200][1]), #["claim_contact_information"]
          send(per_cx2_element_methods[:PER_CX201][0].to_sym, per_cx2_element_methods[:PER_CX201][1]), #["claim_contact_function_code"]
          send(per_cx2_element_methods[:PER_CX202][0].to_sym, per_cx2_element_methods[:PER_CX202][1]), #claim_contact_name
          send(per_cx2_element_methods[:PER_CX203][0].to_sym, per_cx2_element_methods[:PER_CX203][1]), #claim_contact_communication_qualifier
          send(per_cx2_element_methods[:PER_CX204][0].to_sym, per_cx2_element_methods[:PER_CX204][1]), #claim_contact_contact_communication
          send(per_cx2_element_methods[:PER_CX205][0].to_sym, per_cx2_element_methods[:PER_CX205][1]), #claim_contact_communication_number_qualifier_2
          send(per_cx2_element_methods[:PER_CX206][0].to_sym, per_cx2_element_methods[:PER_CX206][1]), #claim_contact_contact_communication_2
          send(per_cx2_element_methods[:PER_CX207][0].to_sym, per_cx2_element_methods[:PER_CX207][1]), #claim_contact_communication_number_qualifier_3
          send(per_cx2_element_methods[:PER_CX208][0].to_sym, per_cx2_element_methods[:PER_CX208][1]) #claim_contact_contact_communication_3
        ]
      }
      per_cx2_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def claim_contact_information(*options)
    end

    def claim_contact_function_code(*options)
    end
    
    def claim_contact_name(*options)
    end

    def claim_contact_communication_qualifier(*options)
    end

    def claim_contact_contact_communication(*options)
    end

    def claim_contact_communication_number_qualifier_2(*options)
    end

    def claim_contact_contact_communication_2(*options)
    end

    def claim_contact_communication_number_qualifier_3(*options)
    end

    def claim_contact_contact_communication_3(*options)
    end
  # End of REF_CX2 Segment Details

  # Start of AMT_I Segment Details #
    def print_amt_i_segment
      amt_i_element_methods = @segments_list[:AMT_I]
      amt_i_elements = verify_amt_i_condition{
        [
          send(amt_i_element_methods[:AMT_I00][0].to_sym, amt_i_element_methods[:AMT_I00][1]), #['segment_name', 'AMT']
          send(amt_i_element_methods[:AMT_I01][0].to_sym, amt_i_element_methods[:AMT_I01][1].to_s), #['print_constant', 'I']
          send(amt_i_element_methods[:AMT_I02][0].to_sym, amt_i_element_methods[:AMT_I02][1]) #interest_amount
        ]
      }
      amt_i_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def interest_amount(*options)
      unless @eob.claim_interest.blank? || @eob.claim_interest.to_f.zero?
        @eob.amount('claim_interest')
      end
    end
  # End of AMT_I Segment Details

  # Start of AMT_AU Segment Details #
    def print_amt_au_segment
      amt_au_element_methods = @segments_list[:AMT_AU]
      amt_au_elements = verify_amt_au_condition{
        [
          send(amt_au_element_methods[:AMT_AU00][0].to_sym, amt_au_element_methods[:AMT_AU00][1]), #['segment_name', 'AMT']
          send(amt_au_element_methods[:AMT_AU01][0].to_sym, amt_au_element_methods[:AMT_AU01][1].to_s), #['print_constant', 'AU']
          send(amt_au_element_methods[:AMT_AU02][0].to_sym, amt_au_element_methods[:AMT_AU02][1]) #coverage_amount
        ]
      }
      amt_au_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def coverage_amount(*options)
      @eob.claim_level_supplemental_amount
    end
  # End of AMT_AU Segment Details

  # Start of QTY_CA Segment Details #
    def print_qty_ca_segment
      qty_ca_element_methods = @segments_list[:QTY_CA]
      qty_ca_elements = verify_qty_ca_condition{
        [
          send(qty_ca_element_methods[:QTY_CA00][0].to_sym, qty_ca_element_methods[:QTY_CA00][1]), #claim_supplemental_information_quantity
          send(qty_ca_element_methods[:QTY_CA01][0].to_sym, qty_ca_element_methods[:QTY_CA01][1].to_s), #claim_supplemental_quantity_qualifier
          send(qty_ca_element_methods[:QTY_CA02][0].to_sym, qty_ca_element_methods[:QTY_CA02][1]) #claim_supplemental_quantity
        ]
      }
      qty_ca_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def claim_supplemental_information_quantity(*options)
    end

    def claim_supplemental_quantity_qualifier(*options)
    end

    def claim_supplemental_quantity(*options)
    end
  # End of QTY_CA Segment Details

  # Start of SVC Segment Details #
    def print_svc_segment
      svc_element_methods = @segments_list[:SVC]
      svc_elements = verify_svc_condition{
        [
          send(svc_element_methods[:SVC00][0].to_sym, svc_element_methods[:SVC00][1]), #['segment_name', 'SVC']
          send(svc_element_methods[:SVC01][0].to_sym, svc_element_methods[:SVC01][1]), #composite_medical_procedure
          send(svc_element_methods[:SVC02][0].to_sym, svc_element_methods[:SVC02][1]), #line_item_charge_amount
          send(svc_element_methods[:SVC03][0].to_sym, svc_element_methods[:SVC03][1]), #line_item_provider_payment_amount
          send(svc_element_methods[:SVC04][0].to_sym, svc_element_methods[:SVC04][1]), #national_uniform_billing_committee_revenue_code
          send(svc_element_methods[:SVC05][0].to_sym, svc_element_methods[:SVC05][1]), #units_of_service_paid_count
          send(svc_element_methods[:SVC06][0].to_sym, svc_element_methods[:SVC06][1]) #composite_medical_procedure_identifier
        ]
      }
      svc_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def composite_medical_procedure(*options)
      qualifier = @service.service_cdt_qualifier.present? ? @service.service_cdt_qualifier.upcase : 'HC'
      if bundled_cpt_code.present?
        element = ["#{qualifier}:#{bundled_cpt_code}"]
      elsif proc_cpt_code.present?
        element = ["#{qualifier}:#{captured_or_blank_value(:cpt_code_default_match, proc_cpt_code)}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
      elsif revenue_code.present?
        element = ["NU:#{revenue_code}"]
      else
        element = ["#{qualifier}:"]
      end
      element.flatten.trim_segment.join(':')
    end

    def line_item_charge_amount(*options)
      @service.amount('service_procedure_charge_amount')
    end

    def line_item_provider_payment_amount(*options)
      @service.amount('service_paid_amount')
    end

    def national_uniform_billing_committee_revenue_code(*options)
      ((proc_cpt_code.present? || bundled_cpt_code.present?) and revenue_code.present?) ? revenue_code : ''
    end

    def units_of_service_paid_count(*options)
      @service.service_quantity.to_f.to_amount
    end

    def composite_medical_procedure_identifier(*options)
      if bundled_cpt_code.present? and proc_cpt_code.present?     
        qualifier = @service.service_cdt_qualifier.present? ? @service.service_cdt_qualifier.upcase : 'HC'
        element = ["#{qualifier}:#{captured_or_blank_value(:cpt_code_default_match, proc_cpt_code)}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
        element.flatten.trim_segment.join(':')
      end
    end
  # End of AMT_AU Segment Details

  # Start of DTM_472 Segment Details #
    def print_dtm_472_segment
      dtm_472_element_methods = @segments_list[:DTM_472]
      dtm_472_elements = verify_dtm_472_condition{
        [
          send(dtm_472_element_methods[:DTM_47200][0].to_sym, dtm_472_element_methods[:DTM_47200][1]), #['segment_name', 'DTM']
          send(dtm_472_element_methods[:DTM_47201][0].to_sym, dtm_472_element_methods[:DTM_47201][1].to_s), #['print_constant', '472']
          send(dtm_472_element_methods[:DTM_47202][0].to_sym, dtm_472_element_methods[:DTM_47202][1]) #service_date
        ]
      }
      dtm_472_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def service_date(*options)
      @service_level_details[:from_date] if can_print_service_date(@service_level_details[:from_date])
    end
  # End of DTM_472 Segment Details

  # Start of DTM_150 Segment Details #
    def print_dtm_150_segment
      dtm_150_element_methods = @segments_list[:DTM_150]
      dtm_150_elements = verify_dtm_150_condition{
        [
          send(dtm_150_element_methods[:DTM_15000][0].to_sym, dtm_150_element_methods[:DTM_15000][1]), #['segment_name', 'DTM']
          send(dtm_150_element_methods[:DTM_15001][0].to_sym, dtm_150_element_methods[:DTM_15001][1].to_s), #['print_constant', '150']
          send(dtm_150_element_methods[:DTM_15002][0].to_sym, dtm_150_element_methods[:DTM_15002][1]) #service_period_start
        ]
      }
      dtm_150_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def service_period_start(*options)
      @service_level_details[:from_date] if can_print_service_date(@service_level_details[:from_date])
    end
  # End of DTM_150 Segment Details

  # Start of DTM_151 Segment Details #
    def print_dtm_151_segment
      dtm_151_element_methods = @segments_list[:DTM_151]
      dtm_151_elements = verify_dtm_151_condition{
        [
          send(dtm_151_element_methods[:DTM_15100][0].to_sym, dtm_151_element_methods[:DTM_15100][1]), #['segment_name', 'DTM']
          send(dtm_151_element_methods[:DTM_15101][0].to_sym, dtm_151_element_methods[:DTM_15101][1].to_s), #['print_constant', '151']
          send(dtm_151_element_methods[:DTM_15102][0].to_sym, dtm_151_element_methods[:DTM_15102][1]) #coverage_amount
        ]
      }
      dtm_151_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def service_period_end(*options)
      @service_level_details[:to_date] if can_print_service_date(@service_level_details[:to_date])
    end
  # End of DTM_151 Segment Details

  # Start of REF_LU Segment Details #
    def print_ref_lu_segment
      ref_lu_element_methods = @segments_list[:REF_LU]
      ref_lu_elements = verify_ref_lu_condition{
        [
          send(ref_lu_element_methods[:REF_LU00][0].to_sym, ref_lu_element_methods[:REF_LU00][1]), #service_identification
          send(ref_lu_element_methods[:REF_LU01][0].to_sym, ref_lu_element_methods[:REF_LU01][1].to_s), #service_reference_id_qualifier
          send(ref_lu_element_methods[:REF_LU02][0].to_sym, ref_lu_element_methods[:REF_LU02][1]) #service_reference_identification
        ]
      }
      ref_lu_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def service_identification(*options)
    end

    def service_reference_id_qualifier(*options)
    end

    def service_reference_identification(*options)
    end
  # End of REF_LU Segment Details

  # Start of REF_6R Segment Details #
    def print_ref_6r_segment
      ref_6r_element_methods = @segments_list[:REF_6R]
      ref_6r_elements = verify_ref_6r_condition{
        [
          send(ref_6r_element_methods[:REF_6R00][0].to_sym, ref_6r_element_methods[:REF_6R00][1]), #['segment_name', 'REF']
          send(ref_6r_element_methods[:REF_6R01][0].to_sym, ref_6r_element_methods[:REF_6R01][1].to_s), #['print_constant', '6R']
          send(ref_6r_element_methods[:REF_6R02][0].to_sym, ref_6r_element_methods[:REF_6R02][1]) #line_item_control_number
        ]
      }
      ref_6r_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def line_item_control_number(*options)
      @service.service_provider_control_number
    end
  # End of REF_6R Segment Details

  # Start of REF_HPI Segment Details #
    def print_ref_hpi_segment
      ref_hpi_element_methods = @segments_list[:REF_HPI]
      ref_hpi_elements = verify_ref_hpi_condition{
        [
          send(ref_hpi_element_methods[:REF_HPI00][0].to_sym, ref_hpi_element_methods[:REF_HPI00][1]), #rendering_provider_information
          send(ref_hpi_element_methods[:REF_HPI01][0].to_sym, ref_hpi_element_methods[:REF_HPI01][1].to_s), #rendering_provider_id_qualifier
          send(ref_hpi_element_methods[:REF_HPI02][0].to_sym, ref_hpi_element_methods[:REF_HPI02][1]) #rendering_provider_identification
        ]
      }
      ref_hpi_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def rendering_provider_information(*options)
    end

    def rendering_provider_id_qualifier(*options)
    end

    def rendering_provider_identification(*options)
    end
  # End of REF_HPI Segment Details

  # Start of REF_0K Segment Details #
    def print_ref_0k_segment
      ref_0k_element_methods = @segments_list[:REF_0K]
      ref_0k_elements = verify_ref_0k_condition{
        [
          send(ref_0k_element_methods[:REF_0K00][0].to_sym, ref_0k_element_methods[:REF_0K00][1]), #health_care_policy
          send(ref_0k_element_methods[:REF_0K01][0].to_sym, ref_0k_element_methods[:REF_0K01][1].to_s), #health_care_policy_id_qualifier
          send(ref_0k_element_methods[:REF_0K02][0].to_sym, ref_0k_element_methods[:REF_0K02][1]) #health_care_policy_identification
        ]
      }
      ref_0k_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def health_care_policy(*options)
    end

    def health_care_policy_id_qualifier(*options)
    end

    def health_care_policy_identification(*options)
    end
  # End of REF_0K Segment Details

  # Start of AMT_B6 Segment Details #
    def print_amt_b6_segment
      amt_b6_element_methods = @segments_list[:AMT_B6]
      amt_b6_elements = verify_amt_b6_condition{
        [
          send(amt_b6_element_methods[:AMT_B600][0].to_sym, amt_b6_element_methods[:AMT_B600][1]), #['segment_name', 'AMT']
          send(amt_b6_element_methods[:AMT_B601][0].to_sym, amt_b6_element_methods[:AMT_B601][1].to_s), #['print_constant', 'B6']
          send(amt_b6_element_methods[:AMT_B602][0].to_sym, amt_b6_element_methods[:AMT_B602][1]) #actual_allowed_amount
        ]
      }
      amt_b6_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def actual_allowed_amount(*options)
      @service_level_details[:supplemental_amount]
    end
  # End of AMT_B6 Segment Details

  # Start of QTY_ZK Segment Details #
    def print_qty_zk_segment
      qty_zk_element_methods = @segments_list[:QTY_ZK]
      qty_zk_elements = verify_qty_zk_condition{
        [
          send(qty_zk_element_methods[:QTY_ZK00][0].to_sym, qty_zk_element_methods[:QTY_ZK00][1]), #service_supplemental_information_quantity
          send(qty_zk_element_methods[:QTY_ZK01][0].to_sym, qty_zk_element_methods[:QTY_ZK01][1].to_s), #service_supplemental_quantity_qualifier
          send(qty_zk_element_methods[:QTY_ZK02][0].to_sym, qty_zk_element_methods[:QTY_ZK02][1]) #service_supplemental_quantity
        ]
      }
      qty_zk_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def service_supplemental_information_quantity(*options)
    end

    def service_supplemental_quantity_qualifier(*options)
    end

    def service_supplemental_quantity(*options)
    end
  # End of QTY_ZK Segment Details

  # Start of LQ_RX Segment Details #
    def print_lq_rx_segment
      lq_rx_element_methods = @segments_list[:AMT_B6]
      lq_rx_elements = verify_lq_rx_condition{
        [
          send(lq_rx_element_methods[:LQ_RX00][0].to_sym, lq_rx_element_methods[:LQ_RX00][1]), #['segment_name', 'LQ']
          send(lq_rx_element_methods[:LQ_RX601][0].to_sym, lq_rx_element_methods[:LQ_RX01][1].to_s), #['print_constant', 'RX']
          send(lq_rx_element_methods[:LQ_RX02][0].to_sym, lq_rx_element_methods[:LQ_RX02][1].to_s) #actual_allowed_amount
        ]
      }
      lq_rx_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def actual_allowed_amount(*options)
      @service_level_details[:supplemental_amount]
    end
  # End of LQ_RX Segment Details

  # Start of SE Segment Details #
    def print_se_segment
      se_element_methods = @segments_list[:SE]
      se_elements = [
        send(se_element_methods[:SE00][0].to_sym, se_element_methods[:SE00][1]), #['segment_name', 'SE']
        send(se_element_methods[:SE01][0].to_sym, se_element_methods[:SE01][1]), #number_of_included_segments
        send(se_element_methods[:SE02][0].to_sym, se_element_methods[:SE02][1]) #transaction_set_control_number
      ]
      se_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def number_of_included_segments(*options)
      @check_level_details[:segments_count]
    end

    # def transaction_set_control_number
    # end
  # End of SE Segment Details

  # Start of GE Segment Details #
    def print_ge_segment
      ge_element_methods = @segments_list[:GE]
      ge_elements = [
        send(ge_element_methods[:GE00][0].to_sym, ge_element_methods[:GE00][1]), #['segment_name', 'GE']
        send(ge_element_methods[:GE01][0].to_sym, ge_element_methods[:GE01][1]), #number_of_transaction_sets_included
        send(ge_element_methods[:GE02][0].to_sym, ge_element_methods[:GE02][1]) #['group_control_number_for_ge_segment', '2831']
      ]
      ge_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end

    def number_of_transaction_sets_included(*options)
      @checks.collect{|check| check.batch.id == @check.batch.id}.compact.length
    end

  def group_control_number_for_ge_segment(option)
    print_constant('2831')
  end
  # End of GE Segment Details

  # Start of IEA Segment Details #
    def print_iea_segment
      iea_element_methods = @segments_list[:IEA]
      iea_elements = [
        send(iea_element_methods[:IEA00][0].to_sym, iea_element_methods[:IEA00][1]), #['segment_name', 'IEA']
        send(iea_element_methods[:IEA01][0].to_sym, iea_element_methods[:IEA01][1]), #['print_constant', '1']
        send(iea_element_methods[:IEA02][0].to_sym, iea_element_methods[:IEA02][1]), #inter_control_number
      ]
      iea_elements.flatten.trim_segment.join(@facility_level_details[:element_separator])
    end
  # End of IEA Segment Details #

  # Individual Segment Details #
end