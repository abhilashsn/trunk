// This function is used to change the visibility of Ref Code Mandatory Checkbox in Grid Setup Tab.
// When we click on Ref Code checkbox, it will display Ref Code Mandatory checkbox.
function change_visibility_of_CB_reference_code_mandatory(){
    if($F('details_reference_code') == "1")
        $('reference_code_mandatory').style.visibility = "visible";
    else
        $('reference_code_mandatory').style.visibility = "hidden";
}

// if we select Balancing Procedure as Balancing Record from Grid Setup Tab, 
// then Balancing Record Tab will be visible. Otherwise it will be hidden. 
function changeVisibilityOfBalancingRecordTab(){
    checked_status = $('details_balance_record_applicable').checked;
    if(checked_status)
        $('tabTabdhtmlgoodies_tabView1_3').disabled = false;
    else
        $('tabTabdhtmlgoodies_tabView1_3').disabled = true;
}

function checkAlpha(text_id){
    var alphaExp = /^[a-zA-Z\s]+$/;
    if ($F(text_id) != ""){
        if ($F(text_id).match(alphaExp))
            return true;
        else{
            alert("Required Letters only");
            $(text_id).focus();
            return false;
        }
    }
        
}
function checkAlphaNumeric(text_id){
    var alphaNumExp = /^[a-zA-Z0-9]+$/;
    if ($F(text_id) != ""){
        if ($F(text_id).match(alphaNumExp))
            return true;
        else{
            alert("Required alphanumeric only");
            $(text_id).focus();
            return false;
        }
    }
}

// Validate the Payer Classification Fields
// Returns true when all the validation are passed, else false
function validatePayerClassificationFields(){
    itemIds = ['min_reason_codes', 'min_percentage_of_reason_codes', 'min_number_of_eobs', 'threshold_time_to_tat']
    var requiredValidation = validateRequiredFields(itemIds);
    var naturalNumberRegex = /[^0][0-9]*/;
    var itemIds = ['min_reason_codes', 'min_percentage_of_reason_codes']
    var naturalNumberValidation = verifyRegexPrecondition(itemIds, naturalNumberRegex);
    if (!requiredValidation) {
        alert("Please enter the Payer Classification fields in Input Setup.");
        return false;
    }
    else if (!naturalNumberValidation) {
        alert("Please enter natural numbers for Min count of reason code & Min % of unique reason codes  in Input Setup.")
        return false;
    }
    else if(requiredValidation && naturalNumberValidation) {
        return true;
    }
}

function enable_835_interest_section(){
    if ($('details_interest_in_service_line').checked){
        $('details_insu_interest_amount_add_interest_with_payment').disabled = true;
        $('details_insu_interest_amount_interest_in_plb').disabled = true;
        $('details_pat_pay_interest_amount_add_interest_with_payment').disabled = true;
        $('details_pat_pay_interest_amount_interest_in_plb').disabled = true;
    }
    else{
        $('details_insu_interest_amount_add_interest_with_payment').disabled = false;
        $('details_insu_interest_amount_interest_in_plb').disabled = false;
        $('details_pat_pay_interest_amount_add_interest_with_payment').disabled = false;
        $('details_pat_pay_interest_amount_interest_in_plb').disabled = false;
    }
}

// Validations that must be passed before saving a facility are verified in this function
// Returns true when all the validation are passed, else false
function mustPassValidationForFacility() {
    var resultOfValidation = false;
    setBalancingRecordSerialNumbers();
    resultOfValidation = validateUniquenessOfCategory() && validateRequiredItems() &&
    validateIsPayerThePatient() && validateBalanceRecordPatientNames() && validateBalanceRecordPatientAccountNumber() &&
    validateProviderNpiLengthInFcui() && validateProviderTinLengthInFcui() &&
    validatePracticeId() && validatePayerClassificationFields() &&
    validateDefaultPayerAddressFields() && validateDefaultCodes() && validateDefaultHipaaCodes() &&
    validationForCasAndLqheConfig() && validateCdtMandatory() && validateDefaultPlanType() &&
    validateDefaultClaimNumber() && validatePresenceOfSamplingPercentage() &&
    validateFacilityClientGroup();
    if(resultOfValidation){
        var agree = confirm("Are you sure ?");
        if (agree == true)
            return true;
        else
            return false;
    }
    else
        return false;
}

function validateProviderNpiLengthInFcui(){
    var values = [];
    var ids = [];
    var flag = true;
    $$(".validate-provider-npi-length").each(
        function(item) {
            if(!item.value.match(/(^\d{10}$)/)){
                if(item.value != null && item.value != ''){
                    ids.push(item.id);
                    values.push(item.value);
                }

            }
        });
    if(ids.length > 0){
        alert(" Following  NPI(s) " +values +" in Lockbox Setup tab should be 10 digit");
        flag = false;
    }
    return flag;
}

function validateProviderTinLengthInFcui(){
    var values = [];
    var ids = [];
    var flag = true;
    $$(".validate-provider-tin-length").each(
        function(item) {
            if(!item.value.match(/(^\d{9}$)/)){
                if(item.value != null && item.value != ''){
                    ids.push(item.id);
                    values.push(item.value);
                }

            }
        });
    if(ids.length > 0){
        alert(" Following  TIN(s) " +values +" in Lockbox Setup tab should be 9 digit");
        flag = false;
    }
    return flag;
}

