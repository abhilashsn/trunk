require File.dirname(__FILE__) + '/../test_helper'
require 'facility'

class FacilityTest < ActiveSupport::TestCase
#  fixtures :facilities

  # List of tests
  # 1. Empty facility create 
  # 2. Create with invalid data
  #   - Check with nil name
  #   - Check with nil sitecode
  #   - Check with nil client
  # 3. Check batch count
  # 4. Check Uniqueness
  #   - Check Uniqueness of name
  #   - Check uniqueness of sitecode
  # 5. Check batch association
  #   - facility and batch have destroy relationship. When a facility is deleted all its subbatches are deleted.

  def setup
    data_setup_for_facility
  end

  def teardown
    data_teardown_for_facility
  end

  def data_setup_for_facility
    sql = ActiveRecord::Base.connection();
    sql.execute "SET autocommit=0";
    sql.begin_db_transaction

    id, value =
    sql.execute("INSERT INTO clients (id, NAME, tat, contracted_tat, partner_id) VALUES (7, 'client1', 48, 20, 1)");

    sql.execute("insert into `facilities` (`id`, `name`, `client_id`, `sitecode`, `facility_tin`, `facility_npi`, `image_type`, `address_one`, `address_two`, `zip_code`, `city`, `state`, `details`, `lockbox_number`, `abbr_name`, `tat`, `processing_location`, `production_status`, `image_file_format`, `image_processing_type`, `index_file_format`, `index_file_parser_type`, `batch_load_type`, `ocr_tolerance`, `non_ocr_tolerance`, `claim_file_parser_type`, `commercial_payerid`, `patient_payerid`, `patient_pay_format`, `plan_type`, `default_service_date`, `default_account_number`, `default_cpt_code`, `default_ref_number`, `default_patient_name`, `is_check_date_as_batch_date`, `average_insurance_eob_processing_productivity`, `average_patient_pay_eob_processing_productivity`, `is_deleted`, `client_dda_number`, `payer_ids_to_exclude`, `supplemental_outputs`, `default_payer_tin`) values('1','PIEDMONT PHYSICIANS GROUP','7','KBKB030Y','582092768','1912956046','1','PO Box 102321','','303682321','Atlanta','GA','--- \n:group_code: false\n:patient_type: false\n:check_date: true\n:late_fee_charge: false\n:revenue_code: false\n:payee_name: true\n:payment_code: false\n:rx_code: false\n:cpt_mandatory: true\n:claim_type: true\n:deposit_service_date: false\n:edit_claim_total: true\n:hcra: false\n:expected_payment: false\n:reference_code: false\n:claim_level_dos: true\n:drg_code: false\n:hipaa_code: true\n:service_date_from: true\n',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'0',NULL,NULL,'0',NULL,NULL,NULL,NULL)");
    sql.execute("insert into `facilities` (`id`, `name`, `client_id`, `sitecode`, `facility_tin`, `facility_npi`, `image_type`, `address_one`, `address_two`, `zip_code`, `city`, `state`, `details`, `lockbox_number`, `abbr_name`, `tat`, `processing_location`, `production_status`, `image_file_format`, `image_processing_type`, `index_file_format`, `index_file_parser_type`, `batch_load_type`, `ocr_tolerance`, `non_ocr_tolerance`, `claim_file_parser_type`, `commercial_payerid`, `patient_payerid`, `patient_pay_format`, `plan_type`, `default_service_date`, `default_account_number`, `default_cpt_code`, `default_ref_number`, `default_patient_name`, `is_check_date_as_batch_date`, `average_insurance_eob_processing_productivity`, `average_patient_pay_eob_processing_productivity`, `is_deleted`, `client_dda_number`, `payer_ids_to_exclude`, `supplemental_outputs`, `default_payer_tin`) values('2','SOUTH COAST','7','w1PQ082g','582194871','1467451922','1','PO BOX 15909',NULL,'314162609','SAVANNAH','GA','--- !map:HashWithIndifferentAccess \ndate_received_by_insurer: false\nhipaa_code: true\npayee_name: true\ncarrier_code: false\nexpected_payment_pat_simplified: false\ngroup_code: false\nclaim_level_dos: false\nexpected_payment_insurance: false\ncheck_date: true\ntransaction_type: false\nmicr_line_info: false\nrevenue_code: false\nreference_code: false\nreference_code_mandatory: false\ncpt_mandatory: true\nlate_fee_charge: false\npayment_code: false\nservice_date_from: true\nrx_code: false\ninterest_in_service_line: false\nclaim_type: true\nclaim_level_eob: false\npatient_account_number_hyphen_format: false\ndrg_code: false\npayment_type: false\npayer_tin: true\npatient_type: false\ndenied: false\npayer_specific_reason_code: false\nhcra: false\n','1161210','CPO','48','Onsite','Production','TIFF','Combine Split',NULL,NULL,'C,P',NULL,NULL,'Standard','D9998',NULL,'Nextgen Format','837 specific','Check Date',NULL,NULL,NULL,'Payer Name','1',NULL,NULL,'0',NULL,NULL,'Operation Log','000000009')");
    sql.execute("insert into `facilities` (`id`, `name`, `client_id`, `sitecode`, `facility_tin`, `facility_npi`, `image_type`, `address_one`, `address_two`, `zip_code`, `city`, `state`, `details`, `lockbox_number`, `abbr_name`, `tat`, `processing_location`, `production_status`, `image_file_format`, `image_processing_type`, `index_file_format`, `index_file_parser_type`, `batch_load_type`, `ocr_tolerance`, `non_ocr_tolerance`, `claim_file_parser_type`, `commercial_payerid`, `patient_payerid`, `patient_pay_format`, `plan_type`, `default_service_date`, `default_account_number`, `default_cpt_code`, `default_ref_number`, `default_patient_name`, `is_check_date_as_batch_date`, `average_insurance_eob_processing_productivity`, `average_patient_pay_eob_processing_productivity`, `is_deleted`, `client_dda_number`, `payer_ids_to_exclude`, `supplemental_outputs`, `default_payer_tin`) values('3','SAVANNAH PRIMARY CARE','7','wZR8083H','020695029','1588663058','1','1326 EISENHOWER DR STE D',NULL,'31406','SAVANNAH','GA','--- !map:HashWithIndifferentAccess \ndate_received_by_insurer: false\nhipaa_code: true\npayee_name: true\ncarrier_code: false\nexpected_payment_pat_simplified: false\ngroup_code: false\nclaim_level_dos: false\nexpected_payment_insurance: false\ncheck_date: false\ntransaction_type: false\nmicr_line_info: false\nrevenue_code: false\nreference_code: false\nreference_code_mandatory: false\ncpt_mandatory: true\nlate_fee_charge: false\npayment_code: false\nservice_date_from: true\nrx_code: false\ninterest_in_service_line: false\nclaim_type: true\nclaim_level_eob: false\npatient_account_number_hyphen_format: false\ndrg_code: false\npayment_type: false\npayer_tin: true\npatient_type: false\ndenied: false\npayer_specific_reason_code: false\nhcra: false\n','1161210','SPC','48','Onsite','Production','TIFF','Combine Split',NULL,NULL,'C,P',NULL,NULL,'Standard','D9998',NULL,'Nextgen Format','837 specific','Check Date',NULL,NULL,NULL,'Payer Name','1',NULL,NULL,'0',NULL,NULL,'Operation Log','000000009')");
    sql.execute("insert into `facilities` (`id`, `name`, `client_id`, `sitecode`, `facility_tin`, `facility_npi`, `image_type`, `address_one`, `address_two`, `zip_code`, `city`, `state`, `details`, `lockbox_number`, `abbr_name`, `tat`, `processing_location`, `production_status`, `image_file_format`, `image_processing_type`, `index_file_format`, `index_file_parser_type`, `batch_load_type`, `ocr_tolerance`, `non_ocr_tolerance`, `claim_file_parser_type`, `commercial_payerid`, `patient_payerid`, `patient_pay_format`, `plan_type`, `default_service_date`, `default_account_number`, `default_cpt_code`, `default_ref_number`, `default_patient_name`, `is_check_date_as_batch_date`, `average_insurance_eob_processing_productivity`, `average_patient_pay_eob_processing_productivity`, `is_deleted`, `client_dda_number`, `payer_ids_to_exclude`, `supplemental_outputs`, `default_payer_tin`) values('4','ORTHOPAEDIC FOOT AND ANKLE CTR','7','wbRB083H','521672232','1952396764','1','6715 FORREST PARK DR',NULL,'31406','SAVANNAH','GA','--- !map:HashWithIndifferentAccess \ndate_received_by_insurer: false\nhipaa_code: true\npayee_name: true\ncarrier_code: false\nexpected_payment_pat_simplified: false\ngroup_code: false\nclaim_level_dos: false\nexpected_payment_insurance: false\ncheck_date: false\ntransaction_type: false\nmicr_line_info: false\nrevenue_code: false\nreference_code: false\nreference_code_mandatory: false\ncpt_mandatory: true\nlate_fee_charge: false\npayment_code: false\nservice_date_from: true\nrx_code: false\ninterest_in_service_line: false\nclaim_type: true\nclaim_level_eob: false\npatient_account_number_hyphen_format: false\ndrg_code: false\npayment_type: false\npayer_tin: true\npatient_type: false\ndenied: false\npayer_specific_reason_code: false\nhcra: false\n','1161210','OFA','48','Onsite','Production','TIFF','Combine Split',NULL,NULL,'C,P',NULL,NULL,'Standard','D9998',NULL,'Nextgen Format','837 specific','Check Date',NULL,NULL,NULL,'Payer Name','1',NULL,NULL,'0',NULL,NULL,'Operation Log','000000009')");
    sql.execute("insert into `facilities` (`id`, `name`, `client_id`, `sitecode`, `facility_tin`, `facility_npi`, `image_type`, `address_one`, `address_two`, `zip_code`, `city`, `state`, `details`, `lockbox_number`, `abbr_name`, `tat`, `processing_location`, `production_status`, `image_file_format`, `image_processing_type`, `index_file_format`, `index_file_parser_type`, `batch_load_type`, `ocr_tolerance`, `non_ocr_tolerance`, `claim_file_parser_type`, `commercial_payerid`, `patient_payerid`, `patient_pay_format`, `plan_type`, `default_service_date`, `default_account_number`, `default_cpt_code`, `default_ref_number`, `default_patient_name`, `is_check_date_as_batch_date`, `average_insurance_eob_processing_productivity`, `average_patient_pay_eob_processing_productivity`, `is_deleted`, `client_dda_number`, `payer_ids_to_exclude`, `supplemental_outputs`, `default_payer_tin`) values('5','SAVANNAH SURGICAL ONCOLOGY','7','wZR9083H','581599993','1275532756','1','7001 HODGSON MEMORIAL DR STE 1',NULL,'31406','SAVANNAH','GA','--- !map:HashWithIndifferentAccess \ndate_received_by_insurer: false\nhipaa_code: true\npayee_name: true\ncarrier_code: false\nexpected_payment_pat_simplified: false\ngroup_code: false\nclaim_level_dos: true\nexpected_payment_insurance: false\ncheck_date: false\ntransaction_type: false\nmicr_line_info: false\nrevenue_code: false\nreference_code: false\nreference_code_mandatory: false\ncpt_mandatory: true\nlate_fee_charge: false\npayment_code: false\nservice_date_from: true\nrx_code: false\ninterest_in_service_line: false\nclaim_type: true\nclaim_level_eob: false\npatient_account_number_hyphen_format: false\ndrg_code: false\npayment_type: false\npayer_tin: false\npatient_type: false\ndenied: false\npayer_specific_reason_code: false\nhcra: false\n','1161210','SSO','48','Onsite','Production','TIFF','Combine Split',NULL,NULL,'C,P',NULL,NULL,'Standard','D9998',NULL,'Nextgen Format','837 specific','Check Date',NULL,NULL,NULL,'Payer Name','1',NULL,NULL,'0',NULL,NULL,'Operation Log','000000009')");
    sql.commit_db_transaction

  end

  def data_teardown_for_facility
    sql = ActiveRecord::Base.connection();
    sql.execute "SET autocommit=0";
    sql.begin_db_transaction
    id, value =

    sql.execute("DELETE FROM service_payment_eobs WHERE insurance_payment_eob_id IN (SELECT id FROM insurance_payment_eobs WHERE check_information_id IN (SELECT id from check_informations where job_id in (select id from jobs where batch_id in (select id from batches where facility_id in (1,2,3,4,5)))))");
    sql.execute("DELETE FROM insurance_payment_eobs WHERE check_information_id IN (SELECT id from check_informations where job_id in (select id from jobs where batch_id in (select id from batches where facility_id in (1,2,3,4,5))))");
    sql.execute("delete from check_informations where job_id in (select id from jobs where batch_id in (select id from batches where facility_id in (1,2,3,4,5)))");
    sql.execute("delete from eob_qas where job_id in (select id from jobs where batch_id in (select id from batches where facility_id in (1,2,3,4,5)))");
    sql.execute("delete from client_images_to_jobs where job_id in (select id from jobs where batch_id in (select id from batches where facility_id in (1,2,3,4,5)))");
    sql.execute("delete from jobs where batch_id in (select id from batches where facility_id in (1,2,3,4,5))");
    sql.execute("delete from batches where facility_id in (1,2,3,4,5)");
    sql.execute("delete from facilities where id in (1,2,3,4,5)");
    sql.execute("delete from clients where id = 7");
    sql.commit_db_transaction
  end


