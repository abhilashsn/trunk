#rake populate:era_project_with_sample_data['number_of_records(ex.12)'] --trace
namespace :populate do
  desc "Task to populate era project data for testing"
	task :era_project_with_sample_data, [:records] => [:environment] do |r,args|
	  1.upto(args.records.to_i) do |i|
			ifi_hash = {:name => "#{i}.zip", :size => "#{i}", :arrival_time => "2012-01-01 #{i}:00:00", 
			            :file_type => 'ERA',:status => 'RECEIVED',:facility_id => Facility.first.id}
			ifi = InboundFileInformation.create(ifi_hash)
		  era_hash = {:file_md5_hash => "123abcde#{i}", :sftp_location => "test/test", 
		              :identifier_hash => "i123abcde#{i}", 
                  :xml_conversion_time => "2013-01-01 00:00:00", :is_duplicate => "", :parent_era_id =>"", 
                  :era_parse_start_time => "2013-01-01 00:00:00",
                  :era_process_start_time => "2013-01-01 00:00:00",
                  :era_parse_end_time => "2013-01-01 01:00:00", 
                  :era_process_end_time => "2013-01-01 02:00:00",
                  :inbound_file_information_id => "#{ifi.id}", :batchid => "#{i}_20130101_#{i}"}
      era = Era.create(era_hash)
      1.upto(2) do |ec|
        era_checks_hash = { :transaction_hash => "i123abcde#{i}#{ec}", :era_id => "#{era.id}", 
                          :tracking_number => "#{i}_#{ec}", "835_single_location" => "test", 
                          :status => "ARRIVED", :transaction_set_control_number => "", 
                   :transaction_handling_code => "", :check_amount => "#{ec}", :credit_debit_flag => "", 
                   :payment_method => "", :payment_format_code => "", :payer_routing_qualifier => "", 
                   :aba_routing_number => "", :payer_account_qualifier => "", 
                   :payer_account_number => "", :payer_company_identifier => "", 
                   :payer_company_supplemental_code => "", :site_routing_qualifier => "", 
                   :site_routing_number => "", :site_account_qualifier => "", 
                   :site_account_number => "", :check_date => "2013-01-01",
                    :check_number => "12345#{era.id}", 
                   :trn_payer_company_identifier => "", :trn_payer_company_supplemental_code => "", 
                   :site_receiver_identification => "", :production_date => "2013-01-01", :payer_name => "abc", 
                   :payer_npi => "", :payer_address_1 => "test", :payer_address_2 => "test", 
                   :payer_city => "test", :payer_state => "test", :payer_zip => "123456", 
                   :era_payid_qualifier => "", :era_payid => "era payid", 
                   :era_misc_check_segments => "test"}
        era_check = EraCheck.create(era_checks_hash)
        1.upto(2) do |ej|
          era_jobs_hash = {:tracking_number => "#{1}", :era_id => "#{era.id}", :transaction_hash => "", 
                      :era_check_id => "#{era_check.id}",:status => "IN PROCESS",
                      :client_id => "#{Facility.first.client.id}", :facility_id => "1",
                      :payee_name => "",:payee_qualifier => "",:payee_npi => "",
                      :payee_tin => "",:payee_planID => "", :payee_address_1 => "", 
                      :payee_address_2 => "", :payee_city => "", :payee_state => "",
                      :payee_zip => "", :era_addl_payeeid_qualifier => "", :era_addl_payeeid => ""}
          era_job = EraJob.create(era_jobs_hash)
        end
		    1.upto(2) do |ip|
				  ipe_hash = {:era_check_id => "#{era_check.id}", :patient_account_number => "1234", 
						      :claim_status_code => "", 
                  :total_submitted_charge_for_claim => "100.00", :total_amount_paid_for_claim => "50.00", 
                  :total_patient_responsibility => "", :claim_indicator_code => "", :claim_number => "",
                  :facility_type_code => "", :claim_frequency_code => "", :drg_code => "", 
                  :drg_weight => "", :discharge_fraction => "", :patient_entity_qualifier => "",
                  :patient_last_name => "", :patient_first_name => "", :patient_middle_initial => "",
                  :patient_suffix => "", :patient_identification_code_qualifier => "",
                  :patient_identification_code => "", :subscriber_entity_qualifier => "",
                  :subscriber_last_name => "", :subscriber_first_name => "", 
                  :subscriber_middle_initial => "",:subscriber_suffix => "", 
                  :subscriber_identification_code_qualifier => "", :subscriber_identification_code => "",
                  :rendering_provider_entity_qualifier => "", :rendering_provider_last_name => "", 
                  :rendering_provider_first_name => "", :rendering_provider_middle_initial => "", 
                  :rendering_provider_suffix => "", :rendering_provider_code_qualifier => "", 
                  :rendering_provider_identification_number => "", 
                  :other_claim_identification_qualifier => "", :other_claim_identifier => "", 
                  :claim_from_date => "", :claim_to_date => "", :date_received_by_insurer => "", 
                  :amt_qualifier => "", :amt_amount => "", :archived_claim_hash => "", 
                  :claim_adjustment_primary_pay_payment => "", :claim_primary_payment_reasoncode => "", 
                  :claim_primary_payment_groupcode => "", :claim_adjustment_co_insurance => "", 
                  :claim_coinsurance_reasoncode => "", :claim_coinsurance_groupcode => "", 
                  :claim_adjustment_deductable => "", :claim_deductable_reasoncode => "", 
                  :claim_deductuble_groupcode => "", :claim_adjustment_copay => "", 
                  :claim_copay_reasoncode => "", :claim_copay_groupcode => "", 
                  :claim_adjustment_non_covered => "", :claim_noncovered_reasoncode => "", 
                  :claim_noncovered_groupcode => "", :claim_adjustment_discount => "", 
                  :claim_discount_reasoncode => "", :claim_discount_groupcode => "", 
                  :claim_adjustment_contractual_amount => "", :claim_contractual_reasoncode => "", 
                  :claim_contractual_groupcode => "", :total_denied => "", :claim_denied_reasoncode => "", 
                  :claim_denied_groupcode => "", :lx_number => "", :ts3_provider_number => "", 
                  :ts3_facility_type_code => "", :ts3_date => "", :ts3_quantity => "", :ts3_amount => "", 
                  :era_misc_claim_segments => ""}
            insurance_payment_era = InsurancePaymentEra.create(ipe_hash)
        end
#        1.upto(2) do |epa|
#         epa_hash = {:era_check_id => ec, :provider_identifier => 'test', :fiscal_period_date => "2013-01-01 01:00:00", :provider_adjustment_reason_code1 => 't', :provider_adjustment_identifier1 => 'test', :provider_adjustment_amount1 => '100.00' }	
#        end
      end
    end
  end  
end






