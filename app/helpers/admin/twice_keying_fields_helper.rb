module Admin::TwiceKeyingFieldsHelper

  def field_names_list

    field_names_hash = { 
      'checkdate' => 'check date',
      'checknumber' => 'check number',
      'checkamount' => 'check amount',
      'aba_routing_number' => 'aba routing number',
      'payer_account_number' => 'payer account number',
      'check_mailed_date' => 'check mailed date',
      'check_received_date' => 'check received date',
      'payment_type' => 'payment type',

      'payee_npi' => 'payee NPI',
      'payee_tin' => 'payee TIN',
      'payee_name' => 'payee name',
      
      'payer_type' => 'payer type',
      'payer_popup' => 'payer name',
      'payer_address_one' => 'payer address one',
      'payer_address_two' => 'payer address two',
      'payer_city' => 'payer city',
      'payer_state' => 'payer state',
      'payer_zipcode' => 'payer zipcode',
      'payer_tin' => 'payer tin',
      'alternate_payer_name' => 're-pricer info',

      'patient_last_name' => 'patient last name',
      'patient_first_name' => 'patient first name',
      'patient_initial' => 'patient middle initial',
      'patient_suffix' => 'patient suffix',
      'patient_account' => 'patient account no',
      'patient_address_one' => 'patient address one',
      'patient_address_two' => 'patient address two',
      'patient_city' => 'patient city',
      'patient_state' => 'patient state',
      'patient_zipcode' => 'patient zipcode',

      'carrier_code' => 'carrier code',
      'claimnumber' => 'claim number',
      'insurance_policy_number' => 'policy number',
      'payer_control_number' => 'payer_control_number',
      'marital_status' => 'marital status',
      'patient_identification_code' => 'patient ID',
      'qualifier' => 'qualifier no',
      'member' => 'member ID',
      'medical_record_number_id' => 'medical record number(MRN)',
      
      'place_of_service' => 'place of service(POS)',
      'secondary_plan_code' => 'secondary plan code',
      'tertiary_plan_code' => 'tertiary plan code',
      'over_payment_recovery' => 'over payment recovery',
      'interest' => 'interest amount',
      'hcra' => 'hcra',
      'fund' => 'fund',
      'plan_type' => 'plan type(Iplan)',
      'payer_indicator' => 'payer indicator',
      'claim_type' => 'claim type',
      'classified_image_type' => 'image type',
      'transaction_type' => 'transaction_type',
      
      'payee_type_format' => 'format',
      'statement_receiver' => 'payee type',
      'statement_applied' => 'patient statement?',
      'multiple_invoice_applied' => 'multiple account# ?',
      'multiple_statement_applied' => 'multiple statement# ?',
      
      'subcriber_last_name' => 'subscriber last name',
      'subcriber_firstname' => 'subscriber first name',
      'subcriber_initial' => 'subscriber initial',
      'subcriber_suffix' => 'subscriber suffix',
      'date_received_by_insurer' => 'date received',
      
      'provider_organisation' => 'provider organisation',
      'provider_provider_last_name' => 'provider last name',
      'prov_firstname' => 'provider first name',
      'prov_initial' => 'provider initial',
      'prov_suffix' => 'provider suffix',
      'provider_address_address_line_one' => 'provider address line one',
      'provider_address_address_line_two' => 'provider address line two',
      'provider_address_city' => 'provider address city',
      'provider_address_state' => 'provider address state',
      'provider_address_zip' => 'provider address zip',
      'provider_provider_npi_number' => 'provider npi',
      'provider_tin' => 'provider tin',

      'state_use_only' => 'state use only',
      'late_filing_charge' => 'late filing charge',
      'drg_code' => 'drg code',
      'patient_type' => 'patient type',
      'document_classification' => 'document classification',
      
      'dateofservicefrom' => 'service from date',
      'dateofserviceto' => 'service to date',
      'procedure_code' => 'CPT code',
      'bundled_procedure_code' => 'bundled CPT code',
      'rx_code' => 'rx code',
      'revenue_code' => 'revenue code',
      'line_item_number' => 'line item number',      
      'provider_control_number' => 'provider control number',
      'units_id' => 'quantity',      
      'claim_from_date' => 'claim from date',
      'claim_to_date' => 'claim to date',
      
      'modifier' => 'modifier',
      'tooth_number' => 'tooth number',
      'payment_status_code' => 'payment_status_code',
      'remark_code' => 'remark code',
      'charge' => 'charge amount',
      'pbid' => 'pbid',
      'allowable' => 'allowable',
      'plan_coverage' => 'plan coverage',
      'drg_amount' => 'drg_amount',
      'expected_payment' => 'expected payment',
      'retention_fees' => 'retention fees',
      'payment' => 'payment', 
      'non_covered' => 'non covered',
      'denied' => 'denied',
      'discount' => 'discount',
      'co_insurance' => 'co-insurance',
      'deductable' => 'deductible',
      'copay' => 'copay',
      'co_pay' => 'copay',
      'patient_responsibility' => 'patient responsibility',
      'primary_payment' => 'primary payment',
      'prepaid' => 'prepaid',
      'contractual' => 'contractual',
      'noncovered_unique_code' => 'non covered unique code',
      'denied_unique_code' => 'denied unique code',
      'discount_unique_code' => 'discount unique code',
      'coinsurance_unique_code' => 'co-insurance unique code',
      'deductible_unique_code' => 'deductible unique code',
      'copay_unique_code' => 'copay unique code',
      'patient_responsibility_unique_code' => 'patient responsibility unique code',
      'primary_payment_unique_code' => 'primary payment unique code',
      'prepaid_unique_code' => 'prepaid unique code',
      'contractual_unique_code' => 'contractual unique code',

      'prov_adjustment_description' => 'provider adjustment description',
      'prov_adjustment_account_number' => 'provider adjustment account number',
      'prov_adjustment_amount_id' => 'provider adjustment amount'
    }

  end

  def processor_list
    users = User.select("users.name, users.id").joins("INNER JOIN roles ON roles.name = 'processor'
       INNER JOIN roles_users ON roles_users.user_id = users.id AND roles_users.role_id = roles.id")
    processor_list = users.collect{ |user| [user.name, user.id]}
    processor_list.sort
  end

  def dropdown_element_count record, element
    option = ''
    case element
    when 'facility'
      unless record.facility_name.blank?
        facilities = record.facility_name.split(',')
        selected_facility_count = facilities.count
        total_facilities_count = Facility.where("client_id = ?", record.client_id).count
        option = option_description total_facilities_count, selected_facility_count
      end
    when 'processor'
      processors = record.processor_name.split(',')
      selected_processors_count = processors.count
      total_processors_count =  User.joins(:roles).where("roles.name = ?", 'processor').count
      option = option_description total_processors_count, selected_processors_count
    when 'field_name'
      total_fields_count = field_names_list.keys.count
      selected_fields_count = record.field_count
      option = option_description total_fields_count, selected_fields_count
    end
    option
  end

  def option_description total_count, selected_count
    if total_count == selected_count
      "-- All Selected --"
    else
      "-- #{selected_count} Selected --"
    end
  end
end