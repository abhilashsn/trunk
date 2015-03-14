module Unified835Output::ConfigGenerator

	def get_config_segment_method_name(element_name, method_name)
		element_value = get_value_for_element(element_name)
		return method_name if element_value.eql?('Code')
		return ['blank_segment'] if ['Blank', ''].include?element_value
		return ['print_constant', element_value.delete('$,{,}')] if element_value =~ /^\$\{.*\}$/
		return ['nil_segment'] if ['Exclude', nil].include?element_value
		[element_value.to_s.strip.convert_to_method]
	end

	def get_value_for_element(name)
		possible_values = [
			@config_835_values[:facility_level].fetch(name.to_sym){{}}.fetch(:value){nil},
			@config_835_values[:client_level].fetch(name.to_sym){{}}.fetch(:value){nil},
			@config_835_values[:partner_level].fetch(name.to_sym){{}}.fetch(:value){nil}
		]
		possible_values.each do |value|
			return value if value.present?
		end
		nil
	end

	# ISA Segment Config Options
		def payer_id(*options)
			interchange_sender_id
		end

		def interchange_control_number(*options)
			inter_control_number
		end

		def tax_identification_number(*options)
			@facility.facility_tin.to_s.strip
		end

		def production_status(*options)
			'P'
		end

		def output_version(*options)
			inter_control_version_number
		end

		def output_version_code(*options)
			repetition_separator
		end
	# End of ISA Segment Config Options

	# GS Segment Config Options
		def facility_name(*options)
			@facility.name.to_s.upcase
		end

		def facility_name_to_15_chars(*options)
			facility_name.slice(0,15)
		end

		def batch_date(*options)
			@checks.first.batch.get_batch_date("%Y%m%d")
		end

		def system_generated_time(*options)
			print_current_time
		end

		def system_generated_date(*options)
			print_todays_date
		end

		def payer_id_with_left_padded_x(*options)
			interchange_sender_id.justify(15, 'X')
		end	
	# End of GS Segment Config Options

	# ST Segment Config Options
		def sequential_counter_9_digits(*options)
			@check_level_details[:index].to_s.justify(9, '0')
		end

		def sequential_counter(*options)
			@check_level_details[:index].to_s.justify(4, '0')
		end
	# End of ST Segment Config Options

	# BPR Segment Config Options
		def transaction_handling_code(*options)
			transaction_handle_code
		end

		def check_amount(*options)
			payment_amount
		end

		def payment_method_code(*options)
			payment_method
		end

		def aba_routing_number(*options)
			(@micr && !@check_level_details[:is_correspondent]) ? @micr.aba_routing_number.to_s.strip : ''
		end

		def payer_account_number(*options)
			@check_level_details[:is_correspondent] ? '' : (@micr.payer_account_number.to_s.strip if @micr)
		end

		def client_dda_number(*options)
			@facility.client_dda_number.to_s
		end

		def check_date(*options)
			@check_level_details[:is_correspondent] ? '' : @check.check_date.strftime('%Y%m%d')
		end

		def check_or_batch_date(*options)
			return @check.output_check_date if @check.check_date.present?
			batch_date
		end

		def output_creation_date(*options)
			print_current_time('%y%m%d')
		end
	# End of BPR Segment Config Options

	# TRN Segment Config Options
		def check_number(*options)
			@check.check_number.to_s
		end

		def batch_id(*options)
			@check.batch.batchid
		end

		def facility_tin_plus_one(*options)
			return nil unless @payment_classified_check.is_non_zero_eft_check?
			@facility.facility_tin.present? ? '1' + @facility.facility_tin : nil
		end

		def lockbox_specific_facility_tin_plus_one(*options)
			return nil unless @payment_classified_check.is_non_zero_eft_check?
			tin_value = facility_lockbox.try(:tin).to_s
			tin_value.present? ? '1' + tin_value : nil			
		end

		def payer_id_left_padded_with_x_10_digit(*options)
			interchange_sender_id.justify(10, 'X')
		end

		def payer_id_left_padded_with_0_10_digit(*options)
			interchange_sender_id.justify(10, '0')
		end
	# End of TRN Segment Config Options

	# REF_EV Segment Config Options
		def multipage_image_name(*options)
			name, extenstion = @check.image_file_name.split('.')
			name.chomp!(name[-2,2])+'.'+extenstion
		end

		def check_image_id(*options)
			@check.image_file_name.to_s
		end
	# End of REF_EV Segment Config Options

	# REF_EA Segment Config Options
		def medical_record_id_number(*options)
			medical_record_number
		end
	# End of REF_EA Segment Config Options

	# REF_BB Segment Config Options
		def uid_for_claim(*options)
			@eob.uid.to_s
		end
	# End of REF_BB Segment Config Options

	# N1_PR Segment Config Options
	# End of N1_PR Segment Config Options

	# N3_PR Segment Config Options
		def payer_street_address(*options)
			payer_address_one
		end

		def payee_street_address(*options)
			payee_address_one
		end

		def patient_street_address(*options)
			payer_address_one
		end
	# End of N3_PR Segment Config Options

	# N4_PR Segment Config Options
		def payer_city(*options)
			payer_city
		end

		def payee_city(*options)
			payee_city
		end

		def patient_city(*options)
			payer_city
		end

		def payer_state(*options)
			payer_state
		end

		def payee_state(*options)
			payee_state
		end

		def patient_state(*options)
			payer_state
		end

		def payer_zip(*options)
			payer_zip_code
		end

		def payee_zip(*options)
			payee_zip_code
		end

		def patient_zip(*options)
			payer_zip_code
		end
	# End of N4_PR Segment Config Options

	# REF_2U Segment Config Options
		def payer_id_for_ascend(*options)
			
		end

		def output_payer_id(*options)
			
		end
	# End of REF_2U Segment Config Options

	# PER_BL Segment Config Options
		def payees_name(*options)
			@payee.try(:name).to_s.strip.upcase[0..60]
		end

		def patient_name(*options)
			payer_name
		end
	# End of PER_BL Segment Config Options

	# N1_PE Segment Config Options
		def payee_id_code_qualifier(*options)
      return 'XX' if @payee.npi.present?
      'FI' if @payee.tin.present?
		end

		def provider_npi_or_tin(*options)
			return @payee.npi if @payee.npi.present?
			@payee.tin if @payee.tin.present?
		end

		def provider_tin(*options)
			@claim && @claim.tin.present? ? @claim.tin : @facility.facility_tin
		end

		def lockbox_specific_payee_name(*options)
			facility_lockbox.try(:payee_name).to_s.strip.upcase[0..60]
		end

		def lockbox_specific_id_code_qualifier(*options)
			'XX'
		end

		def lockbox_specific_provider_npi(*options)
			facility_lockbox.try(:npi).to_s.strip.upcase
		end
	# End of N1_PE Segment Config Options

	# N3_PE Segment Config Options
		def lockbox_specific_payee_street_address(*options)
			facility_lockbox.try(:address_one).to_s.strip.upcase
		end
	# End of N3_PE Segment Config Options

	# N4_PE Segment Config Options
		def lockbox_specific_payee_city(*options)
			facility_lockbox.try(:city).to_s.strip.upcase
		end

		def lockbox_specific_payee_state(*options)
			facility_lockbox.try(:state).to_s.strip.upcase
		end

		def lockbox_specific_payee_zip_code(*options)
			facility_lockbox.try(:zip_code).to_s.strip.upcase
		end
	# End of N4_PE Segment Config Options

	# REF_TJ Segment Config Options
		def provider_tin_check_level(*options)
			@check.payee_tin
		end

		def lockbox_specific_provider_tin(*options)
			facility_lockbox.try(:tin).to_s.strip.upcase
		end
	# End of REF_TJ Segment Config Options

	# LX Segment Config Options
		def sequential_number(*options)
			@claim_level_details[:index].to_s
		end

		def sequential_counter_4_digits(*options)
			@claim_level_details[:index].to_s.rjust(4, '0')
		end
	# End of LX Segment Config Options

	# TS3 Segment Config Options
		def provider_federal_tax_id(*options)
			provider_tin
		end

		def facility_type_code_from_837_or_default_13(*options)
			@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : '13'
		end

		def facility_type_code_from_837_or_default_11(*options)
			@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : '11'
		end

		def total_submitted_charges(*options)
			@eobs.sum("total_submitted_charge_for_claim")
		end

		def last_day_of_current_fiscal_period(*options)
			Date.today.year().to_s+'1231'
		end
	# End of TS3 Segment Config Options

	# CLP Segment Config Options
		def patient_account_number(*options)
			@eob.patient_account_number.to_s
		end

		def claim_total_charge_amount(*options)
			if is_discount_more?(@eob.total_contractual_amount.to_f)
				@check.check_amount.to_f.to_amount
			else
				@eob.amount('total_submitted_charge_for_claim')
			end
		end

		def plan_type(*options)
			@eob.plan_type
		end

		def check_number_plus_batch_date_plus_sequence_number(*options)
			''
		end

		def check_number_plus_batch_date(*options)
			check_number + batch_date
		end

		def facility_type_code_from_837_claim_or_default_13(*options)
			@claim.try(:facility_type_code) || '13'
		end

		def facility_type_code_from_837_claim_or_default_11(*options)
			@claim.try(:facility_type_code) || '11'
		end

		def facility_type_code_from_mpi(*options)
			@claim.try(:facility_type_code)
		end

		def claim_frequency_indicator_from_mpi(*options)
			@claim.try(:claim_frequency_type_code)
		end

		def plan_code(*options)
			@claim.plan_code.to_s[0] if @claim
		end

		def drg_code(*options)
			@eob.drg_code
		end

		def drg_weight(*options)
			@eob.drg_weight
		end
	# End of CLP Segment Config Options

	# NM1_QC Segment Config Options
		def patient_middle_intial(*options)
			patient_middle_name_or_initial
		end

		def patient_suffix(*options)
			patient_name_suffix
		end

		def patient_id_qualifier(*options)
			patient_identification_code_qualifier
		end

		def member_id_qualifier(*options)
			subscriber_identification_code_qualifier
		end

		def patient_id(*options)
			patient_identifier
		end

		def member_id(*options)
			subscriber_identifier
		end
	# End of NM1_QC Segment Config Options

	# NM1_IL Segment Config Options
		def subscriber_middle_initial(*options)
			subscriber_middle_name_or_initial
		end

		def subscriber_suffix(*options)
			subscriber_name_suffix
		end
	# End of NM1_IL Segment Config Options

	# NM1_82 Segment Config Options
		def rendering_provider_last_name(*options)
			@eob.rendering_provider_last_name.to_s.upcase
		end

		def organization_name(*options)
			@eob.provider_organisation.to_s.upcase
		end

		def rendering_provider_middle_initial(*options)
			rendering_provider_middle_name_or_initial
		end

		def provider_suffix(*options)
			rendering_provider_name_suffix
		end

		def id_code_qualifier(*options)
			rendering_provider_identification_code_qualifier
		end

		def provider_npi_or_tin_claim_level(*options)
			rendering_provider_identifier
		end

		def provider_tin_claim_level(*options)
			@eob.provider_tin
		end
	# End of NM1_82 Segment Config Options

	# NM1_PR Segment Config Options
		def repricer_payer_name(*options)
			corrected_priority_payer_name
		end

		def payer_id_number(*options)
			payer_id
		end
	# End of NM1_PR Segment Config Options

	# REF_F8 Segment Config Options
		def policy_number(*options)
			insurance_policy_number
		end

		def eob_image_id(*options)
			get_eob_image.try(:original_file_name)
		end
	# End of REF_F8 Segment Config Options

	# REF_ZZ Segment Config Options
		def provider_upin_number(*options)
			@eob.provider_tin
		end

		def image_name_eob_start_page_eob_end_page(*options)
			image_page_name
		end
	# End of REF_ZZ Segment Config Options

	# DTM_232 Segment Config Options
		def claim_level_service_from_date(*options)
			start_date = @classified_eob.get_start_date(@claim)
			return nil if start_date.nil?
			return '99999999' if can_return_static_start_date(start_date)
			start_date if can_print_service_date(start_date)
		end
	# End of DTM_232 Segment Config Options

	# DTM_233 Segment Config Options
		def claim_level_service_to_date(*options)
			end_date = @classified_eob.get_end_date(@claim)
			return nil if end_date.nil?
			return '99999999' if can_return_static_end_date(end_date)
			end_date if can_print_service_date(end_date)
		end
	# End of DTM_232 Segment Config Options

	# DTM_050 Segment Config Options
		def claim_level_received_date(*options)
			''
		end
	# End of DTM_232 Segment Config Options

	# AMT_I Segment Config Options
		def claim_interest_amount(*options)
			@eob.amount('claim_interest').to_s
		end
	# End of AMT_I Segment Config Options

	# AMT_AU Segment Config Options
		def claim_level_allowed_amount(*options)
			coverage_amount
		end
	# End of AMT_AU Segment Config Options

	# SVC Segment Config Options
		def medical_procedure_identifier(*options)
			@service.service_cdt_qualifier.try(:upcase) || 'HC'
		end

		def cpt_code(*options)
			proc_cpt_code
		end

		def cdt_code(*options)
			''
		end

		def revenue_code_01(*options)
			revenue_code
		end

		def modifier_1(*options)
			@service.service_modifier1.to_s
		end

		def modifier_2(*options)
			@service.service_modifier2.to_s
		end

		def modifier_3(*options)
			@service.service_modifier3.to_s
		end

		def modifier_4(*options)
			@service.service_modifier4.to_s
		end

		def revenue_code_04(*options)
			national_uniform_billing_committee_revenue_code
		end

		def line_item_payment_amount(*options)
			line_item_provider_payment_amount
		end

		def quantity(*options)
			units_of_service_paid_count
		end

		def product_or_service_id_qualifier(*options)
			@service.service_cdt_qualifier.try(:upcase) || 'HC'
		end

		def procedure_code(*options)
			proc_cpt_code
		end
	# End of SVC Segment Config Options

	# DTM_472 Segment Config Options
		def service_date_for_472(*options)
			return nil unless @service_level_details[:from_date]
			if (@service_level_details[:service_in_one_day] || @service_level_details[:to_date].blank?) && is_static_date?(@service_level_details[:from_date])
					return '99999999'
			end
			@service_level_details[:from_date]
		end
	# End of DTM_472 Segment Config Options

	# DTM_151 Segment Config Options
		def service_to_date(*options)
			service_period_end
		end
	# End of DTM_151 Segment Config Options

	# DTM_150 Segment Config Options
		def service_from_date(*options)
			service_period_start
		end
	# End of DTM_150 Segment Config Options

	# REF_6R Segment Config Options
		def document_control_number_plus_service_line_number(*options)
	    xpeditor_document_number = @claim.try(:xpeditor_document_number)
	    return nil unless xpeditor_document_number
    	unless xpeditor_document_number == "0"
      	xpeditor_document_number + (@service_level_details[:index]).to_s.rjust(4 ,'0')
    	end
		end

		def reference_number(*options)
			line_item_control_number
		end

		def document_control_number(*options)
			@claim.try(:xpeditor_document_number).to_s
		end
	# End of REF_6R Segment Config Options

	# AMT_B6 Segment Config Options
		def allowed_amount(*options)
			actual_allowed_amount
		end
	# End of AMT_B6 Segment Config Options

	# SE Segment Config Options
		def count_of_segments_in_the_transaction_set(*options)
			number_of_included_segments
		end

		def matches_the_value_in_st_02(*options)
			transaction_set_control_number
		end
	# End of SE Segment Config Options

	# GE Segment Config Options
		def count_of_the_transaction_sets(*options)
			number_of_transaction_sets_included
		end

		def matches_the_value_in_gs_06(*options)
			'2831'
		end
	# End of GE Segment Config Options

	# IEA Segment Config Options
		def count_of_the_functional_groups(*options)
			'1'
		end

		def matches_the_value_in_isa_13(*options)
			inter_control_number
		end
	# End of IEA Segment Config Options
end