def test_total_col_span_with_claim_level_eob_as_true_and_is_insurance_grid_as_true
    facility = Facility.find(1)

    # Service line parameter value setting
    facility.details[:service_date_from] = true
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 1 - condition matching with all service line parameters set as true
    assert_equal(10, facility.total_col_span(true, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 2 - service date from set to false
    assert_equal(8, facility.total_col_span(true, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(7, facility.total_col_span(true, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(6, facility.total_col_span(true, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(5, facility.total_col_span(true, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = false
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(4, facility.total_col_span(true, true))
  end
#
  def test_total_col_span_with_claim_level_eob_as_false_and_is_insurance_grid_as_true
    facility = Facility.find(2)

    # Service line parameter value setting
    facility.details[:service_date_from] = true
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 1 - condition matching with all service line parameters set as true
    assert_equal(12, facility.total_col_span(false, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 2 - service date from set to false
    assert_equal(10, facility.total_col_span(false, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(9, facility.total_col_span(false, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(8, facility.total_col_span(false, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(7, facility.total_col_span(false, true))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = false
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(6, facility.total_col_span(false, true))

  end

  def test_total_col_span_with_claim_level_eob_as_true_and_is_insurance_grid_as_false
    facility = Facility.find(3)

    # Service line parameter value setting
    facility.details[:service_date_from] = true
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 1 - condition matching with all service line parameters set as true
    assert_equal(8, facility.total_col_span(true, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 2 - service date from set to false
    assert_equal(6, facility.total_col_span(true, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(5, facility.total_col_span(true, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(4, facility.total_col_span(true, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(4, facility.total_col_span(true, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = false
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(4, facility.total_col_span(true, false))

  end

  def test_total_col_span_with_claim_level_eob_as_false_and_is_insurance_grid_as_false
    facility = Facility.find(4)

    # Service line parameter value setting
    facility.details[:service_date_from] = true
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 1 - condition matching with all service line parameters set as true
    assert_equal(10, facility.total_col_span(false, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = true
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 2 - service date from set to false
    assert_equal(8, facility.total_col_span(false, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = true
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(7, facility.total_col_span(false, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = true
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(6, facility.total_col_span(false, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = true
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(6, facility.total_col_span(false, false))

    # Service line parameter value setting
    facility.details[:service_date_from] = false
    facility.details[:reference_code] = false
    facility.details[:revenue_code] = false
    facility.details[:rx_code] = false
    facility.details[:bundled_procedure_code] = false
    #Scenario 3 - service date from value and reference code set to false
    assert_equal(6, facility.total_col_span(false, false))
  end
end