// Validate the Default Payer Address Fields
// Returns true when all the validation are passed, else false
function validateDefaultPayerAddressFields(){
    var itemIds = ['default_payer_address_one', 'default_payer_city',
    'default_payer_state', 'default_payer_zip_code', ]
    var requiredValidation = validateRequiredFields(itemIds);
    var validateData = (validateZipCode('default_payer_zip_code') && validateState('default_payer_state'));
    
    if (requiredValidation) {
        if(validateData){
            return true;
        }
        else{
            return false;
        }
    }
    else{
        alert("Please enter the default payer address fields in General form of Output Setup.");
        return false;
    }
}

function validateDefaultCodes(){
    var result = true;
    if($F('default_codes_for_adjustment_reasons_coinsurance_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_contractual_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_copay_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_deductible_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_denied_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_discount_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_non_covered_group_code') == "" ||
        $F('default_codes_for_adjustment_reasons_ppp_group_code') == ""){
        alert("Group code is mandatory!");
        result = false;
    }
    return result;
}

function validateDefaultHipaaCodes(){
    var result = true;
    if($F('default_codes_for_adjustment_reasons_coinsurance_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_contractual_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_copay_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_deductible_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_denied_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_discount_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_non_covered_hippa_default') == "" ||
        $F('default_codes_for_adjustment_reasons_ppp_hippa_default') == ""){
        alert("Default HIPAA codes are mandatory!");
        result = false;
    }
    return result;
}

function change_visibility_of_doc_classification_validn_config(){
    if($F('details_document_classification') == "1"){
        $('document_classification_mandatory').style.visibility = "visible";
        $('same_doc_classification_within_a_job').style.visibility = "visible";
    }
    else{
        $('document_classification_mandatory').style.visibility = "hidden";
        $('same_doc_classification_within_a_job').style.visibility = "hidden"; 
    }
}

function validatePatientFirstAndLastName(id) {
    var validation;
    if ($('is_partner_bac') != null && $F('is_partner_bac') == 'true') {
        validation = validateData(id, 'Patient Name', false);
    }
    else {
        validation = validatePatientNameField(id, $('details_patient_name_format_validation').checked, false);
    }
    return validation;
}

function validatePracticeId() {
    var fieldId = "details_str_practice_id";
    var resultOfValidation = true;
    if($(fieldId) != null && $('facility_patient_pay_format') != null) {
        var value = $F(fieldId);
        if($F('facility_patient_pay_format').toUpperCase() == 'NEXTGEN FORMAT') {
            if(value.match(/^\d{4}$/) == null) {
                resultOfValidation = false;
                alert("Practice ID must be 4 digit numeric value for Nextgen Grid");
            }
        }
    }    
    return resultOfValidation;
}

function validateCdtMandatory(){
    var resultFlag = true;
    var fieldId = "detail_default_cdt_qualifier"
    if($(fieldId)!= null && $F(fieldId) == ""){
        alert("Default Service Code Qualifier is mandatory");
        resultFlag = false;
    }
    return resultFlag;
}

function validateDefaultPlanType(){
    var defaultPlanType = jQuery('#detail_default_plan_type').val();
    if(defaultPlanType == "" || defaultPlanType == null){
        alert("Default Plan Type is Mandatory");
        return false;
    }
    else if(defaultPlanType.length != 2){
        alert("Default Plan Type should be 2 digit Alphanumeric");
        return false;
    }
    else if(/^[a-zA-Z0-9]*$/.test(defaultPlanType) == false) {
        alert('Default Plan Type should be alphanumeric.');
        return false;
    }
    return true;
}

function validatePresenceOfSamplingPercentage() {
    var validation_result = true
    if($('facility_random_sampling_true').checked == true && $('facility_random_sampling_percentage') != null && $F('facility_random_sampling_percentage').strip() == ''){
        alert("Please enter Sampling Percentage.")
        validation_result = false
    }
    return validation_result;
}

function validateDefaultClaimNumber() {
    var resultOfValidation = true;
    if($('details_default_claim_number')) {
        var defaultClaimNumber = $F('details_default_claim_number').strip();            
        if(defaultClaimNumber != '') {
            if(defaultClaimNumber.match(/^[A-Za-z0-9\-\.]*$/) != null && defaultClaimNumber.match(/\.{2}|\-{2}|^[\-\.]+$/) == null) {
                resultOfValidation = true;
            }
            else {
                alert('Default Claim # should be alphanumeric, hyphen or period only')
                resultOfValidation = false;
            }
        }
    }
    return resultOfValidation;
}

function hideFacilityGroup(checked){
    if(checked){
        document.getElementById("hidethis").style.display =  'none';
    }
}

function showCasConfigForMultipleReasonCode() {
    if($('details_multiple_reason_codes_in_adjustment_field') &&
        $('td_cas_for_all_multiple_reason_codes_in_adjustment_field')) {
        if($('details_multiple_reason_codes_in_adjustment_field').checked == true)
            $('td_cas_for_all_multiple_reason_codes_in_adjustment_field').style.display = "block";
        else
            $('td_cas_for_all_multiple_reason_codes_in_adjustment_field').style.display = "none";
    }
}

function validateFacilityClientGroup(){
    var client_group_type = jQuery('#facility_client_group').val();
    var client_name = jQuery('#facil_client option:selected').text().toUpperCase();
    if (client_name == 'QUADAX' && client_group_type == ''){
        alert('Facility Client Group is mandatory');
        return false
    }
    else{
        return true
    }
}


jQuery(document).ready(function() {
    jQuery('#facil_client').on('change', function(){
        var client_name = jQuery(this).find("option:selected").text();
        if (client_name.toUpperCase() == 'QUADAX'){
            jQuery('#client_group_row').show();
        }else{
            jQuery('#client_group_row').hide();
        }
    });
})