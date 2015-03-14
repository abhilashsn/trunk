module Admin::PopUpHelper

  def get_field_name_list

    field_names_hash = { 'checkdate_id' => 'check date', 'checknumber_id' => 'check number',
      'payer_type' => 'payer type', 'payer_popup' => 'payer name', 'payer_address_two' => 'payer address',
      'payer_city_id' => 'payer city', 'payer_state_id' => 'payer state', 'payer_zipcode_id' => 'payer zipcode',
      'payer_tin_id' => 'payer tin', 'patient_last_name_id' => 'patient lastname',
      'patient_first_name_id' => 'patient firstname', 'patient_initial_id' => 'patient middleinitial',
      'patient_suffix_id' => 'patient suffix', 'patient_account_id' => 'patient account no',
      'claimnumber_id' => 'claim number', 'insurance_policy_number_id' => 'policy number',
      'patient_identification_code_id' => 'patient identificationcode', 'qualifier' => 'qualifier',
      'member_id' => 'member id', 'interest_id' => 'interest', 'plan_type_id' => 'plan type',
      'claim_type' => 'claim type', 'subcriber_last_name_id' => 'subscriber lastname',
      'subcriber_firstname_id' => 'subscriber firstname', 'subcriber_initial_id' => 'subscriber initial',
      'subcriber_suffix_id' => 'subscriber suffix', 'provider_organisation_id' => 'provider organisation',
      'provider_provider_last_name' => 'provider lastname', 'prov_firstname_id' => 'provider firstname',
      'prov_initial_id' => 'provider initial', 'prov_suffix_id' => 'provider suffix',
      'provider_provider_npi_number' => 'provider npi', 'provider_tin_id' => 'provider tin', 'hcra_id' => 'hcra',
      'late_filing_charge_id' => 'late filing charge', 'drg_code_id' => 'drg code',
      'patient_type_id' => 'patient type', 'dateofservicefrom' => 'service from date',
      'dateofserviceto' => 'service to date', 'cpt_procedure_code' => 'cpt code',  'tooth_number' => 'tooth number',
      'bundled_procedure_code' => 'bundled cpt code', 'rx_code' => 'rx code', 'revenue_code' => 'revenue code',
      'provider_control_number' => 'provider control number', 'expected_payment_id' => 'expected payment',
      'claim_from_date_id' => 'claim fromdate', 'claim_to_date_id' => 'claim todate', 'claim_tooth_number' => 'claim toothnumber',
      'units_id' => 'quantity', 'modifier_id1' => 'modifier1', 'modifier_id2' => 'modifier2',
      'modifier_id3' => 'modifier3', 'modifier_id4' => 'modifier4', 'charges_id' => 'charges',
      'allowable_id' => 'allowable', 'payment_id' => 'payment', 'non_covered_id' => 'non covered',
      'denied_id' => 'denied', 'discount_id' => 'discount', 'co_insurance_id' => 'co-insurance',
      'deductable_id' => 'deductible', 'copay_id' => 'copay', 'primary_pay_payment_id' => 'primary pay payment',
      'contractualamount_id' => 'contractual amount', 'balance_id' => 'balance',
      'place_of_service' => 'place of service', 'payee_npi' => 'payee NPI',
      'payee_tin' => 'payee TIN', 'payee_name' => 'payee name',
      'medical_record_number_id' => 'medical record number'}
    
  end

  def update_facility
    render :partial => 'show_facility_for_alert'
  end
end
