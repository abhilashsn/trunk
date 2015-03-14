var count = 0;
var extraCount = 0;
var servicecount = 0;
var row_count = 0;
var string = /^[a-zA-Z0-9\s\&\-\+\.]+$/;
var alphaExp = /^[a-zA-Z]+$/;
var alphaNumExp =  /^[a-zA-Z0-9]+$/;
var char_array = new Array();
var capitalLetter = /^[A-Z]+$/;
var mpi_service_del = 0 ;
var zipcode_check=/(^\d{5}$)|(^\d{9}$)/
var sum = 0;
var mpi_rows = 0;
//var reasoncode_check = /^[A-Za-z0-9\+]+$/;
var reasoncode_check = /^[\s]+$/;
var decimalNumber = /^[-+]?[0-9]+(\.[0-9]+)?$/
var dobRegxp = /^([0-9]){2}(\/|-){1}([0-9]){2}(\/|-)([0-9]){2}$/;
var numericExpression = /^[-/+]{0,1}\d+$/
var realnumberExp = /^[0-9]+(\.[0-9]+)?$/
var npi_check = /(^\d{10}$)/
var revenuecode_check = /(^\d{4}$)/
var svcline_ids_to_delete = new Array();
var busy = 0;
var image_page_number = /^[1-9][0-9]*$/
var processing = 0;
var bServicetimetracking = true;
var confirmation_status = true;
needToValidateAdjustmentLine = true;
setDefaultValuesForJobIncompletionToggle = false;

String.prototype.trim = function() {
    string_to_trim = this.replace(/^\s+/, '');
    return string_to_trim.replace(/\s+$/, '');
};

Array.prototype.getRandom= function(num, cut){
    var A= cut? this:this.slice(0);
    A.sort(function(){
        return .5-Math.random();
    });
    return A.splice(0, num);
}

function round_total(amount){
    var result=Math.round(amount*100)/100;
    return result;
}

// This is a substitute for link_to helper's :popup_up => true
function popup_window(url, window_name, dimensions){
    url = relative_url_root() + url;
    newwindow = window.open(url, window_name, dimensions);
    newwindow.focus();
    return false;
}

function removeAllServiceLines(){
    $('svcline_ids_to_delete').value = "";
    var table = $('service_line_details');
    clearAdjustmentLine('1');
    var i;
    var rowId;
    for (i = 1; i <= $F('svc_line_last_serial_num'); i++){
        if(i != 1) {
            rowId = 'service_row' + i;
            if($(rowId) != null){
                table.deleteRow($(rowId).rowIndex);
            }
        }
    }
    if($('service_line_delete_all') != null)
        $('service_line_delete_all').value = 'true';
    $('total_charge_id').value = 0.00;
    if($('total_non_covered_id') != null)
        $('total_non_covered_id').value = 0.00;
    if($('total_pbid_id') != null)
        $('total_pbid_id').value = 0.00;
    if($('total_allowable_id') != null)
        $('total_allowable_id').value = 0.00;
    if($('total_denied_id') != null)
        $('total_denied_id').value = 0.00;
    if($('total_discount_id') != null)
        $('total_discount_id').value = 0.00;
    if($('total_coinsurance_id') != null)
        $('total_coinsurance_id').value = 0.00;
    if($('total_deductable_id') != null)
        $('total_deductable_id').value = 0.00;
    if($('total_primary_payment_id') != null)
        $('total_primary_payment_id').value = 0.00;
    if($('total_prepaid_id') != null)
        $('total_prepaid_id').value = 0.00;
    if($('total_retention_fees_id') != null)
        $('total_retention_fees_id').value = 0.00;

    if($('total_drg_amount_id') != null)
        $('total_drg_amount_id').value = 0.00;
    if($('total_expected_payment_id') != null)
        $('total_expected_payment_id').value = 0.00;
    if($('total_contractual_amount_id') != null)
        $('total_contractual_amount_id').value = 0.00;
    if($('total_copay_id') != null)
        $('total_copay_id').value = 0.00;
    if($('total_patient_responsibility_id') != null)
        $('total_patient_responsibility_id').value = 0.00;
    if($('total_payment_id') != null)
        $('total_payment_id').value = 0.00;
    if($('total_miscellaneous_one_id') != null)
        $('total_miscellaneous_one_id').value = 0.00;
    if($('total_miscellaneous_two_id') != null)
        $('total_miscellaneous_two_id').value = 0.00;
    if($('total_miscellaneous_balance_id') != null)
        $('total_miscellaneous_balance_id').value = 0.00;
    if($('total_service_balance_id') != null)
        $('total_service_balance_id').value = "";
    $('total_existing_number_of_svc_lines').value = 1; // Only Adjustment Line will be left
    $('svc_line_last_serial_num').value = $F('total_line_count');
    $('adjustment_line_number').value = '';
    count = 0;
}

// This method provides float value to the blank total dollar amount field.
function convertBlankStringToValue(value){
    if(value.strip() == '') return 0.00
    else return value
}

//Deletes a service line
// The condition 'service_id == 0' indicates that the last service line in UI is the Adjustment Line before it is saved in the db.
function removeServiceLine(p, table_id, service_id){
    svcline_ids_to_delete.push(service_id);
    $('svcline_ids_to_delete').value = svcline_ids_to_delete;
    var tbl = $(table_id);

    if($('service_line_to_delete') != null) {
        var lineIds = $F('service_line_to_delete');
        $('service_line_to_delete').value = lineIds + ',' + service_id;
    }

    var procedure_charge = convertBlankStringToValue($F('service_procedure_charge_amount_id'+p));
    var total_procedure_charge = $F('total_charge_id');
    if($F('pbid_status') == "true") {
        var pbid_amount = convertBlankStringToValue($F('service_pbid_id' + p));
        var total_pbid_amount = $F('total_pbid_id');
    }
    var non_covered_charge = convertBlankStringToValue($F('service_non_covered_id'+p));
    var total_non_covered_charge = $F('total_non_covered_id');
    if($F('denied_status') == "true"){
        var denied_charge = convertBlankStringToValue($F('denied_id'+p));
        var total_denied_charge = $F('total_denied_id');
    }
    var discount_charge = convertBlankStringToValue($F('service_discount_id'+p));
    var total_discount_charge = $F('total_discount_id');
    var allowable_charge = convertBlankStringToValue($F('service_allowable_id'+p));
    var total_allowable_charge = $F('total_allowable_id');
    if($F('drg_amount_status') == "true") {
        var drgAmount = convertBlankStringToValue($F('service_drg_amount_id'+p));
        var totalDrgAmount = $F('total_drg_amount_id');
    }
    if($F('expected_payment_status') == "true"){
        var expected_payment = convertBlankStringToValue($F('service_expected_payment_id'+p));
        var total_expected_payment = $F('total_expected_payment_id');
    }
    if($F('retention_fees_status') == "true"){
        var retention_fee = convertBlankStringToValue($F('service_retention_fees_id' + p));
        var total_retention_fee = $F('total_retention_fees_id');
    }
    if($F('prepaid_status') == "true"){
        var prepaid = convertBlankStringToValue($F('service_prepaid_id' + p));
        var total_prepaid = $F('total_prepaid_id');
    }
    if($F('patient_responsibility_status') == "true"){
        var patient_responsibility = convertBlankStringToValue($F('patient_responsibility_id' + p));
        var total_patient_responsibility = $F('total_patient_responsibility_id');
    }
    if($F('miscellaneous_one_status') == "true"){
        var miscellaneous_one_charge = convertBlankStringToValue($F('miscellaneous_one_id'+p));
        var total_miscellaneous_one_charge = $F('total_miscellaneous_one_id');
    }
    if($F('miscellaneous_two_status') == "true"){
        var miscellaneous_two_charge = convertBlankStringToValue($F('miscellaneous_two_id'+p));
        var total_miscellaneous_two_charge = $F('total_miscellaneous_two_id');
    }
    if($F('miscellaneous_balance_status') == "true"){
        var miscellaneous_balance_charge = convertBlankStringToValue($F('miscellaneous_balance_id'+p));
        var total_miscellaneous_balance_charge = $F('total_miscellaneous_balance_id');
    }

    if($('service_contractual_amount_id'+p))
        var service_contractual_amount = convertBlankStringToValue($F('service_contractual_amount_id'+p));
    if($('total_contractual_amount_id'))
        var total_contractual_amount = $F('total_contractual_amount_id');

    var service_coinsurance = convertBlankStringToValue($F('service_co_insurance_id'+p));
    var total_coinsurance = $F('total_coinsurance_id');
    var service_deductable = convertBlankStringToValue($F('service_deductible_id'+p));
    var total_deductable = $F('total_deductable_id');
    var service_co_pay = convertBlankStringToValue($F('service_co_pay_id'+p));
    var total_co_pay = $F('total_copay_id');
    var service_paid_amount = convertBlankStringToValue($F('service_paid_amount_id'+p));
    var total_paid_amount = $F('total_payment_id');
    var service_submitted_charge =  convertBlankStringToValue($F('service_submitted_charge_for_claim_id'+p));
    var total_submitted_charge = $F('total_primary_payment_id');
    var service_balance = convertBlankStringToValue($F('service_balance_id'+p));
    var total_balance = $F('total_service_balance_id');
    if($('adjustment_line_number') != null && $F('adjustment_line_number') != ''){
        if($('service_procedure_charge_amount_id' + p) != null && $F('service_procedure_charge_amount_id' + p).strip() == '') {
            $('adjustment_line_number').value = '';
        }
    }
    if(service_id != 0){
        tbl.deleteRow($('service_row'+p).rowIndex);
    }
    else{
        clearAdjustmentLine(p);
    }

    if(service_id != 0){
        $('total_existing_number_of_svc_lines').value = parseInt($F('total_existing_number_of_svc_lines')) - 1;
    }
    no_service_row_exists = (($('service_row'+p))==null)
    if(service_id == 0)
        no_service_row_exists = true

    if (no_service_row_exists){
        mpi_service_deleted = 1
        mpi_service_del = 1
        total_procedure_charge -= procedure_charge;
        if($F('pbid_status') == "true")
            total_pbid_amount -= pbid_amount;
        total_non_covered_charge -= non_covered_charge;
        if($F('denied_status') == "true"){
            total_denied_charge -= denied_charge;
        }
        if($F('miscellaneous_one_status') == "true"){
            total_miscellaneous_two_charge -= miscellaneous_one_charge;
        }
        if($F('miscellaneous_two_status') == "true"){
            total_miscellaneous_two_charge -= miscellaneous_two_charge;
        }
        if($F('miscellaneous_balance_status') == "true"){
            total_miscellaneous_balance_charge -= miscellaneous_balance_charge;
        }
        total_discount_charge -= discount_charge;
        total_allowable_charge -= allowable_charge;
        if($F('drg_amount_status') == "true")
            totalDrgAmount -= drgAmount;
        if($F('expected_payment_status') == "true"){
            total_expected_payment -= expected_payment;
        }
        if($F('retention_fees_status') == "true")
            total_retention_fee -= retention_fee;
        if($F('prepaid_status') == "true")
            total_prepaid -= prepaid;
        if($F('patient_responsibility_status') == "true")
            total_patient_responsibility -= patient_responsibility;
        if($F('contractualamount_status') == "true")
            total_contractual_amount -= service_contractual_amount;
        total_coinsurance -= service_coinsurance;
        total_deductable -= service_deductable;
        total_co_pay -= service_co_pay;
        total_paid_amount -= service_paid_amount;
        total_submitted_charge -= service_submitted_charge;

        total_balance -= service_balance;

        $('total_charge_id').value = (total_procedure_charge.toFixed(2));
        if($F('pbid_status') == "true")
            $('total_pbid_id').value  = total_pbid_amount.toFixed(2);
        $('total_non_covered_id').value = (total_non_covered_charge.toFixed(2));
        if($F('denied_status') == "true"){
            $('total_denied_id').value = (total_denied_charge).toFixed(2);
        }
        if($F('miscellaneous_one_status') == "true"){
            $('total_miscellaneous_one_id').value = (total_miscellaneous_one_charge).toFixed(2);
        }
        if($F('miscellaneous_two_status') == "true"){
            $('total_miscellaneous_two_id').value = (total_miscellaneous_two_charge).toFixed(2);
        }
        if($F('miscellaneous_balance_status') == "true"){
            $('total_miscellaneous_balance_id').value = (total_miscellaneous_balance_charge).toFixed(2);
        }
        $('total_discount_id').value = (total_discount_charge).toFixed(2);
        $('total_allowable_id').value  = total_allowable_charge.toFixed(2);
        if($F('drg_amount_status') == "true")
            $('total_drg_amount_id').value  = totalDrgAmount.toFixed(2);
        if($F('expected_payment_status') == "true"){
            $('total_expected_payment_id').value  = total_expected_payment.toFixed(2);
        }
        if($F('retention_fees_status') == "true")
            $('total_retention_fees_id').value  = total_retention_fee.toFixed(2);
        if($F('prepaid_status') == "true")
            $('total_prepaid_id').value  = total_prepaid.toFixed(2);
        if($F('patient_responsibility_status') == "true")
            $('total_patient_responsibility_id').value  = total_patient_responsibility.toFixed(2);

        if($F('contractualamount_status') == "true")
            $('total_contractual_amount_id').value = total_contractual_amount.toFixed(2);
        $('total_coinsurance_id').value = total_coinsurance.toFixed(2);
        $('total_deductable_id').value = total_deductable.toFixed(2);
        $('total_copay_id').value = total_co_pay.toFixed(2);
        $('total_payment_id').value = total_paid_amount.toFixed(2);
        $('total_primary_payment_id').value = total_submitted_charge.toFixed(2);

        setTotalBalance(total_balance);
    }
    if($('dateofservicefrom')!= null)
        $('dateofservicefrom').focus();
    else if($('cpt_procedure_code') != null)
        $('cpt_procedure_code').focus();

}

// Deletes the service line added through 'Add Row'
function removeServiceLineAdded(n, table_id){
    var tbl = $(table_id);
    if(n != null && n != '') {
        var chargeAmount = $F('charge_amount_' + n);
        var totalChargeAmount = $F('total_charge_id');
        var noncoveredAmount = $F('noncovered_amount_' + n);
        var totalNoncoveredAmount = $F('total_non_covered_id');
        if($F('denied_status') == "true"){
            var deniedAmount = $F('denied_amount_' + n);
            var totalDeniedAmount = $F('total_denied_id');
        }
        if($F('miscellaneous_one_status') == "true"){
            var miscellaneousOneAmount = $F('miscellaneous_one_amount_' + n);
            var totalMiscellaneousOneAmount = $F('total_miscellaneous_one_id');
        }
        if($F('miscellaneous_two_status') == "true"){
            var miscellaneousTwoAmount = $F('miscellaneous_two_amount_' + n);
            var totalMiscellaneousTwoAmount = $F('total_miscellaneous_two_id');
        }
        if($F('miscellaneous_balance_status') == "true"){
            var miscellaneousBalanceAmount = $F('miscellaneous_balance_amount_' + n);
            var totalMiscellaneousBalanceAmount = $F('total_miscellaneous_balance_id');
        }
        var discountAmount = $F('discount_amount_' + n);
        var totalDiscountAmount = $F('total_discount_id');
        if($F('pbid_status') == "true"){
            var pbidAmount = $F('pbid_amount_' + n);
            var totalPbidAmount = $F('total_pbid_id');
        }
        var allowableAmount = $F('allowable_amount_' + n);
        var totalAllowableAmount = $F('total_allowable_id');
        if($F('drg_amount_status') == "true") {
            var drgAmount = $F('drg_amount_' + n);
            var totalDrgAmount = $F('total_drg_amount_id');
        }
        if($F('expected_payment_status') == "true"){
            var expectedPaymentAmount = $F('expected_payment_amount_' + n);
            var totalExpectedPaymentAmount = $F('total_expected_payment_id');
        }
        if($F('retention_fees_status') == "true"){
            var retentionFeeAmount = $F('retention_fee_amount_' + n);
            var totalRetentionFeeAmount = $F('total_retention_fees_id');
        }
        if($F('prepaid_status') == "true"){
            var prepaidAmount = $F('prepaid_amount_' + n);
            var totalPrepaidAmount = $F('total_prepaid_id');
        }
        if($F('patient_responsibility_status') == "true"){
            var patientResponsibilityAmount = $F('patient_responsibility_amount_' + n);
            var totalPatientResponsibilityAmount = $F('total_patient_responsibility_id');
        }
        if($F('contractualamount_status') == "true"){
            var contractualAmount = $F('contractual_amount_' + n);
            var totalContractualAmount = $F('total_contractual_amount_id');
        }
        var coinsuranceAmount = $F('coinsurance_amount_' + n);
        var totalCoinsuranceAmount = $F('total_coinsurance_id');
        var deductibleAmount = $F('deductible_amount_' + n);
        var totalDeductibleAmount = $F('total_deductable_id');
        var copayAmount = $F('copay_amount_' + n);
        var totalCopayAmount = $F('total_copay_id');
        var paymentAmount = $F('payment_amount_' + n);
        var totalPaymentAmount = $F('total_payment_id');
        var primaryPaymentAmount = $F('primary_payment_amount_' + n);
        var totalPrimaryPaymentAmount = $F('total_primary_payment_id');
        var balanceAmount = $F('balance_amount_' + n);
        var totalBalanceAmount = $F('total_service_balance_id');
    }
    tbl.deleteRow($('service_row' + n).rowIndex);
    $('total_existing_number_of_svc_lines').value = parseInt($F('total_existing_number_of_svc_lines')) - 1;
    if (($('service_row' + n)) == null) {
        totalChargeAmount -= chargeAmount;
        totalNoncoveredAmount -= noncoveredAmount;
        if($F('denied_status') == "true"){
            totalDeniedAmount -= deniedAmount;
        }
        if($F('miscellaneous_one_status') == "true"){
            totalMiscellaneousOneAmount -= miscellaneousOneAmount;
        }
        if($F('miscellaneous_two_status') == "true"){
            totalMiscellaneousTwoAmount -= miscellaneousTwoAmount;
        }
        if($F('miscellaneous_balance_status') == "true"){
            totalMiscellaneousBalanceAmount -= miscellaneousBalanceAmount;
        }
        totalDiscountAmount -= discountAmount;
        if($F('pbid_status') == "true")
            totalPbidAmount -= pbidAmount;
        totalAllowableAmount -= allowableAmount;
        if($F('drg_amount_status') == "true")
            totalDrgAmount -= drgAmount;
        if($F('expected_payment_status') == "true"){
            totalExpectedPaymentAmount -= expectedPaymentAmount;
        }
        if($F('retention_fees_status') == "true")
            totalRetentionFeeAmount -= retentionFeeAmount;
        if($F('prepaid_status') == "true")
            totalPrepaidAmount -= prepaidAmount;
        if($F('patient_responsibility_status') == "true")
            totalPatientResponsibilityAmount -= patientResponsibilityAmount;

        if($F('contractualamount_status') == "true")
            totalContractualAmount -= contractualAmount;
        totalCoinsuranceAmount -= coinsuranceAmount;
        totalDeductibleAmount -= deductibleAmount;
        totalCopayAmount -= copayAmount;
        totalPaymentAmount -= paymentAmount;
        totalPrimaryPaymentAmount -= primaryPaymentAmount;
        if((totalBalanceAmount != "") && (balanceAmount != "")){
            totalBalanceAmount -= balanceAmount;
        }
        $('total_charge_id').value = (totalChargeAmount.toFixed(2));
        $('total_non_covered_id').value = (totalNoncoveredAmount.toFixed(2));
        if($F('denied_status') == "true"){
            $('total_denied_id').value = (totalDeniedAmount).toFixed(2);
        }
        if($F('miscellaneous_one_status') == "true"){
            $('total_miscellaneous_one_id').value = (totalMiscellaneousOneAmount).toFixed(2);
        }
        if($F('miscellaneous_two_status') == "true"){
            $('total_miscellaneous_two_id').value = (totalMiscellaneousTwoAmount).toFixed(2);
        }
        if($F('miscellaneous_balance_status') == "true"){
            $('total_miscellaneous_balance_id').value = (totalMiscellaneousBalanceAmount).toFixed(2);
        }
        $('total_discount_id').value = (totalDiscountAmount).toFixed(2);
        if($F('pbid_status') == "true")
            $('total_pbid_id').value  = totalPbidAmount.toFixed(2);
        $('total_allowable_id').value = totalAllowableAmount.toFixed(2);

        if($F('drg_amount_status') == "true")
            $('total_drg_amount_id').value  = totalDrgAmount.toFixed(2);
        if($F('expected_payment_status') == "true"){
            $('total_expected_payment_id').value = totalExpectedPaymentAmount.toFixed(2);
        }
        if($F('retention_fees_status') == "true")
            $('total_retention_fees_id').value  = totalRetentionFeeAmount.toFixed(2);
        if($F('prepaid_status') == "true")
            $('total_prepaid_id').value  = totalPrepaidAmount.toFixed(2);
        if($F('patient_responsibility_status') == "true")
            $('total_patient_responsibility_id').value  = totalPatientResponsibilityAmount.toFixed(2);
        if($F('contractualamount_status') == "true")
            $('total_contractual_amount_id').value = totalContractualAmount.toFixed(2);
        $('total_coinsurance_id').value = totalCoinsuranceAmount.toFixed(2);
        $('total_deductable_id').value = totalDeductibleAmount.toFixed(2);
        $('total_copay_id').value = totalCopayAmount.toFixed(2);
        $('total_payment_id').value = totalPaymentAmount.toFixed(2);
        $('total_primary_payment_id').value = totalPrimaryPaymentAmount.toFixed(2);
        setTotalBalance(totalBalanceAmount);
    }
    if($('dateofservicefrom')!= null)
        $('dateofservicefrom').focus();
    else if($('cpt_procedure_code') != null)
        $('cpt_procedure_code').focus();
}

// Implementation of 'Add Row'
function addServiceLine(){
    $('add_button').style.visibility = "hidden";
    removeDefaultDateValue('dateofservicefrom');
    removeDefaultDateValue('dateofserviceto');
    var servicelineValidator = (validateAddRowRemarkCodes() &&
        dateRequired('dateofservicefrom') && dateRequired('dateofserviceto') && validateUpmcCptOrRevenueCodeLength('cpt_procedure_code') &&
        validateProcedureCodeLength('cpt_procedure_code') && validateRevenueCodeLength('revenue_code') &&  procedureCodeOrRevenueCodeMandatory('cpt_procedure_code', 'revenue_code') &&
        validateAddRowCptCodes() && validateRXnumber() && validateToothNumber() &&
        refNumCheck('provider_control_number') && validateQuantity('units_id') &&
        linecharge() && linepayment() && service_charge_must_be_nonzero() && validateAmount('prepaid_id') &&
        validateAmount('patient_responsibility_id') && validateAddRowReasonCodes() && validateAddRowAdjustmentAmounts() &&
        validateCorrectnessOfReasonCodes() && confirmHipaaCodesForAddServiceLine() &&
        lineallowable() && validateDrgAmount() &&
        service_balance_check() && amountCheckForLargeSumInAddRow() &&
        allowedAmountValidationNonmpi() && allowedAmountValidationWithChargeOnNonmpi() &&
        validateAmount('pbid_id') && validateAmount('retention_fees_id') && validateDenialServiceLineForUpmcOnAddRow())
    if ($F('bundled_procedure_code_status') == "true"){
        servicelineValidator = servicelineValidator && bundled_procedure_code_validation('bundled_procedure_code')
    }
    servicelineValidator = servicelineValidator && validateTwiceKeyingForAddServiceLine();
    if (servicelineValidator){
        if($('twice_keying_prev_values_of_add_row')) {
            $('twice_keying_prev_values_of_add_row').value = '';
        }
        count++;
        $('total_existing_number_of_svc_lines').value = parseInt($F('total_existing_number_of_svc_lines')) + 1;
        var serviceLineId = parseInt($F('svc_line_last_serial_num')) + 1;
        $('svc_line_last_serial_num').value = serviceLineId;
        if (count <= 400) {
            var tbody = $('service_line_details').getElementsByTagName("TBODY")[0];
            var row1 = document.createElement("TR")
            row1.setAttribute('valign','top')
            row1.setAttribute('class', 'service_line_row' + ' ' + 'service_line_id_')
            row1.vAlign="top"
            row1.setAttribute('id', 'service_row' + serviceLineId);

            var labelTd = document.createElement("TD");
            labelTd.setAttribute('id', "label" + serviceLineId);
            var labelField = document.createElement('LABEL');
            labelField.innerText = serviceLineId - 1;
            labelTd.appendChild(labelField);

            row1.appendChild(labelTd);

            if ($F('service_date_from_status') == "true"){
                var td1 = document.createElement("TD")
                td1.setAttribute('id', "td_date_service_from_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                dateservicefrom = document.getElementById('dateofservicefrom').value
                textField.className = "datebox validate-date"
                textField.setAttribute('value', dateservicefrom)
                textField.setAttribute('id', "date_service_from_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[dateofservice_from" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td1.appendChild(textField)
                row1.appendChild(td1);
                var td2 = document.createElement("TD")
                td2.setAttribute('id', "td_date_service_to_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                dateserviceto = document.getElementById('dateofserviceto').value
                textField.setAttribute('value', dateserviceto)
                textField.className = "datebox validate-date"
                textField.setAttribute('id', "date_service_to_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[dateofservice_to" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td2.appendChild(textField)
                row1.appendChild(td2);
            }

            if($('cpt_or_revenue_code_mandatory') != null && $F('cpt_or_revenue_code_mandatory') == true) {
                var cpt_and_revenuecode_validation = 'validate-cpt-or-revenue-code-mandatory';
            }
            else
                cpt_and_revenuecode_validation = '';
            var td3 = document.createElement("TD")
            td3.setAttribute('id', "td_procedure_code_" + serviceLineId)
            td3.setAttribute('style','width:29px')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            code = $F('cpt_procedure_code')
            textField.setAttribute('value', code)
            textField.setAttribute('style','width:29px')
            textField.className = "fullwidth"
            textField.setAttribute('id', "procedure_code_" + serviceLineId)
            textField.setAttribute('name', "lineinformation[procedure_code" + serviceLineId + "]")
            textField.setAttribute('class', cpt_and_revenuecode_validation + " validate-cpt_code_length validate-upmc_revenue_code_cpt_code_length" );
            textField.setAttribute('readOnly', true)
            td3.appendChild(textField)
            row1.appendChild(td3);

            cdtQualifierElement = document.createElement('INPUT')
            cdtQualifierElement.type = 'hidden'
            cdtQualifierElement.setAttribute('id', 'cdt_qualifier_' + serviceLineId)
            cdtQualifierElement.setAttribute('name', "lineinformation[cdt_qualifier_" + serviceLineId + "]")
            cdtQualifierElement.setAttribute('value', $F('fc_def_cdt_qualifier'))
            cdtQualifierElement.setAttribute('readOnly', true)
            row1.appendChild(cdtQualifierElement);

            if ($F('bundled_procedure_code_status') == "true"){
                var td3 = document.createElement("TD")
                td3.setAttribute('id', "td_bundled_procedure_code_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                emg = document.getElementById('bundled_procedure_code').value
                textField.setAttribute('value', emg)
                textField.setAttribute('style','width:29px')
                textField.className = "fullwidth"
                textField.setAttribute('id', "bundled_procedure_code_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[bundled_procedure_code" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td3.appendChild(textField)
                row1.appendChild(td3);
            }

            if ($F('rx_number_status') == "true"){
                var td98 = document.createElement("TD")
                td98.setAttribute('id', "td_rx_code_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                rx_num = document.getElementById('rx_code').value
                textField.setAttribute('value', rx_num)
                textField.setAttribute('style','width:49px')
                textField.className = "fullwidth"
                textField.setAttribute('id', "rx_code_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[rx_number" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td98.appendChild(textField)
                row1.appendChild(td98);
            }
            if ($F('revenue_code_status') == "true"){
                var td98 = document.createElement("TD")
                td98.setAttribute('id', "td_revenue_code_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                revuenuecode = document.getElementById('revenue_code').value
                textField.setAttribute('value', revuenuecode)
                textField.setAttribute('style','width:25px')
                textField.className = "fullwidth"
                textField.setAttribute('id', "revenue_code_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[revenue_code" + serviceLineId + "]")
                textField.setAttribute('class', cpt_and_revenuecode_validation + " validate-revenue-code");
                textField.setAttribute('readOnly', true)
                td98.appendChild(textField)
                row1.appendChild(td98);
            }

            if ($F('line_item_number_status') == "true"){
                var td98 = document.createElement("TD")
                td98.setAttribute('id', "td_line_item_number_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                lineItemNumber = $F('line_item_number_id')
                textField.setAttribute('value', lineItemNumber)
                textField.setAttribute('size','8')
                textField.className = "fullwidth"
                textField.setAttribute('id', "line_item_number_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[line_item_number" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td98.appendChild(textField)
                row1.appendChild(td98);
            }

            if ($F('reference_code_status') == "true"){
                var td98 = document.createElement("TD")
                td98.setAttribute('id', "td_provider_control_number_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                providerControlNumber = document.getElementById('provider_control_number').value
                textField.setAttribute('value', providerControlNumber)
                textField.setAttribute('style','width:30px')
                textField.className = "fullwidth"
                textField.setAttribute('id', "provider_control_number_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[provider_control_number" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td98.appendChild(textField)
                row1.appendChild(td98);
            }

            var td5 = document.createElement("TD")
            td5.setAttribute('id', "td_units_" + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            units = document.getElementById('units_id').value
            textField.setAttribute('value', units)
            textField.setAttribute('style','width:20px')
            textField.className = "contbox validate-quantity"
            textField.setAttribute('id', "units_" + serviceLineId)
            textField.setAttribute('name', "lineinformation[units" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td5.appendChild(textField)
            row1.appendChild(td5);

            if(!($F('hide_modifiers') == "true")) {
                var td4 = document.createElement("TD")
                td4.setAttribute('id', "td_service_modifier1_id" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                modifier = document.getElementById('modifier_id1').value
                textField.setAttribute('value', modifier)
                textField.setAttribute('style','width:15px')
                textField.className = "modibox"
                textField.setAttribute('id', "service_modifier1_id" + serviceLineId)
                textField.setAttribute('name', "lineinformation[modifier1" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td4.appendChild(textField)
                row1.appendChild(td4);

                var td_modifier2 = document.createElement("TD")
                td_modifier2.setAttribute('id', "td_service_modifier2_id" + serviceLineId)
                textField1 = document.createElement('INPUT')
                textField1.type = 'text'
                modifier1 = document.getElementById('modifier_id2').value
                textField1.setAttribute('value', modifier1)
                textField1.setAttribute('style','width:15px')
                textField1.className = "modibox"
                textField1.setAttribute('id', "service_modifier2_id" + serviceLineId)
                textField1.setAttribute('name', "lineinformation[modifier2" + serviceLineId + "]")
                textField1.setAttribute('readOnly', true)
                td_modifier2.appendChild(textField1)
                row1.appendChild(td_modifier2);

                var td_modifier3 = document.createElement("TD")
                td_modifier3.setAttribute('id', "td_service_modifier3_id" + serviceLineId)
                textField2 = document.createElement('INPUT')
                textField2.type = 'text'
                modifier2 = document.getElementById('modifier_id3').value
                textField2.setAttribute('value', modifier2)
                textField2.setAttribute('style','width:15px')
                textField2.className = "modibox"
                textField2.setAttribute('id', "service_modifier3_id" + serviceLineId)
                textField2.setAttribute('name', "lineinformation[modifier3" + serviceLineId + "]")
                textField2.setAttribute('readOnly', true)
                td_modifier3.appendChild(textField2)
                row1.appendChild(td_modifier3);

                var td_modifier4 = document.createElement("TD")
                td_modifier4.setAttribute('id', "td_service_modifier4_id" + serviceLineId)
                textField3 = document.createElement('INPUT')
                textField3.type = 'text'
                modifier3 = document.getElementById('modifier_id4').value
                textField3.setAttribute('value', modifier3)
                textField3.setAttribute('style','width:15px')
                textField3.className = "modibox"
                textField3.setAttribute('id', "service_modifier4_id" + serviceLineId)
                textField3.setAttribute('name', "lineinformation[modifier4" + serviceLineId + "]")
                textField3.setAttribute('readOnly', true)
                td_modifier4.appendChild(textField3)
                row1.appendChild(td_modifier4);

            }

            if ($F('service_tooth_number_status') == "true" && $F('insurance_grid') == "true"){
                var td97 = document.createElement("TD")
                td97.setAttribute('id', "td_tooth_number_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                tooth_number = $F('tooth_number')
                textField.setAttribute('value', tooth_number)
                textField.setAttribute('size','8')
                textField.className = "fullwidth"
                textField.setAttribute('class'," validate-tooth-number");
                textField.setAttribute('id', "tooth_number_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[tooth_number" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td97.appendChild(textField)
                row1.appendChild(td97);
            }

            if ($F('payment_status_code_status') == "true"){
                var td98 = document.createElement("TD")
                td98.setAttribute('id', "td_payment_status_code_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                paymentStatusCode = $F('payment_status_code_id')
                textField.setAttribute('value', paymentStatusCode)
                textField.setAttribute('size','8')
                textField.className = "fullwidth"
                textField.setAttribute('id', "payment_status_code_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[payment_status_code" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td98.appendChild(textField)
                row1.appendChild(td98);
            }

            if ($F('remark_code_status') == "true"){
                var td98 = document.createElement("TD")
                td98.setAttribute('id', "td_remark_code_" + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                remarkcode = $F('remark_code')
                textField.setAttribute('value', remarkcode)
                textField.setAttribute('size','8')
                textField.setAttribute('style','width:58px')
                textField.className = "fullwidth"
                textField.setAttribute('id', "remark_code_" + serviceLineId)
                textField.setAttribute('name', "lineinformation[remark_code" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td98.appendChild(textField)
                row1.appendChild(td98);
            }

            var td6 = document.createElement("TD")
            td6.setAttribute('id', 'td_charge_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            charges = document.getElementById('charges_id').value
            if (charges == '')
                textField.setAttribute('value', '0.00')
            else
                textField.setAttribute('value', parseFloat(charges).toFixed(2))
            textField.setAttribute('id', 'charge_amount_' + serviceLineId)
            char_array.push(count)
            textField.setAttribute('style','width:47px')
            textField.className = "amount"
            textField.setAttribute('name', "lineinformation[charges" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td6.appendChild(textField)
            row1.appendChild(td6);

            if($F('pbid_status') == "true") {
                td9 = document.createElement("TD")
                td9.setAttribute('id', 'td_pbid_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                pbid = $F('pbid_id')
                if (pbid == '')
                    textField.setAttribute('value', '0.00')
                else
                    textField.setAttribute('value', parseFloat(pbid).toFixed(2))
                textField.setAttribute('id', 'pbid_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount"
                textField.setAttribute('name', "lineinformation[pbid" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td9.appendChild(textField)
                row1.appendChild(td9);
            }

            var td9 = document.createElement("TD")
            td9.setAttribute('id', 'td_allowable_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            allowable = document.getElementById('allowable_id').value
            if (allowable == '')
                textField.setAttribute('value', '0.00')
            else
                textField.setAttribute('value', parseFloat(allowable).toFixed(2))
            textField.setAttribute('id', 'allowable_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount"
            textField.setAttribute('name', "lineinformation[allowable" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td9.appendChild(textField)
            row1.appendChild(td9);

            if($F('plan_coverage_status') == "true") {
                td9 = document.createElement("TD")
                td9.setAttribute('id', 'td_plan_coverage_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                planCoverage = $F('plan_coverage_id')
                textField.setAttribute('value', planCoverage)
                textField.setAttribute('id', 'plan_coverage_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount"
                textField.setAttribute('name', "lineinformation[plan_coverage" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td9.appendChild(textField)
                row1.appendChild(td9);
            }

            if($F('drg_amount_status') == "true") {
                td9 = document.createElement("TD")
                td9.setAttribute('id', 'td_drg_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                drgAmount = $F('drg_amount_id')
                if (drgAmount == '')
                    textField.setAttribute('value', '0.00')
                else
                    textField.setAttribute('value', parseFloat(drgAmount).toFixed(2))
                textField.setAttribute('id', 'drg_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount"
                textField.setAttribute('name', "lineinformation[drg_amount" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td9.appendChild(textField)
                row1.appendChild(td9);
            }

            if($F('expected_payment_status') == "true"){
                var td9 = document.createElement("TD")
                td9.setAttribute('id', 'td_expected_payment_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                expected_payment = document.getElementById('expected_payment_id').value
                if (expected_payment == ''){
                    textField.setAttribute('value', '0.00')
                }
                else
                    textField.setAttribute('value', parseFloat(expected_payment).toFixed(2))
                textField.setAttribute('id', 'expected_payment_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount"
                textField.setAttribute('name', "lineinformation[expected_payment" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td9.appendChild(textField)
                row1.appendChild(td9);
            }
            if($F('retention_fees_status') == "true") {
                td9 = document.createElement("TD")
                td9.setAttribute('id', 'td_retention_fee_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                retentionFee = $F('retention_fees_id')
                if (retentionFee == '')
                    textField.setAttribute('value', '0.00')
                else
                    textField.setAttribute('value', parseFloat(retentionFee).toFixed(2))
                textField.setAttribute('id', 'retention_fee_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount"
                textField.setAttribute('name', "lineinformation[retention_fees" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td9.appendChild(textField)
                row1.appendChild(td9);
            }

            var td13 = document.createElement("TD")
            td13.setAttribute('id', 'td_payment_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            payment = document.getElementById('payment_id').value
            if (payment == '')
                textField.setAttribute('value', '0.00')
            else
                textField.setAttribute('value', parseFloat(payment).toFixed(2))
            textField.setAttribute('id', 'payment_amount_' + serviceLineId)
            textField.setAttribute('style','width:45px')
            textField.className = "amount"
            textField.setAttribute('name', "lineinformation[payment" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td13.appendChild(textField)
            if ($F('patient_type_status') == "true" && $F('payment_code_status') == "true" && $('allowance_code_id') != null && $('capitation_code_id') != null){
                patient_type = $F('patient_type_id');
                if (patient_type == 'INPATIENT'){
                    title_allow = " Inpatient Allowance Code";
                    title_cap = " Inpatient Capitation Code";
                    checkbox_allow_id = "ippayment";
                    checkbox_cap_id = "ipcapitation";
                }
                else if (patient_type == 'OUTPATIENT'){
                    title_allow = " Outpatient Allowance Code";
                    title_cap = " Outpatient Capitation Code";
                    checkbox_allow_id = "opallowance";
                    checkbox_cap_id = "opcapitation";
                }
                //inpatient allowance code
                checkbox_allowance_code = document.createElement('INPUT');
                checkbox_allowance_code.type = "checkbox";
                check_value_allowance_code = $('allowance_code_id').checked;
                checkbox_allowance_code.setAttribute('name', "lineinformation[allowance_code" + serviceLineId + "]");
                checkbox_allowance_code.setAttribute('id', checkbox_allow_id + serviceLineId);
                checkbox_allowance_code.setAttribute("title",title_allow);
                if(check_value_allowance_code == true)
                {
                    checkbox_allowance_code.defaultChecked = true
                    checkbox_allowance_code.setAttribute('value', 'on')
                }
                //inpatient capitation code
                checkbox_capitation_code = document.createElement('INPUT')
                checkbox_capitation_code.type = "checkbox"
                check_value_capitation_code = $('capitation_code_id').checked;
                checkbox_capitation_code.setAttribute('name', "lineinformation[capitation_code" + serviceLineId + "]")
                checkbox_capitation_code.setAttribute('id', checkbox_cap_id + serviceLineId)
                checkbox_capitation_code.setAttribute('title',title_cap)
                if(check_value_capitation_code == true)
                {
                    checkbox_capitation_code.defaultChecked = true
                    checkbox_capitation_code.setAttribute('value', 'on')
                }

                td13.appendChild(checkbox_allowance_code)
                td13.appendChild(checkbox_capitation_code)


            }
            row1.appendChild(td13);

            var td7 = document.createElement("TD")
            td7.setAttribute('id', 'td_noncovered_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            noncovered = document.getElementById('non_covered_id').value
            if (noncovered == '')
                textField.setAttribute('value', '')
            else
                textField.setAttribute('value', parseFloat(noncovered).toFixed(2))
            textField.setAttribute('id', 'noncovered_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount validate-presence-of-unique-code"
            textField.setAttribute('name', "lineinformation[non_covered" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td7.appendChild(textField)
            row1.appendChild(td7);

            unique_code_td = document.createElement("TD")
            unique_code_td.setAttribute('id', 'td_reason_code_noncovered' + serviceLineId + '_unique_code')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            textField.setAttribute('id', 'reason_code_noncovered' + serviceLineId + '_unique_code')
            textField.setAttribute('name', "reason_code[noncovered" + serviceLineId + "][unique_code]")
            textField.setAttribute('value', $F('reason_code_noncovered_unique_code'))
            textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
            textField.setAttribute('size','6')
            textField.setAttribute('readOnly', true)
            unique_code_td.appendChild(textField)
            row1.appendChild(unique_code_td);

            reasonCodeIdElement = document.createElement('INPUT')
            reasonCodeIdElement.type = 'hidden'
            reasonCodeIdElement.setAttribute('id', 'reason_code_id_noncovered' + serviceLineId)
            reasonCodeIdElement.setAttribute('name', "reason_code_id[noncovered" + serviceLineId + "]")
            reasonCodeIdElement.setAttribute('value', $F('reason_code_id_noncovered'))
            reasonCodeIdElement.setAttribute('readOnly', true)
            row1.appendChild(reasonCodeIdElement);
            $('reason_code_id_noncovered').value = "";

            if($F('denied_status') == "true"){
                var td81 = document.createElement("TD")
                td81.setAttribute('id', 'td_denied_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                denied = document.getElementById('denied_id').value
                if (denied == '')
                    textField.setAttribute('value', '')
                else
                    textField.setAttribute('value', parseFloat(denied).toFixed(2))
                textField.setAttribute('id', 'denied_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[denied" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td81.appendChild(textField);
                row1.appendChild(td81);

                unique_code_td = document.createElement("TD")
                unique_code_td.setAttribute('id', 'td_reason_code_denied' + serviceLineId + '_unique_code')
                textField = document.createElement('INPUT')
                textField.type = 'text'
                textField.setAttribute('id', 'reason_code_denied' + serviceLineId + '_unique_code')
                textField.setAttribute('name', "reason_code[denied" + serviceLineId + "][unique_code]")
                textField.setAttribute('value', $F('reason_code_denied_unique_code'))
                textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
                textField.setAttribute('size','6')
                textField.setAttribute('readOnly', true)
                unique_code_td.appendChild(textField)
                row1.appendChild(unique_code_td);

                reasonCodeIdElement = document.createElement('INPUT')
                reasonCodeIdElement.type = 'hidden'
                reasonCodeIdElement.setAttribute('id', 'reason_code_id_denied' + serviceLineId)
                reasonCodeIdElement.setAttribute('name', "reason_code_id[denied" + serviceLineId + "]")
                reasonCodeIdElement.setAttribute('value', $F('reason_code_id_denied'))
                reasonCodeIdElement.setAttribute('readOnly', true)
                row1.appendChild(reasonCodeIdElement);
                $('reason_code_id_denied').value = "";
            }

            var td8 = document.createElement("TD")
            td8.setAttribute('id', 'td_discount_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            discount = document.getElementById('discount_id').value
            if (discount == '')
                textField.setAttribute('value', '')
            else
                textField.setAttribute('value', parseFloat(discount).toFixed(2))
            textField.setAttribute('id', 'discount_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount validate-presence-of-unique-code"
            textField.setAttribute('name', "lineinformation[discount" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td8.appendChild(textField);
            row1.appendChild(td8);

            unique_code_td = document.createElement("TD")
            unique_code_td.setAttribute('id', 'td_reason_code_discount' + serviceLineId + '_unique_code')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            textField.setAttribute('id', 'reason_code_discount' + serviceLineId + '_unique_code')
            textField.setAttribute('name', "reason_code[discount" + serviceLineId + "][unique_code]")
            textField.setAttribute('value', $F('reason_code_discount_unique_code'))
            textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
            textField.setAttribute('size','6')
            textField.setAttribute('readOnly', true)
            unique_code_td.appendChild(textField)
            row1.appendChild(unique_code_td);

            reasonCodeIdElement = document.createElement('INPUT')
            reasonCodeIdElement.type = 'hidden'
            reasonCodeIdElement.setAttribute('id', 'reason_code_id_discount' + serviceLineId)
            reasonCodeIdElement.setAttribute('name', "reason_code_id[discount" + serviceLineId + "]")
            reasonCodeIdElement.setAttribute('value', $F('reason_code_id_discount'))
            reasonCodeIdElement.setAttribute('readOnly', true)
            row1.appendChild(reasonCodeIdElement);
            $('reason_code_id_discount').value = "";

            var td10 = document.createElement("TD")
            td10.setAttribute('id', 'td_coinsurance_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            coinsurance = document.getElementById('co_insurance_id').value
            if (coinsurance == '')
                textField.setAttribute('value', '')
            else
                textField.setAttribute('value', parseFloat(coinsurance).toFixed(2))
            textField.setAttribute('id', 'coinsurance_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount validate-presence-of-unique-code"
            textField.setAttribute('name', "lineinformation[co_insurance_id" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td10.appendChild(textField)
            row1.appendChild(td10);

            unique_code_td = document.createElement("TD")
            unique_code_td.setAttribute('id', 'td_reason_code_coinsurance' + serviceLineId + '_unique_code')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            textField.setAttribute('id', 'reason_code_coinsurance' + serviceLineId + '_unique_code')
            textField.setAttribute('name', "reason_code[coinsurance" + serviceLineId + "][unique_code]")
            textField.setAttribute('value', $F('reason_code_coinsurance_unique_code'))
            textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
            textField.setAttribute('size','6')
            textField.setAttribute('readOnly', true)
            unique_code_td.appendChild(textField)
            row1.appendChild(unique_code_td);

            reasonCodeIdElement = document.createElement('INPUT')
            reasonCodeIdElement.type = 'hidden'
            reasonCodeIdElement.setAttribute('id', 'reason_code_id_coinsurance' + serviceLineId)
            reasonCodeIdElement.setAttribute('name', "reason_code_id[coinsurance" + serviceLineId + "]")
            reasonCodeIdElement.setAttribute('value', $F('reason_code_id_coinsurance'))
            reasonCodeIdElement.setAttribute('readOnly', true)
            row1.appendChild(reasonCodeIdElement);
            $('reason_code_id_coinsurance').value = "";

            var td11 = document.createElement("TD")
            td11.setAttribute('id', 'td_deductible_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            deductable = document.getElementById('deductable_id').value
            if (deductable == '')
                textField.setAttribute('value', '')
            else
                textField.setAttribute('value', parseFloat(deductable).toFixed(2))
            textField.setAttribute('id', 'deductible_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount validate-presence-of-unique-code"
            textField.setAttribute('name', "lineinformation[deductable" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td11.appendChild(textField)
            row1.appendChild(td11);

            unique_code_td = document.createElement("TD")
            unique_code_td.setAttribute('id', 'td_reason_code_deductible' + serviceLineId + '_unique_code')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            textField.setAttribute('id', 'reason_code_deductible' + serviceLineId + '_unique_code')
            textField.setAttribute('name', "reason_code[deductible" + serviceLineId + "][unique_code]")
            textField.setAttribute('value', $F('reason_code_deductible_unique_code'))
            textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
            textField.setAttribute('size','6')
            textField.setAttribute('readOnly', true)
            unique_code_td.appendChild(textField)
            row1.appendChild(unique_code_td);

            reasonCodeIdElement = document.createElement('INPUT')
            reasonCodeIdElement.type = 'hidden'
            reasonCodeIdElement.setAttribute('id', 'reason_code_id_deductible' + serviceLineId)
            reasonCodeIdElement.setAttribute('name', "reason_code_id[deductible" + serviceLineId + "]")
            reasonCodeIdElement.setAttribute('value', $F('reason_code_id_deductible'))
            reasonCodeIdElement.setAttribute('readOnly', true)
            row1.appendChild(reasonCodeIdElement);
            $('reason_code_id_deductible').value = "";

            var td12 = document.createElement("TD")
            td12.setAttribute('id', 'td_copay_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            copay = document.getElementById('copay_id').value
            if (copay == '')
                textField.setAttribute('value', '')
            else
                textField.setAttribute('value', parseFloat(copay).toFixed(2))
            textField.setAttribute('id', 'copay_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount validate-presence-of-unique-code"
            textField.setAttribute('name', "lineinformation[copay" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td12.appendChild(textField)
            row1.appendChild(td12);

            unique_code_td = document.createElement("TD")
            unique_code_td.setAttribute('id', 'td_reason_code_copay' + serviceLineId + '_unique_code')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            textField.setAttribute('id', 'reason_code_copay' + serviceLineId + '_unique_code')
            textField.setAttribute('name', "reason_code[copay" + serviceLineId + "][unique_code]")
            textField.setAttribute('value', $F('reason_code_copay_unique_code'))
            textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
            textField.setAttribute('size','6')
            textField.setAttribute('readOnly', true)
            unique_code_td.appendChild(textField)
            row1.appendChild(unique_code_td);

            reasonCodeIdElement = document.createElement('INPUT')
            reasonCodeIdElement.type = 'hidden'
            reasonCodeIdElement.setAttribute('id', 'reason_code_id_copay' + serviceLineId)
            reasonCodeIdElement.setAttribute('name', "reason_code_id[copay" + serviceLineId + "]")
            reasonCodeIdElement.setAttribute('value', $F('reason_code_id_copay'))
            reasonCodeIdElement.setAttribute('readOnly', true)
            row1.appendChild(reasonCodeIdElement);
            $('reason_code_id_copay').value = "";

            if($F('patient_responsibility_status') == "true"){
                var td90 = document.createElement("TD")
                td90.setAttribute('id', 'td_patient_responsibility_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                patient_responsibility = document.getElementById('patient_responsibility_id').value
                if (patient_responsibility == '')
                    textField.setAttribute('value', '')
                else
                    textField.setAttribute('value', parseFloat(patient_responsibility).toFixed(2))
                textField.setAttribute('id', 'patient_responsibility_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[patient_responsibility" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td90.appendChild(textField);
                row1.appendChild(td90);

                unique_code_td = document.createElement("TD")
                unique_code_td.setAttribute('id', 'td_reason_code_patient_responsibility' + serviceLineId + '_unique_code')
                textField = document.createElement('INPUT')
                textField.type = 'text'
                textField.setAttribute('id', 'reason_code_patient_responsibility' + serviceLineId + '_unique_code')
                textField.setAttribute('name', "reason_code[patient_responsibility" + serviceLineId + "][unique_code]")
                textField.setAttribute('value', $F('reason_code_patient_responsibility_unique_code'))
                textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
                textField.setAttribute('size','6')
                textField.setAttribute('readOnly', true)
                unique_code_td.appendChild(textField)
                row1.appendChild(unique_code_td);

                reasonCodeIdElement = document.createElement('INPUT')
                reasonCodeIdElement.type = 'hidden'
                reasonCodeIdElement.setAttribute('id', 'reason_code_id_patient_responsibility' + serviceLineId)
                reasonCodeIdElement.setAttribute('name', "reason_code_id[patient_responsibility" + serviceLineId + "]")
                reasonCodeIdElement.setAttribute('value', $F('reason_code_id_patient_responsibility'))
                reasonCodeIdElement.setAttribute('readOnly', true)
                row1.appendChild(reasonCodeIdElement);
                $('reason_code_id_patient_responsibility').value = "";
            }

            var td14 = document.createElement("TD")
            td14.setAttribute('id', 'td_primary_payment_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            primary_pay_payment = document.getElementById('primary_pay_payment_id').value
            if (primary_pay_payment == '')
                textField.setAttribute('value', '')
            else
                textField.setAttribute('value', parseFloat(primary_pay_payment).toFixed(2))
            textField.setAttribute('id', 'primary_payment_amount_' + serviceLineId)
            textField.setAttribute('style','width:47px')
            textField.className = "amount validate-presence-of-unique-code"
            textField.setAttribute('name', "lineinformation[primary_pay_payment" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td14.appendChild(textField)
            row1.appendChild(td14);

            unique_code_td = document.createElement("TD")
            unique_code_td.setAttribute('id', 'td_reason_code_primary_payment' + serviceLineId + '_unique_code')
            textField = document.createElement('INPUT')
            textField.type = 'text'
            textField.setAttribute('id', 'reason_code_primary_payment' + serviceLineId + '_unique_code')
            textField.setAttribute('name', "reason_code[primary_payment" + serviceLineId + "][unique_code]")
            textField.setAttribute('value', $F('reason_code_primary_payment_unique_code'))
            textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
            textField.setAttribute('size','6')
            textField.setAttribute('readOnly', true)
            unique_code_td.appendChild(textField)
            row1.appendChild(unique_code_td);

            reasonCodeIdElement = document.createElement('INPUT')
            reasonCodeIdElement.type = 'hidden'
            reasonCodeIdElement.setAttribute('id', 'reason_code_id_primary_payment' + serviceLineId)
            reasonCodeIdElement.setAttribute('name', "reason_code_id[primary_payment" + serviceLineId + "]")
            reasonCodeIdElement.setAttribute('value', $F('reason_code_id_primary_payment'))
            reasonCodeIdElement.setAttribute('readOnly', true)
            row1.appendChild(reasonCodeIdElement);
            $('reason_code_id_primary_payment').value = "";

            if($F('prepaid_status') == "true"){
                var td90 = document.createElement("TD")
                td90.setAttribute('id', 'td_prepaid_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                prepaid = document.getElementById('prepaid_id').value
                if (prepaid == '')
                    textField.setAttribute('value', '')
                else
                    textField.setAttribute('value', parseFloat(prepaid).toFixed(2))
                textField.setAttribute('id', 'prepaid_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[prepaid" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td90.appendChild(textField);
                row1.appendChild(td90);

                unique_code_td = document.createElement("TD")
                unique_code_td.setAttribute('id', 'td_reason_code_prepaid' + serviceLineId + '_unique_code')
                textField = document.createElement('INPUT')
                textField.type = 'text'
                textField.setAttribute('id', 'reason_code_prepaid' + serviceLineId + '_unique_code')
                textField.setAttribute('name', "reason_code[prepaid" + serviceLineId + "][unique_code]")
                textField.setAttribute('value', $F('reason_code_prepaid_unique_code'))
                textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
                textField.setAttribute('size','6')
                textField.setAttribute('readOnly', true)
                unique_code_td.appendChild(textField)
                row1.appendChild(unique_code_td);

                reasonCodeIdElement = document.createElement('INPUT')
                reasonCodeIdElement.type = 'hidden'
                reasonCodeIdElement.setAttribute('id', 'reason_code_id_prepaid' + serviceLineId)
                reasonCodeIdElement.setAttribute('name', "reason_code_id[prepaid" + serviceLineId + "]")
                reasonCodeIdElement.setAttribute('value', $F('reason_code_id_prepaid'))
                reasonCodeIdElement.setAttribute('readOnly', true)
                row1.appendChild(reasonCodeIdElement);
                $('reason_code_id_prepaid').value = "";
            }

            if($('contractualamount_id')) {
                var td89 = document.createElement("TD")
                td89.setAttribute('id', 'td_contractual_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                contractual = document.getElementById('contractualamount_id').value
                if (contractual == '')
                    textField.setAttribute('value','')
                else
                    textField.setAttribute('value', parseFloat(contractual).toFixed(2))
                textField.setAttribute('id', 'contractual_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[contractual" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td89.appendChild(textField)
                row1.appendChild(td89);

                unique_code_td = document.createElement("TD")
                unique_code_td.setAttribute('id', 'td_reason_code_contractual' + serviceLineId + '_unique_code')
                textField = document.createElement('INPUT')
                textField.type = 'text'
                textField.setAttribute('id', 'reason_code_contractual' + serviceLineId + '_unique_code')
                textField.setAttribute('name', "reason_code[contractual" + serviceLineId + "][unique_code]")
                textField.setAttribute('value', $F('reason_code_contractual_unique_code'))
                textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
                textField.setAttribute('size','6')
                textField.setAttribute('readOnly', true)
                unique_code_td.appendChild(textField)
                row1.appendChild(unique_code_td);

                reasonCodeIdElement = document.createElement('INPUT')
                reasonCodeIdElement.type = 'hidden'
                reasonCodeIdElement.setAttribute('id', 'reason_code_id_contractual' + serviceLineId)
                reasonCodeIdElement.setAttribute('name', "reason_code_id[contractual" + serviceLineId + "]")
                reasonCodeIdElement.setAttribute('value', $F('reason_code_id_contractual'))
                reasonCodeIdElement.setAttribute('readOnly', true)
                row1.appendChild(reasonCodeIdElement);
                $('reason_code_id_contractual').value = "";
            }

            if($('miscellaneous_one_id')) {
                td81 = document.createElement("TD")
                td81.setAttribute('id', 'td_miscellaneous_one_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                var miscellaneousOne = $F('miscellaneous_one_id')
                if (miscellaneousOne == '')
                    textField.setAttribute('value', '')
                else
                    textField.setAttribute('value', parseFloat(miscellaneousOne).toFixed(2))
                textField.setAttribute('id', 'miscellaneous_one_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[miscellaneous_one" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td81.appendChild(textField);
                row1.appendChild(td81);

                unique_code_td = document.createElement("TD")
                unique_code_td.setAttribute('id', 'td_reason_code_miscellaneous_one' + serviceLineId + '_unique_code')
                textField = document.createElement('INPUT')
                textField.type = 'text'
                textField.setAttribute('id', 'reason_code_miscellaneous_one' + serviceLineId + '_unique_code')
                textField.setAttribute('name', "reason_code[miscellaneous_one" + serviceLineId + "][unique_code]")
                textField.setAttribute('value', $F('reason_code_miscellaneous_one_unique_code'))
                textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
                textField.setAttribute('size','6')
                textField.setAttribute('readOnly', true)
                unique_code_td.appendChild(textField)
                row1.appendChild(unique_code_td);

                reasonCodeIdElement = document.createElement('INPUT')
                reasonCodeIdElement.type = 'hidden'
                reasonCodeIdElement.setAttribute('id', 'reason_code_id_miscellaneous_one' + serviceLineId)
                reasonCodeIdElement.setAttribute('name', "reason_code_id[miscellaneous_one" + serviceLineId + "]")
                reasonCodeIdElement.setAttribute('value', $F('reason_code_id_miscellaneous_one'))
                reasonCodeIdElement.setAttribute('readOnly', true)
                row1.appendChild(reasonCodeIdElement);
                $('reason_code_id_miscellaneous_one').value = "";
            }

            if($('miscellaneous_two_id')) {
                td81 = document.createElement("TD")
                td81.setAttribute('id', 'td_miscellaneous_two_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                var miscellaneousTwo = $F('miscellaneous_two_id')
                if (miscellaneousTwo == '')
                    textField.setAttribute('value', '')
                else
                    textField.setAttribute('value', parseFloat(miscellaneousTwo).toFixed(2))
                textField.setAttribute('id', 'miscellaneous_two_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[miscellaneous_two" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td81.appendChild(textField);
                row1.appendChild(td81);

                unique_code_td = document.createElement("TD")
                unique_code_td.setAttribute('id', 'td_reason_code_miscellaneous_two' + serviceLineId + '_unique_code')
                textField = document.createElement('INPUT')
                textField.type = 'text'
                textField.setAttribute('id', 'reason_code_miscellaneous_two' + serviceLineId + '_unique_code')
                textField.setAttribute('name', "reason_code[miscellaneous_two" + serviceLineId + "][unique_code]")
                textField.setAttribute('value', $F('reason_code_miscellaneous_two_unique_code'))
                textField.className = "validate-unique-code validate-presence-of-adjustment-amount-in-added-row"
                textField.setAttribute('size','6')
                textField.setAttribute('readOnly', true)
                unique_code_td.appendChild(textField)
                row1.appendChild(unique_code_td);

                reasonCodeIdElement = document.createElement('INPUT')
                reasonCodeIdElement.type = 'hidden'
                reasonCodeIdElement.setAttribute('id', 'reason_code_id_miscellaneous_two' + serviceLineId)
                reasonCodeIdElement.setAttribute('name', "reason_code_id[miscellaneous_two" + serviceLineId + "]")
                reasonCodeIdElement.setAttribute('value', $F('reason_code_id_miscellaneous_two'))
                reasonCodeIdElement.setAttribute('readOnly', true)
                row1.appendChild(reasonCodeIdElement);
                $('reason_code_id_miscellaneous_two').value = "";
            }
            
            if($('miscellaneous_balance_id')) {
                td81 = document.createElement("TD")
                td81.setAttribute('id', 'td_miscellaneous_balance_amount_' + serviceLineId)
                textField = document.createElement('INPUT')
                textField.type = 'text'
                var miscellaneousBalance = $F('miscellaneous_balance_id')
                if (miscellaneousBalance == '')
                    textField.setAttribute('value', '')
                else
                    textField.setAttribute('value', parseFloat(miscellaneousBalance).toFixed(2))
                textField.setAttribute('id', 'miscellaneous_balance_amount_' + serviceLineId)
                textField.setAttribute('style','width:47px')
                textField.className = "amount validate-presence-of-unique-code"
                textField.setAttribute('name', "lineinformation[miscellaneous_balance" + serviceLineId + "]")
                textField.setAttribute('readOnly', true)
                td81.appendChild(textField);
                row1.appendChild(td81);
            }

            var td16 = document.createElement("TD")
            td16.setAttribute('id', 'td_balance_amount_' + serviceLineId)
            textField = document.createElement('INPUT')
            textField.type = 'text'
            balance = document.getElementById('balance_id').value
            if (balance == '')
                textField.setAttribute('value', '0.00')
            else
                textField.setAttribute('value', parseFloat(balance).toFixed(2))
            textField.setAttribute('id', 'balance_amount_' + serviceLineId)
            textField.setAttribute('width', '47px')
            textField.setAttribute('text-align', 'right')
            textField.className = "amount"
            textField.setAttribute('name', "lineinformation[balance" + serviceLineId + "]")
            textField.setAttribute('readOnly', true)
            td16.appendChild(textField)
            row1.appendChild(td16);
            var td17 = document.createElement("TD")
            td17.setAttribute('id', 'td_add_or_delete_' + serviceLineId)
            var buttonnode = document.createElement('input');
            buttonnode.setAttribute('type', 'checkbox');
            buttonnode.setAttribute('id', 'sal' + serviceLineId);
            buttonnode.setAttribute('value', serviceLineId);
            buttonnode.onclick = function(){
                removeServiceLineAdded(this.value, "service_line_details");
            }
            td17.appendChild(buttonnode)
            row1.appendChild(td17);
            tbody.appendChild(row1);

            var line_count = +($F('total_svc_line_count') )
            $('total_svc_line_count').value = line_count + 1;

            if ($F('total_charge_id')!=""){
                var total_pr_charge=$F('total_charge_id').trim();
            }
            else
                var total_pr_charge = 0;
            if ($F('charges_id')!=""){
                var p_charge = $F('charges_id').trim();
            }
            else
                var p_charge = 0;
            var total_procedure_charge = parseFloat(total_pr_charge);
            var procedure_charge = parseFloat(p_charge);
            total_procedure_charge+= procedure_charge
            $('total_charge_id').value =(total_procedure_charge.toFixed(2));
            //Non covered charge
            if ($F('total_non_covered_id')!=""){
                var total_non_charge=$F('total_non_covered_id').trim();
            }
            else
                var total_non_charge = 0;
            if ($F('non_covered_id')!="")
                var non_charge = $F('non_covered_id').trim();
            else
                var non_charge = 0;
            var total_non_covered_charge = parseFloat(total_non_charge);
            var non_covered_charge = parseFloat(non_charge);
            total_non_covered_charge+= non_covered_charge
            $('total_non_covered_id').value =(total_non_covered_charge.toFixed(2));

            //Denied charge

            if($F('denied_status') == "true"){
                if ($F('total_denied_id')!=""){
                    var total_denied_charge=$F('total_denied_id').trim();
                }
                else
                    total_denied_charge = 0;
                if ($F('denied_id')!="")
                    var denied_charge = $F('denied_id').trim();
                else
                    denied_charge = 0;
                var total_denied_charge_display = parseFloat(total_denied_charge);
                var denied_charge_display = parseFloat(denied_charge);
                total_denied_charge_display+= denied_charge_display
                $('total_denied_id').value =(total_denied_charge_display.toFixed(2));
            }

            //Miscellaneous Adjustment Fields

            if($F('miscellaneous_one_status') == "true"){
                if ($F('total_miscellaneous_one_id')!=""){
                    var total_miscellaneous_one_charge = $F('total_miscellaneous_one_id').trim();
                }
                else
                    total_miscellaneous_one_charge = 0;
                if ($F('miscellaneous_one_id')!="")
                    var miscellaneous_one_charge = $F('miscellaneous_one_id').trim();
                else
                    miscellaneous_one_charge = 0;
                var total_miscellaneous_one_charge_display = parseFloat(total_miscellaneous_one_charge);
                var miscellaneous_one_charge_display = parseFloat(miscellaneous_one_charge);
                total_miscellaneous_one_charge_display+= miscellaneous_one_charge_display
                $('total_miscellaneous_one_id').value =(total_miscellaneous_one_charge_display.toFixed(2));
            }

            if($F('miscellaneous_two_status') == "true"){
                if ($F('total_miscellaneous_two_id')!=""){
                    var total_miscellaneous_two_charge = $F('total_miscellaneous_two_id').trim();
                }
                else
                    total_miscellaneous_two_charge = 0;
                if ($F('miscellaneous_two_id')!="")
                    var miscellaneous_two_charge = $F('miscellaneous_two_id').trim();
                else
                    miscellaneous_two_charge = 0;
                var total_miscellaneous_two_charge_display = parseFloat(total_miscellaneous_two_charge);
                var miscellaneous_two_charge_display = parseFloat(miscellaneous_two_charge);
                total_miscellaneous_two_charge_display+= miscellaneous_two_charge_display
                $('total_miscellaneous_two_id').value =(total_miscellaneous_two_charge_display.toFixed(2));
            }

            if($F('miscellaneous_balance_status') == "true"){
                if ($F('total_miscellaneous_balance_id')!=""){
                    var total_miscellaneous_balance_charge = $F('total_miscellaneous_balance_id').trim();
                }
                else
                    total_miscellaneous_balance_charge = 0;
                if ($F('miscellaneous_balance_id')!="")
                    var miscellaneous_balance_charge = $F('miscellaneous_balance_id').trim();
                else
                    miscellaneous_balance_charge = 0;
                var total_miscellaneous_balance_charge_display = parseFloat(total_miscellaneous_balance_charge);
                var miscellaneous_balance_charge_display = parseFloat(miscellaneous_balance_charge);
                total_miscellaneous_balance_charge_display+= miscellaneous_balance_charge_display
                $('total_miscellaneous_balance_id').value =(total_miscellaneous_balance_charge_display.toFixed(2));
            }

            //Discount charge

            if ($F('total_discount_id')!=""){
                var total_discount_charge=$F('total_discount_id').trim();
            }
            else
                var total_discount_charge = 0;
            if ($F('discount_id')!="")
                var discount_charge = $F('discount_id').trim();
            else
                var discount_charge = 0;
            var total_discount_charge_display = parseFloat(total_discount_charge);
            var discount_charge_display = parseFloat(discount_charge);
            total_discount_charge_display+= discount_charge_display
            $('total_discount_id').value =(total_discount_charge_display.toFixed(2));

            //allowable charge

            if ($F('total_allowable_id')!=""){
                var total_allowable_charge=$F('total_allowable_id').trim();
            }
            else
                var total_allowable_charge = 0;
            if ($F('allowable_id')!="")
                var allowable_charge = $F('allowable_id').trim();
            else
                var allowable_charge = 0;
            var total_allowable_charge_display = parseFloat(total_allowable_charge);
            var allowable_charge_display = parseFloat(allowable_charge);
            total_allowable_charge_display+= allowable_charge_display
            $('total_allowable_id').value =(total_allowable_charge_display.toFixed(2));

            //DRG Amount
            if($F('drg_amount_status') == "true") {
                var totalDrgAmount = 0;
                var drgAmount = 0;
                if ($F('total_drg_amount_id') != ""){
                    totalDrgAmount = $F('total_drg_amount_id').trim();
                }
                if ($F('drg_amount_id') != "")
                    drgAmount = $F('drg_amount_id').trim();
                var totalDrgAmountDisplay = parseFloat(totalDrgAmount);
                var drgAmountDisplay = parseFloat(drgAmount);
                totalDrgAmountDisplay += drgAmountDisplay;
                $('total_drg_amount_id').value =(totalDrgAmountDisplay.toFixed(2));
            }

            //PBID Amount
            if($F('pbid_status') == "true") {
                var totalPbid = 0;
                var pbid = 0;
                if ($F('total_pbid_id') != ""){
                    totalPbid = $F('total_pbid_id').trim();
                }
                if ($F('pbid_id') != "")
                    pbid = $F('pbid_id').trim();
                var totalPbidDisplay = parseFloat(totalPbid);
                var pbidDisplay = parseFloat(pbid);
                totalPbidDisplay += pbidDisplay;
                $('total_pbid_id').value =(totalPbidDisplay.toFixed(2));
            }

            //Retention Fees Amount
            if($F('retention_fees_status') == "true") {
                var totalRetentionFees = 0;
                var retentionFees = 0;
                if ($F('total_retention_fees_id') != ""){
                    totalRetentionFees = $F('total_retention_fees_id').trim();
                }
                if ($F('retention_fees_id') != "")
                    retentionFees = $F('retention_fees_id').trim();
                var totalRetentionFeesDisplay = parseFloat(totalRetentionFees);
                var retentionFeesDisplay = parseFloat(retentionFees);
                totalRetentionFeesDisplay += retentionFeesDisplay;
                $('total_retention_fees_id').value =(totalRetentionFeesDisplay.toFixed(2));
            }

            //expected_payment
            if($F('expected_payment_status') == "true"){
                if ($F('total_expected_payment_id')!=""){
                    var total_expected_payment=$F('total_expected_payment_id').trim();
                }
                else
                    var total_expected_payment = 0;
                if ($F('expected_payment_id')!="")
                    var expected_payment = $F('expected_payment_id').trim();
                else
                    var expected_payment = 0;
                var total_expected_payment_display = parseFloat(total_expected_payment);
                var expected_payment_display = parseFloat(expected_payment);
                total_expected_payment_display+= expected_payment_display
                $('total_expected_payment_id').value =(total_expected_payment_display.toFixed(2));
            }

            //contracual_amount
            if($F('contractualamount_status') == "true") {
                if ($('total_contractual_amount_id') && $F('total_contractual_amount_id')!=""){
                    var total_contractual_charge=$F('total_contractual_amount_id').trim();
                }
                else
                    var total_contractual_charge = 0;
                if ($('contractualamount_id') && $F('contractualamount_id')!="")
                    var contractual_charge = $F('contractualamount_id').trim();
                else
                    var contractual_charge = 0;
                var total_contractual_charge_display = parseFloat(total_contractual_charge);
                var contractual_charge_display = parseFloat(contractual_charge);
                total_contractual_charge_display+= contractual_charge_display
                $('total_contractual_amount_id').value =(total_contractual_charge_display.toFixed(2));
            }

            //Copay id
            if ($F('total_copay_id')!=""){
                var total_copay_charge=$F('total_copay_id').trim();
            }
            else
                var total_copay_charge = 0;
            if ($F('copay_id')!="")
                var copay_charge = $F('copay_id').trim();
            else
                var copay_charge =0;
            var total_copay_charge_display = parseFloat(total_copay_charge);
            var copay_charge_display = parseFloat(copay_charge);
            total_copay_charge_display+= copay_charge_display
            $('total_copay_id').value =(total_copay_charge_display.toFixed(2));

            //Deductable
            if ($F('total_deductable_id')!=""){
                var total_deductable_charge=$F('total_deductable_id').trim();
            }
            else
                var total_deductable_charge = 0;
            if ($F('deductable_id')!="")
                var deductable_charge = $F('deductable_id').trim();
            else
                var deductable_charge =0;
            var total_deductable_charge_display = parseFloat(total_deductable_charge);
            var deductable_charge_display = parseFloat(deductable_charge);
            total_deductable_charge_display+= deductable_charge_display
            $('total_deductable_id').value =(total_deductable_charge_display.toFixed(2));

            //Coinsurance

            if ($F('total_coinsurance_id')!=""){
                var total_coinsurance_charge=$F('total_coinsurance_id').trim();
            }
            else
                var total_coinsurance_charge = 0;
            if ($F('co_insurance_id')!="")
                var coinsurance_charge = $F('co_insurance_id').trim();
            else
                var coinsurance_charge =0;
            var total_coinsurance_charge_display = parseFloat(total_coinsurance_charge);
            var coinsurance_charge_display = parseFloat(coinsurance_charge);
            total_coinsurance_charge_display+= coinsurance_charge_display
            $('total_coinsurance_id').value =(total_coinsurance_charge_display.toFixed(2));

            //Payment

            if ($F('total_payment_id')!=""){
                var total_payment_charge=$F('total_payment_id').trim();
            }
            else
                var total_payment_charge = 0;
            if ($F('payment_id')!="")
                var payment_charge = $F('payment_id').trim();
            else
                var payment_charge =0;
            var total_payment_charge_display = parseFloat(total_payment_charge);
            var payment_charge_display = parseFloat(payment_charge);
            total_payment_charge_display+= payment_charge_display
            $('total_payment_id').value =(total_payment_charge_display.toFixed(2));

            //Primary payment

            if ($F('total_primary_payment_id')!=""){
                var total_primary_charge=$F('total_primary_payment_id').trim();
            }
            else
                var total_primary_charge = 0;
            if ($F('primary_pay_payment_id')!="")
                var primary_charge = $F('primary_pay_payment_id').trim();
            else
                var primary_charge =0;
            var total_primary_charge_display = parseFloat(total_primary_charge);
            var primary_charge_display = parseFloat(primary_charge);
            total_primary_charge_display+= primary_charge_display
            $('total_primary_payment_id').value =(total_primary_charge_display.toFixed(2));

            //Prepaid Amount
            if($F('prepaid_status') == "true") {
                var totalPrepaid = 0;
                var prepaid = 0;
                if ($F('total_prepaid_id') != ""){
                    totalPrepaid = $F('total_prepaid_id').trim();
                }
                if ($F('prepaid_id') != "")
                    prepaid = $F('prepaid_id').trim();
                var totalPrepaidDisplay = parseFloat(totalPrepaid);
                var prepaidDisplay = parseFloat(prepaid);
                totalPrepaidDisplay += prepaidDisplay;
                $('total_prepaid_id').value =(totalPrepaidDisplay.toFixed(2));
            }

            //Patient Responsibility Amount
            if($F('patient_responsibility_status') == "true") {
                var totalPatientResponsibility = 0;
                var patientResponsibility = 0;
                if ($F('total_patient_responsibility_id') != ""){
                    totalPatientResponsibility = $F('total_patient_responsibility_id').trim();
                }
                if ($F('patient_responsibility_id') != "")
                    patientResponsibility = $F('patient_responsibility_id').trim();
                var totalPatientResponsibilityDisplay = parseFloat(totalPatientResponsibility);
                var patientResponsibilityDisplay = parseFloat(patientResponsibility);
                totalPatientResponsibilityDisplay += patientResponsibilityDisplay;
                $('total_patient_responsibility_id').value =(totalPatientResponsibilityDisplay.toFixed(2));
            }

            // Balance

            if ($F('total_service_balance_id')!=""){
                var total_balance_charge=$F('total_service_balance_id').trim();
            }
            else
                var total_balance_charge = 0;
            if ($F('balance_id')!="")
                var balance_charge = $F('balance_id').trim();
            else
                var balance_charge =0;
            if(total_balance_charge != ""){
                var total_balance_charge_display = parseFloat(total_balance_charge);
                var balance_charge_display = parseFloat(balance_charge);
                total_balance_charge_display+= balance_charge_display
                total_balance_charge_display = total_balance_charge_display.toFixed(2)
                $('total_service_balance_id').setAttribute("value",round_total(total_balance_charge_display).toFixed(2));
                total_balance()
            }
            else{
                $('total_service_balance_id').value = total_balance_charge.toFixed(2);
                total_balance()
            }
            cleardata();
            if ($F('revenue_code_status') == "true"){
                $('revenue_code').value = ""
                if($F('patient_type_status') == "true" && $F('payment_code_status') == "true" ){
                    if($('allowance_code_id') != null){
                        $('allowance_code_id').checked = false
                    }
                    if($('capitation_code_id') != null){
                        $('capitation_code_id').checked = false
                    }
                }

            }

            $('charges_id').focus();
        }
        else {
            alert(' Exceed the Limit')

        }
    }
    $('add_button').style.visibility = "visible";
    dragAndDropTable('service_line_details');
}

function totalsubmitedCharge(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 1000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_charge_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalNonCovered(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 2000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_non_covered_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalDenied(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 2500 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_denied_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalDiscount(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 3000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_discount_id').value = sum.toFixed(2)

            }
        }
        sum = 0
    }

}

function totalAllowable(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 4000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_allowable_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalDrgAmount(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 4000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_drg_amount_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalExpectedPayment(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 4400 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_expected_payment_id').value = sum.toFixed(2)

            }
        }
        sum = 0
    }
}

//For setting total amount
function totalAmount(id, charLength){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = charLength + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById(id).value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalCoPayInsurance(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 5000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_coinsurance_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }

}

function totalDeductable(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 6000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_deductable_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}

function totalCoPay(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 7000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_copay_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}


function totalPayment(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 8000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_payment_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }
}


function totalPrimaryPayment(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 9000 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_primary_payment_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }

}



function totalContractualAmount(){
    if($('total_contractual_amount_id')) {
        if (char_array.length > 0) {
            for (l = 0; l < char_array.length; l++) {
                if (char_array[l] != "") {
                    totchar = 17000 + char_array[l]
                    sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                    var cordec = Math.pow(10, 2);
                    sum = Math.round(sum * cordec) / cordec;
                    document.getElementById('total_contractual_amount_id').value = sum.toFixed(2)
                }
            }
            sum = 0
        }
    }

}

function totalBalance(){
    if (char_array.length > 0) {
        for (l = 0; l < char_array.length; l++) {
            if (char_array[l] != "") {
                totchar = 10100 + char_array[l]
                sum = parseFloat(sum) + parseFloat(document.getElementById(totchar).value)
                var cordec = Math.pow(10, 2);
                sum = Math.round(sum * cordec) / cordec;
                document.getElementById('total_service_balance_id').value = sum.toFixed(2)
            }
        }
        sum = 0
    }

}
//TODO: Remove this function
// This method populates the HIPAA Codes for one of the PR field - Coinsurance
function reasoncodecoins(dollar_field, adjustment_code, adjustment_description,hippa){
    if (hippa == "true") {
        if (($(dollar_field).value != "") && ($(dollar_field).value != 0) && ($(dollar_field).value != "0.00")) {
            $(adjustment_code).value = 2
            $(adjustment_description).value = "Coinsurance Amount"
        }
    }
}

//TODO: Remove the function
// This method populates the HIPAA Codes for one of the PR field - Deductible
function reasoncodededuct(dollar_field, adjustment_code, adjustment_description,hippa){
    if (hippa != "true") {
        if (($(dollar_field).value != "") && ($(dollar_field).value != 0) && ($(dollar_field).value != "0.00")) {
            $(adjustment_code).value = 1
            $(adjustment_description).value = "Deductible Amount"
        }
    }
}
//TODO:Remove the function
// This method populates the HIPAA Codes for one of the PR field - Co-payment
function reasoncodecopay(dollar_field, adjustment_code, adjustment_description,hippa){
    if (hippa != "true") {
        if (($(dollar_field).value != "") && ($(dollar_field).value != 0) && ($(dollar_field).value != "0.00")) {
            $(adjustment_code).value = 3
            $(adjustment_description).value = "Co-payment Amount"
        }
    }

}

function populateDefaultRcOnTabout(amount_type, dollar_field, unique_code, hipaa){
    if($F('is_partner_bac') != "true" &&  hipaa != "true"){
        defaultReasoncodeAndDescriptionForPrFields(amount_type, dollar_field, unique_code);
    }
}
function populateDefaultRcOnDoubleClick(amount_type, dollar_field, unique_code, hipaa){
    if($F('is_partner_bac') != "true" &&  hipaa == "true"){
        defaultReasoncodeAndDescriptionForPrFields(amount_type, dollar_field, unique_code);
    }
}

//This method populates the HIPAA Codes forthe PR fields - Deductible, Copay & Co insurance
function defaultReasoncodeAndDescriptionForPrFields(amount_type, dollar_field, unique_code){
    var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');
    if(isAdjustmentAmountZero)
        var amountZeroCondition = true;
    else
        amountZeroCondition = parseFloat($F(dollar_field)) != 0;

    if (($(dollar_field).value != "") && amountZeroCondition && $F(unique_code) == "") {
        if (amount_type == 'deductible'){
            $(unique_code).value = $F('default_unique_code_deductible');
        }
        else if (amount_type == 'co_insurance'){
            $(unique_code).value = $F('default_unique_code_coinsurance');
        }
        else{
            $(unique_code).value = $F('default_unique_code_copay');
        }
    }
}

// This method populates the HIPAA Codes for one of the PR field - PPP
function reasoncodeprimarypayment(dollar_field, unique_code){
    if($F('is_partner_bac')!= "true"){
        var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');
        if(isAdjustmentAmountZero)
            var amountZeroCondition = true;
        else
            amountZeroCondition = parseFloat($F(dollar_field)) != 0;
        if (($(dollar_field).value != "") && amountZeroCondition && $F(unique_code) == "") {
            $(unique_code).value = $F('default_unique_code_primary_payment');
        }
    }
}

function setFCDefaultPatName(fid, id){
    var fval = $(fid).value
    if (fval == null || fval == "")
        return true;
    else{
        var agree = confirm("Do you Want to populate Default Patient Name?");
        if (agree == true){
            if (fval  == 'Payer Name'){
                $('patient_last_name_id').value = $('payer_popup').value;
                $('patient_first_name_id').value = $('payer_popup').value;
            } else {
                var patientName = fval.toUpperCase();
                patientName = patientName.split(",");
                if (patientName.size() > 1) {
                    $('patient_last_name_id').value = patientName[0];
                    $('patient_first_name_id').value = patientName[1];
                } else {
                    $('patient_last_name_id').value = patientName[1];
                }
            }
            return true;
        }
        else{
            setTimeout(function() {
                document.getElementById(id).focus();
            }, 20);
            return true;
        }
    }
}

function setFCDefault(sid, vid){
    var svcLineSerialNo = sid.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
    var isAdjustmentLineId = 'is_adjustment_line_' + svcLineSerialNo;
    if($(isAdjustmentLineId) != null && $F(isAdjustmentLineId) == 'true')
        var allow = false;
    else
        allow = true;
    if($F(vid) != "" && allow)
        sid.value = $F(vid)
}

function totalchargereadonly(){
    document.getElementById('total_charge_id').readOnly = true
    document.getElementById('total_non_covered_id').readOnly = true
    if($F('denied_status') == "true"){
        document.getElementById('total_denied_id').readOnly = true
    }
    if($('total_miscellaneous_one_id')){
        $('total_miscellaneous_one_id').readOnly = true;
    }
    if($('miscellaneous_two_status')) {
        $('total_miscellaneous_two_id').readOnly = true;
    }
    if($('total_miscellaneous_balance_id')) {
        $('total_miscellaneous_balance_id').readOnly = true;
    }
    document.getElementById('total_discount_id').readOnly = true
    document.getElementById('total_allowable_id').readOnly = true
    if($F('drg_amount_status') == "true")
        $('total_drg_amount_id').readOnly = true
    if($F('expected_payment_status') == "true"){
        document.getElementById('total_expected_payment_id').readOnly = true
    }
    if($F('retention_fees_status') == "true")
        $('total_retention_fees_id').readOnly = true
    if($('total_contractual_amount_id'))
        document.getElementById('total_contractual_amount_id').readOnly = true
    document.getElementById('total_coinsurance_id').readOnly = true
    document.getElementById('total_deductable_id').readOnly = true
    document.getElementById('total_copay_id').readOnly = true
    document.getElementById('total_payment_id').readOnly = true
    document.getElementById('total_primary_payment_id').readOnly = true
    document.getElementById('total_service_balance_id').readOnly = true
}

function sumbalance(){
    if (document.getElementById('charges_id').value == "" || isNaN(document.getElementById('charges_id').value)) {
        charge = 0
        chargeAmt = 0;
    }
    else {
        chargeAmt = parseFloat(document.getElementById('charges_id').value)
    }
    if (document.getElementById('non_covered_id').value == "")
        noncovered = 0
    else
        noncovered = parseFloat(document.getElementById('non_covered_id').value)
    if($F('denied_status') == "true"){
        if (document.getElementById('denied_id').value == "")
            denied = 0
        else
            denied = parseFloat(document.getElementById('denied_id').value)
    }
    if($('miscellaneous_one_id')) {
        if ($F('miscellaneous_one_id') == "")
            var miscellaneousOne = 0;
        else
            miscellaneousOne = parseFloat($F('miscellaneous_one_id'));
    }
    if($('miscellaneous_two_id')) {
        if ($F('miscellaneous_two_id') == "")
            var miscellaneousTwo = 0;
        else
            miscellaneousTwo = parseFloat($F('miscellaneous_two_id'));
    }
    if($('miscellaneous_balance_id')) {
        if ($F('miscellaneous_balance_id') == "")
            var miscellaneousBalance = 0;
        else
            miscellaneousBalance = parseFloat($F('miscellaneous_balance_id'));
    }
    if (document.getElementById('discount_id').value == "")
        discount = 0
    else
        discount = parseFloat(document.getElementById('discount_id').value)

    if (document.getElementById('co_insurance_id').value == "")
        coinsurance = 0
    else
        coinsurance = parseFloat(document.getElementById('co_insurance_id').value)
    if (document.getElementById('deductable_id').value == "")
        deductuble = 0
    else
        deductuble = parseFloat(document.getElementById('deductable_id').value)
    if (document.getElementById('copay_id').value == "")
        copay = 0
    else
        copay = parseFloat(document.getElementById('copay_id').value)

    if (document.getElementById('payment_id').value == "")
        payment = 0
    else
        payment = parseFloat(document.getElementById('payment_id').value)

    if (document.getElementById('primary_pay_payment_id').value == "")
        primarypayment = 0
    else
        primarypayment = parseFloat(document.getElementById('primary_pay_payment_id').value)
    if($F('prepaid_status') == "true"){
        if (document.getElementById('prepaid_id').value == "")
            prepaid = 0
        else
            prepaid = parseFloat(document.getElementById('prepaid_id').value)
    }
    if($F('patient_responsibility_status') == "true"){
        if (document.getElementById('patient_responsibility_id').value == "")
            patient_responsibility = 0
        else
            patient_responsibility = parseFloat(document.getElementById('patient_responsibility_id').value)
    }
    if($('contractualamount_id')) {
        if (document.getElementById('contractualamount_id').value == "" || isNaN(document.getElementById('contractualamount_id').value))
            contractualamount = 0
        else
            contractualamount = parseFloat(document.getElementById('contractualamount_id').value)
    }
    chargeAmount = chargeAmt
    otherAmount = (discount + noncovered + coinsurance + deductuble + copay + payment + primarypayment)
    if($F('denied_status') == "true"){
        otherAmount += denied
    }
    if($('miscellaneous_one_id')) {
        otherAmount += miscellaneousOne
    }
    if($('miscellaneous_two_id')) {
        otherAmount += miscellaneousTwo
    }
    if($('miscellaneous_balance_id')) {
        otherAmount += miscellaneousBalance
    }
    if($('contractualamount_id')) {
        otherAmount += contractualamount
    }

    if($F('prepaid_status') == "true")
        otherAmount += prepaid

    if($F('patient_responsibility_status') == "true")
        otherAmount += patient_responsibility

    chargeAmount = chargeAmount.toFixed(2);
    balanceAmount = chargeAmount - otherAmount

    $('balance_id').value = balanceAmount.toFixed(2)
}

// Validating 'Allowable'
function lineallowable(){
    if($('allowed_amount_mandatory_status') != null && $F('allowed_amount_mandatory_status') == "true"){
        if (($F('allowable_id') != '')) {
            if (($F('allowable_id').match(decimalNumber)) || ($F('allowable_id').match(numericExpression))) {
                return true
            }
            else {
                alert(' Allowable must be a real number')
                setTimeout(function() {
                    document.getElementById('allowable_id').focus();
                }, 10);
                return false
            }
        }
        else {
            alert('Service Line Allowable cannot be Empty')
            setTimeout(function() {
                document.getElementById('allowable_id').focus();
            }, 10);
            return false;
        }
    }
    else
        return true;
}
// Validating 'DRG Amount'
function validateDrgAmount(){
    if($('drg_amount_id') != null) {
        var fieldValue = $F('drg_amount_id')
        if ((fieldValue != '')) {
            if ((fieldValue.match(decimalNumber)) || (fieldValue.match(numericExpression))) {
                return true
            }
            else {
                alert('DRG Amount must be a real number')
                $('drg_amount_id').select();
                return false
            }
        }
        else return true
    }
    else return true
}

//Validating PBID and Retention Fee Amounts
function validateAmount(id){
    if($(id) != null) {
        var fieldValue = $F(id)
        if ((fieldValue != '')) {
            if ((fieldValue.match(decimalNumber)) || (fieldValue.match(numericExpression))) {
                return true
            }
            else {
                if(id == 'pbid_id'){
                    alert('PBID must be a real number')
                    $(id).select();
                    return false
                }
                else if(id == 'retention_fees_id'){
                    alert('Retention Fee must be a real number')
                    $(id).select();
                    return false
                }
                else if(id == 'prepaid_id'){
                    alert('Prepaid must be a real number')
                    $(id).select();
                    return false
                }
                else if(id == 'patient_responsibility_id'){
                    alert('Patient Responsibility must be a real number')
                    $(id).select();
                    return false
                }
            }
        }
        else return true
    }
    else return true
}

// Clears the service line of 'Add Row'
// After 'Add'ing the service line, the 'Add Row' service line is cleared for entering the new row
function cleardata(){
    if ($F('service_date_from_status') == "true"){
        $('dateofservicefrom').value = "mm/dd/yy"
        $('dateofserviceto').value = "mm/dd/yy"
    }
    if($F('rx_number_status') == "true"){
        $('rx_code').value = ""
    }
    $('cpt_procedure_code').value = ""
    if ($('bundled_procedure_code_status')!= null && $F('bundled_procedure_code_status') == "true"){
        $('bundled_procedure_code').value = ""
    }
    if ($F('revenue_code_status') == "true"){
        $('revenue_code').value = ""
    }
    if ($F('reference_code_status') == "true"){
        $('provider_control_number').value = ""
    }
    if(!($F('hide_modifiers') == "true")){
        $('modifier_id1').value = ""
        $('modifier_id2').value = ""
        $('modifier_id3').value = ""
        $('modifier_id4').value = ""
    }

    $('units_id').value = ""
    if($F('service_tooth_number_status') == "true" && $F('insurance_grid') == "true" && $('tooth_number') != null){
        $('tooth_number').value = ""
    }
    if ($F('remark_code_status') == "true"){
        $('remark_code').value = ""
    }
    if($F('line_item_number_status') == "true")
        $('line_item_number_id').value = ""
    if($F('payment_status_code_status') == "true")
        $('payment_status_code_id').value = ""
    $('charges_id').value = ""
    if($F('pbid_status') == "true")
        $('pbid_id').value = ""
    if($('allowable_id') != null)
        $('allowable_id').value = ""
    if($F('drg_amount_status') == "true")
        $('drg_amount_id').value = ""
    if($F('retention_fees_status') == "true")
        $('retention_fees_id').value = ""
    if($F('plan_coverage_status') == "true")
        $('plan_coverage_id').value = ""
    if($F('expected_payment_status') == "true"){
        $('expected_payment_id').value = ""
    }
    $('payment_id').value = ""
    $('non_covered_id').value = "";
    $('reason_code_noncovered_unique_code').value = "";
    if($F('denied_status') == "true"){
        $('denied_id').value = "";
        $('reason_code_denied_unique_code').value = "";
    }

    if($('miscellaneous_one_id'))
        $('miscellaneous_one_id').value = "";
    if($('reason_code_miscellaneous_one_unique_code'))
        $('reason_code_miscellaneous_one_unique_code').value = "";

    if($('miscellaneous_two_id'))
        $('miscellaneous_two_id').value = "";
    if($('reason_code_miscellaneous_two_unique_code'))
        $('reason_code_miscellaneous_two_unique_code').value = "";

    if($('miscellaneous_balance_id'))
        $('miscellaneous_balance_id').value = "";
    $('discount_id').value = "";
    $('reason_code_discount_unique_code').value = "";
    if($('contractualamount_id'))
        $('contractualamount_id').value = "";
    if($('reason_code_contractual_unique_code'))
        $('reason_code_contractual_unique_code').value = "";
    $('co_insurance_id').value = "";
    $('reason_code_coinsurance_unique_code').value = "";
    $('deductable_id').value = "";
    $('reason_code_deductible_unique_code').value = "";
    $('copay_id').value = "";
    $('reason_code_copay_unique_code').value = "";
    $('primary_pay_payment_id').value = "";
    $('reason_code_primary_payment_unique_code').value = "";
    if($F('prepaid_status') == "true"){
        $('prepaid_id').value = "";
        $('reason_code_prepaid_unique_code').value = "";
    }
    if($F('patient_responsibility_status') == "true"){
        $('patient_responsibility_id').value = "";
        $('reason_code_patient_responsibility_unique_code').value = "";
    }

    $('balance_id').value = ""
    if ($F('patient_type_status') == 'true') {
        if($('allowance_code_id') != null)
            $('allowance_code_id').checked = false;
        if($('capitation_code_id') != null)
            $('capitation_code_id').checked = false;
    }

}
//  Clears the Adjustment service line
function clearAdjustmentLine(count){
    if ($F('service_date_from_status') == "true"){
        $('date_service_from_' + count).value = ""
        $('date_service_to_' + count).value = ""
    }
    $('procedure_code_' + count).value = ""
    if ($('bundled_procedure_code_status') != null && $F('bundled_procedure_code_status') == "true"){
        $('bundled_procedure_code_' + count).value = ""
    }

    if($('rx_code_' + count) != null){
        $('rx_code_' + count).value = ""
    }
    if ($('revenue_code_' + count) != null){
        $('revenue_code_' + count).value = ""
    }
    if ($('provider_control_number_' + count) != null){
        $('provider_control_number_' + count).value = ""
    }

    if(!($F('hide_modifiers') == "true")) {
        $('service_modifier1_id' + count).value = ""
        $('service_modifier2_id' + count).value = ""
        $('service_modifier3_id' + count).value = ""
        $('service_modifier4_id' + count).value = ""
    }
    $('units_' + count).value = ""
    if ($('remark_code_' + count) != null){
        $('remark_code_' + count).value = ""
    }
    if($('line_item_number_' + count) != null)
        $('line_item_number_' + count).value = ""
    if($('payment_status_code_id' + count) != null)
        $('payment_status_code_id' + count).value = ""
    $('service_procedure_charge_amount_id' + count).value = ""
    if($('service_pbid_id' + count) != null)
        $('service_pbid_id' + count).value = ""
    if($('service_allowable_id' + count) != null)
        $('service_allowable_id' + count).value = ""
    if($('service_drg_amount_id' + count) != null)
        $('service_drg_amount_id' + count).value = ""
    if($('service_retention_fees_id' + count) != null)
        $('service_retention_fees_id' + count).value = ""
    if($('service_plan_coverage_id' + count) != null)
        $('service_plan_coverage_id' + count).value = ""
    if($('service_expected_payment_id' + count) != null){
        $('service_expected_payment_id' + count).value = ""
    }
    $('service_paid_amount_id' + count).value = ""
    if($('service_non_covered_id' + count) != null)
        $('service_non_covered_id' + count).value = "";
    if($('reason_code_noncovered' + count + '_unique_code') != null)
        $('reason_code_noncovered' + count + '_unique_code').value = "";
    if($('denied_id' + count) != null)
        $('denied_id' + count).value = "";
    if($('reason_code_denied' + count + '_unique_code') != null)
        $('reason_code_denied' + count + '_unique_code').value = "";

    if($('miscellaneous_one_id' + count) != null)
        $('miscellaneous_one_id' + count).value = "";
    if($('reason_code_miscellaneous_one' + count + '_unique_code') != null)
        $('reason_code_miscellaneous_one' + count + '_unique_code').value = "";
    if($('miscellaneous_two_id' + count) != null)
        $('miscellaneous_two_id' + count).value = "";
    if($('reason_code_miscellaneous_two' + count + '_unique_code') != null)
        $('reason_code_miscellaneous_two' + count + '_unique_code').value = "";
    if($('miscellaneous_balance_id' + count) != null)
        $('miscellaneous_balance_id' + count).value = "";

    if($('service_discount_id' + count) != null)
        $('service_discount_id' + count).value = "";
    if($('reason_code_discount' + count + '_unique_code') != null)
        $('reason_code_discount' + count + '_unique_code').value = "";
    if($('service_co_insurance_id' + count) != null)
        $('service_co_insurance_id' + count).value = "";
    if($('reason_code_coinsurance' + count + '_unique_code') != null)
        $('reason_code_coinsurance' + count + '_unique_code').value = "";
    if($('service_deductible_id' + count) != null)
        $('service_deductible_id' + count).value = "";
    if($('reason_code_deductible' + count + '_unique_code') != null)
        $('reason_code_deductible' + count + '_unique_code').value = "";
    if($('service_co_pay_id' + count) != null)
        $('service_co_pay_id' + count).value = "";
    if($('reason_code_copay' + count + '_unique_code') != null)
        $('reason_code_copay' + count + '_unique_code').value = "";
    if($('service_submitted_charge_for_claim_id' + count) != null)
        $('service_submitted_charge_for_claim_id' + count).value = "";
    if($('reason_code_primary_payment' + count + '_unique_code') != null)
        $('reason_code_primary_payment' + count + '_unique_code').value = "";
    if($('prepaid_id' + count) != null)
        $('prepaid_id' + count).value = "";
    if($('reason_code_prepaid' + count + '_unique_code') != null)
        $('reason_code_prepaid' + count + '_unique_code').value = "";
    if($('service_contractual_amount_id' + count) != null)
        $('service_contractual_amount_id' + count).value = "";
    if($('reason_code_contractual' + count + '_unique_code') != null)
        $('reason_code_contractual' + count + '_unique_code').value = "";
    if($('patient_responsibility_id' + count) != null)
        $('patient_responsibility_id' + count).value = "";
    if($('reason_code_patient_responsibility' + count + '_unique_code') != null)
        $('reason_code_patient_responsibility' + count + '_unique_code').value = "";
    if( $('service_balance_id' + count) != null)
        $('service_balance_id' + count).value = ""
    if ($F('patient_type_status') == 'true')
    {
        if($('opallowance' + count) || $('opcapitation' + count)){
            $('opallowance' + count).checked = false;
            $('opcapitation' + count).checked = false;
        }
        else if($('ipallowance' + count) || $('ipcapitation' + count)){
            $('ipallowance' + count).checked = false;
            $('ipcapitation' + count).checked = false;
        }
    }
}

function remove_serviceline(id){
    var m = 0;
    var val = (id.value)
    var e1 = document.getElementById(val);
    e1.parentNode.removeChild(e1);
    for (k = 0; k < char_array.length; k++) {
        if (char_array[k] == val) {
            char_array[m] = ""
        }
        m++
    }
    var w = 0
    for (s = 0; s < char_array.length; s++) {
        if (char_array[s] != "")
            w++
    }
    if (w == 0) {
        document.getElementById('total_charge_id').value = 0
        document.getElementById('total_allowable_id').value = 0
        if($F('drg_amount_status') == "true")
            $('total_drg_amount_id').value = 0
        if($F('expected_payment_status') == "true"){
            document.getElementById('total_expected_payment_id').value = 0
        }
        document.getElementById('total_payment_id').value = 0
        document.getElementById('total_non_covered_id').value = 0
        if($F('denied_status') == "true"){
            document.getElementById('total_denied_id').value = 0
        }
        if($('total_miscellaneous_one_id')){
            $('total_miscellaneous_one_id').value = 0;
        }
        if($('total_miscellaneous_two_id')){
            $('total_miscellaneous_two_id').value = 0;
        }
        if($('total_miscellaneous_balance_id')){
            $('total_miscellaneous_balance_id').value = 0;
        }
        if($F('retention_fees_status') == "true")
            $('total_retention_fees_id').value = 0
        document.getElementById('total_discount_id').value = 0
        document.getElementById('total_coinsurance_id').value = 0
        document.getElementById('total_deductable_id').value = 0
        document.getElementById('total_copay_id').value = 0
        document.getElementById('total_primary_payment_id').value = 0
        if($('total_contractual_amount_id'))
            document.getElementById('total_contractual_amount_id').value = 0
        document.getElementById('total_service_balance_id').value = 0
    }
    totalsubmitedCharge();
    totalAllowable();
    if($F('drg_amount_status') == "true")
        totalDrgAmount();
    if($F('expected_payment_status') == "true"){
        totalExpectedPayment();
    }
    totalPayment();
    totalNonCovered();
    if($F('denied_status') == "true"){
        totalDenied();
    }
    totalAmount('total_retention_fees_id', 4800);
    totalDiscount();
    totalCoPayInsurance();
    totalDeductable();
    totalCoPay();
    totalPrimaryPayment();
    totalContractualAmount();
    totalBalance();
    servicecount = servicecount - 1
    $('count').value  = servicecount
}

// Validating CPT Code
// The two parameters for the function are as follows:
// cpt_procedure_code : Field id of the CPT code / Bundled CPTcode.
// svc_id : Id of the service in the database.
// 'isInterestLineField' indicates that the service line is an interest service line.
// CPT code should not be mandatory for the interest service line.
// svc_id is used to identify the interest service line.

function procedure_code_validation(cpt_procedure_code, svc_id){
    if($(cpt_procedure_code) != null) {
        var interestLineField = 'interest_service_line_' + svc_id
        var isInterestLineField = 'false'
        if($(interestLineField) != null ){
            // 'interestLineField' holds a boolean value.
            // Its generated only for the interest service line.
            isInterestLineField = $F(interestLineField)
        }
        var proc_code = ($(cpt_procedure_code).value)
        if (proc_code != "") {
            if (busy) return false;
            busy = 1;
            if(proc_code.length == 5 && proc_code.match(alphaNumExp)) {
                busy = 0;
                return true
            }
            else {
                alert("Cpt code must be 5 digit alphanumeric")
                setTimeout(function(){
                    $(cpt_procedure_code).focus();
                }, 0);
                setTimeout('busy = 0', 50);
                return false
            }
        }
        else {
            if (busy) return false;
            busy = 1;
            if($F('cpt_mandatory_status') == "true" && (isInterestLineField != 'true') && cpt_procedure_code != '' ){
                alert("CPT Code Mandatory ");
                setTimeout(function(){
                    $(cpt_procedure_code).focus();
                }, 0);
                setTimeout('busy =0', 50 );
                return false
            }
            else{
                busy = 0;
                return true
            }
        }
    }
    else{
        busy = 0;
        return true;
    }
}

// Validating CPT Code
// The two parameters for the function are as follows:
// cpt_procedure_code : Field id of the CPT code / Bundled CPTcode.
// svc_id : Id of the service in the database.
// 'isInterestLineField' indicates that the service line is an interest service line.
// CPT code should not be mandatory for the interest service line.
// svc_id is used to identify the interest service line.

function bundled_procedure_code_validation(cpt_procedure_code, svc_id){
    var interestLineField = 'interest_service_line_' + svc_id
    var isInterestLineField = 'false'
    if($(interestLineField) != null ){
        // 'interestLineField' holds a boolean value.
        // Its generated only for the interest service line.
        isInterestLineField = $F(interestLineField)
    }

    var proc_code = ($(cpt_procedure_code).value)
    if (proc_code != "") {
        if (busy) return false;
        busy = 1;
        if(proc_code.toUpperCase() == $F('fc_def_cpt_code').toUpperCase() ||
            ((proc_code.length == 5)&&(proc_code.match(alphaNumExp)))) {
            busy = 0;
            return true
        }
        else {
            alert("Bundled Cpt code must be 5 digit alphanumeric")
            setTimeout(function(){
                $(cpt_procedure_code).focus();
            }, 0);
            setTimeout('busy = 0', 50);
            return false
        }
    }
    else {
        busy = 0;
        return true
    }
}


function modifier_validate(modifier){
    if (busy) return false;
    busy = 1;
    if (!($F('hide_modifiers') == "true") && $(modifier) != null && $(modifier).value.length != "0"){
        var modifier_code = ($(modifier).value)
        modifier_length = $F(modifier)
        if (modifier_code.length != "2") {
            alert("Modifier must be 2 digit")
            setTimeout(function(){
                $(modifier).focus();
            }, 0);
            setTimeout('busy = 0', 50);
            return false
        }
        else{
            if(!modifier_code.match(alphaNumExp)){
                alert("Modifier must be 2 digit alphanumeric")
                setTimeout(function(){
                    $(modifier).focus();
                }, 0);
                setTimeout('busy = 0', 50);
                return false
            }
            else{
                busy = 0;
                return true
            }
        }
    }
    else{
        busy = 0;
        return true
    }
}

function modifer_validate_on_save(){
    if (busy) return false;
    busy = 1;
    if ((!($F('hide_modifiers') == "true") && $("modifier_id1") != null && $("modifier_id2") != null && $("modifier_id3") != null) && ((($("modifier_id1").value).length != "0") || (($("modifier_id2").value).length != "0") || (($("modifier_id3").value).length != "0"))){
        var modifier_code1 = ($("modifier_id1").value)
        var modifier_code2 = ($("modifier_id2").value)
        var modifier_code3 = ($("modifier_id3").value)
        if ((modifier_code1.length != "2") || (modifier_code2.length != "2") || (modifier_code3.length != "2")) {
            alert("Modifier must be 2 digit")
            setTimeout(function(){
                $("modifier_id1").focus();
            }, 0);
            setTimeout('busy = 0', 50);
            return false
        }
        else{
            if((!modifier_code1.match(alphaNumExp)) || (!modifier_code2.match(alphaNumExp)) || (!modifier_code3.match(alphaNumExp))){
                alert("Modifier must be 2 digit alphanumeric")
                setTimeout(function(){
                    $(modifier).focus();
                }, 0);
                setTimeout('busy = 0', 50);
                return false
            }
            else{
                busy = 0;
                return true
            }
        }
    }
    else{
        busy = 0;
        return true
    }
}

// Validating Charges
function linecharge(){
    if (($('charges_id').value != '')) {
        if (($('charges_id').value.match(decimalNumber)) || ($('charges_id').value.match(numericExpression))) {
            return true
        }
        else {
            alert(' Charges must be a real number')
            setTimeout(function() {
                document.getElementById('charges_id').focus();
            }, 10);
            return false
        }
    }
    else {
        alert('Service Line Charges cannot be Empty')
        setTimeout(function() {
            document.getElementById('charges_id').focus();
        }, 10);
        return false;
    }
}

// Charge must be non-zero validation for BAC client 'MDR - Marina Del Ray' (MDR) with sitecode 00P84

function service_charge_must_be_nonzero(){
    if($F('sitecode') == "P84"){
        if(($F('payment_id') != "" && parseFloat($F('payment_id')) != "0.00") && (parseFloat($F('charges_id')) == '0.00' || $F('charges_id') == '')){
            alert('Charge must be non-zero. If charge is not specified, capture payment amount as Charge');
            $('charges_id').focus();
            return false;
        }
        else{
            return true;
        }
    }
    else{
        return true;
    }
}

// funtion for validating allowed amount ie, allowed_amount = payment + ppp + pr_amounts;

function allowedAmountValidation(insuranceId, deductableId, copayId, allowableId, paymentId, pppId) {
    var coInsurance = isNaN(parseFloat($F(insuranceId)))? 0 : parseFloat($F(insuranceId));
    var deductable =  isNaN(parseFloat($F(deductableId)))? 0 : parseFloat($F(deductableId));
    var copay = isNaN(parseFloat($F(copayId)))? 0 : parseFloat($F(copayId))
    var allowable = isNaN(parseFloat($F(allowableId)))? 0: parseFloat($F(allowableId));
    var payment = isNaN(parseFloat($F(paymentId)))? 0 : parseFloat($F(paymentId)) ;
    var ppp = isNaN(parseFloat($F(pppId)))? 0 : parseFloat($F(pppId)) ;
    var prAmounts =  coInsurance + deductable + copay;
    var sum = payment + ppp + prAmounts;
    if (sum != allowable) {
        return false;
    }
    else return true;
}

function allowedAmountValidationMpi(){
    var invalid = 0;
    var totalLine = parseInt($F('total_line_count'))
    for(lineCount = 2; lineCount <= totalLine; lineCount++) {
        if($("service_allowable_id" + lineCount) != null) {
            if(!(isNaN(parseFloat($F("service_allowable_id"+lineCount))))) {
                var status = allowedAmountValidation("service_co_insurance_id"+lineCount,
                    "service_deductible_id"+lineCount, "service_co_pay_id"+lineCount,
                    "service_allowable_id"+lineCount, "service_paid_amount_id"+lineCount,
                    "service_submitted_charge_for_claim_id"+lineCount)
                if(status == false) {
                    invalid++;
                    setHighlight(['service_allowable_id'+ lineCount], "uncertain");
                }
                else{
                    setHighlight(['service_allowable_id'+ lineCount], "blank");
                }
            }
        }
    }
    if(invalid > 0) {
        return confirm("Allowed amount is not correct for highlighted line/s: Do you want to continue?");
    }
    else return true;
}

function allowedAmountValidationClaimLevel() {
    var agree;
    var flag =  true
    if($('claim_level_eob') != null && $F('claim_level_eob') == "true" && $('claim_level_allowed_amount_in_grid') != null && $F('claim_level_allowed_amount_in_grid') == "true" && $('total_allowable_id') != null ){
        if( $F('total_allowable_id') != '' ){
            if (($F('total_allowable_id').match(decimalNumber)) || ($F('total_allowable_id').match(numericExpression))) {
                if(allowedAmountValidation("total_coinsurance_id", "total_deductable_id", "total_copay_id",
                    "total_allowable_id", "total_payment_id", "total_primary_payment_id"))
                    flag =  true;
                else{
                    agree = confirm("Allowed amount is not correct, Do you want to continue?");
                    if(agree == true)
                        flag =  true;
                    else{
                        setTimeout(function() {
                            document.getElementById('total_allowable_id').focus();
                        }, 10);
                        flag =  false;
                    }
                }
            }
            else {
                alert(' Allowable must be a real number')
                setTimeout(function() {
                    document.getElementById('total_allowable_id').focus();
                }, 10);
                flag =  false;
            }
        }
        else{
            alert("Allowed Amount cannot be Empty");
            setTimeout(function() {
                document.getElementById('total_allowable_id').focus();
            }, 10);
            flag =  false;
        }
    }
    return flag;
}

function allowedAmountValidationNonmpi() {
    var agree;
    if(allowedAmountValidation("co_insurance_id", "deductable_id", "copay_id",
        "allowable_id", "payment_id", "primary_pay_payment_id"))
        return true;
    else{
        agree = confirm("Allowed amount is not correct, Do you want to continue?");
        if(agree == true)
            return true;
        else{
            setTimeout(function() {
                document.getElementById('allowable_id').focus();
            }, 10);
            return false;
        }
    }
}

function allowedAmountValidationWithCharge(chargeId, allowableId) {
    var allowable = isNaN(Math.abs(parseFloat($F(allowableId)))) ? 0 : Math.abs(parseFloat($F(allowableId)));
    var charge = isNaN(Math.abs(parseFloat($F(chargeId)))) ? 0 : Math.abs(parseFloat($F(chargeId))) ;
    if (charge < allowable) {
        return false;
    }
    else return true;
}

function allowedAmountValidationWithChargeOnMpi(){
    var invalid = 0;
    var firstInvalidLine = 0;
    var totalLine = parseInt($F('total_line_count'))
    if($('client_type') != null && $F('client_type').toUpperCase() == "MEDISTREAMS"){
        for(lineCount = 2; lineCount <= totalLine; lineCount ++) {
            if($("service_allowable_id" + lineCount) != null) {
                if(!(isNaN(parseFloat($F("service_allowable_id" + lineCount))))) {
                    var status = allowedAmountValidationWithCharge(
                        "service_procedure_charge_amount_id" + lineCount,
                        "service_allowable_id" + lineCount)
                    if(status == false) {
                        invalid ++;
                        if(invalid == 1){
                            firstInvalidLine = lineCount;
                        }
                        setHighlight(['service_allowable_id' + lineCount], "uncertain");
                    }
                    else{
                        setHighlight(['service_allowable_id' + lineCount], "blank");
                    }
                }
            }
        }
    }
    if(invalid > 0) {
        alert("Charge amount is less than allowed amount which is not correct. Please correct it");
        setTimeout(function() {
            document.getElementById('service_allowable_id' + firstInvalidLine).focus();
        }, 10);
        return false;
    }
    else return true;
}

function allowedAmountValidationWithChargeOnNonmpi() {
    if($('client_type') != null && $F('client_type').toUpperCase() == "MEDISTREAMS"){
        if(allowedAmountValidationWithCharge("charges_id", "allowable_id"))
            return true;
        else{
            alert("Charge amount is less than allowed amount which is not correct. Please correct it");
            setTimeout(function() {
                document.getElementById('allowable_id').focus();
            }, 10);
            return false;
        }
    }
    else
        return true;
}

function service_balance_check(){
    balance_amount = parseFloat($('balance_id').value)
    if (balance_amount != 0) {
        alert("Balance should be zero")
        return false

    }
    else {
        return true
    }
}

// Validating Payment
function linepayment(){
    if (($('payment_id').value != '')) {
        if (($('payment_id').value.match(decimalNumber)) || ($('payment_id').value.match(numericExpression))) {
            return true
        }
        else {
            alert(' Payment must be a real number')
            setTimeout(function() {
                document.getElementById('payment_id').focus();
            }, 10);
            return false
        }
    }
    else {
        alert('Service Line Payment cannot be Empty')
        setTimeout(function() {
            document.getElementById('payment_id').focus();
        }, 10);
        return false;
    }
}

// Validating Reference
function refNumCheck(provider_control_number){
    if($(provider_control_number) != null) {
        if (busy) return false;
        busy = 1;
        if ($F('reference_code_mandatory_status') == 'true'){
            if($F(provider_control_number).match(alphaNumExp)){
                busy = 0;
                return true;
            }
            else {
                alert('Ref cannot be Empty');
                setTimeout(function(){
                    $(provider_control_number).focus();
                }, 0);
                setTimeout('busy = 0', 50);
                return false;
            }
        }
        else{
            busy = 0;
            return true
        }
    }
    else {
        busy = 0;
        return true;
    }
}

function claimBalanceCheck(){
    if($('claim_level_eob') != null && $F('claim_level_eob') != "true"){
        total_balance();
    }
    else{
        sumClaimbalance();
        if (parseFloat($F('total_service_balance_id')) == 0 && parseFloat($F('total_charge_id')) == 0){
            var toContinue = confirm("Claim level charge and payment amounts are zero. Are you sure?");
            if (toContinue != true)
                $('total_service_balance_id').value = '';
        }
    }
    var isPopulateDefaultValues = "";
    var result = true;
    if($('populate_default_values') != null)
        isPopulateDefaultValues = $F('populate_default_values');
    var insurancePay = $F('insurance_grid');
    var isInterestPaymentCheck = false;
    if($('interest_id') != null && $('client_type') != null) {
        clientName = $F('client_type');
        if(clientName.toUpperCase() == 'QUADAX' && parseFloat($F('checkamount_id')) == parseFloat($F('interest_id')))
            isInterestPaymentCheck = true;
    }
    var isSetDefaultValuesForJobIncompletion = '';
    if($('set_default_values_for_incompletion')) {
        isSetDefaultValuesForJobIncompletion = $F('set_default_values_for_incompletion');
    }
    if((isPopulateDefaultValues == "1" && insurancePay != "true") ||
        isInterestPaymentCheck == true || isSetDefaultValuesForJobIncompletion == "1"){
        result = true;
    }
    else{
        var balanceAmount = parseFloat($F('total_service_balance_id')).toFixed(2);
        if (balanceAmount < 0 || balanceAmount > 0 ) {
            alert("Total service line balance amount should be 0");
            result = false;
        }
        else if (balanceAmount != 0) {
            alert("Please Enter Atleast One Service Line");
            result = false;
        }
        else {
            result = true;
        }
    }
    //console_logger('claimBalanceCheck', result);
    return result;
}

function copyPatientName(){
    var checkBox = $("copy_patient")
    if (checkBox.checked) {
        $("subcriber_last_name_id").value = $("patient_last_name_id").value;
        $("subcriber_firstname_id").value = $("patient_first_name_id").value;
        $("subcriber_initial_id").value = $("patient_initial_id").value;
        $("subcriber_suffix_id").value = $("patient_suffix_id").value;
    }
    else{
        $("subcriber_last_name_id").value = "";
        $("subcriber_firstname_id").value = "";
        $("subcriber_initial_id").value = "";
        $("subcriber_suffix_id").value = "";
    }
}

function confirmationAlert(){
    var toProceed = completeButtonPressed();
    if(toProceed == true) {
        var agree = confirm("Are you sure ?");
        if (agree == true){
            if($('after_button_hiding') != null)
                $('after_button_hiding').value = $F('submit_button_name');
            if($('complete_button_id') != null)
                $('complete_button_id').disabled = true;
            if($('incomplete_button_id') != null)
                $('incomplete_button_id').disabled = true;
            document.forms.item('form1').submit();
        }
        else {
            var interestOnlyCheckCondition = ($('interest_only_check') != null && $('interest_only_check').checked);
            if((window.frames['myiframe']) != null){
                if(interestOnlyCheckCondition){
                    window.frames['myiframe'].document.getElementById('proc_save_eob_button_id').disabled = true;
                }
                else{
                    window.frames['myiframe'].document.getElementById('proc_save_eob_button_id').disabled = false;
                }
            }
            else if($('proc_save_eob_button_id') != null){
                if(interestOnlyCheckCondition){
                    $('proc_save_eob_button_id').disabled = true;
                }
                else{
                    $('proc_save_eob_button_id').disabled = false;
                }
            }
            if($('qa_update_job_button_id') != null)
                $('qa_update_job_button_id').disabled = false;
            if($('qa_save_eob_button_id') != null){
                if(interestOnlyCheckCondition){
                    $('qa_save_eob_button_id').disabled = true;
                }
                else{
                    $('qa_save_eob_button_id').disabled = false;
                }
            }
            if($('qa_delete_eob_button_id') != null)
                $('qa_delete_eob_button_id').disabled = false;
            return false;
        }

    }
    else
        return false;
}
// The balance value is populated in the dollar amount fields on the event of double click
function setBalancevalue(field_id){

    if (document.getElementById('balance_id')) {
        $(field_id).value = $F('balance_id')
    }


    if($F('claim_level_eob') == "true"){
        $(field_id).value = $F('total_service_balance_id')
    }
}

function setMpiBalancevalue(mpi_field,val,total){
    mpi_field_id = mpi_field + val
    $(mpi_field_id).value =  $F('service_balance_id' + val)
    total_charge(mpi_field,total)
}

//Toggling of the Check details row
function togleDiv()
{
    $("check_info").toggle();
}

//Toggling of the Adjustment Service Line
function toggleAdjustmentLine() {

    var row = "service_row" +  1;
    if($('total_existing_number_of_svc_lines') != null && parseInt($F('total_existing_number_of_svc_lines')) > 1){
        if($('adjustment_line_number') != null && $F('adjustment_line_number') != '')
            alert('Please delete the existing adjustment service line to continue.');
        else {
            $(row).toggle();
            var adjustmentLinePaymentFieldId = 'service_paid_amount_id' + 1;
            if($(adjustmentLinePaymentFieldId) != null) {
                setTimeout(function(){
                    $(adjustmentLinePaymentFieldId).focus();
                }, 0);
            }
        }
    }
    else if($(row).style.display != 'none') {
        $(row).style.display = 'none';
    }
    else
        alert('Please enter a valid service line to continue.');
}

function reasoncodeCheck(amount, reasoncode, description){
    lineAmount = parseFloat($(amount).value)
    reasonCode = ($(reasoncode).value)
    reasonCodeDescription = ($(description).value)
    var amountField = reasoncode.split("_");
    if (isNaN(lineAmount)) {
        lineAmount = 0
    }
    if (lineAmount != 0 || lineAmount != "") {
        var hypen_check =  reasonCode.indexOf("-");
        var asterik_check = reasonCode.indexOf("*")
        if ((reasonCode == "") || (reasonCodeDescription == "")) {
            alert("Please Enter  " + amountField[0] + " Code and Description")
            $(reasoncode).focus()
        }
        else{
            if ((hypen_check >= 0 ) || (asterik_check >= 0) || (reasonCode.match(reasoncode_check))) {
                alert("Please Enter Valid " + amountField[0] + " Reasoncode")
                $(reasoncode).focus()
                return false
            }
            else{
                return true
            }
        }
    }
}


//Validating RX Number
function validateRXnumber(){
    if($('rx_code') != null) {
        if ($F('rx_code').match(alphaNumExp)) {
            return true;
        }
        else {
            alert('Rx Number cannot be Empty')
            $('rx_code').focus();
            return false;
        }
    }
    else
        return true;
}

// Changes the Payment Code title according to the Payment Type
function enablePaymentcode(){
    patient_type = $F('patient_type_id');
    if (patient_type == 'INPATIENT'){
        if($('allowance_code_id') != null){
            $('allowance_code_id').title = " Inpatient Allowance Code";
        }
        if($('capitation_code_id') != null){
            $('capitation_code_id').title = " Inpatient Capitation Code";
        }
    }
    else if (patient_type == 'OUTPATIENT'){
        if($('allowance_code_id') != null){
            $('allowance_code_id').title = " Outpatient Allowance Code";
        }
        if($('capitation_code_id') != null){
            $('capitation_code_id').title = " Outpatient Capitation Code";
        }
    }
}


function sumClaimbalance(){
    var noncovered = 0;
    var charge = 0;
    var chargeAmt = 0;
    var denied = 0;
    var miscellaneousOne = 0;
    var miscellaneousTwo = 0;
    var miscellaneousBalance = 0;
    var discount = 0;
    var coinsurance = 0;
    var deductuble = 0;
    var copay = 0;
    var payment = 0;
    var primarypayment = 0;
    var prepaid = 0;
    var patient_responsibility = 0;
    var contractualamount = 0;

    if (document.getElementById('total_charge_id').value == "" || isNaN(document.getElementById('total_charge_id').value)) {
        chargeAmt = 0;
    }
    else {
        chargeAmt = parseFloat(document.getElementById('total_charge_id').value)
    }

    if (document.getElementById('total_non_covered_id')){
        if (document.getElementById('total_non_covered_id').value == "")
            noncovered = 0
        else
            noncovered = parseFloat(document.getElementById('total_non_covered_id').value)
    }
    if (document.getElementById('denied_status')) {
        if ($F('denied_status') == "true") {
            if (document.getElementById('total_denied_id').value == "")
                denied = 0
            else
                denied = parseFloat(document.getElementById('total_denied_id').value)
        }
    }

    if ($('total_miscellaneous_one_id')) {
        if ($F('total_miscellaneous_one_id') == "")
            miscellaneousOne = 0;
        else
            miscellaneousOne = parseFloat($F('total_miscellaneous_one_id'));
    }

    if ($('total_miscellaneous_two_id')) {
        if ($F('total_miscellaneous_two_id') == "")
            miscellaneousTwo = 0;
        else
            miscellaneousTwo = parseFloat($F('total_miscellaneous_two_id'));
    }
    if ($('total_miscellaneous_balance_id')) {
        if ($F('total_miscellaneous_balance_id') == "")
            miscellaneousBalance = 0;
        else
            miscellaneousBalance = parseFloat($F('total_miscellaneous_balance_id'));
    }

    if (document.getElementById('total_discount_id') ){
        if (document.getElementById('total_discount_id').value == "")
            discount = 0
        else
            discount = parseFloat(document.getElementById('total_discount_id').value)
    }

    if (document.getElementById('total_coinsurance_id') ){
        if (document.getElementById('total_coinsurance_id').value == "")
            coinsurance = 0
        else
            coinsurance = parseFloat(document.getElementById('total_coinsurance_id').value)
    }

    if (document.getElementById('total_deductable_id') ){
        if (document.getElementById('total_deductable_id').value == "")
            deductuble = 0
        else
            deductuble = parseFloat(document.getElementById('total_deductable_id').value)
    }

    if (document.getElementById('total_copay_id') ){
        if (document.getElementById('total_copay_id').value == "")
            copay = 0
        else
            copay = parseFloat(document.getElementById('total_copay_id').value)
    }

    if (document.getElementById('total_payment_id')){
        if (document.getElementById('total_payment_id').value == "")
            payment = 0
        else
            payment = parseFloat(document.getElementById('total_payment_id').value)
    }
    if (document.getElementById('total_primary_payment_id')){
        if (document.getElementById('total_primary_payment_id').value == "")
            primarypayment = 0
        else
            primarypayment = parseFloat(document.getElementById('total_primary_payment_id').value)
    }

    if (document.getElementById('prepaid_status')) {
        if ($F('prepaid_status') == "true") {
            if (document.getElementById('total_prepaid_id').value == "")
                prepaid = 0
            else
                prepaid = parseFloat(document.getElementById('total_prepaid_id').value)
        }
    }
    if (document.getElementById('patient_responsibility_status')) {
        if ($F('patient_responsibility_status') == "true") {
            if (document.getElementById('total_patient_responsibility_id').value == "")
                patient_responsibility = 0
            else
                patient_responsibility = parseFloat(document.getElementById('total_patient_responsibility_id').value)
        }
    }


    if (document.getElementById('total_contractual_amount_id')) {
        if (document.getElementById('total_contractual_amount_id').value == "" ) {
            contractualamount = 0
        }
        else
            contractualamount = parseFloat(document.getElementById('total_contractual_amount_id').value)
    }

    var chargeAmount = chargeAmt
    var otherAmount = (discount + noncovered + coinsurance + deductuble + copay + payment + primarypayment )

    if (document.getElementById('denied_status')) {
        if ($F('denied_status') == "true") {
            otherAmount += denied
        }
    }

    if ($('total_miscellaneous_one_id')) {
        otherAmount += miscellaneousOne;
    }
    if ($('total_miscellaneous_two_id')) {
        otherAmount += miscellaneousTwo;
    }
    if ($('total_miscellaneous_balance_id')) {
        otherAmount += miscellaneousBalance;
    }
    if ($('total_contractual_amount_id')) {
        otherAmount += contractualamount;
    }

    if (document.getElementById('prepaid_status')) {
        if ($F('prepaid_status') == "true") {
            otherAmount += prepaid
        }
    }

    if (document.getElementById('patient_responsibility_status')) {
        if ($F('patient_responsibility_status') == "true") {
            otherAmount += patient_responsibility
        }
    }

    chargeAmount = chargeAmount.toFixed(2);
    var balanceAmount = chargeAmount - otherAmount

    $('total_service_balance_id').value = balanceAmount.toFixed(2);
}
function validatePatientName(patient_last_name_id, patient_first_name_id, patient_initial_id, patient_suffix_id, provider_last_name, prov_firstname_id,prov_initial_id,prov_suffix_id)
{
    //console_logger('validatePatientName', true);
    var ptPartName = $F(patient_last_name_id) + $F(patient_first_name_id);
    var pvPartName = $F(provider_last_name) + $F(prov_firstname_id);
    var ptFullName = $F(patient_last_name_id) + $F(patient_first_name_id) + $F(patient_initial_id) + $F(patient_suffix_id);
    var pvFullName = $F(provider_last_name) + $F(prov_firstname_id) + $F(prov_initial_id) + $F(prov_suffix_id);
    var errorMsg ="";
    if ($("question_check") != null && $F("question_check")==1){
        if ($F("insurance")==0)
        {
            populatePayerInfo('payer_popup');
            return false;
        }
    }
    if((ptFullName==pvFullName) && ptFullName != '')
    {
        errorMsg = errorMsg+"Patient Name cannot be same as Provider Name";
    }
    if ((ptPartName ==pvPartName) && ptPartName != '')
    {
        return confirm("Patient Name entered is same as Provider Name. Continue?")
    }
    if(errorMsg == "")
    {
        return true;
    }
    else
    {
        alert(errorMsg);
        return false;
    }

}

function checkProviderAdjustmentForQa(){
    saved_provider_adjustment_amount = $F('provider_adjustment_amount');
    balance = $F('balance');
    new_provider_adjustment_amount = $F('provider_adjustment');
    if($F('status') == "Complete"){
        if(parseFloat(saved_provider_adjustment_amount) == 0){
            return true;
        }
        else{
            if(parseFloat(balance) == 0){
                return true;
            }
            else{
                changed_amount = parseFloat(balance)+parseFloat(saved_provider_adjustment_amount)
                if(parseFloat(changed_amount) == parseFloat(new_provider_adjustment_amount)){
                    return true;
                }
                else{
                    if(isTransactionTypeMissingCheckOrCheckOnly() == false) {
                        alert("The check is not balanced yet. Please enter the correct Provider Adjustment Amount, if any");
                        $("provider_adjustment").focus();
                        return false;
                    }
                    else
                        return true;
                }
            }
        }
    }
    else
        return true;
}

//claim_from and claim_to date validation for Navicure

function validate_ClaimDatevalue(claimdate_id){

    text_value = $F(claimdate_id);
    year_array = text_value.split("/");
    if (($F(claimdate_id) != '')) {
        $(claimdate_id).style.backgroundColor = 'white'
        if (($F(claimdate_id).match(dobRegxp))) {
            if (((year_array[1] >= 1) && (year_array[1] <= 31)) || (year_array[1] == 99)) {
                if (((year_array[0] >= 1) && (year_array[0] <= 12)) || (year_array[0] == 99)) {
                    if (((year_array[2] >= 00) && (year_array[2] <= 50)) || (year_array[2] == 99)){
                        if(isFutureDate()){
                            return true;
                        }
                        else{
                            alert('Future Date not Allowed');
                            $(claimdate_id).select();
                            return false
                        }
                    }
                    else {
                        alert('Year must be in between 2000 and 2050');
                        $(claimdate_id).select();
                        return false
                    }
                }
                else {
                    alert('Enter a Valid month');
                    $(claimdate_id).select();
                    return false
                }
            }
            else {
                alert('Enter a Valid date');
                $(claimdate_id).select();
                return false
            }
        }
        else {
            alert('Date format is wrong')
            $(claimdate_id).select();
            return false

        }
    }
    else {
        return true;
    }

}

/*
 * Validation for payer state and payer type prompted from payer state text box. On Completion of State validation, Payer Type validation will take place
 */
function validatePayerStateAndType(payerStateId) {
    if(validateState(payerStateId)) {
        notifyUserForPayerType(true);
    }
}


String.prototype.ltrim = function() {
    return this.replace(/^\s+/,"");
}
function checkComment(){
    var validation = true;
    if ($("complete_button_id")!= null){
        $("complete_button_id").disabled = true;
    }
    $('complete_comment_text_area').style.display = "none";
    $('complete_proc_comment_other').style.display = "none";
    $('incomplete_comment_text_area').style.display = "block";
    var comment = $F('incomplete_processor_comment').trim();
    if(comment == null || comment == "comment" || comment == "" || comment == "--" )
    {
        alert("Please Enter Comment");
        $('incomplete_processor_comment').focus();
        validation = false;
    }
    return validation;
}

function checkCommentForComplete(){
    if ($("incomplete_button_id")!= null){
        $("incomplete_button_id").disabled = true;
    }
    $('complete_comment_text_area').style.display = "block";
    $('incomplete_comment_text_area').style.display = "none";
    return 1;
}

function checkQualifier(id_field,qualifier_field){
    var checkQualifierStatus = true;
    if($(id_field) != null) {
        var idnumber = $(id_field).value;
        if (idnumber){
            var selIndex = $(qualifier_field).selectedIndex;
            var qualifier = $(qualifier_field).options[selIndex].text;
            if (qualifier != "--")
                checkQualifierStatus =  true;
            else{
                alert("Please Select Qualifier")
                setTimeout(function() {
                    $(qualifier_field).focus();
                }, 100);

                checkQualifierStatus =  false;
            }
        }
    }
    return checkQualifierStatus
}

function checkQualifierSave(id_field, qualifier_field){
    var is_valid = true;
    var patient_identification_code_id = $(toString(id_field))
    if (patient_identification_code_id){
        var code_id = patient_identification_code_id.value
        if (code_id != null){
            var selIndex = $(qualifier_field).selectedIndex;
            var qualifier = $(qualifier_field).options[selIndex].text;
            if (qualifier == "--"){
                alert("Please Select Qualifier")
                $(qualifier_field).focus();
                is_valid = false;
            }
        }
    }
    //console_logger('checkQualifierSave', is_valid);
    return is_valid;
}

// If the EOB capturing is a Claim Level EOB type then hide all the service lines. Only the Totals should be shown.
function hide_for_claim_level_eob(){
    if($('claim_level_eob') != null && $F('claim_level_eob') == "true"){
        if ($("adding_row") != null)
            $("adding_row").style.display = 'none';
        for(row_id = 0; row_id < $F('total_line_count'); row_id++){
            row = "service_row" + row_id
            if($(row)){
                $(row).style.display = 'none';
            }
        }
    }
}

// The Total fields are prepopulated as '0.00' . When the user is about to enter $amount for Claim Level EOBs in the Total fields, it is set as blank
function setBlank(field){
    if($F('claim_level_eob') == "true"){
        if($F(field) == 0.00){
            $(field).value = ""
        }
    }
}
function setBlank_new(field){
    if($F('claim_level_eob') == "true"){
        if($F(field) == 0.00){
            $(field).value = ""
        }
    }
}
// Only for the HLSC Clients, Provider name is populated as 'None' on double click of the element.
function setDefaultProvider() {
    if($F('hlsc_client') == "true") {
        $('provider_provider_last_name').value = "None"
        $('prov_firstname_id').value = "None"
    }
}

// Provides an alert if the EOB Page is blank
function checkEobPage(){
    var result =  true;
    if($F('image_page_number') == "" || $F('image_page_number') == "0"){
        alert("Please enter the page # of the EOB that you are trying to save");
        $('image_page_number').value = ""
        $('image_page_number').focus();
        result = false;
    }
    //console_logger('checkEobPage', true);
    return result;
}

//This is for all facilities
function checkImagePageToNumberForProcView(){
    var flag = true;
    job_pages_to = $F('pages_to');
    job_pages_from = $F('pages_from');
    eob_page = $F('image_page_number');
    page_to = $F('image_page_to_number');
    pat_acc_id = $F('patient_account_id');
    if((parseInt(page_to) == parseInt(eob_page))||(parseInt(page_to) == (parseInt(eob_page)+ 1)) ){
        flag = true;
    }
    else{
        if(parseInt(page_to) > parseInt(job_pages_to) || parseInt(page_to) < parseInt(job_pages_from)){
            alert("Invalid Image Page To#!!Please select the proper image to save EOB.");
            $('image_page_to_number').value = "";
            $('image_page_to_number').focus();
            flag = false;
        }
        else{
            if(parseInt(page_to) < parseInt(eob_page)){
                $('image_page_to_number').value = parseInt(eob_page);
                flag = true;
            }
            else{
                var agree = confirm("Are you sure to save eob with Account Number " +$F('patient_account_id')+ " with last page as "+parseInt(page_to)+"?")
                if(agree == true){
                    flag = true;
                }
                else{
                    flag = false;
                    $('image_page_to_number').value = "";
                }
            }
        }
    }
    //console_logger('checkImagePageToNumberForProcView', flag);
    return flag;
}

//Provides an alert if the Image Pageto number is blank
//Provides an alert if image_page_to is different from from the saved value.
function checkImagePageToNumberForQaView(){
    previous_image_page_to_number = $F('previous_image_page_to_number');
    page_to = $F('image_page_to_number');
    page_from = $F('image_page_number');
    pt_acc_num = $F('patient_account_id');
    job_page_to = $F('pages_to');
    job_pages_from = $F('pages_from');
    if($F('image_page_to_number') == "" || parseInt(page_to) == 0){
        alert("Page To# should be greater than or equal to Page From#");
        $('image_page_to_number').value = "";
        $('image_page_to_number').focus();
        return false;
    }
    else{
        if(parseInt(page_to) == parseInt(previous_image_page_to_number) && (parseInt(page_to) > parseInt(page_from))){
            return true;
        }
        else{
            if(parseInt(page_to) < parseInt(page_from)){
                alert("Page To# should be greater than or equal to Page From#");
                return false;
            }
            else{
                if((parseInt(page_to) > parseInt(job_page_to)) || (parseInt(page_to) < parseInt(job_pages_from))){
                    alert("Invalid Page To#");
                    $('image_page_to_number').value = "";
                    $('image_page_to_number').focus();
                    return true;
                }
                else{
                    if(($F('image_page_to_number').match(image_page_number))){
                        var agree = confirm("Eob with Account Number " + $F('patient_account_id') + " was previously saved with " + parseInt(previous_image_page_to_number) + " as last page. Do you wish to change it to " + parseInt(page_to) + "?");
                        if(agree == true){
                            $('qa_save_eob_button_id').focus();
                            return true;
                        }
                        else{
                            $('image_page_to_number').value = "";
                            $('image_page_to_number').focus();
                            return false;
                        }
                    }
                    else{
                        alert("Invalid Page To#");
                        $('image_page_to_number').value = "";
                        $('image_page_to_number').focus();
                        return false;
                    }
                }
            }
        }
    }
}
//This is used for checking whether PageTo is less than Page From on QA view.
//This will be calling on click of SAVE EOB.
function checkPageTo(){
    var flag = true;
    if($('qa_view') != null){
        page_to = $F('image_page_to_number');
        page_from = $F('image_page_number');
        if(parseInt(page_to) < parseInt(page_from)){
            alert("Page To# should be greater than or equal to Page From#");
            flag = false;
        }
        else
            flag = true;
    }
    return flag;
}
// The function 'disablePageNumber' makes the Page# readonly field
function disablePageNumber(){
    $('image_page_number').readOnly = true
}

function changeOfImagePageNumber(){
    alert("Page# has been changed");
}

// The function 'setTransactionType' sets the Transaction Type based on selection in payer type dropdown box.
// If the Payer Type is 'PatPay', the Transaction Type is to be 'Patient Pay', else the default Transaction Type 'Complete EOB' is selected.
function setTransactionType() {
    var payerTypeObject = document.form1.payer_type;
    var getSelectedIndexOfPayerType = payerTypeObject.selectedIndex;
    var payerType = payerTypeObject[getSelectedIndexOfPayerType].value;
    var transactionTypeObject = document.form1.transaction_type;

    if(transactionTypeObject != null){
        var countOfOptionsOfTransactionType = transactionTypeObject.length;
        if(payerType == "PatPay") {
            for(j = 0; j < countOfOptionsOfTransactionType; j++) {
                if(transactionTypeObject[j].value == "Patient Pay") {
                    transactionTypeObject[j].selected = true;
                    patientDetailsSetBlankValue()
                    checkDetailsSetBlankValue()
                }
                else{
                    transactionTypeObject[j].disabled = true;
                }
            }
        }
        else{
            for(j=0; j<countOfOptionsOfTransactionType; j++) {
                transactionTypeObject[j].disabled = false;
                if(transactionTypeObject[j].value == "Complete EOB") {
                    transactionTypeObject[j].selected = true;
                }
            }
        }
    }
}

function setPayerTin(commercialPayerTin, patpayPayerTin){
    var payerTypeObject = document.form1.payer_type;
    var getSelectedIndex = payerTypeObject.selectedIndex;
    var payerType = payerTypeObject[getSelectedIndex].value;

    if($("payer_tin_id") != null){
        if(payerType == "PatPay") {
            $("payer_tin_id").value = patpayPayerTin
        }
        else{
            $("payer_tin_id").value = commercialPayerTin
        }
    }
}

function setValidationForTransactionTypeMissingCheck() {
    var transactionTypeObject = document.form1.transaction_type;
    if(transactionTypeObject != null) {
        var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
        if(transactionType == "Missing Check"){
            if(parseFloat($F('checkamount_id')) == 0.00){
                var item_ids = ["aba_routing_number_id", "payer_account_number_id"]
                removeCustomValidations(item_ids, "required")
                item_ids = ["checknumber_id"]
                removeCustomValidations(item_ids, "validate-nonzero-alphanum")
                removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
                removeCustomValidations(["checkdate_id"], "validate-check-date");

            }
        }
    }
}

// The function 'transactionTypePossibleValue' set alerts and values for the Transaction Type based on the conditions.
// The 'transaction_type_possible_value' contain the possible value for Transaction Type
function transactionTypePossibleValue(){
    var payerTypeObject = document.form1.payer_type;
    var getSelectedIndexOfPayerType = payerTypeObject.selectedIndex;
    var payerType = payerTypeObject[getSelectedIndexOfPayerType].value;
    var countOfOptionsOfPayerType = payerTypeObject.length;

    var transactionTypeObject = document.form1.transaction_type;
    var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
    var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
    var countOfOptionsOfTransactionType = transactionTypeObject.length;
    var any_eob_processed = ($('any_eob_processed') != null && $F('any_eob_processed') == "true");

    if(any_eob_processed){
        totalPaymentAmountCheck()   // This is not called when there are no saved EOBs
    }

    if((payerType != "PatPay") && (transactionType == "Patient Pay")){
        alert("The Payer Type is not 'PatPay', but the Image Type Chosen is 'Patient Pay'");
        for(j = 0; j < countOfOptionsOfPayerType; j++){
            if(payerTypeObject[j].value == "PatPay"){
                payerTypeObject[j].selected = true;
            }
        }
    }

    if((payerType == "PatPay") && (transactionType != "Patient Pay")){
        alert("The Payer Type is 'PatPay', but the Image Type Chosen is not 'Patient Pay'")
        for(j = 0; j < countOfOptionsOfTransactionType; j++) {
            if(transactionTypeObject[j].value == "Patient Pay") {
                transactionTypeObject[j].selected = true;
                patientDetailsSetBlankValue()
                checkDetailsSetBlankValue()
            }
            else{
                transactionTypeObject[j].disabled = true;
            }
        }
    }
    if((transactionType == "Correspondence") && $('aba_routing_number') &&
        $('payer_account_number') && $F('aba_routing_number') != "" &&
        $F('payer_account_number') != ""){
        alert("Image Type is chosen as 'Correspondence' but it has MICR Info, which makes the Image Type 'Complete EOB' ")
        for(j = 0; j < countOfOptionsOfTransactionType; j++){
            if(transactionTypeObject[j].value == "Complete EOB"){
                transactionTypeObject[j].selected = true;
                setValuesForTransactionTypeCompleteEob();
                if($('aba_routing_number_id') != null)
                    $('aba_routing_number_id').value = $F('aba_routing_number')
                if($('payer_account_number_id') != null)
                    $('payer_account_number_id').value = $F('payer_account_number')
            }
        }
    }
}

// The function 'transactionTypeDefaultValues' provide default values for passing the UI validations
function transactionTypeDefaultValues(){
    var transactionTypeObject = document.form1.transaction_type;
    var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
    var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
    if(transactionType == "Correspondence"){
        removeAllServiceLines()
        patientDetailsSetDefaultValue()
        checkDetailsSetDefaultValue()
        getImagePage()                     // The image_page_no of the EOB is set where Patient Account No is set by default value.
        ServiceLineHideOrShow()
    }
    if(transactionType == "Check Only"){
        if(parseFloat($F('checkamount_id')) > 0.00){
            removeAllServiceLines()
            patientDetailsSetDefaultValue()
            checkDetailsSetBlankValue()
            getImagePage()                    // The image_page_no of the EOB is set where Patient Account No is set by default value.
            ServiceLineHideOrShow()
        }
        else{
            alert("Check amount is not greater than $0, so the Image Type cannot be 'Check Only'")
        }
    }
    if(transactionType == "Missing Check"){
        if(parseFloat($F('checkamount_id')) == 0.00){
            setValuesForTransactionTypeMissingCheck();
        }
        else{
            alert("Check amount is not $0, so the Image Type cannot be 'Missing Check'")
        }
    }
    if(transactionType == "Patient Pay"){
        setValuesForTransactionTypePatPay();
    }
    if(transactionType == "Complete EOB"){
        setValuesForTransactionTypeCompleteEob();
    }
}

function setValuesForTransactionTypeCompleteEob() {
    patientDetailsSetBlankValue();
    checkDetailsSetBlankValue();
    ServiceLineHideOrShow();
}

function setValuesForTransactionTypeMissingCheck() {
    patientDetailsSetBlankValue();
    checkDetailsSetDefaultValue();
    ServiceLineHideOrShow();
}

function setValuesForTransactionTypePatPay() {
    if($('transaction_type_config') != null && $F('transaction_type_config') == 'true' &&
        $F('tab_type') == "Patient"){
        patientDetailsSetBlankValue();
        checkDetailsSetBlankValue();
        ServiceLineHideOrShow();
        var checkNumberConditionForCorrespondence = $F('checknumber_id').strip() == '' ||
        parseInt($F('checknumber_id')) == 0;
        var checkAmountConditionForCorrespondence = $F('checkamount_id').strip() == '' ||
        parseFloat($F('checkamount_id')) == 0;
        if(checkNumberConditionForCorrespondence && checkAmountConditionForCorrespondence) {
            //console_logger(' correspondence', 'correspondence');
            var item_ids = ["checknumber_id", "checkamount_id", "checkdate_id",  "aba_routing_number_id", "payer_account_number_id"];
            removeCustomValidations(item_ids, "required");
            removeCustomValidations(["checknumber_id"], "validate-nonzero-alphanum");
            removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
            removeCustomValidations(["checkdate_id"], "validate-check-date");
        }
    }
}
// The function 'patientDetailsSetDefaultValue' populate the default values in Patient Details field to pass the the UI validations.
function patientDetailsSetDefaultValue(){
    $('patient_last_name_id').value = "UNKNOWN"
    $('patient_first_name_id').value = "UNKNOWN"
    $('subcriber_last_name_id').value = "UNKNOWN"
    $('subcriber_firstname_id').value = "UNKNOWN"
    $('patient_account_id').value = "0"
    $('total_service_balance_id').value = "0.00"
    $('patient_last_name_id').readOnly = true
    $('patient_first_name_id').readOnly = true
    $('subcriber_last_name_id').readOnly = true
    $('subcriber_firstname_id').readOnly = true
    $('patient_account_id').readOnly = true
}

// The function 'checkDetailsSetDefaultValue' populate the default values in Check Details field to pass the the UI validations.
function checkDetailsSetDefaultValue(){
    if($("transaction_type") != null){
        var transactionTypeObject = document.form1.transaction_type;
        var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
        var item_ids;
        $('payer_id').value = $F('default_payer_id');

        if($F('payer_popup').toUpperCase() != $F('default_payer_name').toUpperCase())
            $('payer_popup').value = $F('default_payer_name')
        if($F('payer_pay_address_one').toUpperCase() != $F('default_payer_add_one').toUpperCase())
            $('payer_pay_address_one').value = $F('default_payer_add_one')
        if($F('payer_address_two').toUpperCase() != $F('default_payer_add_two').toUpperCase())
            $('payer_address_two').value = $F('default_payer_add_two')
        if($F('payer_city_id').toUpperCase() != $F('default_payer_city').toUpperCase())
            $('payer_city_id').value = $F('default_payer_city')
        if($F('payer_payer_state').toUpperCase() != $F('default_payer_state').toUpperCase())
            $('payer_payer_state').value = $F('default_payer_state')
        if($F('payer_zipcode_id') != $F('default_payer_zip'))
            $('payer_zipcode_id').value = $F('default_payer_zip')
        if(transactionType == "Missing Check"){
            $('payer_id').value = ""
            $('payer_popup').value = ""
            $('payer_pay_address_one').value = ""
            $('payer_address_two').value = ""
            $('payer_city_id').value = ""
            $('payer_payer_state').value = ""
            $('payer_zipcode_id').value = ""
        }
        if($('checkdate_id').value != "01/01/00")
            $('checkdate_id').value = "01/01/00"
        if($('checknumber_id').value != "0")
            $('checknumber_id').value = "0"
        if($('checkamount_id').value != "0.00" || $('checkamount_id').value != "0.0" || $('checkamount_id').value != "0")
            $('checkamount_id').value = "0.00"
        if($('aba_routing_number_id') != null)
            $('aba_routing_number_id').value = ""
        if($('payer_account_number_id') != null)
            $('payer_account_number_id').value = ""

        // By bassing the validations by changing the element's class attribute
        item_ids = ["aba_routing_number_id", "payer_account_number_id"]
        removeCustomValidations(item_ids, "required")
        item_ids = ["checknumber_id"]
        removeCustomValidations(item_ids, "validate-nonzero-alphanum")
        removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");

        $('payer_popup').readOnly = true
        $('payer_pay_address_one').readOnly = true
        $('payer_address_two').readOnly = true
        $('payer_city_id').readOnly = true
        $('payer_payer_state').readOnly = true
        $('payer_zipcode_id').readOnly = true
        if(transactionType == "Missing Check"){
            $('payer_popup').readOnly = false
            $('payer_pay_address_one').readOnly = false
            $('payer_address_two').readOnly = false
            $('payer_city_id').readOnly = false
            $('payer_payer_state').readOnly = false
            $('payer_zipcode_id').readOnly = false
        }

        $('checkdate_id').readOnly = true
        $('checknumber_id').readOnly = true
        $('checkamount_id').readOnly = true
        if($('aba_routing_number_id') != null)
            $('aba_routing_number_id').readOnly = true
        if($('payer_account_number_id') != null)
            $('payer_account_number_id').readOnly = true
    }
}

// The function 'patientDetailsSetBlankValue' populate the blank values in Patient Details field to pass the the UI validations.
function patientDetailsSetBlankValue(){
    if($F('patient_last_name_id').toUpperCase() == "UNKNOWN")
        $('patient_last_name_id').value = ""
    if($F('patient_first_name_id').toUpperCase() == "UNKNOWN")
        $('patient_first_name_id').value = ""
    if($F('subcriber_last_name_id').toUpperCase() == "UNKNOWN")
        $('subcriber_last_name_id').value = ""
    if($F('subcriber_firstname_id').toUpperCase() == "UNKNOWN")
        $('subcriber_firstname_id').value = ""
    if($F('patient_account_id') == "0")
        $('patient_account_id').value = ""
    total_service_balance = parseFloat($F('total_service_balance_id'))
    if($F('total_service_balance_id') != "" && total_service_balance != 0.00)
        $('total_service_balance_id').value = ""

    $('total_service_balance_id').readOnly = true        // total_service_balance_id is readonly by default
    $('patient_last_name_id').readOnly = false
    $('patient_first_name_id').readOnly = false
    $('subcriber_last_name_id').readOnly = false
    $('subcriber_firstname_id').readOnly = false
    $('patient_account_id').readOnly = false
}

// The function 'checkDetailsSetBlankValue' populate the blank values in Check Details field to pass the the UI validations.
function checkDetailsSetBlankValue(){
    if($F('payer_id') == $F('default_payer_id')){
        $('payer_id').value = ""
        $('payer_popup').value = ""
        $('payer_pay_address_one').value = ""
        $('payer_address_two').value = ""
        $('payer_city_id').value = ""
        $('payer_payer_state').value = ""
        $('payer_zipcode_id').value = ""
    }
    if($F('checkdate_id') == "01/01/00")
        $('checkdate_id').value = ""
    if($F('checknumber_id') == "0")
        $('checknumber_id').value = ""
    if($F('checkamount_id') == "0.00" || $F('checkamount_id') == "0.0" || $F('checkamount_id') == "0")
        $('checkamount_id').value = ""

    // By bassing the 'required' validation by changing the element's class attribute
    var item_ids = ["aba_routing_number_id", "payer_account_number_id", 'checkdate_id', 'checknumber_id', 'checkamount_id']
    setFieldsValidateAgainstCustomMethod(item_ids, "required");

    $('payer_popup').readOnly = false
    $('payer_pay_address_one').readOnly = false
    $('payer_address_two').readOnly = false
    $('payer_city_id').readOnly = false
    $('payer_payer_state').readOnly = false
    $('payer_zipcode_id').readOnly = false
    $('checkdate_id').readOnly = false
    $('checknumber_id').readOnly = false
    $('checkamount_id').readOnly = false
    if($('aba_routing_number_id') != null)
        $('aba_routing_number_id').readOnly = false
    if($('payer_account_number_id') != null)
        $('payer_account_number_id').readOnly = false
}

// The function 'ServiceLineHideOrShow' hides/clears or shows the 'Add Row' & 'Adjustment Line', through which only we can save a service line.
function ServiceLineHideOrShow(){
    var transactionTypeObject = document.form1.transaction_type;
    if(transactionTypeObject != null){
        var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
        hide_service_line = ($('transaction_type') && ((transactionType == "Check Only") ||
            (transactionType == "Correspondence")));
        if(hide_service_line){
            Element.hide('adjustment_line')
        }
        else{
            Element.show('adjustment_line')
        }
        disableServiceLine()
    }
}

// The function 'disableServiceLine' clears the 'ADD Row' so that no service lines can be added.
function disableServiceLine(){
    var transactionTypeObject = document.form1.transaction_type;
    if(transactionTypeObject != null){
        var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
        clear_service_line = ($('transaction_type') && ((transactionType == "Check Only") ||
            (transactionType == "Correspondence")))
        if(clear_service_line){
            cleardata()
        }
    }
}


// The function 'totalPaymentAmountCheck' makes the Transaction Type 'Complete EOB' if the Payment dollar amount for the job/check sums to 0, else 'Missing Check'
function totalPaymentAmountCheck()
{
    if($('transaction_type') != null){
        var transactionTypeObject = document.form1.transaction_type;
        var getIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getIndexOfTransactionType].value;
        var countOfOptionsOfTransactiontype = transactionTypeObject.length;

        var payerTypeObject = document.form1.payer_type;
        var getSelectedIndexOfPayerType = payerTypeObject.selectedIndex;
        var payerType = payerTypeObject[getSelectedIndexOfPayerType].value;
        job_payment_so_far = parseFloat($F('job_payment_so_far'))
        eob_payment = parseFloat($F('total_payment_id'))
        var isAnyEobProcessed = $F('any_eob_processed');
        var userIsProcessor = $F('user_role_is_processor');
        var transactionTypeDisableCondition = (isAnyEobProcessed == "true" && userIsProcessor == "true");

        // total_payment_amount_so_far in 'Processor view' calculated by the saved payment amount for the job plus the payment added for the current EOB.
        total_payment_amount_so_far = job_payment_so_far + eob_payment

        if($('qa_view') != null){
            // For updation view the calulation of total_payment_amount_so_far is (saved payment amount for the job - the given EOB's saved 'payment amount' + the payment of the given EOB in UI)
            saved_eob_payment = parseFloat($F('saved_eob_payment'))
            total_payment_amount_so_far = job_payment_so_far - saved_eob_payment + eob_payment
        }
        total_payment_amount_so_far = parseFloat(total_payment_amount_so_far)
        // If the Payment dollar amount for the job/check sums to 0 then even if the Transaction Type is 'Missing Check', the Transaction Type is changed to 'Complete EOB'
        if(total_payment_amount_so_far == 0.00){
            $('transaction_type_possible_value').value = "Complete EOB"
            var possible_candidate_complete_eob = ((payerType != "PatPay") &&
                $F('transaction_type_possible_value') == "Complete EOB" &&
                (transactionType == "Missing Check"))
            if(possible_candidate_complete_eob){
                alert("The Payment dollar amount for the job sums to 0, the possible candidate for Image Type is 'Complete EOB'  ")
                for(j = 0; j < countOfOptionsOfTransactiontype; j++){
                    if(transactionTypeObject[j].value == "Complete EOB"){
                        if(transactionTypeDisableCondition)
                            transactionTypeObject.disabled = true;
                        else
                            transactionTypeObject.disabled = false;

                        transactionTypeObject[j].selected = true;
                        var item_ids = ["aba_routing_number_id", "payer_account_number_id"];
                        removeCustomValidations(item_ids, "required");
                        removeCustomValidations(["checknumber_id"], "validate-nonzero-alphanum");
                        removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
                        removeCustomValidations(["checkdate_id"], "validate-check-date");
                    }
                }
            }
        }
        // If the Check Details if of default values(like checkamount & checknumber are 0) & Payment dollar amount for the job/check sums to > 0 and
        // if the Transaction Type is 'Complete EOB', the Transaction Type is changed to 'Missing Check'
        else if(total_payment_amount_so_far > 0.00){
            var possible_candidate_missing_check = ((payerType != "PatPay") &&
                (transactionType == "Complete EOB") &&
                ($F('checknumber_id') == "0" &&($F('checkamount_id') == "0.00" || $F('checkamount_id') == "0.0" || $F('checkamount_id') == "0")))
            if(possible_candidate_missing_check){
                alert("The Payment dollar amount for the job sums to greater than 0, the possible candidate for Image Type is 'Missing Check'  ")
                for(j = 0; j < countOfOptionsOfTransactiontype; j++){
                    if(transactionTypeObject[j].value == "Missing Check"){
                        if(transactionTypeDisableCondition)
                            transactionTypeObject.disabled = true;
                        else
                            transactionTypeObject.disabled = false;


                        transactionTypeObject[j].selected = true;
                        item_ids = ["aba_routing_number_id", "payer_account_number_id"];
                        removeCustomValidations(item_ids, "required");
                        removeCustomValidations(["checknumber_id"], "validate-nonzero-alphanum");
                        removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
                        removeCustomValidations(["checkdate_id"], "validate-check-date");
                    }
                }
            }
        }
    }
//console_logger('totalPaymentAmountCheck', true);
}

// The function 'amountCheck' aims at providing a confirmation box to all
//  $amount fields( alias 'Fields')(have class as 'amount') if
//  each of them have amount >= $10,000 on 'change' & 'double click' event of the 'Fields'.
// If the user does not confirm it, the background color of 'Fields' changes to
//  red color, else yellow color.
// The following methods are called which will provide the confirmation box and
// color coding in the respective scenario.
// If the amount is >= $10,000 : 'verifyLargeAmount'
//  else : 'verifySmallAmount'
function amountCheck(amount_id){
    var amount = $F(amount_id);
    if(parseFloat(amount) >= 10000){
        verifyLargeAmount(amount_id);
    }
    else if(parseFloat(amount) < 10000 || amount == ""){
        verifySmallAmount(amount_id);
    }
}

// The function 'verifyLargeAmount' aims at providing a confirmation box to all
// $amount fields( alias 'Fields')(have class as 'amount') if
//  each of them have amount >= $10,000.
// This is called on 'change' & 'double click' event of the 'Fields'.
// If the user does not confirm it, the background color of 'Fields' changes to
//  red color(class 'normalized_uncertain'), else yellow color(class 'edited').
// This is called if the amount of each of the 'Fields' is >= $10,000.
function verifyLargeAmount(amount_field_id){
    var agree = confirm("Are you sure that the amount is above $10000.00");
    if(agree == true){
        // Confirmed that the 'Field' can have amount >= $10,000.
        setHighlight([amount_field_id], "edited");
    }
    else{
        // Confirmed that the 'Field' cannot have amount >= $10,000.
        setHighlight([amount_field_id], "normalized_uncertain");
        // Focus is set to the 'Field' to re-enter.
        $(amount_field_id).focus();
    }
}

// The function 'verifySmallAmount' aims at providing a confirmation box to
//  all $amount fields( alias 'Fields')(have class as 'amount') if
//  each of them have amount < $10,000.
// This is called on 'change' & 'double click' event of the 'Fields'.
// This resets the color to white(class 'blank')
function verifySmallAmount(amount_field){
    // Resetting color to white if the amount < $10,000.
    var class_names  = $(amount_field).className.split(' ')
    if(class_names.include('blue-color')){
        setHighlight([amount_field], "blue-color");
    }
    else{
        setHighlight([amount_field], "blank");
    }
}

// The function 'amountCheckForLargeSum' aims at providing a confirmation box to
//  all $amount fields( alias 'Fields') if any of them have amount >= $10,000.
// If the user does not confirm it, the background color of 'Fields' changes
// to red color(class 'normalized_uncertain'), else yellow color(class 'edited').
// The function 'amountCheckForLargeSum' provides a confirmation box while
//  saving an EOB that gives the total count of 'Fields' having background color red,
//   indicating that the user has not confirmed that the 'Fields' are
//    having correct amount if its >= $10,000.
// The variable 'large_sum_fields' stores the total count of 'Fields' having
//  background color red, indicating that the user has not confirmed that
//   the 'Fields' are having correct amount if its >= $10,000.
function amountCheckForLargeSum(){
    var large_sum_fields = $$(".normalized_uncertain").length;
    var bAgree = true;
    if(large_sum_fields > 0){
        // Firing the confirmation if there are 'Fields' >= $10,000 and not confirmed
        bAgree = confirm(large_sum_fields + "field(s) with amount greater than $10,000 highlighted in 'Red'");
    }
    //console_logger('amountCheckForLargeSum', bAgree);
    return bAgree;
// Only if agree is true the EOB is able to save.
}

// The function 'amountCheckForLargeSumInAddRow' aims at providing a
// confirmation box to all $amount fields( alias 'Fields') in the 'Add Row' if
//  any of them have amount >= $10,000.
// If the user does not confirm it, the background color of 'Fields' changes to
// red color(class 'normalized_uncertain'), else yellow color(class 'edited').
// The function 'amountCheckForLargeSumInAddRow' provides a confirmation box while
//  saving an EOB that gives the total count of 'Fields' having background color red,
//  indicating that the user has not confirmed that the 'Fields' are
//  having correct amount if its >= $10,000.
// The variable 'large_sum_fields' stores the total count of 'Fields' having
// background color red, indicating that the user has not confirmed that
// the 'Fields' are having correct amount if its >= $10,000.
function amountCheckForLargeSumInAddRow(){
    var large_sum_fields = 0;
    var amount_field_id;
    // All the amount fields in 'Add Row'
    var amount_ids = ["charges_id", "allowable_id", "payment_id", "drg_amount_id",
    "expected_payment_id", "non_covered_id", "denied_id", "discount_id",
    "co_insurance_id", "deductable_id", "copay_id", "primary_pay_payment_id",
    "prepaid_id", "contractualamount_id", "retention_fees_id", "patient_responsibility_id",
    "miscellaneous_one_id", "miscellaneous_two_id", "miscellaneous_balance_id"];
    var bAgree = true;
    for(amt_cnt = 0; amt_cnt < amount_ids.length; amt_cnt++){
        amount_field_id = amount_ids[amt_cnt];
        if($(amount_field_id) != null){
            class_name =$(amount_field_id).className.split(' ');
            len = class_name.length;
            if( class_name[len - 1] == "normalized_uncertain" &&
                $F(amount_field_id) >= 10000){
                large_sum_fields += 1;
            }
        }
    }
    if(large_sum_fields > 0){
        // Firing the confirmation if there are 'Fields' >= $10,000 and not confirmed
        bAgree = confirm(large_sum_fields + "field(s) with amount greater than $10,000 highlighted in 'Red'");
    }
    // Resetting color of 'Add Row' to white after adding the row.
    if(bAgree == true){
        for(amt_cnt = 0; amt_cnt < amount_ids.length; amt_cnt++){
            amount_field_id = amount_ids[amt_cnt];
            if($(amount_field_id) != null){
                verifySmallAmount(amount_field_id);
            }
        }
    }
    return bAgree;
// Only if bAgree is true the Add Row service line can be addded.
}

// The function 'isPatientThePayer' provides an  alert that the EOB has to be
//  indexed in the Patient Pay Grid
// Condition for alert : Patient name = Payer name &&
// PatPay format set in FC = "Simplified Format" &&
// the current Tab Type = "Insurance".
// It will form the Patient full name from different patient name
// related fields by the help of a function 'insertToArray'
function isPatientThePayer(){
    var patient_name = [];
    var bAgree = true;
    // The function 'insertToArray' takse an array and a value as inputs.
    // If the value is not blank, the value is inserted to the array and returns the array.
    patient_name = insertToArray(patient_name, $F('patient_first_name_id'))
    patient_name = insertToArray(patient_name, $F('patient_initial_id'))
    patient_name = insertToArray(patient_name, $F('patient_last_name_id'))
    patient_name = insertToArray(patient_name, $F('patient_suffix_id'))
    patient_name =  patient_name.join(' ');
    if(patient_name != "" && $F('patient_pay_format') == "Simplified Format" &&
        $F('payer_popup') == patient_name && $F('tab_type') == "Insurance"){
        alert("As Payer Name matches the Patient Name, this check belongs to Patpay.\n\
        Please continue processing in the Patpay grid.")
        bAgree = false;
    }
    if($('eob_balance_record_type') != null && $F('eob_balance_record_type') != '')
        bAgree = true;
    //console_logger('isPatientThePayer', bAgree);
    return bAgree;

}

// The function 'shouldCommercialPayerExist' provides an alert when
// a new payer is entered,
//  if the Commecial payid is not set in FC.
function shouldCommercialPayerExist(){
    var payerTypeObject = document.form1.payer_type;
    var getIndexOfPayerType = payerTypeObject.selectedIndex;
    var payerType = payerTypeObject[getIndexOfPayerType].value;
    var defaultPayerId;

    if($('default_payer_id') != null){
        defaultPayerId = $F('default_payer_id')
    }
    else{
        // Providing a non-existing scenario to make the payer_id never
        //  equals to default_payer_id
        defaultPayerId = -1
    }
    var bAgree = true;
    if($F('payer_popup') != "" && $('commercial_payerid') == null && payerTypeObject != null &&
        (payerType != "PatPay") && ( $F('payer_id') == "" || $F('payer_id') == "undefined" ||
            $F('payer_id') == defaultPayerId)){
        alert("Invalid Payer info.\n\
         New Payer can't be entered since the Commercial Payer is not set for this Lockbox.")
        bAgree = false;
    }
    //console_logger('shouldCommercialPayerExist', bAgree);
    return bAgree;

}

//For the PatPay grid, the MICR data fields are made mandatory.
function setFieldsMandatoryForPatpay(){
    if($('tab_type')){
        if($F('tab_type') == 'Patient'){
            var item_ids = ["service_procedure_charge_amount_id1"];
            if($('correspondence_batch') != null && $F('correspondence_batch') == "false") {
                item_ids.push("aba_routing_number_id", "payer_account_number_id");
            }
            if($('reference_code_mandatory_status') != null &&
                $F('reference_code_mandatory_status') == 'true')
                item_ids.push("provider_control_number_1");
            if($('payment_type_id') != null) {
                if($('check_information_payment_method') != null ) {
                    if($F('check_information_payment_method') == 'CHK') {
                        item_ids.push("payment_type_id");
                    }
                    else
                        removeCustomValidations(["payment_type_id"], "required");
                }
                else {
                    var nonCorrespondenceCheckCondition = ($('correspondence_check') != null && $F('correspondence_check') == "false");
                    if(nonCorrespondenceCheckCondition) {
                        item_ids.push("payment_type_id");
                    }
                }
            }

            setFieldsValidateAgainstCustomMethod(item_ids, "required");
        }
    }
}

// function for processing interest only check
function interestOnlyCheck(clientName){
    //console_logger('interestOnlyCheck', 'interestOnlyCheck');
    if(clientName){
        if(clientName.toLowerCase() == 'quadax') {
            var checkAmount = isNaN(parseFloat($F('checkamount_id')))? 0 : parseFloat($F('checkamount_id'));
            if($('interest_id') != null && $('total_existing_number_of_svc_lines') != null){
                var interestAmount = isNaN(parseFloat($F('interest_id')))? checkAmount + 1 : parseFloat($F('interest_id'));
                var tbl = document.getElementById('service_line_details');
                if(checkAmount == interestAmount &&
                    ($F('total_existing_number_of_svc_lines') == 1) ){
                    var status = confirm("do you want to process this as interest only check?");
                    if (status == true){
                        needToValidateAdjustmentLine = false;
                        if($F('claim_level_eob') == 'true'){
                            var elements = tbl.rows[3].getElementsByTagName('input')
                            for(i = 0; i < elements.length; i++ ){
                                if (elements[i].type != 'hidden')
                                    elements[i].value = ''
                            }
                            $('total_service_balance_id').value = '0.00'
                            return true;
                        }
                        else{
                            removeAllServiceLines();
                            $('total_service_balance_id').value = '0.00';
                            return true;
                        }
                    }
                    else{
                        $('total_service_balance_id').value = '';
                        $('interest_id').focus();
                        return false;
                    }
                }
                else return true;
            }
            else return true;
        }
        else return true;
    }
    else return true;
}

function setValuesForEobSaveOnProcView() {
    setImagePageToNumber();
    checkImagePageToNumberForProcView();
    setValuesForEobSave();
}

function setValuesForEobSaveOnQaView() {
    setValuesForEobSave();
}

function setValuesForEobSave() {
    var payment_method_flag =  isValidPaymentMethod();
    setTotalEditedFields();
    setValidationForFields();
    if (payment_method_flag)
        setValidationForPaymentMethod();
    setValidationForTransactionTypeMissingCheck();
    checkEobPage();
    totalPaymentAmountCheck();
    setDefaultValuesForPatpay();
    setServiceLineSerialNumbers();
    setClaimLevelServiceLineSerialNumbers();
}

// Cascaded call of methods which are necessary to pass all the validations in the DataCapture Grid
function mustPassValidations(clientName){

    var payment_method_flag =  isValidPaymentMethod();
    var validationsResult = false;
    var stringOfIdsOfPayerDetails = "'',payer_popup,payer_pay_address_one,payer_city_id,payer_payer_state,payer_zipcode_id";
    var patientStmtFldsPresent = document.getElementById('patient_stmt_flds_present').value;

    validationsResult = (checkJobAllocationQueue() && validateTabType() && validateLengthOfPayeeNpi() &&
        validateLengthOfPayeeTin() &&validateNpiTinAgainstFacility() &&
        validateAccountNumberForMoxpPatpayGrid() && validateCheckWithInterestEob()&&
        alertForValidPaymentMethod() && negativeValidationForCheckAmount() &&
        validatePresenceOfUniqueCodeForOrphanAdjustmentAmount() &&
        validatePresenceOfAdjustmentAmountForOrphanUniqueCode() && validateProviderDetails() &&
        validatePayerDetails(stringOfIdsOfPayerDetails) &&
        validatePartiallyEnteredAddRow() && confrimHipaaCodes($$(".validate-confirm-hippa-code")) &&
        setPaymentMethodInRelationToMicr() &&
        confirmProcedureCodeIsEmpty() && confirmClaimLevelServiceLineIsEmpty() &&
        checkAccountNumberPrefix('patient_account_id') &&
        validateRumcAccountNumberPrefix('patient_account_id') &&
        checkAccountNumberPrefixForQuadaxFacilities() && validateNextgenAccountNumber() &&
        validateAccountNumberForChoc('patient_account_id') &&
        checkQualifier('patient_identification_code_id','qualifier') &&
        validateCheckDetailsWithValueOfPaymentMethod(payment_method_flag) &&
        interestOnlyCheck(clientName) &&  validateAllCptCodes() &&
        claimBalanceCheck() && amountCheckForLargeSum() && isValidAccNum() &&
        allowedAmountValidationMpi() && allowedAmountValidationClaimLevel() && allowedAmountValidationWithChargeOnMpi() &&
        validateRejectionComment() && validateClaimNumber() &&
        isAbaValid('aba_routing_number_id', '') &&
        isPayerAccNumValid('payer_account_number_id', '') &&
        validateTotalFields() && validateEobCorrectness() && checkPageTo() &&
        validatePresenceofPayeeNpiAndTin() && validateDenialServiceLineForUpmcOnSave());

    if(patientStmtFldsPresent == 'true'){
        validationsResult = validationsResult && validateAccNumWithImage() &&
        validateEobWithDiscount();
    }

    if ($('tab_type')) {
        if ($F('tab_type') == 'Insurance') {
            validationsResult = validationsResult &&
            shouldCommercialPayerExist() &&
            isPatientThePayer() &&
            payerTypeMandatory() &&
            validateTransactionType() &&
            validateAllRemarkCodes() &&
            validateAdjustmentLineCount() &&
            validateAdjustmentLine() &&
            validateModificationForInterestEob() &&
            confirmPayerIndicator() &&
            checkQualifierSave('patient_identification_code_id','qualifier') &&
            validatePatientName('patient_last_name_id','patient_first_name_id',
                'patient_initial_id', 'patient_suffix_id', 'provider_provider_last_name',
                'prov_firstname_id', 'prov_initial_id', 'prov_suffix_id' )

            if($F('medical_record_number_status') == "true")
                validationsResult = validationsResult && validateAlphaNumeric('medical_record_number_id') ;
        }
    }
    //console_logger(validationsResult, 'mustPassValidations');
    if(validationsResult)
        return true;
    else
        return false;
}

// Provides the alert for the Payer Type
function payerTypeMandatory(){
    var bAgree = true;
    var payerTypeObject = document.form1.payer_type;
    var countOfOptionsOfPayerType = payerTypeObject.length;
    var getIndexOfPayerType = payerTypeObject.selectedIndex;
    var payerType = payerTypeObject[getIndexOfPayerType].value;

    if($("payer_popup").value != ""){
        if( payerType == "--" && countOfOptionsOfPayerType > 1){
            var valPayerId = $("payer_id").value
            if(valPayerId == "undefined" || valPayerId == "null" || valPayerId.length == 0) {
                alert("Select Payer Type");
                payerTypeObject.focus();
                bAgree = false;
                $("payer_id").value = null
            }
        }
        else
            bAgree = true;
    }
    //console_logger('payerTypeMandatory', bAgree);
    return bAgree;
}

//showing rejection comment drop down list for quadax for QA view
function visible_comment(){
    var status = $F('status')
    if(status == "Incomplete"){
        $('complete_comment_text_area').style.display = "none";
        $('incomplete_comment_text_area').style.display = "block";
    }
    else{
        $('complete_comment_text_area').style.display = "block";
        $('incomplete_comment_text_area').style.display = "none";
    }
    $('rejection_comment_ddlist').style.visibility = "hidden";
}


// check presence of comment in comment text box for QA view
function check_comment(){
    var validation = true
    removeRequiredForCheckMailedAndReceivedDate();
    if($F('status') == "Incomplete"){
        var comment = $F('incomplete_processor_comment').trim();
        var comment = $F('incomplete_processor_comment').trim();
        if(comment == null || comment == "comment" || comment == "" || comment == "--" )
        {
            alert("Please Enter Comment");
            $('incomplete_processor_comment').focus();
            validation = false;
       

        }
    }
    return validation
}

//function for clearing total balance in case of interest payment checks
function clearBalance(){
    if($('interest_id') != null && $('client_type') != null) {
        clientName = $F('client_type');
        if(clientName.toUpperCase() == 'QUADAX' && parseFloat($F('checkamount_id')) == parseFloat($F('interest_id')))
            $('total_service_balance_id').value = '0.00';
        else
            setTotalBalance($F('total_service_balance_id'));
    }
}

// For Merit Mountainside, patient acc num has to be min. 5 char long
// 7 char long acc nums are missing the cycle num '00' prefix
function isValidAccNum(){
    //console_logger('isValidAccNum', 'isValidAccNum');
    if ( $('facility') != null && $F('facility').toUpperCase() == 'MERIT MOUNTAINSIDE' ){
        if ( $F('patient_account_id').length < 5 ){
            setTimeout(function() {
                $('patient_account_id').focus();
            }, 10);
            alert("Account number must contain at least 5 digits!");
            return false;
        }
        else if( $F('patient_account_id').length < 7 ) {
            response = confirm("Account number should contain 7 digits. Are you sure?")
            if (response == false) {
                setTimeout(function() {
                    $('patient_account_id').focus();
                }, 10);
            }
            return response
        }
        else
            return true;
    }
    else
        return true;
}

function validateTransactionType(){
    var tabTypeValue;
    if(parent.myiframe != "undefined" && parent.myiframe != null &&
        parent.myiframe.document.getElementById('tab_type') != null) {
        tabTypeValue = parent.myiframe.document.getElementById('tab_type').value;
    }
    else {
        tabTypeValue = $F('tab_type');
    }
    if(tabTypeValue == 'nextgen'){
        return true;
    }
    else{
        var validation = (validateForMissingCheck() && validateForCheckOnly());
        //console_logger('validateTransactionType', validation);
        return validation;
    }
}

function validateForMissingCheck(){
    var bAgree = true;
    var transactionType;
    var checkAmount;
    if($("transaction_type") != null) {
        transactionType = $("transaction_type");
    }
    else if(parent.myiframe  != "undefined" && parent.myiframe  != null &&
        parent.myiframe.document.getElementById('transaction_type') != null) {
        transactionType = parent.myiframe.document.getElementById('transaction_type');
    }
    else
        transactionType = null;
    if($("checkamount_id") != null) {
        checkAmount = $("checkamount_id");
    }
    else if(parent.myiframe.document.getElementById('checkamount_id') != null) {
        checkAmount = parent.myiframe.document.getElementById('checkamount_id');
    }
    else
        checkAmount = null;

    if(transactionType != null && checkAmount != null) {
        var condition = (transactionType &&
            $F(transactionType) == "Missing Check" &&
            parseFloat($F(checkAmount)) > 0)
        if(condition == true){
            bAgree = false;
            alert("Check amount is not $0, so the Image Type cannot be 'Missing Check'");
        }
    }
    return bAgree;
}

function validateForCheckOnly(){
    var bAgree = true;
    var transactionType;
    var checkAmount;

    if($("transaction_type") != null) {
        transactionType = $("transaction_type");
    }
    else if(parent.myiframe  != "undefined" && parent.myiframe  != null &&
        parent.myiframe.document.getElementById('transaction_type') != null) {
        transactionType = parent.myiframe.document.getElementById('transaction_type');
    }
    else
        transactionType = null;

    if($("checkamount_id") != null) {
        checkAmount = $("checkamount_id");
    }
    else if(parent.myiframe.document.getElementById('checkamount_id') != null) {
        checkAmount = parent.myiframe.document.getElementById('checkamount_id');
    }
    else
        checkAmount = null;

    if(transactionType != null && checkAmount != null) {
        if(transactionType && $F(transactionType) == "Check Only"){
            if(parseFloat($F(checkAmount)) > 0){
                bAgree = true;
            }
            else{
                bAgree = false;
                alert("Check amount is not greater than $0,\n\
                    so the Image Type cannot be 'Check Only'");
            }
        }
    }
    return bAgree;
}

function validateTwiceKeyingForAllFields(){
    var resultOfValidation = true;
    if($('twice_keying_fields') != null && $('twice_keying_prev_values_of_all_fields') != null) {
        var twice_keying_fields = $F('twice_keying_fields').trim();
        if(twice_keying_fields != '') {
            var allFields = $$('input:text', 'select');
            var elementsToAvoid = [];
            var allFieldIds = [];
            var fieldIds;

            for(i = 0; i < allFields.length; i++) {
                allFieldIds.push(allFields[i].id);
            }

            if($('adding_row') != null) {
                var addRowElements = document.querySelectorAll("#adding_row input[type=text]");
                for(i = 0; i < addRowElements.length; i++) {
                    elementsToAvoid.push(addRowElements[i].id);
                }
            }
            if($('provider_adjustment_grid_container') != null) {
                var provider_adjustment_elements = document.querySelectorAll("#provider_adjustment_grid_container input[type=text]");
                var select_elements = document.querySelectorAll("#provider_adjustment_grid_container select");
                provider_adjustment_elements = Array.prototype.slice.call(provider_adjustment_elements)
                for(var i = 0; i < select_elements.length; i++) {
                    provider_adjustment_elements.push(select_elements[i]);
                }
                for( i = 0; i < provider_adjustment_elements.length; i++) {
                    elementsToAvoid.push(provider_adjustment_elements[i].id);
                }
            }

            if(elementsToAvoid.length > 0) {
                fieldIds = arrayElementsWithoutElementsFromAnotherArray(allFieldIds, elementsToAvoid);
            }

            var previous_value =  $F('twice_keying_prev_values_of_all_fields');
            var returnValue  = validateTwiceKeyingFields(fieldIds, previous_value);
            resultOfValidation = returnValue[0];
            var nameValuePairArray = returnValue[1];
            $('twice_keying_prev_values_of_all_fields').value = nameValuePairArray;
        }
    }
    return resultOfValidation;
}

function validateTwiceKeyingForAddServiceLine(){
    var resultOfValidation = true;
    if($('twice_keying_fields') != null && $('twice_keying_prev_values_of_add_row') != null) {
        var twice_keying_fields = $F('twice_keying_fields').trim();
        if(twice_keying_fields != '') {
            var add_row_elements = document.querySelectorAll("#adding_row input[type=text]");
            var allFieldIds = [];
            for(var i = 0; i < add_row_elements.length; i++) {
                allFieldIds.push(add_row_elements[i].id);
            }
            var previousValuesAndIds = $F('twice_keying_prev_values_of_add_row');
            var normalizedPreviousValue = normalizePreviousValuesAndIds(allFieldIds, previousValuesAndIds);
            var returnValue = validateTwiceKeyingFields(allFieldIds, normalizedPreviousValue);
            resultOfValidation = returnValue[0];
            var nameValuePairArray = returnValue[1];
            $('twice_keying_prev_values_of_add_row').value = nameValuePairArray;
        }
    }
    return resultOfValidation;
}

function validateTwiceKeyingForProviderAdjustment(){
    var resultOfValidation = true;
    if($('twice_keying_fields') != null && $('twice_keying_prev_values_of_provider_adjustment') != null) {
        var twice_keying_fields = $F('twice_keying_fields').trim();
        if(twice_keying_fields != '') {
            var elements = document.querySelectorAll("#provider_adjustment_grid_container input[type=text]");
            var select_elements = document.querySelectorAll("#provider_adjustment_grid_container select");
            elements = Array.prototype.slice.call(elements)
            for(var i = 0; i < select_elements.length; i++) {
                elements.push(select_elements[i]);
            }
            var allFieldIds = [];
            for(i = 0; i < elements.length; i++) {
                allFieldIds.push(elements[i].id);
            }
            var previousValuesAndIds = $F('twice_keying_prev_values_of_provider_adjustment');
            var normalizedPreviousValue = normalizePreviousValuesAndIds(allFieldIds, previousValuesAndIds);
            var returnValue = validateTwiceKeyingFields(allFieldIds, normalizedPreviousValue);
            resultOfValidation = returnValue[0];
            var nameValuePairArray = returnValue[1];
            $('twice_keying_prev_values_of_provider_adjustment').value = nameValuePairArray;
        }
    }
    return resultOfValidation;

}

function randomSamplingForTwiceKeyingFields(){
    var resultOfValidation = true;
    var exclude_double_keying_elements = [];
    var exclude_elements = ['page', 'checknumber_id', 'job_pages_from', 'job_pages_to', 'amount_so_far', 'balance', 'provider_organisation_id', 'generated_check_number' ]
    if($('fcui_random_sampling') != null && $('fcui_random_sampling_percentage') != null && $F('fcui_random_sampling') == 'true' && $F('fcui_random_sampling_percentage').strip() != ''){
        if( $('twice_keying_prev_values_of_random_sampling_fields') != null) {
            var twice_keying_fields = $F('twice_keying_fields').trim();
            var twice_keying_fields_array = []
            var random_elements = []
            twice_keying_fields_array = twice_keying_fields.split(',')
            var allFields = $$('input:text', 'select');
            var allFieldIds = [];
            for(i = 0; i < allFields.length; i++) {
                for(j=0; j<twice_keying_fields_array.length; j++){
                    if((allFields[i] != '') && (allFields[i].id).include(twice_keying_fields_array[j]) && twice_keying_fields_array[j] != ''){

                        exclude_double_keying_elements.push(allFields[i].id)
                    }
                }
            }
            for(i = 0; i < allFields.length; i++) {
                if(exclude_elements.length > 0 &&  (allFields[i] != '') && (!(exclude_elements.include(allFields[i].id))) && (!(exclude_double_keying_elements.include(allFields[i].id)))  && (allFields[i].value.strip() != '') && ( allFields[i].value != '-' && allFields[i].value != '--') && (allFields[i].value != 'mm/dd/yy') && (!(allFields[i].className.include('disable-double-keying')) && (parseFloat(allFields[i].value) != 0) && (allFields[i].readOnly != true) && (allFields[i].disabled != true))){
                    allFieldIds.push(allFields[i].id);
                }
            }
            if($F('twice_keying_prev_values_of_random_sampling_fields').strip() == '' ){
                var sampling_percentage = parseFloat($F('fcui_random_sampling_percentage'))
                var element_count = Math.ceil((allFieldIds.length) * (sampling_percentage/100))
                random_elements = allFieldIds.getRandom(element_count)
                $('twice_keying_fields_for_random_sampling').value = random_elements
            }
            if(random_elements.length > 0){
                for(i=0; i<random_elements.length; i++){

                    $(random_elements[i]).oncopy = function (){
                        return false;
                    }
                    $(random_elements[i]).onpaste = function (){
                        return false;
                    }
                    $(random_elements[i]).oncut = function (){
                        return false;
                    }
                }
            }
            var previousValuesAndIds = $F('twice_keying_prev_values_of_random_sampling_fields');
            var normalizedPreviousValue = normalizePreviousValuesAndIds(allFieldIds, previousValuesAndIds);
            var returnValue = validateTwiceKeyingFieldsForRandomSamplingElements(allFieldIds, normalizedPreviousValue);
            resultOfValidation = returnValue[0];
            var nameValuePairArray = returnValue[1];
            $('twice_keying_prev_values_of_random_sampling_fields').value = nameValuePairArray;
        }
    }

    return resultOfValidation;
}

function validateTwiceKeyingFieldsForRandomSamplingElements(allFieldIds, previous_value) {
    var resultOfValidation = true;
    if(allFieldIds.length > 0 && $('twice_keying_fields_for_random_sampling')) {
        var twice_keying_fields = $F('twice_keying_fields_for_random_sampling').trim().split(',');
        if(twice_keying_fields.length > 0) {
            var normalizedFieldIds = [];
            for(i = 0; i < allFieldIds.length; i++) {
                if(!(allFieldIds[i].startsWith('confirm'))) {
                    normalizedFieldIds.push(allFieldIds[i]);
                }
            }
            var name_value_pair_array = getFieldNameValueCombination(normalizedFieldIds, twice_keying_fields);
            resultOfValidation = validateCurrentAndPreviousCombination(previous_value, name_value_pair_array);
        }
    }
    return [resultOfValidation, name_value_pair_array];
}

function normalizePreviousValuesAndIds(allFieldIds, previousValuesAndIds) {
    var previousValueIds = [];
    var normalizedPreviousValue = [];
    var idAndValue;
    var previousValuesAndIdsArray = previousValuesAndIds.split(',');
    for(var i = 0; i < previousValuesAndIdsArray.length; i++) {
        idAndValue = previousValuesAndIdsArray[i].split(':');
        if(idAndValue != []) {
            previousValueIds.push(idAndValue[1]);
        }
    }

    var normalizedPreviousValueIds = arrayElementsFoundInAnotherArray(previousValueIds, allFieldIds);
    var normalizedId;
    for(i = 0; i < normalizedPreviousValueIds.length; i++) {
        for(var j = 0; j < previousValuesAndIdsArray.length; j++) {
            normalizedId = normalizedPreviousValueIds[i];
            idAndValue = previousValuesAndIdsArray[j].split(':');
            if(idAndValue != [] && normalizedId != '' && idAndValue[1] == normalizedId) {
                normalizedPreviousValue.push(previousValuesAndIdsArray[j]);
            }
        }
    }
    normalizedPreviousValue = normalizedPreviousValue.join(',');
    return normalizedPreviousValue;
}

function validateTwiceKeyingFields(allFieldIds, previous_value) {
    var resultOfValidation = true;
    if(allFieldIds.length > 0 && $('twice_keying_fields')) {
        var twice_keying_fields = $F('twice_keying_fields').trim().split(',');
        if(twice_keying_fields.length > 0) {
            var normalizedFieldIds = [];
            for(i = 0; i < allFieldIds.length; i++) {
                if(!(allFieldIds[i].startsWith('confirm'))) {
                    normalizedFieldIds.push(allFieldIds[i]);
                }
            }
            var name_value_pair_array = getFieldNameValueCombination(normalizedFieldIds, twice_keying_fields);
            resultOfValidation = validateCurrentAndPreviousCombination(previous_value, name_value_pair_array);
        }
    }
    return [resultOfValidation, name_value_pair_array];
}


function getFieldNameValueCombination(elements, twice_keying_fields){
    var array = [];
    var uniqueCodeFields = [];
    var adjustmentReason;
    var twiceKeyingFieldsLength = twice_keying_fields.length;
    for (var i = 0; i < twiceKeyingFieldsLength; i++) {
        for (var j = 0; j < elements.length; j++){
            if($(elements[j]) != null && $(elements[j]).readOnly != true &&
                $(elements[j]).disabled != true &&  elements[j].include(twice_keying_fields[i]) ==  true){
                if(elements[j].include('unique_code')) {
                    adjustmentReason = findAdjustmentReason(elements[j]);
                    uniqueCodeFields.push([adjustmentReason + '_unique_code', elements[j]]);
                }
                else {
                    if($(elements[j]) != null && $F(elements[j]) != null) {
                        var value = $F(elements[j]).toUpperCase();
                        array.push(twice_keying_fields[i] + ":" + elements[j] + ":" + value);
                    }
                }
            }
        }
    }

    var uniqueCodeFieldLength = uniqueCodeFields.length;
    if(uniqueCodeFieldLength > 0) {
        for(i = 0; i < uniqueCodeFieldLength; i++) {
            for (j = 0; j < twiceKeyingFieldsLength; j++) {
                if(uniqueCodeFields[i][0] == twice_keying_fields[j]) {
                    if($(uniqueCodeFields[i][1]))
                        array.push(twice_keying_fields[j] + ":" + uniqueCodeFields[i][1] + ":" + $F(uniqueCodeFields[i][1]));
                }
            }
        }
    }

    return array;
}

function validateCurrentAndPreviousCombination(previous_value, name_value_pair_array){
    var resultOfValidation = true;
    var i;
    var splited_value;
    var id;
    var ids  = []
    var uncolor = []
    var firstAttemptStatisticsArray = []
    if($('twice_keying_first_attempt_statistics')) {
        var firstAttemptStatistics = $F('twice_keying_first_attempt_statistics');
        firstAttemptStatisticsArray = firstAttemptStatistics.split(',');
    }
    if(previous_value != ''){
        var previous_value_array;
        var normalized_field_name;
        var firstAttemptStatus;
        splited_value = previous_value.split(',');
        for( i=0;i<splited_value.length; i++){
            var mpi_changed_fields = []
            mpi_changed_fields = $F('837_changed_fields').split(',')
            previous_value_array = splited_value[i].split(':');
            normalized_field_name = previous_value_array[0];
            id = previous_value_array[1];
            firstAttemptStatus = "";
            if(!mpi_changed_fields.include(id)){
                if($(id)) {
                    if(!($(id).className.include('disable-double-keying'))){
                        if (((name_value_pair_array.include(splited_value[i])) == false)){
                            ids.push(id);
                            reCalculateTotalAmountFields(id);
                            if($F(id).strip() != "") {
                                firstAttemptStatus = "failure";
                            }
                            $(id).value = '';
                        }
                        else{
                            uncolor.push(id);
                            if($F(id).strip() != "") {
                                firstAttemptStatus = "success";
                            }
                        }
                    }
                }
                if(firstAttemptStatus != "") {
                    firstAttemptStatisticsArray = insertToTwiceKeyingStatistics(firstAttemptStatisticsArray,
                        normalized_field_name, id, firstAttemptStatus);
                }
            }
        }

        if(ids.length > 0) {
            setTimeout(function() {
                if($(ids[0]))
                    $(ids[0]).focus();
            }, 10);
            setHighlight(ids, "blue-color");
            alert("The keyed data does not match the data captured in the previous attempt. Please rekey.");
            resultOfValidation = false;
        }

        if($('837_changed_fields') != null && ($F('837_changed_fields').strip()) != ''){
            ids = []
            var mpi_changed_fields = []
            mpi_changed_fields = $F('837_changed_fields').split(',')
            for(var k=0; k < name_value_pair_array.length; k++){
                for( i=0;i<mpi_changed_fields.length; i++){
                    id  = mpi_changed_fields[i];
                    value  = $F(mpi_changed_fields[i])
                    if(name_value_pair_array[k].include(id)){
                        if(value != '' && value != '-' && value != '--')
                            ids.push(id);
                        reCalculateTotalAmountFields(id);
                        if($(id) && $F(id) != '--' && $F(id) != '-')
                            $(id).value = '';
                        mpi_changed_fields.splice(i, 1)
                           

                    }
                }
            }
            $('837_changed_fields').value = mpi_changed_fields
            if(ids.length > 0){
                resultOfValidation = twiceKeyingReEnterAlert(ids);
            }
           
        }

        if(uncolor.length > 0) {
            removeCustomValidations(uncolor, 'blue-color');
            removeCustomValidations(uncolor, 'edited');

        }
    }
    else{
        if((previous_value == '')){
            for( i=0;i<name_value_pair_array.length; i++){
                id  = name_value_pair_array[i].split(':')[1];
                if(!($(id).className.include('disable-double-keying'))){
                    value  = name_value_pair_array[i].split(':')[2];
                    if(value != '' && value != '-' && value != '--')
                        ids.push(id);
                    reCalculateTotalAmountFields(id);
                    if($(id) && $F(id) != '--' && $F(id) != '-')
                        $(id).value = '';
                }

            }
        }
        if($('837_changed_fields') != null  && ($F('837_changed_fields').strip()) != ''){
            var mpi_changed_fields = []
            mpi_changed_fields = $F('837_changed_fields').split(',')
            for(var k=0; k < name_value_pair_array.length; k++){
                for( i=0;i<mpi_changed_fields.length; i++){

                    id  = mpi_changed_fields[i];
                    value  = $F(mpi_changed_fields[i])
                    if(name_value_pair_array[k].include(id)){
                        if(value != '' && value != '-' && value != '--')
                            ids.push(id);
                        reCalculateTotalAmountFields(id);
                        if($(id) && $F(id) != '--' && $F(id) != '-')
                            $(id).value = '';
                        mpi_changed_fields.splice(i, 1)
                    }
                }
            }
            $('837_changed_fields').value = mpi_changed_fields
        }
        if(ids.length > 0){
            resultOfValidation = twiceKeyingReEnterAlert(ids);
        }
    
    }
    if($('twice_keying_first_attempt_statistics')) {
        $('twice_keying_first_attempt_statistics').value = firstAttemptStatisticsArray.join(",");
    }
    return resultOfValidation;
}


function twiceKeyingReEnterAlert(ids){
    var resultOfValidation = true;
    if(ids.length > 0) {
        setTimeout(function() {
            if($(ids[0])) {
                $(ids[0]).focus();
            }
        }, 10);
        setHighlight(ids, "edited");
        alert("Please re-enter the highlighted fields.");
        resultOfValidation = false;
    }
    return resultOfValidation;
}

function insertToTwiceKeyingStatistics(firstAttemptStatisticsArray, field_name, fieldId, firstAttemptStatus) {
    if(firstAttemptStatus == "success")
        var status = "1";
    else
        status = "0";
    var svcLineSerialNo = fieldId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
    if(svcLineSerialNo != '') {
        field_name = field_name + '_' + svcLineSerialNo
    }
    var field_name_and_status = field_name + ":" + status;
    var successCondition = field_name + ":" + "1";
    var failureCondition = field_name + ":" + "0";
    if(firstAttemptStatisticsArray.include(successCondition) == false &&
        firstAttemptStatisticsArray.include(failureCondition) == false) {
        firstAttemptStatisticsArray.push(field_name_and_status)
    }
    return firstAttemptStatisticsArray;
}

function reCalculateTotalAmountFields(fieldId) {
    if($(fieldId) != null) {
        var value = $F(fieldId);
        var totalFieldId;
        if(isNaN(parseFloat(value)) != true) {
            var svcLineSerialNo = fieldId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
            if(svcLineSerialNo != '' && (fieldId.include('unique_code') != true)) {
                if(fieldId.include('submitted_charge')) {
                    totalFieldId = 'total_primary_payment_id';
                }
                else if(fieldId.include('charge')) {
                    totalFieldId = 'total_charge_id';
                }
                else if(fieldId.include('pbid')) {
                    totalFieldId = 'total_pbid_id';
                }
                else if(fieldId.include('allowable')) {
                    totalFieldId = 'total_allowable_id';
                }
                else if(fieldId.include('plan_coverage')) {
                    totalFieldId = 'total_plan_coverage_id';
                }
                else if(fieldId.include('drg_amount')) {
                    totalFieldId = 'total_drg_amount_id';
                }
                else if(fieldId.include('expected_payment')) {
                    totalFieldId = 'total_expected_payment_id';
                }
                else if(fieldId.include('retention_fees')) {
                    totalFieldId = 'total_retention_fees_id';
                }
                else if(fieldId.include('paid_amount')) {
                    totalFieldId = 'total_payment_id';
                }
                else if(fieldId.include('non_covered')) {
                    totalFieldId = 'total_non_covered_id';
                }
                else if(fieldId.include('denied')) {
                    totalFieldId = 'total_denied_id';
                }
                else if(fieldId.include('discount')) {
                    totalFieldId = 'total_discount_id';
                }
                else if(fieldId.include('co_insurance')) {
                    totalFieldId = 'total_coinsurance_id';
                }
                else if(fieldId.include('deductible')) {
                    totalFieldId = 'total_deductable_id';
                }
                else if(fieldId.include('co_pay')) {
                    totalFieldId = 'total_copay_id';
                }
                else if(fieldId.include('patient_responsibility')) {
                    totalFieldId = 'total_patient_responsibility_id';
                }
                else if(fieldId.include('prepaid')) {
                    totalFieldId = 'total_prepaid_id';
                }
                else if(fieldId.include('contractual')) {
                    totalFieldId = 'total_contractual_amount_id';
                }
                else if(fieldId.include('miscellaneous_one')) {
                    totalFieldId = 'total_miscellaneous_one_id';
                }
                else if(fieldId.include('miscellaneous_two')) {
                    totalFieldId = 'total_miscellaneous_two_id';
                }
                else if(fieldId.include('miscellaneous_balance')) {
                    totalFieldId = 'total_miscellaneous_balance_id';
                }
                
                if(totalFieldId != '' && $(totalFieldId) != null && $F(fieldId) != '' && parseFloat($F(fieldId)) != 0) {
                    $(totalFieldId).value = parseFloat($F(totalFieldId)) - $F(fieldId);
                    var serviceBalanceId = 'service_balance_id' + svcLineSerialNo;
                    if(serviceBalanceId) {
                        $(serviceBalanceId).value = '';
                    }
                }
            }
        }
    }
}

function setTwiceKeyingFields(reasonCodeSetNameId) {
    if($('twice_keying_fields') != null) {
        if(toString(reasonCodeSetNameId).strip() != '') {
            if($('client_id') && $('facility_id')) {
                var parameters = 'reason_code_set_name_id=' + reasonCodeSetNameId +
                '&client_id=' + $F('client_id') +
                '&facility_id=' + $F('facility_id');
                var url = relative_url_root() + "/admin/twice_keying_fields/get_field_names";
                new Ajax.Request(url, {
                    asynchronous: true,
                    parameters: parameters,
                    onComplete: function(getFieldNames) {
                        var fieldNames = eval("(" + getFieldNames.responseText + ")");
                        if(fieldNames != '') {
                            var twice_keying_fields_before_changing_payer = $F('twice_keying_fields');
                            $('twice_keying_fields').value = fieldNames;
                            if(twice_keying_fields_before_changing_payer.split(',').sort().join(',') !=  $F('twice_keying_fields').split(',').sort().join(',')){
                                if($('twice_keying_prev_values_of_all_fields'))
                                    $('twice_keying_prev_values_of_all_fields').value = '';
                                if($('twice_keying_prev_values_of_add_row'))
                                    $('twice_keying_prev_values_of_add_row').value = '';
                                if($('twice_keying_prev_values_of_provider_adjustment'))
                                    $('twice_keying_prev_values_of_provider_adjustment').value = '';
                            }
                        }
                    }
                });
            }
        }
    }
}

function validateUnknownPayer(){
    if($("transaction_type") != null) {
        var transactionTypeObject = document.form1.transaction_type;
        var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
        var item_ids = ['payer_popup', 'payer_pay_address_one', 'payer_city_id',
        'payer_payer_state', 'payer_zipcode_id']

        if((transactionType != "Correspondence") &&
            ($('payer_popup').value.trim().toUpperCase() == "UNKNOWN")){
            $('payer_id').value = ""
            $('payer_popup').value = ""
            $('payer_pay_address_one').value = ""
            $('payer_address_two').value = ""
            $('payer_city_id').value = ""
            $('payer_payer_state').value = ""
            $('payer_zipcode_id').value = ""
            setFieldsValidateAgainstCustomMethod(item_ids, "required");
        }
    }
}
function validateCheckDetails() {
    if(parseFloat($F('checkamount_id')) > 0) {
        var proceedValidation;
        if($('payment_method') != null) {
            if($F('payment_method') == 'CHK' || $F('payment_method') == 'OTH')
                proceedValidation = true;
        }
        else if($('check_information_payment_method') != null) {
            if($F('check_information_payment_method') == 'CHK')
                proceedValidation = true;
        }
        else {
            proceedValidation = true;
        }

        if(proceedValidation) {
            var item_ids = ["aba_routing_number_id", "payer_account_number_id", 'checkdate_id', 'checknumber_id', 'checkamount_id'];
            setFieldsValidateAgainstCustomMethod(item_ids, "required");
            item_ids = ["aba_routing_number_id"];
            setFieldsValidateAgainstCustomMethod(item_ids, "validate-aba");
            item_ids = ["payer_account_number_id"];
            setFieldsValidateAgainstCustomMethod(item_ids, "validate-payer-acc-num");
            item_ids = ["checknumber_id"];
            setFieldsValidateAgainstCustomMethod(item_ids, "validate-nonzero-alphanum");
            item_ids = ["checkdate_id"];
            setFieldsValidateAgainstCustomMethod(item_ids, "datebox");
        }
    }
}
function removeRequiredForCheckMailedAndReceivedDate(){
    //code for removing mandatory field validation for check_mailed_date and check_received_date
    var item_ids = ["check_mailed_date_id", "check_received_date_id"];
    if ($('check_mailed_date_id') != null && $F('check_mailed_date_id') == 'mm/dd/yy')
        $('check_mailed_date_id').value = ""
    if ($('check_received_date_id') != null && $F('check_received_date_id') == 'mm/dd/yy')
        $('check_received_date_id').value = ""
    removeCustomValidations(item_ids, 'required');
}

function setValidationForFields(){
    validateCheckDetails();
    removeRequiredForCheckMailedAndReceivedDate();
    setFieldsMandatoryForPatpay();
    validateUnknownPayer();
//console_logger('setValidationForFields', true);
}

// This function do the following:
// 1) Get the stand alone remark codes from the Add Row of the DC grid.
// 2) Prepare the remark code by splitting the multiple codes from field by ':'.
// 3) All the entered remark codes from the DC grid are checked if they
//    exist in ANSI Remark Code List by the function 'findInvalidRemarkCodes'.
function validateAddRowRemarkCodes() {
    var agree = true;
    if($('ansi_remark_code') != null && $F('ansi_remark_code') == "true") {
        if($('remark_code') != null && $F('remark_code') != "") {
            var remarkCodeId = [];
            var allRemarkCodesEntered = $F('remark_code').trim().split(':');
            var length = remarkCodeId.length;
            var codeLength = allRemarkCodesEntered.length;
            if (allRemarkCodesEntered.length > 0 && allRemarkCodesEntered[0] != '')
            {
                remarkCodeId = arrayInsertionForAParticlularLength(remarkCodeId,
                    'remark_code', length, length + codeLength);
                agree = findInvalidRemarkCodes(allRemarkCodesEntered, codeLength,
                    remarkCodeId);
            }
        }
    }
    return agree;
}

// This function do the following:
// 1) Get the stand alone remark codes from the Saved/MPI service lines of the DC grid.
// 2) Prepare the remark code by splitting the multiple codes from field by ':'.
// 3) All the entered remark codes from the DC grid are checked if they
//    exist in ANSI Remark Code List by the function 'findInvalidRemarkCodes'.
// 'codeLength' is an array containing the number of the RemarkCodes in each field.
function validateAllRemarkCodes() {
    var agree = true;
    if($('ansi_remark_code') != null && $F('ansi_remark_code') == "true") {
        var allRemarkCodesEntered = [];
        var remarkCodeIds = [];
        var codeLength = [];
        var code_id;
        var codes;
        var count;
        if($('total_line_count') != null) {
            for(count = 1; count <= $F('total_line_count'); count++) {
                code_id = "remark_code_" + count;
                if($(code_id) != null && $F(code_id).trim() != "") {
                    codes = $F(code_id).toUpperCase().split(':');
                    allRemarkCodesEntered.push(codes);
                    remarkCodeIds.push(code_id);
                    codeLength.push(codes.length);
                }
            }
        }
        code_id = 'claim_level_remark_code';
        if($(code_id) != null && $F(code_id).strip() != '') {
            codes = $F(code_id).toUpperCase().split(':');
            allRemarkCodesEntered.push(codes);
            remarkCodeIds.push(code_id);
            codeLength.push(codes.length);
        }
        if (allRemarkCodesEntered.length > 0 && allRemarkCodesEntered[0] != '')
            agree = findInvalidRemarkCodes(allRemarkCodesEntered, codeLength, remarkCodeIds);
    }
    //console_logger('validateAllRemarkCodes', agree);
    return agree;
}

// This function do the following:
// 1) All the entered remark codes from the DC grid are checked if they exist
//    in ANSI Remark Code List in DB by the function 'getInvalidRemarkCodes'.
// 2) Fields containing Invalid Remark Codes are given background color 'red'
//    by the function 'setHighlight'.
// 'remarkCodesAndIds' is an array containing Field Ids and its
// Remark codes(in an array) in alternate position, starting with a Field Id.
// Like [[id, code], [id, code],..]; obtained out of a hash.
// 'codeLength' is an array containing the number of the RemarkCodes in each field.
function findInvalidRemarkCodes(allRemarkCodesEntered, codeLength, remarkCodeIds) {
    var agree = true;
    if(allRemarkCodesEntered.length > 0) {
        var remarkCodesAndIds = [];
        var invalidRemarkCodes = [];
        var invalidRemarkCodeIds = [];
        setHighlight(remarkCodeIds, "blank");
        remarkCodesAndIds = getInvalidRemarkCodes(allRemarkCodesEntered,
            codeLength, remarkCodeIds);
        for(i = 0; i < remarkCodesAndIds.length; i++) {
            invalidRemarkCodeIds[i] = remarkCodesAndIds[i][0];
            invalidRemarkCodes[i] = remarkCodesAndIds[i][1];
        }
        if(invalidRemarkCodes.length > 0) {
            setHighlight(invalidRemarkCodeIds, "uncertain");
            alert("The following Remark Codes are invalid found in the service line(s) : " +
                invalidRemarkCodes);
            $(invalidRemarkCodeIds.first()).focus();
            agree = false;
        }
    }
    return agree;
}

// This returns those ANSI Remark Codes which are present in
//  Master ANSI Remark Code List from DB by a Synchronous AJAX request.
// 'remarkCodesAndIds' is an array containing Field Ids and its
// Remark codes(in an array) in alternate position, starting with a Field Id.
// Like [[id, code], [id, code],..]; obtained out of a hash.
function getInvalidRemarkCodes(allRemarkCodesEntered, codeLength, remarkCodeIds) {
    var parameters = 'remark_code_ids=' + remarkCodeIds +
    '&remark_codes_entered=' + allRemarkCodesEntered +
    '&code_length=' + codeLength;
    var remarkCodesAndIds = [];
    var url = relative_url_root() + "/insurance_payment_eobs/get_invalid_remark_codes";
    new Ajax.Request(url, {
        asynchronous: false,
        parameters: parameters,
        onComplete: function(getRemarkCode) {
            remarkCodesAndIds = eval("(" + getRemarkCode.responseText + ")");
        }
    });
    return remarkCodesAndIds;
}

function uncheckClaimLevelEob(){

    var item = $('claim_level_grid')
    if (item && item.checked){
        item.checked = false;
    }

}

function disableComplete(){
    $("complete_button_id").disabled = true;
    $("incomplete_button_id").disabled = true;
}

function enableComplete(){
    $("complete_button_id").disabled = false;
    $("incomplete_button_id").disabled = false;
}

function setClaimFromdate(){
    if($F('fc_def_sdate_choice') == "Check Date"){
        $('dateofservicefrom').value = $F('checkdate_id')
    } else {
        var date = $F('fc_def_sdate');
        if(date.strip().length == 10) {
            var dateArray = date.split('/');
            var year = dateArray[2].slice(2); // extracting last two digits of year
            var defaultDate = dateArray[0] + '/' + dateArray[1] + '/' + year; // combining into date
        }
        else {
            defaultDate = date;
        }
        $('dateofservicefrom').value = defaultDate;
    }
}

function getPatientName(){
    var patientName = "";
    var firstName = $F('patient_first_name_id');
    var suffixName = $F('patient_suffix_id');
    var lastName = $F('patient_last_name_id');
    var initialName = $F('patient_initial_id');

    if(firstName != "")
        patientName = firstName;
    if(initialName != ""){
        if(patientName != ""){
            patientName = patientName + " " + initialName;
        }
        else
            patientName = initialName;
    }
    if(lastName != ""){
        if(patientName != ""){
            patientName = patientName + " " + lastName;
        }
        else
            patientName = lastName;
    }
    if(suffixName != ""){
        if(patientName != ""){
            patientName = patientName + " " + suffixName;
        }
        else
            patientName = suffixName;
    }
    return patientName;
}

function defaultValues() {
    var insuranceGrid = $F('insurance_grid');
    if($('populate_default_values') != null) {
        if($('populate_default_values').checked == true) {
            setDefaultValues(insuranceGrid);
            if($('rejection_comment') != null)
                $('rejection_comment').style.display = "block";
        }
        else {
            resetDefaultValues(insuranceGrid);
            if($('rejection_comment') != null) {
                $('rejection_comment').value = '--';
                $('rejection_comment').style.display = "none";
            }
            if($('comment') != null) {
                $('comment').value = '';
                $('comment').style.display = "none";
            }
        }
    }
}

function setDefaultValues(insuranceGrid) {
    if($F('payer_pay_address_one') == "")
        $('payer_pay_address_one').value = "NOT PROVIDED";
    if($F('payer_address_two') == "")
        $('payer_address_two').value = "NOT PROVIDED";
    if($F('payer_city_id') == "")
        $('payer_city_id').value = "DEFAULT CITY";
    if($F('payer_payer_state') == "")
        $('payer_payer_state').value = "XX";
    if($F('payer_zipcode_id') == "")
        $('payer_zipcode_id').value = "99999";
    if(insuranceGrid == "true"){
        setDefaultPatientNameFromFcui();
    }
    else{
        if($('patient_address_one') != null && $F('patient_address_one') == "")
            $('patient_address_one').value = "NOT PROVIDED";
        if($('patient_address_two') != null && $F('patient_address_two') == "")
            $('patient_address_two').value = "NOT PROVIDED";
        if($('patient_city_id') != null && $F('patient_city_id') == "")
            $('patient_city_id').value = "DEFAULT CITY";
        if($('patient_state_id') != null && $F('patient_state_id') == "")
            $('patient_state_id').value = "XX";
        if($('patient_zipcode_id') != null && $F('patient_zipcode_id') == "")
            $('patient_zipcode_id').value = "99999";
    }
}

function setDefaultPatientNameFromFcui(){

    var fval = $('fc_def_pat_name').value
    if (fval  == 'Payer Name'){
        if ($('patient_last_name_id').value == "")
            $('patient_last_name_id').value = $('payer_popup').value;
        if ($('patient_first_name_id').value == "")
            $('patient_first_name_id').value = $('payer_popup').value;
        if ($('subcriber_last_name_id') && $('subcriber_last_name_id').value == "")
            $('subcriber_last_name_id').value =  $('payer_popup').value;
        if ($('subcriber_firstname_id') && $('subcriber_firstname_id').value == "")
            $('subcriber_firstname_id').value =  $('payer_popup').value;
    }
    else
    {
        var patientName = fval.toUpperCase();
        patientName = patientName.split(",");
        if ($('patient_last_name_id').value == "")
            $('patient_last_name_id').value = patientName[0];
        if ($('patient_first_name_id').value == "")
            $('patient_first_name_id').value = patientName[1];
        if ($('subcriber_last_name_id') && $('subcriber_last_name_id').value == "")
            $('subcriber_last_name_id').value =  patientName[0];
        if ($('subcriber_firstname_id') && $('subcriber_firstname_id').value == "")
            $('subcriber_firstname_id').value =  patientName[1];

    }
}

function resetDefaultPatientNameFromFcui(){
    var fval = $('fc_def_pat_name').value
    if (fval  == 'Payer Name'){
        if ($('patient_last_name_id').value == $('payer_popup').value)
            $('patient_last_name_id').value = "";
        if ($('patient_first_name_id').value == $('payer_popup').value)
            $('patient_first_name_id').value = "";
        if ($('subcriber_last_name_id') && $('subcriber_last_name_id').value == $('payer_popup').value)
            $('subcriber_last_name_id').value =  "";
        if ($('subcriber_firstname_id') && $('subcriber_firstname_id').value == $('payer_popup').value)
            $('subcriber_firstname_id').value =  "";
    }
    else
    {
        var patientName = fval.toUpperCase();
        patientName = patientName.split(",");
        if ($('patient_last_name_id').value ==  patientName[0])
            $('patient_last_name_id').value = "";
        if ($('patient_first_name_id').value == patientName[1])
            $('patient_first_name_id').value = "";
        if ($('subcriber_last_name_id') && $('subcriber_last_name_id').value == patientName[0])
            $('subcriber_last_name_id').value =  "";
        if ($('subcriber_firstname_id') && $('subcriber_firstname_id').value ==  patientName[1])
            $('subcriber_firstname_id').value = "";

    }


}
function resetDefaultValues(insuranceGrid) {
    if($F('payer_pay_address_one') == "NOT PROVIDED")
        $('payer_pay_address_one').value = "";
    if($F('payer_address_two') == "NOT PROVIDED")
        $('payer_address_two').value = "";
    if($F('payer_city_id') == "DEFAULT CITY")
        $('payer_city_id').value = "";
    if($F('payer_payer_state') == "XX")
        $('payer_payer_state').value = "";
    if($F('payer_zipcode_id') == "99999")
        $('payer_zipcode_id').value = "";
    $('total_service_balance_id').value = "";
    if(insuranceGrid == "true"){
        resetDefaultPatientNameFromFcui();
    }
    else{
        if($('patient_address_one') != null && $F('patient_address_one') == "NOT PROVIDED")
            $('patient_address_one').value = "";
        if($('patient_address_two') != null && $F('patient_address_two') == "NOT PROVIDED")
            $('patient_address_two').value = "";
        if($('patient_city_id') != null && $F('patient_city_id') == "DEFAULT CITY")
            $('patient_city_id').value = "";
        if($('patient_state_id') != null && $F('patient_state_id') == "XX")
            $('patient_state_id').value = "";
        if($('patient_zipcode_id') != null && $F('patient_zipcode_id') == "99999")
            $('patient_zipcode_id').value = "";

        var patientName = getPatientName();
        if($F('payer_popup') == patientName)
            $('payer_popup').value = "";
        if($F('subcriber_last_name_id') == $F('patient_last_name_id'))
            $('subcriber_last_name_id').value = "";
        if($F('subcriber_firstname_id') == $F('patient_first_name_id'))
            $('subcriber_firstname_id').value = "";
        if($F('subcriber_suffix_id') == $F('patient_suffix_id'))
            $('subcriber_suffix_id').value = "";
        if($F('subcriber_initial_id') == $F('patient_initial_id'))
            $('subcriber_initial_id').value = "";
    }
}


//showing text area comment box for QA/processor view
function makeCommentVisible(){
    if ($('rejection_comment') != null) {
        if($F('rejection_comment') == "Other") {
            if($('comment') != null) {
                $('comment').value = "";
                $('comment').style.display = "block";
                $('comment').focus();
            }
        }
        else {
            if($('comment') != null) {
                $('comment').value = "";
                $('comment').style.display = "none";
            }
        }
    }
}

function makeOrboCommentVisible(){
    if ($('reason_description') != null) {
        if($F('reason_description') == "Other") {
            if($('comment') != null) {
                $('comment').value = "";
                $('comment').style.display = "block";
                $('comment').focus();
            }
        }
        else {
            if($('comment') != null) {
                $('comment').value = "";
                $('comment').style.display = "none";
            }
        }
    }
}

function validateIncompleteRejectionComment(){
    var validation = false;
    if($('incomplete_processor_comment') != null) {
        if($('incomplete_processor_comment').style.display == "none")
            validation = true;
        else {
            if($F('incomplete_processor_comment') == "--") {
                alert("Please enter the Incomplete Rejection Comment.");
                $('incomplete_processor_comment').focus();
            }
            else if($F('incomplete_processor_comment') == "Other") {
                if($('incomplete_proc_comment_other') != null) {
                    var comment = $F('incomplete_proc_comment_other').trim();
                    if(comment == ""){
                        alert("Please Enter Comment");
                        $('incomplete_proc_comment_other').focus();
                    }
                    else
                        validation = true;
                }
            }
            else
                validation = true;
        }
    }
    else
        validation = true;
    return validation;
}


//showing text area comment box for QA/processor view
function makeIncompleteCommentVisible(){
    if ($('incomplete_processor_comment') != null) {
        if($F('incomplete_processor_comment') == "Other") {
            if($('incomplete_proc_comment_other') != null) {
                $('incomplete_proc_comment_other').value = "";
                $('incomplete_proc_comment_other').style.display = "block";
                $('incomplete_proc_comment_other').focus();
            }
        }
        else {
            if($('incomplete_proc_comment_other') != null) {
                $('incomplete_proc_comment_other').value = "";
                $('incomplete_proc_comment_other').style.display = "none";
            }
        }
    }
}

function makeCompleteCommentVisible(){
    if ($('complete_processor_comment') != null) {
        if($F('complete_processor_comment') == "Other") {
            if($('complete_proc_comment_other') != null) {
                $('complete_proc_comment_other').value = "";
                $('complete_proc_comment_other').style.display = "block";
                $('complete_proc_comment_other').focus();
            }
        }
        else {
            if($('complete_proc_comment_other') != null) {
                $('complete_proc_comment_other').value = "";
                $('complete_proc_comment_other').style.display = "none";
            }
        }
    }
}


function validateRejectionComment(){
    var validation = false;
    if($('rejection_comment') != null) {
        if($('rejection_comment').style.display == "none")
            validation = true;
        else {
            if($F('rejection_comment') == "--") {
                alert("Please enter the Rejection Comment.");
                setTimeout(function() {
                    document.getElementById('rejection_comment').focus();
                }, 10);
            }
            else if($F('rejection_comment') == "Other") {
                if($('comment') != null) {
                    var comment = $F('comment').trim();
                    if(comment == ""){
                        alert("Please Enter Comment");
                        setTimeout(function() {
                            document.getElementById('comment').focus();
                        }, 10);
                    }
                    else
                        validation = true;
                }
            }
            else
                validation = true;
        }
        if( $('rejection_comment').style.display == "block" && validation == true && $('tab_type') != null){
            if($F('tab_type') == 'Patient'){
                var item_ids = ['date_service_from_1', 'date_service_to_1',
                'service_procedure_charge_amount_id1', 'service_paid_amount_id1',
                'procedure_code_1', 'provider_control_number_1'];
                removeCustomValidations(item_ids, 'required');
                var cpt = ['procedure_code_1'];
                setFieldsValidateAgainstCustomMethod(cpt, 'validate-cpt_code_length');
            }
        }
    }
    else
        validation = true;
    //console_logger('validateRejectionComment', validation);
    return validation;
}

// Validates the presence of check and payer related elements while
//  creating a Balance Record EOB.
// The mandatory fields which are blank are caught and an alert is provided to
//  enter them to continue with the process.
function validateCheckAndPayerDetails() {
    var payment_method_flag =  isValidPaymentMethod();
    var validationResult = true
    var payerDetails = ['payer_popup', 'payer_pay_address_one', 'payer_address_two',
    'payer_city_id', 'payer_payer_state', 'payer_zipcode_id'];
    var checkAndPayerDetails = [];
    checkAndPayerDetails.push(payerDetails);
    if($('payment_method') != null){
        validationResult = validateCheckDetailsWithValueOfPaymentMethod(payment_method_flag)
    }
    else if($('correspondence_check') != null && $F('correspondence_check') == "false") {
        var checkDetails = ['checkdate_id', 'checknumber_id', 'checkamount_id'];
        checkAndPayerDetails.push(checkDetails);
    }
    checkAndPayerDetails = checkAndPayerDetails.flatten()
    if (validationResult == true)
        validationResult = validatePresenceOfRequiredFields(checkAndPayerDetails) && payerTypeMandatory();
    return validationResult
}

// Submits the form to create a Balance Record EOB.
function balanceRecordCreation() {
    if(validateCheckAndPayerDetails() == true){

        if($('balance_record_type') != null && $('eob_balance_record_type') != null) {
            var balance_record_type = $F('balance_record_type');
            var saved_balance_record_type = $F('eob_balance_record_type');
            if(balance_record_type.capitalize() != 'None' &&
                saved_balance_record_type.capitalize() == 'None' ||
                saved_balance_record_type == '' ||
                saved_balance_record_type == null) {
                var agree = confirm("A balance Record will be created with type '" + balance_record_type +"'. Do you want to continue?");
                if(agree) {
                    if($('proc_save_eob_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('proc_save_eob_button_id');
                        $('proc_save_eob_button_id').disabled = true;
                    }
                    else if($('qa_save_eob_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('qa_save_eob_button_id');
                        $('qa_save_eob_button_id').disabled = true;
                    }
                    if($('qa_update_job_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('qa_update_job_button_id');
                        $('qa_update_job_button_id').disabled = true;
                    }
                    if($('qa_delete_eob_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('qa_delete_eob_button_id');
                        $('qa_delete_eob_button_id').disabled = true;
                    }
                    document.forms["form1"].submit();
                }
            }
        }

    }
    else
        $('balance_record_type').value = 'None'

}

// Validates if the Check Amount is balanced or not.
// A balanced check will have balance amount with value 0.00.
function isCheckBalanced(){
    var proceed = false;
    var checkForOffset = true;
    if(parent.document.getElementById("resizable") != null){
        if(parent.myiframe.document.getElementById('tab_type').value == 'nextgen'){
            balance_obj = parent.myiframe.document.getElementById('totalbal_id');
        }
        else{
            balance_obj = parent.myiframe.document.getElementById('balance');
        }
        checkForOffset = createOffsetEob();
        if(checkForOffset == true){
            proceed = balanceValidation(balance_obj);
        }
        else{

            proceed = true
        }
    }
    else{
        balance_obj = document.getElementById('balance');
        if(balance_obj != null){
            job_status_obj = document.getElementById('status');
            job_status = job_status_obj.value;
            if(job_status == "Complete") {
                checkForOffset = createOffsetEobForQa();
                if(checkForOffset == true){
                    proceed = balanceValidation(balance_obj);
                }
                else{

                    proceed = true
                }
            }
            else{
                proceed = true;
            }
        }
        else
            proceed = true;
    }
    return proceed;
}

function balanceValidation(balance_obj){
    var balanceAmount = balance_obj.value;
    balanceAmount = parseFloat(balanceAmount);
    if($('provider_adjustment_amount') != null) {
        var adjustmentAmount = parseFloat($F('provider_adjustment_amount'));
        if(adjustmentAmount != balanceAmount && balanceAmount != 0.00) {
            if(isTransactionTypeMissingCheckOrCheckOnly() == false) {
                alert('The check is not balanced yet. Please enter the correct Provider Adjustment Amount, if any');
                return false;
            }
            else
                return true;
        }
        else
            return true;
    }
    else{
        if(balanceAmount != 0.00) {
            if(isTransactionTypeMissingCheckOrCheckOnly() == false) {
                alert('The check needs to be balanced inorder to Complete the job.');
                return false;
            }
            else
                return true;
        }
        else
            return true;
    }
}

function validateEobPresence(eobcount){
    var resultOfValidation = true;
    if(window.frames['myiframe']) {
        var eobCountField = window.frames['myiframe'].document.getElementById("eob_count_value");
    }
    else {
        eobCountField = document.getElementById("eob_count_value");
    }
    if($(eobCountField)) {
        if (parseInt($F(eobCountField)) < 1){
            alert("Atleast one EOB should be saved");
            resultOfValidation = false;
        }
    }
    return resultOfValidation;
}

function validateOrboComplete(eobcount){
    var flag =  validateEobPresence(eobcount)
    if (flag == true)
        return confirm("Are you sure?");
    else
        return flag
}
function disablePayerAddressForApprovedPayers() {
    var isAnyEobPresent = $F('is_any_eob_saved_for_job');
    if($('payer_status') != null && $F('payer_status') !=  '') {
        var itemIds = ['payer_popup', 'payer_pay_address_one', 'payer_address_two', 'payer_city_id',
        'payer_payer_state', 'payer_zipcode_id', 'payer_tin_id'];
        var payerStatus = $F('payer_status').toUpperCase();
        if(isAnyEobPresent == "true" || payerStatus == 'MAPPED' ||  payerStatus == 'UNMAPPED' ||
            payerStatus == 'APPROVED') {
            if(payerStatus == 'MAPPED') {
                removeCustomValidations(itemIds, 'required');
            }
            if($('is_partner_bac') != null && $F('is_partner_bac') == "true")
                makeTextFieldsReadOnlyIrrespectiveOfContent(itemIds);
            else
                makeTextFieldsReadOnly(itemIds);
        }
        else
            unmakeTextFieldsReadOnly(itemIds);
    }
}

function confirmPayerIndicator(){
    var confirmed = true
    if($('payer_indicator') != null && $('payer_payid') != null && $('payer_popup') != null){
        if($F('payer_payid') == "CMUN1" &&
            $('correspondence_batch') != null && $F('correspondence_batch') == 'false') {
            var payer_indicator = $F('payer_indicator');
            if(payer_indicator != "UHC"){
                if($('balance_record_type') != null &&
                    $F('balance_record_type').capitalize() != 'None') {
                    confirmed = true;
                }
                else {
                    var payer_name = $F('payer_popup');
                    var agree = confirm("You are going to change the payer indicator of a payment EOB of " +
                        payer_name + " from CHK to " + payer_indicator + ". Are you sure?");
                    if (agree != true) {
                        $('payer_indicator').focus();
                        confirmed = false;
                    }
                }
            }
        }
    }
    //console_logger('confirmPayerIndicator', confirmed);
    return confirmed;
}

function payerIndicatorForCorrespondenceCheck() {
    if($('payer_payid') != null && $('payer_indicator') != null &&
        $('correspondence_batch') != null) {
        if($F('correspondence_batch') == 'true' && $F('payer_payid') == 'CMUN1') {
            $('payer_indicator').options[$('payer_indicator').length - 1] = null;
            $('payer_indicator').options[$('payer_indicator').length] = new Option('', '');
            $('payer_indicator').options[$('payer_indicator').length] = new Option('CHK', 'UHC');
            $('payer_indicator').options[$('payer_indicator').length] = new Option('PAY', 'UHS');
            for(j = 0; j < $('payer_indicator').options.length; j++) {
                if($("payer_indicator").options[j].value == '') {
                    $("payer_indicator").options[j].selected = true;
                }
            }
        }
    }
}

//The function 'setReasoncodeId' provides the unique code and reason code id in respective fields for auto complete in unique code
//The selected type ahead element is filled in the unique code  like '<unique_code> + <reason_code_id>'
//'onblur' event of the unique code field, this method makes the unique_code and reason code id as hidden placed in the respective fields.
function setReasoncodeId(uniqueCodeFieldId){
    var uniqueCodes = $F(uniqueCodeFieldId);
    var collectionOfWords = uniqueCodeFieldId.split("_");
    var reasonCodeIdFieldId;
    var flag = "1";
    if(collectionOfWords[2] == "claim"){
        var adjustmentReason = collectionOfWords[3];
        if(collectionOfWords[4] != 'unique')
            adjustmentReason = adjustmentReason + '_' + collectionOfWords[4]
        reasonCodeIdFieldId = 'reason_code_id_claim_' + adjustmentReason;
    }

    else {
        adjustmentReason = collectionOfWords[2];
        if(collectionOfWords[3] != 'unique')
            adjustmentReason = adjustmentReason + '_' + collectionOfWords[3]
        reasonCodeIdFieldId = 'reason_code_id_' + adjustmentReason;
    }
    if($(reasonCodeIdFieldId)) {
        if(uniqueCodes != null && uniqueCodes != ""){
            var collectionOfUniqueCodesAndReasonCodeIds;
            if(uniqueCodes.match(/;/) == null)
                collectionOfUniqueCodesAndReasonCodeIds = [uniqueCodes];
            else{
                flag = "0";
                collectionOfUniqueCodesAndReasonCodeIds = uniqueCodes.split(";");
            }
            var requiredData = conditionsForSettingReasonCodeIds(collectionOfUniqueCodesAndReasonCodeIds);
            $(uniqueCodeFieldId).value = requiredData[0];
            $(reasonCodeIdFieldId).value = requiredData[1];
            if(flag == "0")

                $(reasonCodeIdFieldId).value = "";

        }
        else{
            $(reasonCodeIdFieldId).value = "";
            $(uniqueCodeFieldId).value = "";
        }
    }
}

function conditionsForSettingReasonCodeIds(uniqueCodesAndReasoncodeIds){
    var uniqueCodeString;
    var reasonCodeIdString;
    var requiredData = []
    for(index = 0; index < uniqueCodesAndReasoncodeIds.length; index++){
        if(uniqueCodesAndReasoncodeIds[index] != ""){
            if(uniqueCodesAndReasoncodeIds[index].match(/\+/) != null){
                var uniqueCodeAndReasonCodeId = uniqueCodesAndReasoncodeIds[index].split("+");
                if (uniqueCodeString == null){
                    uniqueCodeString = uniqueCodeAndReasonCodeId[0] + "";
                }
                else{
                    uniqueCodeString = uniqueCodeString + ';'+ uniqueCodeAndReasonCodeId[0] + "";
                }
                if (reasonCodeIdString == null){
                    reasonCodeIdString = uniqueCodeAndReasonCodeId[1] + "";
                }
                else{
                    reasonCodeIdString = reasonCodeIdString + ';'+ uniqueCodeAndReasonCodeId[1] + "";
                }
            }
            else{
                if($('default_unique_code_deductible') != null && uniqueCodesAndReasoncodeIds[index] == $F('default_unique_code_deductible')){
                    var idOfDeductible = $F('default_id_deductible');
                    if (reasonCodeIdString == null){
                        reasonCodeIdString = idOfDeductible + "";
                    }
                    else{
                        reasonCodeIdString = reasonCodeIdString + ';'+ idOfDeductible;
                    }
                }
                else if($('default_unique_code_coinsurance') != null && uniqueCodesAndReasoncodeIds[index] == $F('default_unique_code_coinsurance')){
                    var idOfCoinsurance = $F('default_id_coinsurance');
                    if (reasonCodeIdString == null){
                        reasonCodeIdString = idOfCoinsurance + "";
                    }
                    else{
                        reasonCodeIdString = reasonCodeIdString + ';' + idOfCoinsurance + "";
                    }
                }
                else if($('default_unique_code_copay') != null && uniqueCodesAndReasoncodeIds[index] == $F('default_unique_code_copay')){
                    var idOfCopay = $F('default_id_copay');
                    if (reasonCodeIdString == null){
                        reasonCodeIdString = idOfCopay + "";
                    }
                    else{
                        reasonCodeIdString = reasonCodeIdString + ';' + idOfCopay + "";
                    }
                }
                else if($('default_unique_code_primary_payment') != null && uniqueCodesAndReasoncodeIds[index] == $F('default_unique_code_primary_payment')){
                    var idOfPrimaryPayment = $F('default_id_primary_payment');
                    if (reasonCodeIdString == null){
                        reasonCodeIdString = idOfPrimaryPayment + "";
                    }
                    else{
                        reasonCodeIdString = reasonCodeIdString + ';'+ idOfPrimaryPayment + "";
                    }
                }
                else
                    reasonCodeIdString = "";

                if (uniqueCodeString == null){
                    uniqueCodeString = uniqueCodesAndReasoncodeIds[index] + "";
                }
                else{
                    uniqueCodeString = uniqueCodeString + ';'+ uniqueCodesAndReasoncodeIds[index] + "";
                }
            }
        }
    }
    var uniqueCodeArray = uniqueCodeString.split(';')
    var defaultUniqueCode = ['1', '2', '3', '4', '5']
    var defaultUniqueCodeExists = findAnyElement(uniqueCodeArray, defaultUniqueCode)
    if(defaultUniqueCodeExists){
        reasonCodeIdString = "";
    }
    requiredData.push(uniqueCodeString,reasonCodeIdString);
    return requiredData;
}

function setDefaultValuesForPatpay(){
    var insurancePay = $F('insurance_grid');
    var isPopulateDefaultValues = '';
    if($('populate_default_values') != null)
        isPopulateDefaultValues = $F('populate_default_values');
    if(isPopulateDefaultValues == "1" && insurancePay != "true"){
        var patientLastName = $F('patient_last_name_id');
        var patientFirstName = $F('patient_first_name_id');
        var patientSuffix =  $F('patient_suffix_id');
        var patientMiddle = $F('patient_initial_id');
        var patientName = getPatientName();
        if(patientLastName != ""){
            if($F('subcriber_last_name_id') == "")
                $('subcriber_last_name_id').value = patientLastName;
        }
        if(patientFirstName != ""){
            if($F('subcriber_firstname_id') == "")
                $('subcriber_firstname_id').value = patientFirstName;
        }
        if(patientSuffix != ""){
            if($F('subcriber_suffix_id') == "")
                $('subcriber_suffix_id').value = patientSuffix;
        }
        if(patientMiddle != ""){
            if($F('subcriber_initial_id') == "")
                $('subcriber_initial_id').value = patientMiddle;
        }
        if($F('payer_popup') == "")
            $('payer_popup').value = patientName;
    }
//console_logger('setDefaultValuesForPatpay', true);
}

function hideAdjustmentLine() {
    if($('hide_adjustment_line') != null && $F('hide_adjustment_line') == "true"){
        row = "service_row" + '1';
        if($(row) != null)
            $(row).style.display = 'none';
    }
}

function isPayerTypeSet(){
    var payerTypeObject = document.form1.payer_type;
    var getSelectedIndexOfPayerType = payerTypeObject.selectedIndex;
    var payerType = payerTypeObject[getSelectedIndexOfPayerType].value;
    var countOfOptionsOfPayerType = payerTypeObject.length;
    var result = true;
    var valPayerType = $F('payer_id');
    if($F('payer_popup') != "" && (valPayerType == "null" || valPayerType == "undefined" || valPayerType.length == 0)) {
        if( payerType == "--"){
            if( countOfOptionsOfPayerType == 3 ){
                alert("New Payer should have Commercial or PatPay as payer type.");
                payerTypeObject.focus();
                result = false;
            }
            else if( countOfOptionsOfPayerType == 2){
                for(j = 0; j < countOfOptionsOfPayerType; j++){
                    if(payerTypeObject[j].value != "--"){
                        payerTypeObject[j].selected = true;
                    }
                }
                result = true;
            }
            else{
                alert("New Payer can't be entered since the Commercial Payer is not set for this Lockbox.");
                payerTypeObject.focus();
                result = false;
            }
        }
    }
    return result;
}

function resetPayerAssociatedData(){
    var payer_name = $F('payer_popup').strip();
    if(( $F('hidden_payer_name') == '') || $F('hidden_payer_name').toUpperCase() == payer_name.toUpperCase())
        $('hidden_payer_name').value = payer_name;
    else {
        alert('Since you have changed the payer, please re-enter the unique codes.');
        var url = relative_url_root() + '/application/clean_up_reason_codes_jobs';
        var parameters = 'job_id=' + $('job_id').value + '&get_deleted_rc_jobs_count=true';
        var rcjobsAjax = new Ajax.Request(url, {
            method: 'get',
            parameters: parameters,
            onComplete: function cleanUpRcGrid(deleted_row_count){
                var deletedRows = deleted_row_count.responseText;
                var table = document.getElementById("reason_code_grid");
                for (i = 1; i <= deletedRows; i = (i+1)){
                    table.deleteRow(1);
                };
                clearInvalidUniqueCodes();
            }
        });
        $('hidden_payer_name').value = payer_name;
    }
}

function clearInvalidUniqueCodes() {
    $$('.validate-unique-code').each(
        function(item) {
            if($(item) != null)
                item.value = '';
        });
}

function isUniqueCodeValid(id){
    var input = $F(id);
    var resultOfValidation = true;
    var arrayOfIdsAndCodes = [];
    if(validHipaaAndUniqueCodes != ""){
        var validUniqueCodesArray;
        var testValues = [];
        if(validHipaaAndUniqueCodes.match(/\;/) != null)
            validUniqueCodesArray = validHipaaAndUniqueCodes.split(";");
        else
            validUniqueCodesArray = [validHipaaAndUniqueCodes];
        var validToContainSeparator = ($('multiple_reason_codes_in_adjustment_field') &&
            $F('multiple_reason_codes_in_adjustment_field') == 'true')
        if(validToContainSeparator == false && input.match(/\;/) != null)
            resultOfValidation = false;
        if(resultOfValidation == true) {
            if(validToContainSeparator == true)
                testValues = input.split(";");
            else
                testValues = [input];
            arrayOfIdsAndCodes.push([id, testValues]);

            var invalidUniqueCodes = compareTwoArrays(validUniqueCodesArray, testValues);
            invalidUniqueCodes = sanitizeArray(invalidUniqueCodes);
            if(invalidUniqueCodes.length != 0)
                resultOfValidation = false;
        }
        if(resultOfValidation) {
            resultOfValidation = validateCountOfHipaaCodes(arrayOfIdsAndCodes, false);
        }
    }
    return resultOfValidation;
}

function getthewindow(){
    if($("insurance").value==0){
        populatePayerInfo('payer_popup');
    }
}

function display_footnote_payer_alert(is_footnote_payer){
    if(is_footnote_payer)
        alert("This is a footnote based payer, please key-in reason code descriptions first.");
}

function set_payer_details() {
    $('payerid').value = document.getElementById('payer_id').value;
    $('payer_name').value = document.getElementById('payer_popup').value;
    $('payer_add_one').value = document.getElementById('payer_pay_address_one').value;
    $('payer_add_two').value = document.getElementById('payer_address_two').value;
    $('payer_city').value = document.getElementById('payer_city_id').value;
    $('payer_state').value = document.getElementById('payer_payer_state').value;
    $('payer_zip').value = document.getElementById('payer_zipcode_id').value;
}

function setDefaultClaimTypeForQAView(elementId){
    var dollar_amts = ["co_insurance","deductable", "deductible", "copay", "co_pay",
    "primary_pay_payment", "service_submitted_charge_for_claim_id","charges_id",
    "service_procedure_charge_amount_id","payment_id","service_paid_amount_id"];
    for (var i = 0; i < dollar_amts.length; i++) {
        if (elementId.match(dollar_amts[i])) {
            for(j = 0; j < $("claim_type").options.length; j++) {
                if($("claim_type").options[j].value == "--") {
                    $("claim_type").options[j].selected = true;
                }
            }
        }
    }
}

function validateAddRowAdjustmentAmounts() {
    var validation = true;
    var amountFieldIds = ['non_covered_id', 'denied_id', 'discount_id',
    'co_insurance_id', 'deductable_id', 'copay_id', 'primary_pay_payment_id',
    'prepaid_id', 'patient_responsibility_id', 'contractualamount_id',
    'miscellaneous_one_id', 'miscellaneous_two_id'];
    var uniqueCodeIds = ['reason_code_noncovered_unique_code', 'reason_code_denied_unique_code',
    'reason_code_discount_unique_code', 'reason_code_coinsurance_unique_code',
    'reason_code_deductible_unique_code', 'reason_code_copay_unique_code',
    'reason_code_primary_payment_unique_code', 'reason_code_prepaid_unique_code',
    'reason_code_patient_responsibility_unique_code', 'reason_code_contractual_unique_code',
    'reason_code_miscellaneous_one_unique_code', 'reason_code_miscellaneous_two_unique_code'];
    var adjustmentAmountValue;
    var emptyAdjustmentReasons = [];
    var emptyAdjustmentAmountFieldIds = [];
    var adjustmentReason;
    for(i = 0; i < amountFieldIds.length; i++) {
        if($(amountFieldIds[i]) != null && $(uniqueCodeIds[i]) != null) {
            adjustmentAmountValue = $F(amountFieldIds[i]);

            var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');

            if(isAdjustmentAmountZero &&
                (adjustmentAmountValue != '' && parseFloat(adjustmentAmountValue) == 0))
                var amountCondition = ((adjustmentAmountValue).strip() == '');
            else
                amountCondition = (adjustmentAmountValue.strip() == '' || parseFloat(adjustmentAmountValue) == 0);
            if(($F(uniqueCodeIds[i])).strip() != '' && amountCondition) {
                adjustmentReason = uniqueCodeIds[i].split('_');
                emptyAdjustmentReasons.push(adjustmentReason[2].capitalize());
                emptyAdjustmentAmountFieldIds.push(amountFieldIds[i]);
            }
        }
    }
    if(emptyAdjustmentReasons.length > 0) {
        var indexOfPrimaryPayment = emptyAdjustmentReasons.indexOf('Primary');
        emptyAdjustmentReasons[indexOfPrimaryPayment] = 'PPP';
        var indexOfPatientResponsibility = emptyAdjustmentReasons.indexOf('Patient');
        emptyAdjustmentReasons[indexOfPatientResponsibility] = 'Patient Responsibility';
        if($('is_adjustment_amount_mandatory') != null && $F('is_adjustment_amount_mandatory') == 'true') {
            validation = false;
            alert("Please enter the adjustment amounts for the following adjustment reasons.\n\
            " + emptyAdjustmentReasons);
            setTimeout(function() {
                $(emptyAdjustmentAmountFieldIds[0]).focus();
            }, 20);

        }
        else {
            var toContinue = confirm('There are no adjustment amounts against the following adjustment reasons. \n\
                Are you sure?\n\
                '+ emptyAdjustmentReasons);
            validation = toContinue;
        }
    }
    return validation;

}

function validateAddRowReasonCodes() {
    var validation = true;
    var amountFieldIds = ['non_covered_id', 'denied_id', 'discount_id',
    'co_insurance_id', 'deductable_id', 'copay_id', 'primary_pay_payment_id',
    'prepaid_id', 'patient_responsibility_id', 'contractualamount_id',
    'miscellaneous_one_id', 'miscellaneous_two_id'];
    var uniqueCodeIds = ['reason_code_noncovered_unique_code', 'reason_code_denied_unique_code',
    'reason_code_discount_unique_code', 'reason_code_coinsurance_unique_code',
    'reason_code_deductible_unique_code', 'reason_code_copay_unique_code',
    'reason_code_primary_payment_unique_code', 'reason_code_prepaid_unique_code',
    'reason_code_patient_responsibility_unique_code', 'reason_code_contractual_unique_code',
    'reason_code_miscellaneous_one_unique_code', 'reason_code_miscellaneous_two_unique_code'];
    var emptyUniqueCodeId;
    var emptyUniqueCodeIds = [];
    var adjustmentReason;
    var adjustmentReasonArray = [];
    var emptyAdjustmentReasons = [];

    for(i = 0; i < amountFieldIds.length; i++) {
        if($(amountFieldIds[i]) != null && $(uniqueCodeIds[i]) != null && $F(amountFieldIds[i]) != '') {
            emptyUniqueCodeId = reasonCodesValidation(amountFieldIds[i], uniqueCodeIds[i]);
            if(emptyUniqueCodeId != null) {
                adjustmentReasonArray = emptyUniqueCodeId.split('_');
                adjustmentReason = adjustmentReasonArray[2];
                if(adjustmentReasonArray[3] != 'unique')
                    adjustmentReason = adjustmentReason + adjustmentReasonArray[3];
                emptyAdjustmentReasons.push(adjustmentReason.capitalize());
                emptyUniqueCodeIds.push(emptyUniqueCodeId);
            }
        }
    }
    if(emptyAdjustmentReasons.length > 0) {
        var indexOfPrimaryPayment = emptyAdjustmentReasons.indexOf('Primary');
        emptyAdjustmentReasons[indexOfPrimaryPayment] = 'PPP';
        var indexOfPatientResponsibility = emptyAdjustmentReasons.indexOf('Patient');
        emptyAdjustmentReasons[indexOfPatientResponsibility] = 'Patient Responsibility';
        var indexOfMiscellaneousOne = emptyAdjustmentReasons.indexOf('Miscellaneousone');
        emptyAdjustmentReasons[indexOfMiscellaneousOne] = 'Misc Adj1';
        var indexOfMiscellaneousTwo = emptyAdjustmentReasons.indexOf('Miscellaneoustwo');
        emptyAdjustmentReasons[indexOfMiscellaneousTwo] = 'Misc Adj2';
        if($('is_reason_code_mandatory') != null && $F('is_reason_code_mandatory') == 'true') {
            validation = false;
            alert("Please enter the Unique Codes for the following amount fields.\n\
            " + emptyAdjustmentReasons);
            setTimeout(function() {
                $(emptyUniqueCodeIds[0]).focus();
            }, 20);

        }
        else {
            var toContinue = confirm('There are no unique codes against the following adjustment amount fields.\n\
                 Are you sure?\n\
                '+ emptyAdjustmentReasons);
            validation = toContinue;
        }

    }
    return validation;
}

function reasonCodesValidation(amountFieldID, uniqueCodeID) {
    var emptyUniqueCodeId;
    if($(amountFieldID) != null) {
        var adjustmentAmountValue = $F(amountFieldID);
        var isReasonCodeMandatory = ($('is_reason_code_mandatory') != null && $F('is_reason_code_mandatory') == 'true');
        var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');
        if(isReasonCodeMandatory && isAdjustmentAmountZero &&
            (adjustmentAmountValue != '' && parseFloat(adjustmentAmountValue) == 0))
            var amountCondition = (($F(amountFieldID)).strip() != '');
        else
            amountCondition = (($F(amountFieldID)).strip() != '' && parseFloat($F(amountFieldID)) != 0);
        if(amountCondition) {
            if($(uniqueCodeID) != null && ($F(uniqueCodeID)).strip() == '') {
                emptyUniqueCodeId = uniqueCodeID;
            }
        }
    }
    return emptyUniqueCodeId;
}

function validateCorrectnessOfReasonCodes() {
    var validation = true;
    var uniqueCodeIds = ['reason_code_noncovered_unique_code', 'reason_code_denied_unique_code',
    'reason_code_discount_unique_code', 'reason_code_coinsurance_unique_code',
    'reason_code_deductible_unique_code', 'reason_code_copay_unique_code',
    'reason_code_primary_payment_unique_code', 'reason_code_prepaid_unique_code',
    'reason_code_patient_responsibility_unique_code', 'reason_code_contractual_unique_code',
    'reason_code_miscellaneous_one_unique_code', 'reason_code_miscellaneous_two_unique_code'];
    var allUniqueCodes = [];
    var uniqueCodesFromField = [];
    var uniqueCodesFromFieldValue;
    var values;
    var arrayOfIdsAndCodes = [];
    validHipaaAndUniqueCodes += ';';
    allUniqueCodes = validHipaaAndUniqueCodes.split(';');
    var invalidUniqueCodes = [];
    for(i = 0; i < uniqueCodeIds.length; i++) {
        if($(uniqueCodeIds[i]) != null && $F(uniqueCodeIds[i]) != '') {
            uniqueCodesFromFieldValue = $F(uniqueCodeIds[i]);

            var validToContainSeparator = ($('multiple_reason_codes_in_adjustment_field') &&
                $F('multiple_reason_codes_in_adjustment_field') == 'true')
            if(validToContainSeparator != true && uniqueCodesFromFieldValue.match(/\;/) != null) {
                validation = false;
                alert('Multiple codes cannot be entered in ' + uniqueCodesFromFieldValue)
                break;
            }
            values = uniqueCodesFromFieldValue.split(';');
            uniqueCodesFromField.push(values);
            arrayOfIdsAndCodes.push([uniqueCodeIds[i], values]);
        }
    }
    if(validation) {
        uniqueCodesFromField = sanitizeArray(uniqueCodesFromField);
        if(uniqueCodesFromField.length > 0) {
            invalidUniqueCodes = compareTwoArrays(allUniqueCodes, uniqueCodesFromField);
            if(invalidUniqueCodes.length > 0) {
                validation = false;
                alert("Following are the invalid adjustment codes.\n\
            " + invalidUniqueCodes);
            }
        }
        if(validation) {
            validation = validateCountOfHipaaCodes(arrayOfIdsAndCodes, true);
        }
    }
    return validation;

}

function validateCountOfHipaaCodes(arrayOfIdsAndCodes, isAlertNeeded) {
    var resultOfValidation = true;
    var hipaaCodesFromField = [];
    var hipaaCodesFromFieldLength;
    var fieldId;
    var arrayOfCodes = [];
    var invalidFieldIds = [];
    var invalidAdjustmentReason = [];
    var adjustmentReason;
    var standardHipaaCodes = [];
    if($('hipaa_adjustment_codes_field') && arrayOfIdsAndCodes.length > 0) {
        for(var j = 0; j < arrayOfIdsAndCodes.length; j++) {
            fieldId = arrayOfIdsAndCodes[j][0];
            arrayOfCodes = arrayOfIdsAndCodes[j][1];
            if(arrayOfCodes.length > 1) {
                standardHipaaCodes = $F('hipaa_adjustment_codes_field').split(',');
                hipaaCodesFromField = arrayElementsFoundInAnotherArray(standardHipaaCodes, arrayOfCodes);
                hipaaCodesFromFieldLength = hipaaCodesFromField.length;
                if(hipaaCodesFromFieldLength > 1 || (hipaaCodesFromFieldLength > 0 && hipaaCodesFromFieldLength != arrayOfCodes.length)) {
                    invalidFieldIds.push(fieldId);
                }
            }
        }

        var invalidFieldIdsLength = invalidFieldIds.length;
        if(invalidFieldIdsLength > 0) {
            for(var k = 0; k < invalidFieldIdsLength; k++) {
                adjustmentReason = findAdjustmentReason(invalidFieldIds[k]);
                invalidAdjustmentReason.push(adjustmentReason);
            }
            resultOfValidation = false;
            if(isAlertNeeded)
                alert("Please enter either all reason codes or one HIPAA Code for the fields  " + invalidAdjustmentReason);
        }
    }
    return resultOfValidation;
}

function findAdjustmentReason(toMatch){
    var adjustmentReasons = ["noncovered", "non_covered", "discount",
    "denied", "coinsurance", 'co_insurance', "deductuble", "deductible", "deductable",
    "copay", "co_pay", "primary_payment", "service_submitted_charge_for_claim_id",
    "prepaid", "patient_responsibility", "contractual", "miscellaneous_one",
    "miscellaneous_two"];
    var matchedAdjustmentReason = null;
    for (var i = 0; i < adjustmentReasons.length; i++) {
        if (toMatch.match(adjustmentReasons[i])) {
            matchedAdjustmentReason = adjustmentReasons[i];
            break;
        }
    }
    if(matchedAdjustmentReason == 'non_covered')
        matchedAdjustmentReason = 'noncovered';
    else if(matchedAdjustmentReason == 'deductuble' || matchedAdjustmentReason == 'deductable')
        matchedAdjustmentReason = 'deductible';
    else if(matchedAdjustmentReason == 'co_pay')
        matchedAdjustmentReason = 'copay';
    else if(matchedAdjustmentReason == 'service_submitted_charge_for_claim_id')
        matchedAdjustmentReason = 'primary_payment';
    else if(matchedAdjustmentReason == 'co_insurance')
        matchedAdjustmentReason = 'coinsurance';
    else if(matchedAdjustmentReason == 'patient_responsibility')
        matchedAdjustmentReason = 'patient_responsibility';

    return matchedAdjustmentReason;
}

function validatePresenceOfUniqueCodeForOrphanAdjustmentAmount() {
    var adjustmentAmountId;
    var adjustmentAmountValue;
    var orphanAdjustmentAmountIds = [];
    var svcLineSerialNum;
    var adjustmentReason;
    var uniqueCodeId;
    var validationResult;
    var proceed;
    $$(".validate-presence-of-unique-code").each(
        function(item) {
            adjustmentAmountId = item.id;
            adjustmentAmountValue = item.value;
            setHighlight([adjustmentAmountId], 'blank');
            proceed = false;
            if(adjustmentAmountId.match('total')) {
                if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
                    proceed = true;
                else
                    proceed = false;
            }
            else proceed = true;
            var isReasonCodeMandatory = ($('is_reason_code_mandatory') != null && $F('is_reason_code_mandatory') == 'true');
            var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');
            if(isReasonCodeMandatory && isAdjustmentAmountZero &&
                (adjustmentAmountValue != '' && parseFloat(adjustmentAmountValue) == 0))
                var amountCondition = (adjustmentAmountValue != '');
            else
                amountCondition = (adjustmentAmountValue != '' && parseFloat(adjustmentAmountValue) != 0);

            if(proceed && amountCondition) {
                svcLineSerialNum = adjustmentAmountId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                adjustmentReason = findAdjustmentReason(adjustmentAmountId);
                uniqueCodeId = getUniqueCodeId(adjustmentReason, svcLineSerialNum);
                if($(uniqueCodeId) != null && ($F(uniqueCodeId)).strip() == '') {
                    orphanAdjustmentAmountIds.push(adjustmentAmountId);
                }
            }
        });
    if(orphanAdjustmentAmountIds.length > 0) {
        setHighlight(orphanAdjustmentAmountIds, "uncertain");
        if($('is_reason_code_mandatory') != null && $F('is_reason_code_mandatory') == 'true') {
            validationResult = false;
            alert("Please enter the Unique Codes against the highlighted adjustment amount fields");
        }
        else {
            var toContinue = confirm('There are no unique codes against the highlighted adjustment amount fields. Are you sure?');
            validationResult = toContinue;
        }
    }
    else
        validationResult = true;
    //console_logger('validatePresenceOfUniqueCodeForOrphanAdjustmentAmount', validationResult);
    return validationResult;
}

function validatePresenceOfAdjustmentAmountForOrphanUniqueCode() {
    var uniqueCodeId;
    var adjustmentAmountId;
    var uniqueCodeValue;
    var orphanUniqueCodeIds = [];
    var svcLineSerialNum;
    var adjustmentReason;
    var validationResult;
    var proceed;
    $$(".validate-presence-of-adjustment-amount").each(
        function(item) {
            uniqueCodeId = item.id;
            uniqueCodeValue = item.value;
            proceed = false;
            setHighlight([uniqueCodeId], 'blank');
            svcLineSerialNum = uniqueCodeId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
            if(uniqueCodeId.match('claim') || svcLineSerialNum == '') {
                if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
                    proceed = true;
                else
                    proceed = false;
            }
            else proceed = true;
            if(proceed && uniqueCodeValue != '') {
                adjustmentReason = findAdjustmentReason(uniqueCodeId);
                adjustmentAmountId = getAdjustmentAmountIds(adjustmentReason, svcLineSerialNum);
                if($(adjustmentAmountId) != null) {
                    var adjustmentAmountValue = $F(adjustmentAmountId);
                    var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');
                    if(isAdjustmentAmountZero &&
                        (adjustmentAmountValue != '' && parseFloat(adjustmentAmountValue) == 0))
                        var amountCondition = ((adjustmentAmountValue).strip() == '');
                    else
                        amountCondition = ((adjustmentAmountValue).strip() == '' ||
                            parseFloat(adjustmentAmountValue) == 0);

                    if(amountCondition) {
                        orphanUniqueCodeIds.push(uniqueCodeId);
                    }
                }
            }
        });

    $$(".validate-presence-of-adjustment-amount-in-added-row").each(
        function(item) {
            uniqueCodeId = item.id;
            uniqueCodeValue = item.value;
            setHighlight([uniqueCodeId], 'blank');
            svcLineSerialNum = uniqueCodeId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
            if(uniqueCodeValue != '') {
                adjustmentReason = findAdjustmentReason(uniqueCodeId);
                adjustmentAmountId = getAdjustmentAmountIds(adjustmentReason, svcLineSerialNum);
                if($(adjustmentAmountId) != null) {
                    var isAdjustmentAmountZero = ($('is_adjustment_amount_zero') != null && $F('is_adjustment_amount_zero') == 'true');
                    if(isAdjustmentAmountZero &&
                        ($F(adjustmentAmountId) != '' && parseFloat($F(adjustmentAmountId)) == 0))
                        var amountCondition = (($F(adjustmentAmountId)).strip() == '');
                    else
                        amountCondition = (($F(adjustmentAmountId)).strip() == '' ||
                            parseFloat($F(adjustmentAmountId)) == 0);
                    if(amountCondition) {
                        orphanUniqueCodeIds.push(uniqueCodeId);
                    }
                }
            }
        });
    if(orphanUniqueCodeIds.length > 0) {
        setHighlight(orphanUniqueCodeIds, "uncertain");
        if($('is_adjustment_amount_mandatory') != null && $F('is_adjustment_amount_mandatory') == 'true') {
            validationResult = false;
            alert("Please enter the adjustment amounts for the highlighted Unique Code fields");
        }
        else {
            var toContinue = confirm('There are no adjustment amount against the highlighted unique code fields. Are you sure?');
            validationResult = toContinue;
        }
    }
    else
        validationResult = true;
    //console_logger('validatePresenceOfAdjustmentAmountForOrphanUniqueCode', validationResult);
    return validationResult;
}

function getAdjustmentAmountIds(adjustmentReason, svcLineSerialNum) {
    var adjustmentAmountFieldId = null;
    if(adjustmentReason == 'noncovered') {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_non_covered_id';
        else
            adjustmentAmountFieldId = 'service_non_covered_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'denied' && $F('denied_status') == "true") {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_denied_id';
        else
            adjustmentAmountFieldId = 'denied_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'miscellaneous_one' && $F('miscellaneous_one_status') == "true") {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_miscellaneous_one_id';
        else
            adjustmentAmountFieldId = 'miscellaneous_one_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'miscellaneous_two' && $F('miscellaneous_two_status') == "true") {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_miscellaneous_two_id';
        else
            adjustmentAmountFieldId = 'miscellaneous_two_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'discount') {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_discount_id';
        else
            adjustmentAmountFieldId = 'service_discount_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'coinsurance') {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_coinsurance_id';
        else
            adjustmentAmountFieldId = 'service_co_insurance_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'deductible' || adjustmentReason == "deductable") {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_deductable_id';
        else
            adjustmentAmountFieldId = 'service_deductible_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'copay' &&
        ($('total_copay_id') != null || $('service_co_pay_id' + svcLineSerialNum) != null)) {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_copay_id';
        else
            adjustmentAmountFieldId = 'service_co_pay_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'primary_payment') {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_primary_payment_id';
        else
            adjustmentAmountFieldId = 'service_submitted_charge_for_claim_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'prepaid' && $F('prepaid_status') == "true") {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_prepaid_id';
        else
            adjustmentAmountFieldId = 'prepaid_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'patient_responsibility' && $F('patient_responsibility_status') == "true") {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_patient_responsibility_id';
        else
            adjustmentAmountFieldId = 'patient_responsibility_id' + svcLineSerialNum;
    }
    else if(adjustmentReason == 'contractual' &&
        ($('total_contractual_amount_id') != null || $('service_contractual_amount_id' + svcLineSerialNum))) {
        if($('claim_level_eob') != null && $F('claim_level_eob') == 'true')
            adjustmentAmountFieldId = 'total_contractual_amount_id';
        else
            adjustmentAmountFieldId = 'service_contractual_amount_id' + svcLineSerialNum;
    }
    return adjustmentAmountFieldId;
}

function getUniqueCodeId(adjustmentReason, svcLineSerialNum) {
    var uniqueCodeId = null;
    if($('claim_level_eob') != null && $F('claim_level_eob') == 'true'){
        uniqueCodeId = 'reason_code_claim_' + adjustmentReason + svcLineSerialNum + '_unique_code';
    }
    else{
        uniqueCodeId = 'reason_code_' + adjustmentReason + svcLineSerialNum + '_unique_code';
    }
    return uniqueCodeId;
}

//This is for setting Patient Identification code as 'BALANCERECORD'
//if qualifier is HIC and eob is balance record.
//This will invoke onblur of Qualifier.
//This is applicable for sitecode = 896
function setPatientIdentificationCodeForSitecode896(){
    var sitecode = $F('sitecode');
    var qualifier = $F('qualifier');
    //   sitecode = sitecode.replace(/^[0]+/,'')//sitecode after trimming left padded zeroes
    var patientIdentificationCode = $F('patient_identification_code_id');
    if(sitecode == "896"){
        if($('eob_balance_record_type') != null && $F('eob_balance_record_type') != ""){
            if(qualifier == "HIC")
                $('patient_identification_code_id').value = "BALANCERECORD";
            else{
                if(patientIdentificationCode == "BALANCERECORD")
                    $('patient_identification_code_id').value = "";
                else
                    $('patient_identification_code_id').value = patientIdentificationCode;
            }
        }
    }
}

String.prototype.startsWith = function(prefix) {
    return this.indexOf(prefix) === 0;
}

function checkAccountNumberPrefix(accNumId){
    var facility = $F('facility').toUpperCase();
    var clientCode = $F('sitecode').toUpperCase();
    var accountNumber = $F(accNumId).toUpperCase();
    var checkPrefix  = $F('details_account_num_prefix');
    var message;
    var result = true;
    if (checkPrefix == 'true'){
        message = "Patient Account Number should start with the Client Code : " + clientCode
        result = validatePrefix(message, accountNumber, clientCode, accNumId)
    }
    else if ((checkPrefix == 'false' || checkPrefix == '') && facility == 'MERCY HEALTH PARTNERS'){
        message = "This is not a valid account number. Please correct it"
        result =  validateAccountNumberPrefixForMercyHealthPartners(message, accountNumber, clientCode, accNumId)
    }
    return result;
}
function validatePrefix(message, accountNumber, clientCode, accNumId) {
    if (accountNumber != "" && accountNumber.startsWith(clientCode) == false  && clientCode != ""){
        alert(message);
        setTimeout(function() {
            document.getElementById(accNumId).focus();
        }, 10);
        return false;
    }
    else
        return true;
}

function validateAccountNumberPrefixForMercyHealthPartners(message, accountNumber, clientCode, accNumId) {
    if (accountNumber != "" && accountNumber.startsWith('M0') == true  && clientCode == "MO"){
        alert(message);
        setTimeout(function() {
            document.getElementById(accNumId).focus();
        }, 10);
        return false;
    }
    else
        return true;
}

function getConfirmationToCaptureChargeAmountInOtherAmounts(elementId){
    var confirmation;
    var result = true;
    var charge_amount_applicable_amount_fields_other_than_denied = ['non_covered', 'noncovered',
    'discount', 'co_insurance', 'coinsurance', 'deductable', 'deductible',
    'copay', 'co_pay', 'primary_pay_payment', 'service_submitted_charge_for_claim_id',
    'primary_payment', 'contractual', 'service_paid_amount_id', 'payment',
    'total_payment_id', 'miscellaneous_one', 'miscellaneous_two', 'miscellaneous_balance'];

    for (var i = 0; i < charge_amount_applicable_amount_fields_other_than_denied.length; i++) {
        if (elementId.match(charge_amount_applicable_amount_fields_other_than_denied[i])) {
            if($F(elementId) != "" && parseFloat($F(elementId)) > 0.0){
                if (processing) return false;
                processing = 1;
                confirmation = confirm("You are supposed to balance the EOB by capturing Charge amount in the Denied. Are you sure to continue?");
                if (confirmation == true){
                    processing = 0;
                    result = true;
                }
                else{
                    setTimeout(function() {
                        $(elementId).focus();
                    }, 0);
                    setTimeout(('processing = 0'), 50);
                    result = false;
                }
            }
            break;
        }
    }
    return result;
}

function setSubmitButtonValue(value){
    if ($('submit_button_name') != null){
        $('submit_button_name').value = value;
    }
    return true;
//console_logger('setSubmitButtonValue', $('submit_button_name').value);
}

function setJobButtonValue(value){
    if ($('submit_button_name') != null){
        $('submit_button_name').value = value;
    }
    return 1;
}

function validateQuantity(fieldId) {
    var isValid = true;
    if($(fieldId) != null) {
        var fieldValue = $F(fieldId);
        if(fieldValue.strip() != '') {
            if(fieldValue.match(/^[\-\d]{0,3}[\.\d]{0,3}$/) == null) {
                isValid = false;
                alert('Quantity should be a real number, Eg : 99.99 or -99.99');
                $(fieldId).focus();
            }
        }
    }
    return isValid;
}

function validateProviderAdjustment() {
    if($('prov_adjustment_amount_id') != null && ($F('prov_adjustment_amount_id')).strip() == '') {
        alert("Please enter the amount");
        $('prov_adjustment_amount_id').focus();
        return false;
    }
    else return true;
}


function adjustHeightOfServiceLineTable() {
    if($('service_line_div') != null) {
        var svcLineLength = parseInt($F('total_existing_number_of_svc_lines'));
        var height;
        if(svcLineLength <= 3)
            height = svcLineLength * 10 + 16;
        else
            height = 76;
        $('service_line_div').style.height = height + 'px';
    }
}

function showInfo(id, show) {
    if($(id) != null) {
        visibility = $(id).style.visibility;
        if(visibility == "hidden")
            $(id).style.visibility = "visible";
        else
            $(id).style.visibility = "hidden";
    }
}

function auto_patient_detail() {
    $("patient_first_name").value = $F("patient_first_name_id");
    $("patient_last_name").value = $F("patient_last_name_id");
    $("patient_initial").value = $F("patient_initial_id");
    $("patient_suffix").value = $F("patient_suffix_id");
    $("check_number").value = $F("checknumber_id");
}

//This is for validating dollar amount , can have up to 2 decimal places.
function validateDollarAmount(id){
    var amount = $F(id);
    var result = true;
    var matchString = /^\$?\-?([1-9]{1}[0-9]{0,2}(\,[0-9]{3})*(\.[0-9]{0,2})?|[1-9]{1}\d*(\.[0-9]{0,2})?|0(\.[0-9]{1,2})?|(\.[0-9]{1,2})?|(0[1-9]{1}.[0-9]{1,2})?)$/;
    if (amount != ''){
        if (amount.match(matchString))
            result = true;
        else{
            alert('Invalid Amount!');
            setTimeout(function() {
                document.getElementById(id).focus();
            }, 10);
            result = false;
        }
    }
    return result;
}

function validatePlanCoverage(id){
    var plan_coverage = $F(id);
    var result = true;
    if ($(id) !=  null && plan_coverage != ''){
        if ((plan_coverage.match(/^0*(?:[0-9]{1,2}|100)$/)) ){
            $(id).value = parseFloat($F(id));
            result = true;
        }

        else{
            alert('Invalid Plan coverage');
            setTimeout(function() {
                document.getElementById(id).focus();
            }, 10);
            result = false;
        }
    }
    return result;
}

function setTdWidthOfRow(svcLineCount) {
    var totalWidth = 0;
    var label_fields_and_text_field_tds = [['label_from_date', 'td_date_service_from_'],
    ['label_to_date','td_date_service_to_' ],
    ['label_procedure_code', 'td_procedure_code_'],
    ['label_bundled_procedure_code', 'td_bundled_procedure_code_'],
    ['label_rx_code', 'td_rx_code_'],
    ['label_revenue_code', 'td_revenue_code_'],
    ['label_line_item', 'td_line_item_number_'],
    ['label_reference_code', 'td_provider_control_number_'],
    ['label_units', 'td_units_'],
    ['label_payment_status_code', 'td_payment_status_code_'],
    ['label_remark_code', 'td_remark_code_'],
    ['label_charge', 'td_charge_amount_'],
    ['label_pbid', 'td_pbid_amount_'],
    ['label_allow', 'td_allowable_amount_'],
    ['label_drg_amount', 'td_drg_amount_'],
    ['label_expected_payment', 'td_expected_payment_amount_'],
    ['label_retention_fee' , 'td_retention_fee_amount_'],
    ['label_prepaid' , 'td_prepaid_amount_'],
    ['label_patient_responsibility' , 'td_patient_responsibility_amount_'],
    ['label_plan_coverage' , 'td_plan_coverage_amount_'],
    ['label_payment', 'td_payment_amount_'],
    ['label_balance', 'td_balance_amount_'],
    ['label_add_or_delete', 'td_add_or_delete_']
    ]

    var label_fields_and_text_field_tds_with_colspan = [
    ['label_modifier',  ['td_service_modifier1_id' + svcLineCount, 'td_service_modifier2_id' + svcLineCount,
    'td_service_modifier3_id' + svcLineCount, 'td_service_modifier4_id' + svcLineCount] ],
    ['label_non_covered', ['td_noncovered_amount_' + svcLineCount, 'td_reason_code_noncovered' + svcLineCount + '_unique_code']],
    ['label_denied', ['td_denied_amount_' + svcLineCount, 'td_reason_code_denied' + svcLineCount + '_unique_code']],
    ['label_discount', ['td_discount_amount_' + svcLineCount, 'td_reason_code_discount' + svcLineCount + '_unique_code']],
    ['label_coinsurance', ['td_coinsurance_amount_' + svcLineCount, 'td_reason_code_coinsurance' + svcLineCount + '_unique_code']],
    ['label_deductible', ['td_deductible_amount_' + svcLineCount, 'td_reason_code_deductible' + svcLineCount + '_unique_code']],
    ['label_copay', ['td_copay_amount_' + svcLineCount, 'td_reason_code_copay' + svcLineCount + '_unique_code']],
    ['label_primary_payment', ['td_primary_payment_amount_' + svcLineCount, 'td_reason_code_primary_payment' + svcLineCount + '_unique_code']],
    ['label_contractual', ['td_contractual_amount_' + svcLineCount, 'td_reason_code_contractual' + svcLineCount + '_unique_code']],
    ['label_miscellaneous_one', ['td_miscellaneous_one_amount_' + svcLineCount, 'td_reason_code_miscellaneous_one' + svcLineCount + '_unique_code']],
    ['label_miscellaneous_two', ['td_miscellaneous_two_amount_' + svcLineCount, 'td_reason_code_miscellaneous_two' + svcLineCount + '_unique_code']],
    ['label_miscellaneous_balance', ['td_miscellaneous_balance_amount_' + svcLineCount, 'td_reason_code_miscellaneous_balance' + svcLineCount + '_unique_code']]
    ]


    var label, text_field_td, text_field_tds, width, width_of_each_element;
    for(var i = 0; i < label_fields_and_text_field_tds.length; i++) {
        label = label_fields_and_text_field_tds[i][0];
        text_field_td = label_fields_and_text_field_tds[i][1] + svcLineCount;
        if( $(label) != null) {
            width = $(label).getWidth();
            totalWidth += width;
            $(text_field_td).style.width = width + 'px';
        }
    }

    for(i = 0; i < label_fields_and_text_field_tds_with_colspan.length; i++) {
        label = label_fields_and_text_field_tds_with_colspan[i][0];
        text_field_tds = label_fields_and_text_field_tds_with_colspan[i][1];
        if( $(label) != null) {
            width = $(label).getWidth();
            totalWidth += width;
            width_of_each_element = parseInt(width) / text_field_tds.length;
            for(var j = 0; j < text_field_tds.length; j++) {
                $(text_field_tds[j]).style.width = width_of_each_element + 'px';
            }
        }
    }
}

function setAccountNoCapturedTime(current_time){
    $('acc_no_captured_time_id').value = current_time
}

//This is for validating Total Fields in QA view.
// No Blank allowed
// Should be Numeric
// Should be equal or greater than Incorrect Field.Otherwise alert the user
function validateTotalFields(){
    var result = true;
    if($('processor_input_fields') != null){
        var totalField = $F('processor_input_fields');
        var incorrectField = $F('incorrect');
        if(totalField == ''){
            alert("Total Field can not blank!");
            setTimeout(function() {
                document.getElementById('processor_input_fields').focus();
            }, 10);
            result = false;
        }
        else if(totalField.match(/^\d{1,3}$/) == null){
            alert("Total Field is not a Number!");
            setTimeout(function() {
                document.getElementById('processor_input_fields').focus();
            }, 10);
            result = false;
        }
        else if(incorrectField.match(/^\d{1,3}$/) == null){
            alert("Incorrect Field is not a Number!");
            setTimeout(function() {
                document.getElementById('incorrect').focus();
            }, 10);
            result = false;
        }
        else if(parseInt(totalField) < parseInt(incorrectField)){
            alert("Total Field should be equal or greater than Incorrect!");
            setTimeout(function() {
                document.getElementById('incorrect').focus();
            }, 10);
            result = false;
        }
    }
    return result;
}

function setTotalEditedFields() {
    total_edited_fields = 0;
    $$(".ocr_data.edited").each(
        function(item) {
            total_edited_fields += 1;
        });
    $('total_edited_fields').value = total_edited_fields;
}

function hideRejectReason() {
    if($('rejection_comment') != null) {
        $('rejection_comment').value = '--';
        $('rejection_comment').style.display = "none";
    }
    if($('comment') != null) {
        $('comment').value = '';
        $('comment').style.display = "none";
    }
}

function validateQaStatus(){
    var chk_box_elements = document.forms[1].elements['toggle'];
    var qa_status_elements = document.forms[1].elements['qa_status_id'];
    for(var i = 0; i < chk_box_elements.length; i++){
        if(chk_box_elements[i].checked){
            if(qa_status_elements[i].value == 'COMPLETED')
                return confirm("This job is already verified and completed by QA. Are you sure to deallocate the QA user?");
            else
                return true;
        }
    }
}

function set_qa_status(){
    if($F('toggle') == "0")
        $F('qa_status_id') = "";
}

function validatePartiallyEnteredAddRow() {
    var validation = true
    if($('charges_id') != null  && $('payment_id') != null) {
        if($('claim_level_eob') == null || ($('claim_level_eob') != null && $F('claim_level_eob') != "true")) {
            if($F('charges_id').strip() != '' && $F('payment_id').strip() != '') {
                validation = confirm("You have entered value in Add-Row, Are you sure \n\
you want to continue Save EOB without adding the Add-Row?");
            }
        }
    }
    //console_logger(validation, 'validatePartiallyEnteredAddRow');
    return validation;
}

function isTransactionTypeMissingCheckOrCheckOnly() {
    var foundDesiredTransactionType = false;
    var transactionType;
    if($('transaction_type_saved') != null)
        transactionType = $F('transaction_type_saved');
    else if(parent.myiframe.document.getElementById('transaction_type_saved') != null)
        transactionType = parent.myiframe.document.getElementById('transaction_type_saved').value;

    if(transactionType == 'Missing Check' || transactionType == 'Check Only'){
        foundDesiredTransactionType = true;
    }

    return foundDesiredTransactionType;
}

function mustPassValidationsForProviderAdjustment(allowSpecialCharacters){
    var validationResult = false;
    var payeeName = $('facility').value;
    validationResult = (validateProviderAdjustment() &&
        validateDollarAmount('prov_adjustment_amount_id') &&
        checkAccountNumberPrefix('prov_adjustment_account_number') && validateRumcAccountNumberPrefix('prov_adjustment_account_number') &&
        validateDescription() &&  validateTwiceKeyingForProviderAdjustment());

    if (payeeName == 'MOUNT NITTANY MEDICAL CENTER'){
        validationResult = (validationResult &&
            validateAlphaNumeric('prov_adjustment_account_number') &&
            vallidateMoxpAccountNumber());
    }
    else if(allowSpecialCharacters.toString() == "true" && $F('is_partner_bac') != "true"){
        validationResult = (validationResult && validateAlphanumericHyphenPeriodForwardSlash('prov_adjustment_account_number'));
    }
    else{
        validationResult = (validationResult && validateAlphaNumeric('prov_adjustment_account_number'));
    }
    validationResult = (validationResult &&
        validateAccountNumberForChoc('prov_adjustment_account_number') );

    if(validationResult){
        if($('twice_keying_prev_values_of_provider_adjustment')) {
            $('twice_keying_prev_values_of_provider_adjustment').value = '';
        }
        return true;
    }
    else
        return false;
}

//this function will check provider adjustment description is '-' or not
function validateDescription(){
    var result = true;
    var description = $('prov_adjustment_description');
    if(description != null && (description.value == '-' || description.value == '') ){
        alert("Please Enter Description");
        setTimeout(function() {
            description.focus();
        }, 20);
        result = false;
    }
    return result;
}

function confirmForTransactionType() {
    var transactionType = null;
    var result = true
    if($('transaction_type_saved') != null)
        transactionType = $F('transaction_type_saved');
    else if(parent.myiframe.document.getElementById('transaction_type_saved') != null)
        transactionType = parent.myiframe.document.getElementById('transaction_type_saved').value;
    if(transactionType == "Missing Check" && confirmation_status == true){
        result = confirm("The transaction is classified as Missing Check. Are you sure?");
    }
    return result;
}

function delayEventsForPayment(element, lineNumber){
    setTimeout(function(){
        total_charge_mpi('service_paid_amount_id','total_payment_id')
    },50);
    setTimeout(function(){
        save_charge('service_paid_amount_id','total_payment_id')
    },50);
    setTimeout(function(){
        serviceBalance(lineNumber)
    },50);
}

function delayEventsForAllow(element){
    setTimeout(function(){
        total_charge_mpi('service_allowable_id','total_allowable_id')
    },50);
    setTimeout(function(){
        save_charge('service_allowable_id','total_allowable_id')
    },50);
}

function setDocumentClassification() {
    var documentClassification, i;
    var clientName = $F('client_type').toUpperCase();
    var documentClassificationQuadax;
    if($('payment_method') != null && $('document_classification_id') != null) {
        $('document_classification_id').options.length = 0;
        if($F('payment_method') == 'CHK' || $F('payment_method') == 'OTH') {
            documentClassification = ['--', 'Roster', 'EOB', 'Payer Check w/o EOB',
            'Patient Payment' , 'Patient Payment w/ Updates' , 'Patient Payment w/o Statement',
            'Other Payment', 'EOB w/ EFT', 'Total Denial', 'Financial Aid',
            'Uncashed Check', 'Credit Card Insurance', 'Credit Card Patient Payment'];
        }
        if($F('payment_method') == 'COR' || $F('payment_method') == 'EFT') {
            documentClassification = ['--', 'Updates', 'Mail Returns',
            'Bankruptcy', 'Claim Updates', 'Collections',
            'EOB w/ EFT', 'Total Denial',
            'Refunds', 'Exceptions', 'Financial Aid',
            'Uncashed Check','Credit Card Insurance', 'Credit Card Patient Payment'];
            if(clientName == 'QUADAX'){
                documentClassificationQuadax = ['Medical Records', 'RAC', 'W9']
                documentClassification = documentClassification.concat(documentClassificationQuadax)
     
            }
        }
        for(i = 0; i < documentClassification.length; i++ ) {
            $('document_classification_id').options[i] = new Option(documentClassification[i], documentClassification[i]);
        }
    }
}

function isCheckNumberAutoGenerated() {
    var isCheckNumberAutoGenerated = false;
    var sequence_number_str;
    var sequence_number;

    if($('checknumber_id') != null && $('generated_check_number') != null) {
        var checkNumber = $F('checknumber_id').strip();
        if(checkNumber != "" && (checkNumber.startsWith('RX') || checkNumber.startsWith('RM'))) {
            var checkNumberLength = checkNumber.length;
            var checkNumberWithoutTimeStamp = checkNumber.substring(0, checkNumberLength - 6);
            var timeStampInCheckNumber = checkNumber.substring(checkNumberLength - 6, checkNumberLength);
            isCheckNumberAutoGenerated = (checkNumberWithoutTimeStamp == ($F('generated_check_number').strip()) &&
                timeStampInCheckNumber != '' &&
                timeStampInCheckNumber.match(/([0-1]{1}\d{1}|[2][0-3]{1})[0-5]{1}\d{1}[0-5]{1}\d{1}/) != null)
        }
        else if(checkNumber != "" && checkNumber.startsWith('REVMEDNOPAY')){
            sequence_number_str = checkNumber.substring(11, 18);
            sequence_number = parseInt(sequence_number_str, 10)
            isCheckNumberAutoGenerated = (sequence_number != 0 && sequence_number_str.match(/\d{1,7}/) != null)
        }
        else if(checkNumber != "" && checkNumber.startsWith('SL')){
            sequence_number_str = checkNumber.substring(2, 12);
            sequence_number = parseInt(sequence_number_str, 10)
            isCheckNumberAutoGenerated = (sequence_number != 0 && sequence_number_str.match(/\d{1,10}/) != null)
        }
    }
    return isCheckNumberAutoGenerated;
}

function submitFormOnDeleteEob(event)
{
    var agree =confirm("Are You sure you want to delete?");
    if(agree) {
        if($('submit_button_after_hiding') != null)
            $('submit_button_after_hiding').value = $F('submit_button_name');
        if($('qa_save_eob_button_id') != null)
            $('qa_save_eob_button_id').disabled = true;
        if($('qa_update_job_button_id') != null)
            $('qa_update_job_button_id').disabled = true;
        if($('qa_delete_eob_button_id') != null)
            $('qa_delete_eob_button_id').disabled = true;
        if($('after_button_hiding') != null)
            $('after_button_hiding').value = $F('submit_button_name');
        document.forms["form1"].submit();

    }
    else
        Event.stop(event);

}

function setServiceLineSerialNumbers() {
    var serialNumbers = [];
    var svcLineId;
    var adjustmentLine = '';
    $$(".service_line_row").each(
        function(item) {
            var serialNumber = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "")
            var classNames = item.className;
            classNames = classNames.split(' ');
            for(var i = 0; i < classNames.length; i++) {
                if(classNames[i].startsWith('service_line_id') == true) {
                    svcLineId = classNames[i];
                    svcLineId = svcLineId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                }
                else
                    svcLineId = '';
            }
            if($('adjustment_line_number_of_new_line') == null || (serialNumber != $F('adjustment_line_number_of_new_line'))) {
                serialNumber = serialNumber + '_' + svcLineId;
                serialNumbers.push(serialNumber);
            }
            else if($('adjustment_line_number_of_new_line') != null && $F('adjustment_line_number_of_new_line').strip() != '') {
                adjustmentLine = [serialNumber, svcLineId];
            }
        });
    if(adjustmentLine != ''){
        serialNumber = adjustmentLine[0] + '_' + adjustmentLine[1];
        serialNumbers.push(serialNumber);
    }
    $('service_line_serial_numbers').value = serialNumbers;
}

function confirmDeleteAllRows(){
    var balanceAmount = parseFloat($F('total_service_balance_id')).toFixed(2);

    if (balanceAmount == 0) {
        agree = confirm("Are you sure?");
        if(agree == true){
            removeAllServiceLines();
            return true;
        }
        else
            return false;
    }
    else if (balanceAmount != 0)
    {
        alert("There is no service line");
        return false;
    }
    else
        return false;

}

function enableComplete_patientpay(){

    clientName = $F('client_name_id');
    if($F('client_name_id') == "MEDISTREAMS"){
        $("incomplete_button_id").disabled = true;
    }
    else{
        $("incomplete_button_id").disabled = false;
    }
    $("complete_button_id").disabled = false;

}

function setDefaultClaimTypeInQAViewForRemarkCode(){
    for(j = 0; j < $("claim_type").options.length; j++) {
        if($("claim_type").options[j].value == "--") {
            $("claim_type").options[j].selected = true;
        }
    }
}

// Validation for checking
// 1) there should be atleast one normal service line for  entering adjustment line
function validateAdjustmentLineCount() {
    var validation = true;
    var transactionTypeObject = document.form1.transaction_type;
    if(transactionTypeObject != null) {
        var getSelectedIndexOfTransactionType = transactionTypeObject.selectedIndex;
        var transactionType = transactionTypeObject[getSelectedIndexOfTransactionType].value;
        if(transactionType == "Check Only" || transactionType == "Correspondence") {
            needToValidateAdjustmentLine = false;
        }
    }

    if(needToValidateAdjustmentLine) {
        var adjustmenLineNumber = '';
        var saved_adjustment_line_exist = false;
        if(($('adjustment_line_number') != null && $F('adjustment_line_number') != '')) {
            adjustmenLineNumber = $F('adjustment_line_number');
            saved_adjustment_line_exist = true;
        }
        else if(($('total_line_count') != null &&
            $('service_procedure_charge_amount_id' + $F('total_line_count')) != null &&
            $('service_procedure_charge_amount_id' + $F('total_line_count')).readOnly == true)){
            adjustmenLineNumber = 1;
        }

        if(adjustmenLineNumber != '') {
            if($('total_existing_number_of_svc_lines') != null) {
                if(saved_adjustment_line_exist)
                    var condition = $F('total_existing_number_of_svc_lines') == '2';
                else
                    condition = $F('total_existing_number_of_svc_lines') == '1';
                if(condition) {
                    validation = false;
                    alert('Please enter atleast one normal service line.');
                }
            }
        }
    }
    return validation;
}

function getSavedTT(){
    var clientName = $F('client_name_id').toUpperCase();
    if (clientName == 'MEDISTREAMS'){
        if(parent.myiframe  != "undefined" && parent.myiframe  != null && parent.myiframe.document.getElementById('job_id') != null){
            var job_id = parent.myiframe.document.getElementById('job_id').value;
        }
        var parameters = 'job_id=' + job_id;
        var url = relative_url_root() + "/insurance_payment_eobs/get_saved_transaction_type";
        new Ajax.Request(url, {
            method: 'get',
            asynchronous: false,
            parameters: parameters,
            onComplete: function(saved_tt) {
                var saved_transaction_type =  saved_tt.responseText;
                saved_transaction_type = saved_transaction_type.gsub('"','')
                if(parent.myiframe  != "undefined" && parent.myiframe  != null && parent.myiframe.document.getElementById('transaction_type') != null) {
                    var transactionType = parent.myiframe.document.getElementById('transaction_type').value;
                    if(saved_transaction_type != '' && saved_transaction_type != transactionType ){
                        alert("The Transaction type has been changed to " + saved_transaction_type +" from " +transactionType+ " based on the EOBs processed in this transaction")
                        confirmation_status = false
                    }
                }
            }
        });
    }
}

function alertForConfirmingPaymentMethod(){
    var total_charge = $F('total_charge_id');
    var total_payment = $F('total_payment_id');
    var check_amount = $F('checkamount_id');
    if($('payment_method') != null) {
        if (($F('payment_method') == 'CHK')||($F('payment_method') == 'OTH')){
            if ((total_charge == total_payment)&& (total_payment == check_amount )){
                alert('Please confirm the Payment method. If it is Check only, Roster, Incentive or Bulk payment use "OTH", else "CHK" ')
            }
        }
    }
}

function getStarttimeOFSVC(){
    if (bServicetimetracking  == true){
        var start_time =  new Date();
        $('service_start_time').value = start_time
        bServicetimetracking = false
    }
}
function onlineReportForUser(){
    job_id =$('job_id').value
    url = relative_url_root() +"/insurance_payment_eobs/user_report?job_id="+job_id
    window.open(url, "reportwindow","height=250,width=500,resizable=1,scrollbars=yes, menubar=no,toolbar=no,footer=no");
}
function closeReportPopUp(){
    window.close();
}

function validateAndCreateInterestEob() {
    var validationResult = true;
    var clientName = $F('client_type').toUpperCase();
    var parent_job_id =  $F('child_job_parent_job_id');
    var interest_in_service_line = $F('interest_in_service_line');
    if (clientName == 'MEDISTREAMS' && interest_in_service_line != 'true' &&
        ($('interest_only_eob_id') == null || ($('interest_only_eob_id') != null && $F('interest_only_eob_id') == ''))) {

        var result;
        var  eob_count = $F("eob_count_value");
        var stringOfIdsOfPayerDetails = "'',payer_popup,payer_pay_address_one,payer_city_id,payer_payer_state,payer_zipcode_id";
        var checkInterest =  $F('interest_id');
        var checkAmount = $F('checkamount_id');
        if (parseInt(eob_count) == 0 && parseFloat(checkAmount) == parseFloat(checkInterest) &&
            (parent_job_id == '' || parent_job_id == null)) {

            result = confirm("This transaction has got Interest. The system will be creating a interest EOB record. Are you sure?");
            if (result == true) {
                if (validatePayerDetails(stringOfIdsOfPayerDetails)) {
                    $('interest_eob').value = true;
                    if($('image_page_number') != null) {
                        $('image_page_number').value = '1';
                    }
                    validationResult = true;
                    if($('proc_save_eob_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('proc_save_eob_button_id');
                        $('proc_save_eob_button_id').disabled = true;
                    }
                    else if($('qa_save_eob_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('qa_save_eob_button_id');
                        $('qa_save_eob_button_id').disabled = true;
                    }
                    if($('qa_update_job_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('qa_update_job_button_id');
                        $('qa_update_job_button_id').disabled = true;
                    }
                    if($('qa_delete_eob_button_id') != null) {
                        $('submit_button_after_hiding').value = $F('qa_delete_eob_button_id');
                        $('qa_delete_eob_button_id').disabled = true;
                    }
                    document.forms["form1"].submit();
                    return;
                }
                else {
                    $('interest_eob').value = false;
                    $('interest_id').value = '';
                    validationResult = false;
                }
            }
            else {
                $('interest_eob').value = false;
                $('interest_id').value = '';
                validationResult = false;
            }
        }
    }
    return validationResult;
}

//Confirmation message for Mismatch Transaction
function alertForMismatchTransaction(){
    if(parent.myiframe.document.getElementById('checkinforamation_mismatch_transaction').checked){
        if (confirm('You are going to categorize this transaction as Mismatch. Are you sure?')){
        } else {
            parent.myiframe.document.getElementById('checkinforamation_mismatch_transaction').focus();
        }
    }
}

function completeButtonPressed(){
    var validationResult = true;
    var interest_in_service_line = false;
    if(window.frames['myiframe'] != null)
        var eob_type =  window.frames['myiframe'].document.getElementById('tab_type').value;
    else if($('tab_type') != null)
        eob_type = $F('tab_type');
    if (eob_type != 'Insurance'){
        return true;
    }

    var total;
    if(window.frames['myiframe'] != null) {
        var clientName = window.frames['myiframe'].document.getElementById('client_type').value.toUpperCase();
        interest_in_service_line = window.frames['myiframe'].document.getElementById('interest_in_service_line').value;
        var parent_job_id =   window.frames['myiframe'].document.getElementById('child_job_parent_job_id').value;
        var check_have_interest_eob = window.frames['myiframe'].document.getElementById('check_have_interest_eob').value;
    }
    else {
        clientName = $F('client_type').toUpperCase();
        interest_in_service_line = $F('interest_in_service_line');
        parent_job_id =   $F('child_job_parent_job_id');
        check_have_interest_eob = $F('check_have_interest_eob');
    }
    if (clientName == 'MEDISTREAMS' && interest_in_service_line != 'true' && check_have_interest_eob != 'true'){
        if( parent_job_id == '' || parent_job_id == null) {
            $('image_type').value = 'EOB';
            if(window.frames['myiframe'] != null) {
                window.frames['myiframe'].document.getElementById('interest_eob').value = false;
                var job_id = window.frames['myiframe'].document.getElementById("job_id").value;
            }
            else {
                $('interest_eob').value = false;
                job_id = $F("job_id");
            }
            var parameters = 'job_id=' + job_id;

            var url = relative_url_root() + "/insurance_payment_eobs/calculate_total_claim_interest";
            new Ajax.Request(url, {
                method: 'get',
                asynchronous: false,
                parameters: parameters,
                onComplete: function(sum) {
                    total = sum.responseText;
                    if (total != '' && total != "null")
                        $('total_claim_interest').value = total;
                    if( ($F('total_claim_interest') != "null") && ($F('total_claim_interest') != ' ')){
                        if ((parseFloat($F('total_claim_interest')) != 0)){

                            var confirm_dummy = confirm("This transaction has got Interest. The system will be creating a dummy EOB record. \n\
Are you sure?");
                            if (confirm_dummy ==  true) {
                                $('complete_button_flag').value = true;
                                if(window.frames['myiframe'] != null) {
                                    window.frames['myiframe'].document.getElementById('submit_button_after_hiding').value = 'COMPLETE'
                                    window.frames['myiframe'].document.getElementById('proc_save_eob_button_id').disabled = true;
                                }
                                else {
                                    if($('qa_update_job_button_id') != null) {
                                        $('submit_button_after_hiding').value = $F('qa_update_job_button_id');
                                        $('qa_update_job_button_id').disabled = true;
                                    }
                                    if($('qa_save_eob_button_id') != null)
                                        $('qa_save_eob_button_id').disabled = true;
                                    if($('qa_delete_eob_button_id') != null)
                                        $('qa_delete_eob_button_id').disabled = true;
                                }
                                validationResult = true;
                            }
                            else {
                                if(window.frames['myiframe'] != null) {
                                    window.frames['myiframe'].document.getElementById('proc_save_eob_button_id').disabled = false;
                                }
                                else {
                                    if($('qa_update_job_button_id') != null)
                                        $('qa_update_job_button_id').disabled = false;
                                    if($('qa_save_eob_button_id') != null)
                                        $('qa_save_eob_button_id').disabled = false;
                                    if($('qa_delete_eob_button_id') != null)
                                        $('qa_delete_eob_button_id').disabled = false;
                                }
                                validationResult = false;
                            }
                        }
                    }
                }
            });
        }
    }
    return validationResult;
}

function validateCheckWithInterestEob() {
    var validationResult = true;
    if($('interest_only_eob_id') != null && $F('interest_only_eob_id') != $F('insurance_id')) {
        alert('The check contains an interest EOB, so please do not enter more EOBs. \n\
Please proceed with completing this Job or delete the Interest EOB to proceed.')
        validationResult = false;
    }

    return validationResult;
}

function validateModificationForInterestEob() {
    var validationResult = true;
    var clientName = $('client_type').value.toUpperCase();
    if($('interest_id') != null && $('check_have_interest_eob') != null) {
        if (clientName == 'MEDISTREAMS' && $F('check_have_interest_eob') == 'true'){
            if($F('claim_interest_hidden_field') != '' &&
                parseFloat($F('claim_interest_hidden_field')) != parseFloat($F('interest_id')))
                validationResult = confirm("The interest amount in this EOB is edited. \n\
The system will update the dummy interest EOB record. Are you sure?");
        }
    }
    return validationResult;
}

function negativeValidationForCheckAmountPatpay(){
    check_amount = $('check_amount_id').value;
    if(check_amount < 0){
        alert ("The Check / EFT amount should always be a positive number. Please enter the correct value.");
        setTimeout(function() {
            $('checkamount_id').focus();
        }, 10);
        return false;
    }
    else{
        return true;
    }
}


function negativeValidationForCheckAmount(){

    check_amount = $('checkamount_id').value;

    if(check_amount < 0){
        alert ("The Check / EFT amount should always be a positive number. Please enter the correct value.");
        setTimeout(function() {
            $('checkamount_id').focus();
        }, 10);
        return false;
    }
    else{
        return true;
    }
}

function confirmNameAndIdentifier() {
    var resultOfValidation = true;
    if($('required') && $F('required') != 'required') {
        var emptyFields = [];
        var emptyFieldIds = [];
        if($('patient_account_id') && $F('patient_account_id').strip() == '') {
            emptyFields.push('Account #');
            emptyFieldIds.push('patient_account_id');
        }
        if($('patient_first_name_id') && $F('patient_first_name_id').strip() == '') {
            emptyFields.push('Patient First Name');
            emptyFieldIds.push('patient_first_name_id');
        }
        emptyFields = emptyFields.join(', ');
        if(emptyFields != '' && emptyFieldIds.length > 0) {
            var message = "Please confirm whether " + emptyFields + " is/are not available on the image.";
            resultOfValidation = confirm(message);
            if(!resultOfValidation) {
                setTimeout(function(){
                    $(emptyFieldIds[0]).focus();
                }, 10);
            }
        }
    }
    return resultOfValidation;
}

function validateNextgenAccountNumber() {
    var gridTypeValue;
    var resultOfValidation = true;
    if(parent != 'undefined' && parent != null && parent.myiframe != "undefined" && parent.myiframe != null &&
        parent.myiframe.document.getElementById('grid_type') != null) {
        gridTypeValue = parent.myiframe.document.getElementById('grid_type').value;
    }
    else {
        gridTypeValue = $F('grid_type');
    }
    if(gridTypeValue == 'nextgen' && $('patient_account_id') != null){
        if($('required') == null || ($('required') && $F('required') == 'required')) {
            var accountNumber = $F('patient_account_id');
            if($('qa_view') != null) {
                if(accountNumber.length != 16) {
                    alert('Account# should be 16 digits.');
                    resultOfValidation = false;
                }
            }
            else {
                if(accountNumber.length > 12 || accountNumber.length == 0) {
                    alert('Account# should have digit length != 0 and less than or equal to 12');
                    resultOfValidation = false;
                }
            }
        }
    }
    if(resultOfValidation == false) {
        setTimeout(function(){
            $('patient_account_id').focus();
        }, 0);
    }
    return resultOfValidation;
}

function createOffsetEob(){
    var flagForofffset = true;
    if (parent.myiframe.document.getElementById('client_type') != null)
        var clientName = parent.myiframe.document.getElementById('client_type').value.toUpperCase();
    if (parent.myiframe.document.getElementById('amount_so_far') != null)
        var totalPayment = parent.myiframe.document.getElementById('amount_so_far').value;
    totalPayment = parseFloat(totalPayment);
    if (parent.myiframe.document.getElementById('balance') != null)
        var balance = parent.myiframe.document.getElementById('balance').value;
    balance = parseFloat(balance);
    if (parent.myiframe.document.getElementById('correspondence_check') != null)
        var correspondance_check = parent.myiframe.document.getElementById('correspondence_check').value;
    if (parent.myiframe.document.getElementById('offset_eob_present') != null)
        var offset_eob_present = document.getElementById('offset_eob_present').value;
    if (parent.myiframe.document.getElementById('child_job_parent_job_id') != null)
        var parent_job_id =  parent.myiframe.document.getElementById('child_job_parent_job_id').value;
    if (clientName == 'MEDISTREAMS' && (parent_job_id == '' || parent_job_id == null) &&
        (correspondance_check != null && correspondance_check == "true") &&
        (totalPayment < 0 && balance > 0 ) && (Math.abs(totalPayment) == Math.abs(balance) ) ) {
        flagForofffset = false;
        if( offset_eob_present != 'true'){
            var confirm_offset_create = confirm("This transaction has got negative amount so far. The system will be creating an offset EOB record. \n\
                Are you sure?");
            if(confirm_offset_create == true){
                $('flag_for_offset_eob').value = 'true';
                flagForofffset = false;
            }
            else
                flagForofffset = true;
        }
        else
            flagForofffset = true;
    }
    return flagForofffset;
}

function createOffsetEobForQa(){
    var flagForofffset = true;
    var clientName = $F('client_type').toUpperCase();
    var totalPayment = $F('amount_so_far');
    totalPayment = parseFloat(totalPayment);
    var balance = $F('balance');
    balance = parseFloat(balance);
    var correspondance_check = $F('correspondence_check');
    var offset_eob_present = $F('offset_eob_present');
    var parent_job_id =  $F('child_job_parent_job_id');
    if (clientName == 'MEDISTREAMS' && (parent_job_id == '' || parent_job_id == null) &&
        (correspondance_check != null && correspondance_check == "true") &&
        ( totalPayment <0 && balance > 0 ) && (Math.abs(totalPayment)== Math.abs(balance) ) ) {
        flagForofffset = false;
        if( offset_eob_present != 'true'){
            var confirm_offset_create = confirm("This transaction has got negative amount so far. The system will be creating an offset EOB record. \n\
                Are you sure?");
            if(confirm_offset_create == true){
                $('flag_for_offset_eob').value = 'true';
                flagForofffset = false;
            }
            else
                flagForofffset = true;
        }
        else
            flagForofffset = true;
    }
    return flagForofffset;
}


function validateTabType(){
    var tab_type_flag = true;
    if( $('tab_type') && $('payer_type') && $('type_of_payer_created_by_admin')) {
        if (($F('tab_type').toUpperCase() == "INSURANCE")&& ($F('payer_type').toUpperCase() != 'PATPAY') && ($F('type_of_payer_created_by_admin').toUpperCase()=='PATPAY')){
            alert("Payer is PatPay, please process in PatPay Grid");
            tab_type_flag = false;
        }
    }
    return tab_type_flag;
}

function validateSaveOfOcrEos(){
    var value = true;
    if($('mode_value') != null) {
        var mode = $F('mode_value');
        if (mode == 'VERIFICATION' ){
            if(parent.myiframe && parent.myiframe.document.getElementById('ocr_eob_length')) {
                var ocr_eob_length =  parent.myiframe.document.getElementById('ocr_eob_length').value;
                if(ocr_eob_length != "0"){
                    alert("Please save all the OCR EOBS before completing the job");
                    value = false;
                }
            }
        }

    }
    return value

}


function validatePlaceOfService(){
    var result = true;
    var placeOfService = $('insurancepaymenteob_place_of_service');
    if(placeOfService != null && placeOfService.value != ''){
        var value = placeOfService.value;
        if(value.match(/^0+$/) == null && value.match(/^\d{2}$/) != null){
            result = true;
        }
        else{
            alert("The Place of service you entered is not correct. Please check");
            setTimeout(function() {
                placeOfService.focus();
            }, 10);
            result = false;
        }
    }
    return result;
}

function copyPayerAddressToPatientAddress() {
    if($('patient_add_same_as_payer') != null) {
        if($F('patient_add_same_as_payer') == '1') {
            $('patient_address_one').value = $F('payer_pay_address_one');
            $('patient_address_two').value = $F('payer_address_two');
            $('patient_city_id').value = $F('payer_city_id');
            $('patient_state_id').value = $F('payer_payer_state');
            $('patient_zipcode_id').value = $F('payer_zipcode_id');
        }
        else {
            $('patient_address_one').value = '';
            $('patient_address_two').value = '';
            $('patient_city_id').value = '';
            $('patient_state_id').value = '';
            $('patient_zipcode_id').value = '';
        }
    }

}

function validateProcedureCodeLength(id) {
    var resultOfValidation = true;
    var clientName = $F('client_name').strip().toUpperCase();
    if($(id) != null && clientName != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER') {
        var value = $F(id);
        if(value != '') {
            if(value.length != 5) {
                resultOfValidation = false;
                alert('CPT code should be of length 5');
                setTimeout(function() {
                    $(id).focus();
                }, 10);
            }
        }
    }
    return resultOfValidation;
}

function validateRevenueCodeLength(id) {
    var resultOfValidation = true;
    if($(id) != null) {
        var value = $F(id);
        if(value != '') {
            if(value.length != 4) {
                resultOfValidation = false;
                alert('Revenue code should be of length 4');
                setTimeout(function() {
                    $(id).focus();
                }, 10);
            }
        }
    }
    return resultOfValidation;
}

function validateUpmcCptOrRevenueCodeLength(id){
    var resultOfValidation = true;
    var clientName = $F('client_name').strip().toUpperCase();
    if(clientName == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' && $(id) != null){
        var length = $F(id).length
        if(length != 5 && length != 4 && $F(id) != '' ){
            resultOfValidation = false;
            alert('Invalid CPT/Revenue Code Length');
            setTimeout(function() {
                $(id).focus();
            }, 10);
        }
        else{
            if(length == 4){
                setHighlight([id], "blank");
            }
        }
    }
    return resultOfValidation;
}

function procedureCodeOrRevenueCodeMandatory(procedureCodeId, revenueCodeId, svcLineId) {
    var resultOfValidation = true;
    var isInterestLine = false;
    if(svcLineId != '' && svcLineId != null) {
        var interestLineField = 'interest_service_line_' + svcLineId;
        if($(interestLineField) != null)
            isInterestLine = true;
    }
    if($('cpt_or_revenue_code_mandatory') != null && $F('cpt_or_revenue_code_mandatory') == 'true' &&
        isInterestLine == false) {
        if($(procedureCodeId) != null && $(revenueCodeId) == null) {
            if($F(procedureCodeId).strip() == '') {
                resultOfValidation = false;
                if(svcLineId == '' || svcLineId == null) {
                    alert('CPT Code is mandatory');
                    setTimeout(function() {
                        $(procedureCodeId).focus();
                    }, 10);
                }
            }
        }
        else if($(procedureCodeId) != null && $(revenueCodeId) != null) {
            if($F(procedureCodeId).strip() == '' && $F(revenueCodeId).strip() == '') {
                resultOfValidation = false;
                if(svcLineId == '' || svcLineId == null) {
                    alert('CPT Code OR Revenue Code is mandatory');
                    setTimeout(function() {
                        $(procedureCodeId).focus();
                    }, 10);
                }
            }
        }
    }
    return resultOfValidation;
}

function confirmProcedureCodeIsEmpty() {
    var resultOfValidation = true;
    if($('cpt_or_revenue_code_mandatory') != null && $F('cpt_or_revenue_code_mandatory') == 'true') {
        var procedureCodeIds = [];
        var emptyProcedureCodeIds = [];
        var elementId;
        $$(".validate-cpt-or-revenue-code-mandatory").each(
            function(item) {
                if(item.id.match(/procedure_code/)) {
                    procedureCodeIds.push(item.id);
                }
            });
        var totalProcedureCodeIdLength = procedureCodeIds.length
        for(var i = 0; i < totalProcedureCodeIdLength; i++){
            elementId = procedureCodeIds[i];
            if($F(elementId).strip() == '') {
                emptyProcedureCodeIds.push(elementId);
            }
        }
        if(totalProcedureCodeIdLength != 0 && totalProcedureCodeIdLength == emptyProcedureCodeIds.length) {
            resultOfValidation = confirm("There are no CPT Code in the service lines. Are you sure?");
        }
    }
    return resultOfValidation;
}

function validateAccountNumberForMoxpPatpayGrid(){
    var checkPrefix = $F('details_account_num_prefix');
    var facility = $F('facility').toUpperCase();
    var defaultAccountNumber = $F('fc_def_ac_num').toUpperCase();
    var accountNumber = $F('patient_account_id').toUpperCase();
    var insuranceGrid = $F('insurance_grid');
    var return_flag = true;
    if (facility == 'MOUNT NITTANY MEDICAL CENTER' && insuranceGrid != "true" &&
        (checkPrefix == 'false' || checkPrefix == '') && accountNumber != ''){
        if(!((accountNumber == defaultAccountNumber) ||
            (accountNumber.match(/^[M][0-9]+$/) != null) ||
            (accountNumber.match(/^[A-LN-Z]([0-9]){11}$/) != null) ||
            (accountNumber.substr(1,3) == '000' && (accountNumber.match(/^[a-zA-Z]\d+$/) != null)))) {
            if (accountNumber.match(/^[a-zA-Z]/) == null){
                alert("Patient Account Number should start with an alphabet");
                return_flag = false;
            }
            else if((accountNumber.match(/^[a-zA-Z]{3}\d+$/) != null) && (accountNumber.match(/\d{5}$/) != null)){
                if (accountNumber.charAt(1) == 'O' || accountNumber.charAt(2) == 'O'){
                    alert("Letter O will never be used in this type of account number");
                    return_flag = false;
                }
            }
            else {
                alert("Patient Account Number is not valid. Please check");
                return_flag = false;
            }
        }
    }
    return return_flag;
}

function validatePresenceofPayeeNpiAndTin(){
    var payee_return =true;
    payee_tin = $F('payee_tin')
    payee_npi = $F('payee_npi')
    if(payee_tin== "" && payee_npi=="" && $('fc_npi_or_tin_validation') &&
        ($F('fc_npi_or_tin_validation') == 'NPI' || $F('fc_npi_or_tin_validation') == 'TIN')){
        alert("Please Enter either payee tin or payee npi")
        setFieldsValidateAgainstCustomMethod("payee_tin", "required");
        setFieldsValidateAgainstCustomMethod("payee_npi", "required");
        setTimeout(function() {
            $('payee_tin').focus();
        }, 20);
        return_payee = false
    }
    else{
        return_payee =true;
        removeCustomValidations("payee_tin", "required")
        removeCustomValidations("payee_npi", "required")
    }
    return return_payee;
}

// This function validates the parameters for MPI search.
// This is applied for only client RMS
// Input :
// accountNumber : Patient Account Number
// patientLastName : Patient Last Name
// dateOfServiceFrom : Service From Date
// chargeId : Charge Amount
// Output :
// resultOfValidation : Result Of Validation,  true if sucess, else false.
function validateMpiParametersForRms(accountNumber, patientLastName, dateOfServiceFrom, chargeId){
    var resultOfValidation = true;
    if($('client_type') != null && $F('client_type').toUpperCase() == "REVENUE MANAGEMENT SOLUTIONS"){
        if((accountNumber.strip() == '') && (((patientLastName.strip() == '') || (dateOfServiceFrom.strip() == '') || (chargeId.strip() == '')))){
            alert("Patient Account Number or Patient Last Name, From Date, Charge Amount are mandatory");
            resultOfValidation = false;
        }
    }
    return resultOfValidation;
}

function filterReasonCode(){
    var value = $F('to_find').toUpperCase();
    var table = document.getElementById ("reason_code_grid")
    var  iLen = table.rows.length
    for (var i = 1; i < (iLen) ; i++) {
        var td_value = "rc_"+i
        var document_value = document.getElementById(td_value).innerHTML
        document_value = document_value.toUpperCase();
        var row_count = "rw_value_"+i
        if(value != ''){
            if(document_value.startsWith(value)){
                document.getElementById(row_count).style.display = "";

            }
            else  {
                document.getElementById(row_count).style.display  = "none";
            }
        }
        else{
            document.getElementById(row_count).style.display = "";
        }
    }
}

function validateAddRowCptCodes() {
    var resultOfValidation = true;
    var cptCodes = [];
    var cptCodeIds = [];
    var codeId = 'cpt_procedure_code';
    var reEntryField = 'confirm_cpt_procedure_code';
    var codeValue;
    var reEntryFieldValue;
    var serialNumber;
    var reEntryFieldId;
    var validatedprocedureCodes = [];
    var clientName = $F('client_name').strip().toUpperCase();
    if($(codeId) != null && $(reEntryField) != null) {
        if (clientName != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' || (clientName == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' &&   $F(codeId).length == '5')){
            codeValue = $F(codeId).strip().toUpperCase();
            reEntryFieldValue = $F(reEntryField).strip().toUpperCase();
            var classNames = $(codeId).className.split(' ');
            if(codeValue != '') {
                if(reEntryFieldValue == '' && classNames.indexOf('uncertain') != -1) {
                    alert("Please correct / re-enter the invalid CPT code to continue");
                    resultOfValidation = false;
                }
                else {
                    $$(".validate-cpt_code_length").each(
                        function(item) {
                            serialNumber = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                            reEntryFieldId = 'confirm_procedure_code_' + serialNumber;
                            if(item.value.strip() != '') {
                                if(item.readOnly == true) {
                                    validatedprocedureCodes.push(item.value);
                                }
                                else if($(reEntryFieldId) != null && $F(reEntryFieldId) != ''){
                                    validatedprocedureCodes.push(item.value);
                                }
                            }
                        });

                    if(reEntryFieldValue != '' && reEntryFieldValue != codeValue) {
                        cptCodes.push(codeValue);
                        cptCodeIds.push(codeId);
                    }
                    else if(reEntryFieldValue == '') {
                        if(validatedprocedureCodes.length > 0) {
                            if(validatedprocedureCodes.indexOf(codeValue) == -1) {
                                cptCodes.push(codeValue);
                                cptCodeIds.push(codeId);
                            }
                        }
                        else {
                            cptCodes.push(codeValue);
                            cptCodeIds.push(codeId);
                        }
                    }

                    if (cptCodes.length > 0)
                        resultOfValidation = identifyInvalidCptCodes(cptCodes, cptCodeIds);

                    if(resultOfValidation) {
                        setHighlight([codeId], "blank");
                        if($('confirm_cpt_procedure_code'))
                            $('confirm_cpt_procedure_code').value = '';
                        validatedprocedureCodes.push(codeValue);

                        if(validatedprocedureCodes.length > 0) {
                            $$(".validate-cpt_code_length").each(
                                function(item) {
                                    if(codeValue.strip() == item.value.strip()) {
                                        serialNumber = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                                        reEntryFieldId = 'confirm_procedure_code_' + serialNumber;
                                        if($(reEntryFieldId) != null)
                                            $(reEntryFieldId).value = codeValue;
                                    }
                                });
                        }
                    }
                }
            }
        }
    }


    return resultOfValidation;
}

function validateAllCptCodes() {
    var resultOfValidation = true;
    var cptCodes = [];
    var cptCodeIds = [];
    var codeField = 'procedure_code_';
    var reEntryField = 'confirm_procedure_code_';
    var count;
    var codeId;
    var codeValue;
    var reEntryFieldValue;
    var serialNumber;
    var reEntryFieldId;
    var validatedprocedureCodes = [];
    var clientName = $F('client_name').strip().toUpperCase();
    var revenueCode = [];
    $$(".validate-cpt_code_length").each(
        function(item) {
            serialNumber = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
            reEntryFieldId = 'confirm_procedure_code_' + serialNumber;
            if(item.value.strip() != '' && $(reEntryFieldId) != null) {
                if(item.readOnly == true) {
                    validatedprocedureCodes.push(item.value);
                }
                else if($F(reEntryFieldId) != ''){
                    validatedprocedureCodes.push(item.value);
                }
            }
        });

    for(count = 1; count <= $F('total_line_count'); count++) {
        codeId = codeField + count;
        if($(codeId) != null && $(reEntryField + count) != null) {
            if(clientName == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'  && $F(codeId).length == 4){
                revenueCode.push(codeId)
            }
            if (clientName != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' || (clientName == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' &&   $F(codeId).length == '5')){
                codeValue = $F(codeId).strip().toUpperCase();
                reEntryFieldValue = $F(reEntryField + count).strip().toUpperCase();
                if(codeValue != '') {
                    if(reEntryFieldValue != '' && reEntryFieldValue != codeValue) {
                        cptCodes.push(codeValue);
                        cptCodeIds.push(codeId);
                    }
                    else if(reEntryFieldValue == '') {
                        if(validatedprocedureCodes.length > 0) {
                            if(validatedprocedureCodes.indexOf(codeValue) == -1) {
                                cptCodes.push(codeValue);
                                cptCodeIds.push(codeId);
                            }
                        }
                        else {
                            cptCodes.push(codeValue);
                            cptCodeIds.push(codeId);
                        }
                    }
                }
            }
        }
    }
    if(revenueCode.length > 0){
        setHighlight(revenueCode, "blank");
    }

    if (cptCodes.length > 0)
        resultOfValidation = identifyInvalidCptCodes(cptCodes, cptCodeIds);

    var validCptCodeIds = [];
    var classNames;
    $$(".validate-cpt_code_length").each(
        function(item) {
            classNames = item.className.split(' ');
            if(classNames.indexOf('uncertain') == -1) {
                validCptCodeIds.push(item.id);
            }
        });

    if(validCptCodeIds.length > 0) {
        reEntryFieldId = '';
        for(i = 0; i < validCptCodeIds.length; i++) {
            serialNumber = validCptCodeIds[i].replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
            reEntryFieldId = 'confirm_procedure_code_' + serialNumber;
            if($(reEntryFieldId) != null) {
                if($F(reEntryFieldId) != ''){
                    $('confirm_cpt_div_' + serialNumber).style.display = 'none';
                    $('td_procedure_code_' + serialNumber).style.width = '30';
                }
                $(reEntryFieldId).value = $F(validCptCodeIds[i]);
            }
        }
    }
    return resultOfValidation;
}

// cptCodes = Array of CPT codes
// cptCodeIds = Array of CPT code Ids
function identifyInvalidCptCodes(cptCodes, cptCodeIds) {
    var resultOfValidation = true;
    if(cptCodes.length > 0 && cptCodeIds.length > 0) {
        var invalidCptCodesAndIds = getInvalidCptCodes(cptCodes, cptCodeIds);
        if(invalidCptCodesAndIds != null) {
            var invalidCptCodesAndIdsLength = invalidCptCodesAndIds.length;
            if(invalidCptCodesAndIdsLength > 0) {
                var invalidCptCodeIds = [];
                var invalidCptCodes = [];
                for(i = 0; i < invalidCptCodesAndIdsLength; i++) {
                    invalidCptCodes[i] = invalidCptCodesAndIds[i][0];
                    invalidCptCodeIds[i] = invalidCptCodesAndIds[i][1];
                }
                if(invalidCptCodes.length > 0 && invalidCptCodeIds.length > 0) {
                    setHighlight(invalidCptCodeIds, "uncertain");
                    alert("The following CPT Codes are invalid found in the service line(s)." +
                        invalidCptCodes.uniq());
                    resultOfValidation = false;
                }
            }
        }
    }
    return resultOfValidation;
}

function getInvalidCptCodes(cptCodes, cptCodeIds) {
    var cptCodesAndIds = [];
    if(cptCodeIds.length > 0 && cptCodes.length > 0) {
        var parameters = 'cpt_code_ids=' + cptCodeIds.join(',') +
        '&cpt_codes=' + cptCodes.join(',');

        var url = relative_url_root() + "/insurance_payment_eobs/get_invalid_cpt_codes";
        new Ajax.Request(url, {
            asynchronous: false,
            parameters: parameters,
            onComplete: function(getCptCode) {
                cptCodesAndIds = eval("(" + getCptCode.responseText + ")");
            }
        });
    }
    return cptCodesAndIds;
}

function showReEntryCptCodeField(lineCount) {
    var confirm_cpt_div_id;
    var cpt_td;
    var reEntryFieldId;
    var cptCodeId;
    if(lineCount == null || lineCount == '') {
        confirm_cpt_div_id = 'confirm_cpt_div';
        cpt_td = 'label_procedure_code';
        reEntryFieldId = 'confirm_cpt_procedure_code';
        cptCodeId = 'cpt_procedure_code';
    }
    else{
        confirm_cpt_div_id = 'confirm_cpt_div_' + lineCount;
        cpt_td = 'td_procedure_code_' + lineCount;
        reEntryFieldId = 'confirm_procedure_code_' + lineCount;
        cptCodeId = 'procedure_code_' + lineCount;
    }

    if($(cptCodeId) != null && $(reEntryFieldId) != null) {
        var classNames = $(cptCodeId).className;
        classNames = classNames.split(' ');
        if(classNames.indexOf('uncertain') != -1) {
            var cptCodeValue = $F(cptCodeId).strip().toUpperCase();
            var reEntryFieldValue = $F(reEntryFieldId).strip().toUpperCase();
            if(cptCodeValue != '' && reEntryFieldValue != cptCodeValue) {
                var value = confirm("Invalid CPT code. Please check and re-enter below");
                if(value == true){
                    $(confirm_cpt_div_id).style.display = '';
                    $(cpt_td).style.width='75';
                    $(reEntryFieldId).value = '';
                    setTimeout(function() {
                        $(reEntryFieldId).focus();
                    }, 20);
                }
                else{
                    $(cpt_td).style.width = '30';
                    $(cptCodeId).value = '';
                    $(reEntryFieldId).value = '';
                    $(confirm_cpt_div_id).style.display = 'none';
                    setTimeout(function() {
                        $(cptCodeId).focus();
                    }, 20);
                }
            }
        }
    }
}

function hideReEntryCptCodeField(lineCount) {
    var confirm_cpt_div_id;
    var cpt_td;
    var reEntryFieldId;
    var cptCodeId;
    var serialNumber;
    if(lineCount == null || lineCount == '') {
        confirm_cpt_div_id = 'confirm_cpt_div';
        cpt_td = 'label_procedure_code';
        reEntryFieldId = 'confirm_cpt_procedure_code';
        cptCodeId = 'cpt_procedure_code';
    }
    else {
        confirm_cpt_div_id = 'confirm_cpt_div_' + lineCount;
        cpt_td = 'td_procedure_code_' + lineCount;
        reEntryFieldId = 'confirm_procedure_code_' + lineCount;
        cptCodeId = 'procedure_code_' + lineCount;
    }

    if($(cptCodeId) != null && $(reEntryFieldId) != null) {
        var cptCodeValue = $F(cptCodeId).strip().toUpperCase();
        var reEntryFieldValue = $F(reEntryFieldId).strip().toUpperCase();
        if(cptCodeValue != '' && reEntryFieldValue != '' && reEntryFieldValue == cptCodeValue) {
            $(confirm_cpt_div_id).style.display = 'none';
            $(cpt_td).style.width = '30';

            var procedureCodeIds = [];
            $$(".validate-cpt_code_length").each(
                function(item) {
                    if(item.value.strip() == cptCodeValue) {
                        serialNumber = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                        reEntryFieldId = 'confirm_procedure_code_' + serialNumber;
                        if($(reEntryFieldId) != null)
                            $(reEntryFieldId).value = reEntryFieldValue;
                        procedureCodeIds.push(item.id);
                    }
                });
            setHighlight(procedureCodeIds, "blank");
        }
        else {
            alert("Please re-enter CPT code");
            $(reEntryFieldId).value = '';
            setTimeout(function() {
                $(reEntryFieldId).focus();
            }, 20);
        }
    }
}

function setReEntryFieldsForValidatedCptCode(cptFieldId) {
    if($(cptFieldId) != null) {
        var cptCodeValue = $F(cptFieldId).strip();
        var serialNumber = cptFieldId.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
        var reEntryFieldId = 'confirm_procedure_code_' + serialNumber;

        if($(reEntryFieldId) != null) {
            var reEntryFieldValue = $F(reEntryFieldId).strip();
            if(cptCodeValue != '' && reEntryFieldValue != cptCodeValue) {
                var cptCodeValueOfAnother;
                var serialNumberOfAnother;
                var reEntryFieldIdOfAnother;
                var reEntryFieldValueOfAnother;

                $$(".validate-cpt_code_length").each(
                    function(item) {
                        if(item.id != cptFieldId && reEntryFieldValue != cptCodeValue) {
                            cptCodeValueOfAnother = item.value.strip();
                            if(cptCodeValueOfAnother == cptCodeValue) {
                                serialNumberOfAnother = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                                reEntryFieldIdOfAnother = 'confirm_procedure_code_' + serialNumberOfAnother;
                                if($(reEntryFieldIdOfAnother) != null) {
                                    reEntryFieldValueOfAnother = $F(reEntryFieldIdOfAnother).strip();
                                    if(reEntryFieldValueOfAnother == cptCodeValueOfAnother) {
                                        $(reEntryFieldId).value = cptCodeValue;
                                        setHighlight([cptFieldId], "blank");
                                    }
                                }
                                else if(item.readOnly == true) {
                                    $(reEntryFieldId).value = cptCodeValue;
                                    setHighlight([cptFieldId], "blank");
                                }

                            }
                        }
                    });
            }
        }
    }
}

function toggleClaimLevelSvcWindow() {
    if (claim_level_service_lines_window.isVisible())
    {
        claim_level_service_lines_window.hide();
    }else{
        claim_level_service_lines_window.show();
        setTimeout(function() {
            $('service_line_description').focus();
        }, 100);
    }
}

function addClaimLevelServiceLine() {
    var resultOfValidation = validateClaimLevelServiceLine('service_line_description', 'service_line_amount');
    if(resultOfValidation) {
        var serviceLineId = parseInt($F('claim_level_svc_last_serial_num')) + 1;
        $('claim_level_svc_last_serial_num').value = serviceLineId;

        var tbody = $('claim_level_service_line_id').getElementsByTagName("TBODY")[0];
        var row = document.createElement("TR");
        row.setAttribute('id', 'claim_level_service_row_' + serviceLineId);
        row.setAttribute('valign', 'top');
        row.vAlign = "top";

        var labelTd = document.createElement("TD");
        labelTd.setAttribute('id', "label" + serviceLineId);
        var labelField = document.createElement('LABEL');
        labelField.innerText = serviceLineId;
        labelTd.appendChild(labelField);

        row.appendChild(labelTd);

        var td = document.createElement("TD");
        var textField = document.createElement('INPUT');
        textField.type = 'text';
        var value = $F('service_line_description').toUpperCase();
        var id = 'claim_level_service_line_description_' + serviceLineId;
        textField.setAttribute('value', value);
        textField.setAttribute('id', id);
        textField.setAttribute('name', "claim_level_service_line[description_" + serviceLineId + "]");
        textField.setAttribute('readOnly', true)
        textField.className = "required validate-alphanumeric fullwidth";
        td.appendChild(textField);
        row.appendChild(td);

        td = document.createElement("TD");
        textField = document.createElement('INPUT');
        textField.type = 'text';
        value = $F('service_line_amount');
        if (value == '')
            textField.setAttribute('value', '0.00');
        else
            textField.setAttribute('value', parseFloat(value).toFixed(2));
        id = 'claim_level_service_line_amount_' + serviceLineId;
        textField.setAttribute('id', id);
        textField.setAttribute('name', "claim_level_service_line[amount_" + serviceLineId + "]");
        textField.setAttribute('style', 'width:45px; text-align:right');
        textField.className = "required validate-currency-dollar";
        textField.setAttribute('readOnly', true)
        td.appendChild(textField);
        row.appendChild(td);

        var hiddenTextField = document.createElement('INPUT');
        hiddenTextField.type = 'hidden';
        var serviceLineRecordId = '';
        value = serviceLineId + '_' + serviceLineRecordId;
        hiddenTextField.setAttribute('value', value);
        id = 'claim_level_service_line_record_id_' + serviceLineId;
        hiddenTextField.setAttribute('id', id);
        hiddenTextField.setAttribute('name', "claim_level_service_line[record_id_" + serviceLineId + "]");
        hiddenTextField.className = 'claim_level_service_lines_to_add';
        row.appendChild(hiddenTextField);

        td = document.createElement("TD");
        td.setAttribute('id', 'td_delete_' + serviceLineId);
        td.align = "center"
        td.valign = "middle"
        var buttonnode = document.createElement('input');
        buttonnode.setAttribute('type', 'button');
        buttonnode.setAttribute('id', 'td_id_' + serviceLineId);
        buttonnode.setAttribute('value', '-');
        buttonnode.className = 'submit_add'
        buttonnode.setAttribute('style','width:20px');
        buttonnode.onclick = function(){
            removeClaimLevelServiceLine(serviceLineId);
        }
        td.appendChild(buttonnode);
        row.appendChild(td);
        tbody.appendChild(row);
        $('service_line_description').value = '';
        $('service_line_amount').value = '';
        setTimeout(function() {
            $('service_line_description').focus();
        }, 10);
    }
}

function validateClaimLevelServiceLine(descriptionId, amountId) {
    var resultOfValidation = true;
    if($(descriptionId)) {
        if($F(descriptionId).strip() == ''){
            resultOfValidation = false;
            alert('Description is mandatory');
            setTimeout(function() {
                $(descriptionId).focus();
            }, 10);
        }
        if(resultOfValidation)
            resultOfValidation = validateServiceDescription(descriptionId);
    }
    if(resultOfValidation && $(amountId)) {
        if($F(amountId).strip() == ''){
            resultOfValidation = false;
            alert('Amount is mandatory');
            setTimeout(function() {
                $(amountId).focus();
            }, 10);
        }
        if(resultOfValidation)
            resultOfValidation = validateDollarAmount(amountId);
    }
    return resultOfValidation;
}

function validateServiceDescription(descriptionId) {
    var resultOfValidation = true;
    if($(descriptionId)) {
        if(($F(descriptionId).match(/^[a-zA-Z0-9]*$/) == null)) {
            resultOfValidation = false;
        }
        if(resultOfValidation == false) {
            alert('Description should be alpha numeric');
            setTimeout(function() {
                $(descriptionId).focus();
            }, 10);
        }
    }
    return resultOfValidation;
}

function removeClaimLevelServiceLine(lineCount, ServiceLineRecordId) {
    var svcSerialAndRecordId;
    var svcLineSerialNum;
    if(ServiceLineRecordId != '') {
        var recordIdsToDelete = $F('claim_level_svc_record_ids_to_delete') + ',' + ServiceLineRecordId;
        $('claim_level_svc_record_ids_to_delete').value = recordIdsToDelete;
    }
    var svcSerialAndRecordIds = $F('claim_level_svc_serial_and_record_ids');
    svcSerialAndRecordIds = svcSerialAndRecordIds + ',';
    var svcSerialAndRecordIdsArray = svcSerialAndRecordIds.split(',');
    for(i = 0; i < svcSerialAndRecordIdsArray.length; i++) {
        svcSerialAndRecordId = svcSerialAndRecordIdsArray[i];
        svcSerialAndRecordId = svcSerialAndRecordId.split('_');
        svcLineSerialNum = svcSerialAndRecordId[0];
        if(svcLineSerialNum == lineCount) {
            svcSerialAndRecordIdsArray[i] = '';
        }
    }
    svcSerialAndRecordIds = svcSerialAndRecordIdsArray.join(',');
    $('claim_level_svc_serial_and_record_ids').value = svcSerialAndRecordIds;

    var table = $('claim_level_service_line_id');
    table.deleteRow($('claim_level_service_row_' + lineCount).rowIndex);
}

function setClaimLevelServiceLineSerialNumbers() {
    if($('claim_level_service_lines_applicable') != null && $F('claim_level_service_lines_applicable') == 'true') {
        var serialNumberAndRecordId = "";
        $$(".claim_level_service_lines_to_add").each(
            function(item) {
                serialNumberAndRecordId = serialNumberAndRecordId + ',' + item.value;
            });
        $('claim_level_svc_serial_and_record_ids').value = serialNumberAndRecordId;
    }
}

function confirmClaimLevelServiceLineIsEmpty() {
    var resultOfValidation = true;
    if($('claim_level_service_lines_applicable') != null && $F('claim_level_service_lines_applicable') == 'true') {
        if($('claim_level_eob') != null && $F('claim_level_eob') == "true") {
            if($F('claim_level_svc_serial_and_record_ids').blank()) {
                resultOfValidation = confirm("Service Descriptions are empty. Please confirm");
            }
        }
    }
    return resultOfValidation;
}

function validateAdjustmentLine() {
    var resultOfValidation = true;
    adjustmenLineNumber = '';
    if($('adjustment_line_number') != null && !$F('adjustment_line_number').blank()){
        var adjustmenLineNumber = $F('adjustment_line_number');
    }
    else if($('service_row1') != null) {
        if($('service_row1').style.display != 'none') {
            adjustmenLineNumber = '1';
        }
    }
    $('adjustment_line_to_save').value = adjustmenLineNumber;
    if(adjustmenLineNumber != '') {
        var adjustmentAmounts = ['service_co_insurance_id', 'service_co_pay_id',
        'service_deductible_id', 'denied_id', 'service_discount_id',
        'service_non_covered_id', 'service_submitted_charge_for_claim_id',
        'service_contractual_amount_id', 'service_prepaid_id',
        'patient_responsibility_id', 'miscellaneous_one_id', 'miscellaneous_two_id',
        'miscellaneous_balance_id'];
        var totalAdjustmentAmount = 0.00;
        var non_zero_adjustment_amounts = false;
        var adjustmentAmount, adjustmentAmountId;
        for(i = 0; i < adjustmentAmounts.length; i++) {
            adjustmentAmountId = adjustmentAmounts[i] + adjustmenLineNumber;
            if($(adjustmentAmountId) != null) {
                adjustmentAmount = $F(adjustmentAmountId);
                if(isNaN(adjustmentAmount) ||  adjustmentAmount.blank())
                    adjustmentAmount = 0;
                adjustmentAmount = parseFloat(adjustmentAmount);
                totalAdjustmentAmount = totalAdjustmentAmount + adjustmentAmount;
                if(adjustmentAmount != 0) {
                    non_zero_adjustment_amounts = true;
                }
            }
        }

        var chargeAmount = $F('service_procedure_charge_amount_id' + adjustmenLineNumber);
        if(isNaN(chargeAmount) ||  chargeAmount.blank())
            chargeAmount = 0;
        var paymentAmount = $F('service_paid_amount_id' + adjustmenLineNumber);
        if(isNaN(paymentAmount) ||  paymentAmount.blank())
            paymentAmount = 0;
        var allowableAmount = $F('service_allowable_id' + adjustmenLineNumber);
        if(isNaN(allowableAmount) ||  allowableAmount.blank())
            allowableAmount = 0;
        var balanceAmount = parseFloat(chargeAmount) - (parseFloat(paymentAmount) + parseFloat(totalAdjustmentAmount));

        resultOfValidation = parseFloat(balanceAmount).toFixed(2) == 0 && chargeAmount == 0 &&
        allowableAmount == 0 && non_zero_adjustment_amounts;
        if(!resultOfValidation) {
            alert('Please enter a balanced adjustment line with an adjustment amount');
        }
    }
    return resultOfValidation;
}

function getKeyedinPatientStmtFieldValues(){
    statement_applied = $F('statement_applied');
    multiple_invoice_applied = $F('multiple_invoice_applied');
    multiple_statement_applied = $F('multiple_statement_applied');
    statement_receiver = $F('statement_receiver');
    payee_type_format = $F('payee_type_format');

    payee_type_format_a = (payee_type_format == 'A')
    payee_type_format_b = (payee_type_format == 'B')
    payee_type_format_c = (payee_type_format == 'C')

    statement_applied_present_condn = (statement_applied == 'true')
    statement_applied_absent_condn = (statement_applied == 'false' ||
        statement_applied == '')
    statement_applied_false_condn = (statement_applied == 'false')
    statement_applied_blank_condn = (statement_applied == '')
    multiple_invoice_applied_present_condn = (multiple_invoice_applied == 'true')
    multiple_invoice_applied_absent_condn = (multiple_invoice_applied == 'false' ||
        multiple_invoice_applied == '')
    multiple_invoice_applied_false_condn = (multiple_invoice_applied == 'false')
    multiple_invoice_applied_blank_condn = (multiple_invoice_applied == '')
    multiple_statement_applied_present_condn = (multiple_statement_applied == 'true')
    multiple_statement_applied_absent_condn = (multiple_statement_applied == 'false' ||
        multiple_statement_applied == '')

    physician_condition1 = ((payee_type_format_b || payee_type_format_c) &&
        statement_applied_false_condn &&
        multiple_invoice_applied_absent_condn &&
        multiple_statement_applied_absent_condn)
    physician_condition2 = (payee_type_format_c && statement_applied_present_condn &&
        multiple_invoice_applied_present_condn &&
        multiple_statement_applied_absent_condn)
    physician_condition3 = (payee_type_format_b && statement_applied_present_condn &&
        multiple_invoice_applied_false_condn &&
        multiple_statement_applied_absent_condn)
    hospital_condition1 = (payee_type_format_a && statement_applied_false_condn &&
        multiple_invoice_applied_absent_condn &&
        multiple_statement_applied_absent_condn)
}

function set_default_values_with_statement_fields(){
    getKeyedinPatientStmtFieldValues();
    if(statement_receiver.toUpperCase() == 'PHYSICIAN'){
        if(physician_condition1){
            setDefaultAmountValues();
            setDefaultAccNumberForPhysician();
        }

        else if(physician_condition2){
            setDefaultAmountValues();
            setDefaultAccNumberForPhysician();
        }

        else if(physician_condition3){
            setDefaultAmountValues();
            $('patient_account_id').value = "";
        }

        else{
            setBlankValues();
        }
    }
    else if(statement_receiver.toUpperCase() == 'HOSPITAL'){
        if(hospital_condition1){
            setDefaultAmountValues();
            setDefaultAccNumberForHospital();
        }
        else{
            setBlankValues();
        }
    }
}

function validateAccNumWithImage(){
    var flag = true;
    getKeyedinPatientStmtFieldValues();
    var message = "Please confirm the patient account number is not there on the check image. If it is there, please use it instead of the default value."

    var acc_num_from_ui = $F('patient_account_id');
    if(statement_receiver.toUpperCase() == 'PHYSICIAN'){
        populated_acc_num = getDefaultAccNumberForPhysician();
        acc_number_condn = (acc_num_from_ui == populated_acc_num)
        if((physician_condition1 || physician_condition2) && acc_number_condn)
            alert(message);
        flag = true;
    }
    else if(statement_receiver.toUpperCase() == 'HOSPITAL'){
        populated_acc_num = getDefaultAccNumberForHospital();
        if(hospital_condition1 && (acc_num_from_ui == populated_acc_num)){
            alert(message);
            flag = true;
        }
    }
    return flag;
}

function setDefaultValuesAsCheckamount(){
    check_amount = $F('checkamount_id');
    if($('service_procedure_charge_amount_id1') != null){
        $('service_procedure_charge_amount_id1').value = check_amount;
    }
    if($('service_paid_amount_id1') != null){
        $('service_paid_amount_id1').value = check_amount;
    }
    if($('total_charge_id') !=null){
        $('total_charge_id').value = check_amount;
    }
    if($('total_payment_id') !=null)
        $('total_payment_id').value = check_amount;
    if($('service_balance_id1') !=null)
        $('service_balance_id1').value = '0.00';
    if($('total_service_balance_id') !=null)
        $('total_service_balance_id').value = '0.00';
}

function setDefaultForPrValues(){
    if($('total_copay_id')!=null)
        $('total_copay_id').value = '0.00';// total patient responsibility field
    if($('service_co_pay_id1')!=null)
        $('service_co_pay_id1').value = '';// svc patient responsibility field
    if($('reason_code_copay1_unique_code')!=null)
        $('reason_code_copay1_unique_code').value = '';// patient responsibility unique code field
    if($F('claim_level_eob')== 'true'){
        if($('total_copay_id')!=null)
            $('total_copay_id').value = ''
        if($('reason_code_claim_copay_unique_code')!=null)
            $('reason_code_claim_copay_unique_code').value = ''
    }
}

function setDefaultForDiscountValues(){
    if($('total_contractual_amount_id')!=null)
        $('total_contractual_amount_id').value = '0.00';// total discounted total
    if($('service_contractual_amount_id1')!=null)
        $('service_contractual_amount_id1').value = '';// svc discounted total field
    if($('reason_code_contractual1_unique_code')!=null)
        $('reason_code_contractual1_unique_code').value = '';// discounted unique code field
    if($F('claim_level_eob')== 'true'){
        if($('total_contractual_amount_id')!=null)
            $('total_contractual_amount_id').value = ''
        if($('reason_code_claim_contractual_unique_code')!=null)
            $('reason_code_claim_contractual_unique_code').value = ''
    }
}

function setChargeValues(totalPayment){
    if($('total_charge_id')!=null)
        $('total_charge_id').value = totalPayment;
    if($('service_procedure_charge_amount_id1')!=null)
        $('service_procedure_charge_amount_id1').value = totalPayment;
    if($F('claim_level_eob')== 'true'){
        if($('total_charge_id')!=null)
            $('total_charge_id').value = totalPayment
    }
}

function setDiscountValues(){
    if($('total_contractual_amount_id')!=null)
        $('total_contractual_amount_id').value = discount;// total discounted total
    if($('service_contractual_amount_id1')!=null)
        $('service_contractual_amount_id1').value = discount;// svc discounted total field
    if($F('claim_level_eob')== 'true'){
        if($('total_contractual_amount_id')!=null)
            $('total_contractual_amount_id').value = discount
    }
}

function setDefaultAmountValues(){
    setDefaultValuesAsCheckamount();
    setDefaultForDiscountValues();
    setDefaultForPrValues();
}

function getDefaultAccNumberForPhysician(){
    batch_lockbox_number = $F('batch_lockbox_number');
    if(batch_lockbox_number == 637234)
        accNumber = "000002";

    else if(batch_lockbox_number == 637260)
        accNumber = "000003";

    else if(batch_lockbox_number == 637235)
        accNumber = "000001";
    return accNumber;
}

function getDefaultAccNumberForHospital(){
    batch_lockbox_number = $F('batch_lockbox_number');
    if(batch_lockbox_number == 637234)
        accNumber = "0003BUXP0";

    else if(batch_lockbox_number == 637260)
        accNumber = "000003";

    else if(batch_lockbox_number == 637235)
        accNumber = "001G4XP0";
    return accNumber;
}

function setDefaultAccNumberForPhysician(){
    accNumber = getDefaultAccNumberForPhysician();
    $('patient_account_id').value = accNumber;
}

function setDefaultAccNumberForHospital(){
    accNumber = getDefaultAccNumberForHospital();
    $('patient_account_id').value = accNumber;
}

function setBlankValues(){
    if($('service_procedure_charge_amount_id1') != null)
        $('service_procedure_charge_amount_id1').value = "";
    if($('service_paid_amount_id1') != null)
        $('service_paid_amount_id1').value = "";
    $('total_charge_id').value = '0.00';
    $('total_payment_id').value = '0.00';
    if($('service_balance_id1') != null)
        $('service_balance_id1').value = "";
    $('total_service_balance_id').value = "";
    if($('total_contractual_amount_id'))
        $('total_contractual_amount_id').value = "";// total discounted total
    if($('service_contractual_amount_id1') != null){
        $('service_contractual_amount_id1').value = "";// svc discounted total field
        $('reason_code_contractual1_unique_code').value = "";// discounted unique code field
    }
    $('total_copay_id').value = "";// total patient responsibility field
    if($('service_co_pay_id1') != null){
        $('service_co_pay_id1').value = "";// svc patient responsibility field
        $('reason_code_copay1_unique_code').value = "";// patient responsibility unique code field
    }
    $('patient_account_id').value = "";
}

function validateEobWithDiscount(){
    var flag = true;
    var discount;
    if($('total_contractual_amount_id') && $F('total_contractual_amount_id').strip() != '' && isNaN($F('total_contractual_amount_id')))
        discount = parseFloat(document.getElementById('total_contractual_amount_id').value).toFixed(2);
    else
        discount = 0;
    var currentPayment = parseFloat(document.getElementById('total_payment_id').value).toFixed(2);
    var batchDate = document.getElementById('batch_date').value;
    if($('date_service_from_1') != null)
        var serviceDate = document.getElementById('date_service_from_1').value;
    if($F('claim_level_eob')== 'true')
        var serviceDate = document.getElementById('claim_from_date_id').value;
    var centuryNumber = '20';
    var serviceDateObject = new Date(serviceDate);
    var serviceDateWithDaysAdded = new Date(serviceDateObject.getYear(),
        serviceDateObject.getMonth(), serviceDateObject.getDate() + 36)
    var serviceDateFormatted = centuryNumber + serviceDateWithDaysAdded.getYear() + '-' +
    (serviceDateWithDaysAdded.getMonth() + 1) + '-' + serviceDateWithDaysAdded.getDate();
    var batchDateObject = new Date(batchDate);
    var batchDateFormatted = centuryNumber + batchDateObject.getYear() + '-' +
    (batchDateObject.getMonth() + 1) + '-' + batchDateObject.getDate();
    var batchDateValue = batchDateFormatted.split('-');
    var serviceDateValue = serviceDateFormatted.split('-');
    var batchDateString = new Date();
    batchDateString.setFullYear(batchDateValue[0],(batchDateValue[1] - 1 ),batchDateValue[2]);
    var serviceDateString = new Date();
    serviceDateString.setFullYear(serviceDateValue[0],(serviceDateValue[1] - 1 ),serviceDateValue[2]);
    var statement_applied = document.getElementById('statement_applied').value;
    var multiple_invoice_applied = document.getElementById('multiple_invoice_applied').value;
    var multiple_statement_applied = document.getElementById('multiple_statement_applied').value;
    var statement_receiver = document.getElementById('statement_receiver').value;
    var payee_type_format = $F('payee_type_format');

    payee_type_format_a = (payee_type_format == 'A')
    statement_applied_present_condn = (statement_applied == 'true')

    multiple_invoice_applied_absent_condn = (multiple_invoice_applied == 'false' ||
        multiple_invoice_applied == '')
    multiple_statement_applied_false_condn = (multiple_statement_applied == 'false')
    multiple_statement_applied_true_condn = (multiple_statement_applied == 'true')
    multiple_statement_false_and_discount_equal_zero_condn = (statement_applied_present_condn &&
        multiple_statement_applied_false_condn && discount == 0)
    multiple_statement_false_and_discount_greater_zero_condn = (statement_applied_present_condn &&
        multiple_statement_applied_false_condn && discount > 0)
    multiple_statement_true_with_discount_condn = (statement_applied_present_condn &&
        multiple_statement_applied_true_condn && discount > 0)
    statement_applied_true_with_discount_condn = (statement_applied_present_condn &&
        discount >= 0)
    totalPayment = parseFloat(currentPayment);
    totalDiscount = parseFloat(discount);
    if(statement_receiver.toUpperCase() == 'HOSPITAL' && payee_type_format_a){
        if((batchDateString <= serviceDateString) &&
            statement_applied_true_with_discount_condn){
            //            alert("Please verify the charge, payment and Discount value as the difference between the batch date and svc date is less than or equal to 37 days");

            if(totalPayment < totalDiscount){
                default_discount_zero = true;
                alert("The Payment amount is less than Discount amount. Payment should be Charge in this case and no Discount should be there.");
                setDefaultForDiscount(default_discount_zero);
                flag = true;
            }
            else if(totalPayment == totalDiscount){
                default_discount_zero = false;
                flag = true;
            }
            else
                flag = true;

        }
        else if((batchDateString > serviceDateString) &&
            multiple_statement_true_with_discount_condn){
            alert("The deposit date is greater than 37 days from service date and there is discount. The system will default Charge with payment amount. Are you sure?");
            setChargeValues(totalPayment);
            setDefaultForDiscountValues();
            setDefaultForPrValues();
            flag = true;
        }
        else if(multiple_invoice_applied_absent_condn &&
            multiple_statement_false_and_discount_greater_zero_condn &&
            (batchDateString > serviceDateString)){
            alert("The deposit date is greater than 37 days from service date and there is discount. The system will default Charge and Payment with check amount. Are you sure?");
            setDefaultValuesAsCheckamount();
            setDefaultForDiscountValues();
            setDefaultForPrValues();
            flag = true;
        }
        else if((batchDateString <= serviceDateString) &&
            multiple_invoice_applied_absent_condn &&
            multiple_statement_false_and_discount_equal_zero_condn){
            alert("Please verify the charge, payment and Discount value as the difference between the batch date and svc date is less than or equal to 37 days");
            flag = true;

        }
    }
    return flag;
}

function setDefaultForDiscount(default_discount_zero){
    var totalPayment = parseFloat($F('total_payment_id')).toFixed(2);
    var totalCharge = parseFloat($F('total_charge_id')).toFixed(2);
    if(default_discount_zero == true){
        setChargeValues(totalPayment);
        setDefaultForDiscountValues();
        setDefaultForPrValues();
    }
    else if(default_discount_zero == false){
        discount = parseFloat(totalCharge - totalPayment).toFixed(2);
        setDiscountValues(discount);
        setDefaultForPrValues();
    }
}


function validateRcPageNumber(){
    var result_of_validation = true;
    if($('rc_page_no') != null){
        var image_page_from = parseInt($F('parent_job_image_from'))
        var image_page_to = parseInt($F('parent_job_image_to'))
        var rc_page_no = $F('rc_page_no')
        if(isNaN(parseInt(rc_page_no)) == true){
            alert("RC Page # should be a Number")
            $('rc_page_no').focus();
            result_of_validation = false
        }
        else{
            if(!(parseInt(rc_page_no) >= image_page_from && parseInt(rc_page_no) <= image_page_to)){
                alert("Please enter a valid RC Page Number")
                $('rc_page_no').focus();
                result_of_validation = false
            }
        }
        if(result_of_validation) {
            $('create_button').style.display = 'none'
        }
        else{
            $('create_button').style.display = ''
        }
    }
    return result_of_validation;
}

function validateDefaultReasonCodes() {
    var resultOfValidation = true;
    if($('is_partner_bac') != null && $F('is_partner_bac') != "true" &&
        $('reason_code_reason_code') != null && $('reason_code_reason_code_description') != null) {
        var code = $F('reason_code_reason_code').strip().toUpperCase();
        var description = $F('reason_code_reason_code_description').strip().toUpperCase();
        if(code != '' && description != '') {
            var defaultReasonCodes = [['1',  'DEDUCTIBLE AMOUNT'], ['2', 'COINSURANCE AMOUNT'], ['3', 'CO-PAYMENT AMOUNT']];
            var facility = $F('facility').toUpperCase();
            var defaultCode, defaultDescription;
            if(facility == 'HORIZON EYE')
                defaultReasonCodes.push(['46', 'THIS SERVICE IS NOT COVERED']);
            else
                defaultReasonCodes.push(['23', 'THE IMPACT OF PRIOR PAYER(S) ADJUDICATION INCLUDING PAYMENTS AND/OR ADJUSTMENTS']);

            for(i = 0; i < defaultReasonCodes.length; i++){
                defaultCode = defaultReasonCodes[i][0];
                defaultDescription = defaultReasonCodes[i][1];
                if(code == defaultCode && description == defaultDescription) {
                    resultOfValidation = false;
                    alert('Default Reason Code & Reason Code Description should be captured as HIPAA CODES in adjustment fields');
                    break;
                }
            }
        }
    }
    if(resultOfValidation) {
        $('create_button').style.display = 'none'
    }
    return resultOfValidation;
}

function orboCormustPassValidations(client_name){

    var result

    if(client_name == 'ORBOGRAPH' || client_name == 'ORB TEST FACILITY'){
        result = validateOrboPayerName() && validatePatientName() &&  validateAccountNumber()  && validateKey() &&
        validateCategory() && validatePayment() && validateLetterDate() && checkPageTo() && validateEobCorrectness()
    }

    return result
}


function orboCorConfirmSave(){
    var  confirm_result = confirm("Are you Sure?");
    if(confirm_result == true){

        $('submit_button').disabled = true;
        $('submit_button_flag').value = true
        document.forms["form1"].submit();

    }
    return confirm_result
}

function validateOrboPayerName(){
    var payerName = 'ins_payer'
    var result_of_validation = true
    if ($(payerName) != null && $F(payerName).strip() == ''){
        alert("Payer name cannot be blank!");
        setTimeout(function() {
            $(payerName).focus();
        }, 50);

        result_of_validation = false
    }
    else if (($(payerName) != null && !$F(payerName).match(/^[a-zA-Z0-9\s]+$/))){
        alert("Payer name should be alphanumeric")
        setTimeout(function() {
            $(payerName).focus();
        }, 50);

        result_of_validation = false
    }
    return result_of_validation
}
function validateAccountNumber(){
    var accNum = 'patient_account_id'
    var result_of_validation = true
    if ($(accNum) != null && $F(accNum).strip() == ''){
        alert("Account number cannot be blank!");
        setTimeout(function() {
            $(accNum).focus();
        }, 50);

        result_of_validation = false
    }
    else if (($(accNum) != null && !$F(accNum).match(alphaNumExp))){
        alert("Account number should be alphanumeric")
        setTimeout(function() {
            $(accNum).focus();
        }, 50);

        result_of_validation = false
    }
    return result_of_validation

}

function validatePatientName(){
    var patientNameIds = ['patient_last_name_id', 'patient_first_name_id']
    var result_of_validation = true
    if($('readonly') == null || $('readonly') && $F('readonly') != 'true') {
        if (($(patientNameIds[0]) != null) || ($(patientNameIds[1]) != null )){
            if(($F(patientNameIds[0]).strip() == '')){
                alert("Patient Last Name cannot be blank!");
                setTimeout(function() {
                    $(patientNameIds[0]).focus();
                }, 50);

                result_of_validation = false

            }
            else if(($F(patientNameIds[1]).strip() == '')){
                alert("Patient First Name cannot be blank!");
                setTimeout(function() {
                    $(patientNameIds[1]).focus();
                }, 50);

                result_of_validation = false

            }
        }
        else {
            setFieldsValidateAgainstCustomMethod(patientNameIds, "validate-alphanum-hyphen-space-period");

            result_of_validation = false
        }
    }
    return result_of_validation

}

function validateKey(){
    var key = 'cor_key'
    var result_of_validation = true
    if($('readonly') == null || $('readonly') && $F('readonly') != 'true') {
        if ($(key) != null && $F(key).strip() == ''){
            alert("Key cannot be blank!");
            setTimeout(function() {
                $(key).focus();
            }, 50);

            result_of_validation = false
        }
        else if (($(key) != null && !$F(key).match(numericExpression))){
            alert("Key should be numeric")
            setTimeout(function() {
                $(key).focus();
            }, 50);

            result_of_validation = false
        }
    }
    return result_of_validation
}

function validateCategory(){
    var key = 'category_action'
    var result_of_validation = true
    if ($(key) != null && $F(key).strip() == ''){
        alert("Category cannot be blank!");
        setTimeout(function() {
            $(key).focus();
        }, 50);

        result_of_validation = false
    }
    else if (($(key) != null && !$F(key).match(numericExpression))){
        alert("Category should be numeric")
        setTimeout(function() {
            $(key).focus();
        }, 50);

        result_of_validation = false
    }
    return result_of_validation
}

function validateLetterDate(){
    var letter_date = 'letter_date'
    var result_of_validation = true
    if ($(letter_date) != null && $F(letter_date).strip() == ''){
        alert("Letter Date cannot be blank!");
        setTimeout(function() {
            $(letter_date).focus();
        }, 50);

        result_of_validation = false
    }
    else if ($(letter_date) != null){
        result_of_validation = applyDateValidation(letter_date)
    }
    return result_of_validation

}

function validatePayment(){
    var payment = 'cor_payment'
    var result_of_validation = true
    if($('readonly') == null || $('readonly') && $F('readonly') != 'true') {
        if ($(payment) != null && $F(payment).strip() == ''){
            alert("Payment amount cannot be blank!");
            setTimeout(function() {
                $(payment).focus();
            }, 50);

            result_of_validation = false
        }
        else if ($(payment) != null){
            result_of_validation = validateDollarAmount(payment)
        }
    }
    return result_of_validation
}

function validateNpiTinAgainstFacility() {
    var facility_id = $F('facility_id');
    var return_flag = true;
    var parameters = 'facility_id=' + facility_id + '&job_id=' + $('job_id').value + '&npi=' + '&npi=' + $F('payee_npi') + '&tin=' + $F('payee_tin')
    var url = relative_url_root() + "/insurance_payment_eobs/is_npi_tin_valid_for_facility";
    if(($('payee_npi') != null &&  $F('payee_npi') != '' && $F('fc_npi_or_tin_validation') == 'NPI') || ($('payee_tin') != null && $F('payee_tin') != '' && $F('fc_npi_or_tin_validation') == 'TIN')){
        new Ajax.Request(url, {
            asynchronous: false,
            method: 'get',
            parameters: parameters,
            onComplete: function(result) {
                var flag = result.responseText;
                if(flag == 'false'){
                    if($F('fc_npi_or_tin_validation') == 'NPI') {
                        alert("Required valid  Payee NPI");
                        setTimeout(function() {
                            $('payee_npi').focus();
                        }, 10);
                    }
                    else if($F('fc_npi_or_tin_validation') == 'TIN'){
                        alert("Required valid Payee TIN");
                        setTimeout(function() {
                            $('payee_tin').focus();
                        }, 10);
                    }
                    return_flag = false;
                }
            }
        });
    }
    return return_flag;
}

function validateLengthOfPayeeNpi(){
    var return_flag = true;
    if($('payee_npi') != null && $F('payee_npi') != null  && $F('payee_npi') != ''){
        if(!$F('payee_npi').match(/(^\d{10}$)/)){
            alert("Payee NPI should be 10 digit")
            setTimeout(function() {
                $('payee_npi').focus();
            }, 10);
            return_flag = false;
        }
    }
    return return_flag;
}

function validateLengthOfPayeeTin(){
    var return_flag = true;
    if($('payee_tin') != null && $F('payee_tin') != null  && $F('payee_tin') != ''){
        if(!$F('payee_tin').match(/(^\d{9}$)/)){
            alert("Payee TIN should be 9 digit")
            setTimeout(function() {
                $('payee_tin').focus();
            }, 10);
            return_flag = false;
        }
    }
    return return_flag;
}

function populate_ocr_data(value){
    jobId = $F('job_id')
    page_no = $F('page_no')
    grid_action = "show_eob_grid"
    mode = "VERIFICATION"
    mpi_data_selected = value
    confirmation = confirm("The data displayed in the grid will change.Are You sure to continue ?")
    if(confirmation == true){
        url = grid_action+"?mpi_data_selected=" + mpi_data_selected +"&job_id=" + jobId+"&page="+page_no+"&mode="+mode;
        window.location.href = url;
        $('spinner').show();
    }
}

function validateRumcAccountNumberPrefix(account_id){
    var account_number = $F(account_id).toUpperCase().trim();
    var flag = true;
    var facility = $F('facility').toUpperCase();
    if(facility == 'RICHMOND UNIVERSITY MEDICAL CENTER'){
        if(account_number.startsWith('AC')){
            alert("The Account Number begins with AC which is for Accordis. Please use Default Account Number instead of the a/c number from the image");
            setTimeout(function() {
                $(account_id).focus();
            }, 10);
            flag = false;
        }
    }
    return flag;
}

function HideIncompleteButtonBasedOnCheckAmount(){
    var check_amount = parseFloat($F('checkamount_id'));
    var hide_incomplete_button_for_non_zero_payment = $F('hide_incomplete_button_for_non_zero_payment')
    var hide_incomplete_button_for_all = $F('hide_incomplete_button_for_all')
    var hide_incomplete_button_for_correspondance = $F('hide_incomplete_button_for_correspondance')
    var display_value = ((hide_incomplete_button_for_non_zero_payment == "1" && check_amount > 0 ) || hide_incomplete_button_for_all == "1" || (hide_incomplete_button_for_correspondance == "1" && $('correspondence_check') != null && $F('correspondence_check') == "true"))? 'none' : 'block'
    if($('qa_view') != null  ){
        var list = $('status');
        if(display_value == 'none'){
            for (i=0;i<list.length;  i++) {
                if (list.options[i].value == 'Incomplete') {

                    list.remove(i);
                }

            }
        }
        else{
            var opt = document.createElement("option");
            list.options.add(opt);
            opt.text = "Incomplete";
            opt.value = "Incomplete";
        }
    }
    else{
        parent.document.getElementById('hide_incomplete_button').style.display = display_value
        parent.document.getElementById('incomplete_comment_text_area').style.display = display_value
    }
}

function checkAccountNumberPrefixForQuadaxFacilities(){
    var account_number = $F('patient_account_id').toUpperCase().trim();
    var facility = $F('facility').toUpperCase();
    var flag = true;
    if(account_number.startsWith('OP') && (facility == "OPTIM HEALTHCARE" || facility == "TATTNALL HOSPITAL COMPANY LLC" )){
        if(account_number.charAt(2) == 'L'){
            alert("Invalid Account Number");
            setTimeout(function() {
                $('patient_account_id').focus();
            }, 10);
            flag = false;
        }
        else if(account_number.charAt(2) == 'I'){
            if(account_number.charAt(3) == '.'){
                flag = true;
            }
            else{
                alert("Invalid Account Number");
                setTimeout(function() {
                    $('patient_account_id').focus();
                }, 10);
                flag = false;
            }
        }
    }
    return flag;
}

function vallidateMoxpAccountNumber(){
    if($('facility') != null){
        var moxpPayee = $('facility').value;
        var accountNumber = $('prov_adjustment_account_number').value;

        if (moxpPayee == 'MOUNT NITTANY MEDICAL CENTER' && accountNumber != ''){
            if (accountNumber.match(/(^[A-Z]{3}[0-9]{5}$)/) != null ||
                accountNumber.match(/^[M][0-9]+$/) != null ||
                accountNumber.match(/^[A-LN-Z]([0-9]){11}$/) != null ||
                accountNumber == "MOXP0"){
                return true;
            }
            else{
                alert("Invalid Account Number");
                setTimeout(function() {
                    $('prov_adjustment_account_number').focus();
                }, 10);
                return false;
            }
        }
        else
            return true;
    }
    else
        return true;
}

function validateClaimNumber() {
    var resultOfValidation = true;
    if($('claimnumber_id') && $('default_claim_number') &&
        $F('tab_type').toUpperCase() == "INSURANCE" && $F('payer_type').toUpperCase() != 'PATPAY') {
        var claimNumber = $F('claimnumber_id').strip();
        var defaultClaimNumber = $F('default_claim_number').strip();
        if(claimNumber == '' && defaultClaimNumber != '') {
            var result = confirm("You have not entered claim number. Do you want to fill this field with value from Image?");
            if(result) {
                resultOfValidation = false;
                setTimeout(function() {
                    $('claimnumber_id').focus();
                }, 20);
            }
            else {
                $('claimnumber_id').value = defaultClaimNumber.toUpperCase();
            }
        }
    }
    return resultOfValidation;
}

function populateClaimNumber() {
    if($('claimnumber_id') != null && $('default_claim_number') != null &&
        $F('tab_type').toUpperCase() == "INSURANCE" && $F('payer_type').toUpperCase() != 'PATPAY') {
        $('claimnumber_id').value = $F('default_claim_number').strip().toUpperCase();
    }
}

function validateToothNumber(){
    var flag = true;
    var invalid_tooth_numbers = []
    if($('tooth_number') != null && $F('tooth_number') != ''){
        var tooth_number = $F('tooth_number').toUpperCase();
        var splitted_tooth_number = tooth_number.split(',')
        if(!(tooth_number.match(/^[a-zA-Z0-9,]+$/))){
            alert("Tooth Number should be Alphanumeric with Comma seperator");
            setTimeout(function() {
                $('tooth_number').focus();
            }, 10);
            flag = false;
        }
        else if((splitted_tooth_number.indexOf("") == -1) == false){
            alert("Invalid Tooth Number Format");
            setTimeout(function() {
                $('tooth_number').focus();
            }, 10);
            flag = false;
        }
        else{
            for(var i = 0; i< splitted_tooth_number.length; i++){
                if(((splitted_tooth_number[i].match(/^(?:[1-9]|1[0-9]|2[0-9]|3[0-2]?)$/)) == null) && ((splitted_tooth_number[i].match(/^[a-tA-T]$/)) == null) ){
                    invalid_tooth_numbers.push(splitted_tooth_number[i]);
                }
            }
            if(invalid_tooth_numbers.length >  0){
                alert("Following Tooth Numbers : " + invalid_tooth_numbers + " are found invalid. Tooth Number should be in between A to T or 1 to 32 Range.")
                setTimeout(function() {
                    $('tooth_number').focus();
                }, 10);
                flag = false;
            }
        }
    }
    return flag;
}


function autoPopulateTinAndProviderName(){
    var payee_name  = $F('checkinforamation_payee_name').trim();
    if(payee_name != null || payee_name != ''){
        if($('provider_organisation_id') != null){
            $('provider_organisation_id').value = payee_name
        }
        var parameters = 'facility_name=' + payee_name + '&job_id=' + $('job_id').value
        var url = relative_url_root() + "/insurance_payment_eobs/get_upmc_tin";
        new Ajax.Request(url, {
            asynchronous: false,
            method: 'get',
            parameters: parameters,
            onComplete: function(result) {
                var flag = result.responseText.trim();
                if(flag != '' && flag != null && $('payee_tin') != null){
                    $('payee_tin').value = flag
                    $('payee_tin').readOnly = true;
                }
            }
        });
    }
}

function displayProviderAdjustmentGrid(checkedStatus, view, id){
    var saveEobButton;
    if(view == "processor"){
        saveEobButton = parent.myiframe.document.getElementById('proc_save_eob_button_id');
    }
    else if(view == "qa"){
        saveEobButton = document.getElementById('qa_save_eob_button_id');
    }
    var interestOnlyCheck = document.getElementById('checkinforamation_interest_only_check');

    if(checkedStatus) {
        var agree = confirm("Are you sure to process this transaction as Interest only?");
        if (agree == true){
            show_prov_adjustment_grid(checkedStatus, view);
            saveEobButton.disabled = true;
            interestOnlyCheck.value = true;
        }
        else{
            document.getElementById(id).checked = false;
        }
    }
    else{
        show_prov_adjustment_grid(checkedStatus, view);
        saveEobButton.disabled = false;
        interestOnlyCheck.value = false;
    }
}

function validateUpmcJobComplete(role){
    var resultOfValidation = true;
    if($('interest_only_check')) {
        var interestOnlyCheckStatus = $('interest_only_check').checked;
        var payeeName;
        var payeeTin;
        var eobCountField;
        var checkDate;
        var stringOfIdsOfPayerDetails = "'',payer_popup,payer_pay_address_one,payer_city_id,payer_payer_state,payer_zipcode_id,''";
        resultOfValidation = false;

        if (interestOnlyCheckStatus){
            if(window.frames['myiframe']) {
                eobCountField = window.frames['myiframe'].document.getElementById("eob_count_value");
                payeeName = window.frames['myiframe'].document.getElementById("checkinforamation_payee_name");
                payeeTin = window.frames['myiframe'].document.getElementById("payee_tin");
                checkDate = window.frames['myiframe'].document.getElementById("checkdate_id");
            }
            else {
                eobCountField = document.getElementById("eob_count_value");
                payeeName = document.getElementById("checkinforamation_payee_name");
                payeeTin = document.getElementById("payee_tin");
                checkDate = document.getElementById("checkdate_id");
            }

            if(eobCountField != null && parseInt(eobCountField.value, 10) > 0){
                alert("Interest Only Check should not have any EOBs");
                resultOfValidation = false;
            }
            else if(payeeName != null && payeeName.value == ''){
                alert("Please Enter Payee Name");
                setTimeout(function() {
                    payeeName.focus();
                }, 10);
                resultOfValidation = false;
            }
            else if(payeeTin != null && payeeTin.value == ''){
                alert("Please Enter Payee TIN");
                setTimeout(function() {
                    payeeTin.focus();
                }, 10);
                resultOfValidation = false;
            }
            else if((checkDate != null) && (checkDate.type != 'hidden') && (checkDate.value == '' || checkDate.value == "mm/dd/yy")){
                alert("Please Enter Check Date");
                setTimeout(function() {
                    checkDate.focus();
                }, 10);
                resultOfValidation = false;
            }
            else {
                resultOfValidation = validatePayerDetails(stringOfIdsOfPayerDetails);
                if(resultOfValidation == true && role == "processor"){
                    setPayerAndCheckDetails();
                }
            }
        }
        else{
            resultOfValidation = validateEobPresence();
        }
    }
    else{
        resultOfValidation = validateEobPresence();
    }
    return resultOfValidation;
}

function setPayerAndCheckDetails(){
    var hiddenPayerIdList = new Array('payerId', 'payerName', 'payerAddressOne', 'payerAddressTwo', 'payerCity', 'payerState', 'payerZip', 'payerTin', 'payerType');
    var hiddenCheckIdList = new Array('abaRoutingNumber', 'payerAccountNumber', 'checkDate', 'checkAmount', 'checkNumber', 'alternatePayerName', 'paymentType', 'payeeTin', 'payeeName');
    var actualPayerIdList = new Array('payer_id', 'payer_popup', 'payer_pay_address_one', 'payer_address_two', 'payer_city_id', 'payer_payer_state', 'payer_zipcode_id', 'payer_tin_id', 'payer_type');
    var actualCheckIdList = new Array('aba_routing_number_id', 'payer_account_number_id', 'checkdate_id', 'checkamount_id', 'checknumber_id', 'alternate_payer_name_id', 'payment_type_id', 'payee_tin', 'checkinforamation_payee_name');
    var field;
    var i;

    for(i = 0; i < hiddenPayerIdList.length; i++) {
        if(window.frames['myiframe']) {
            field = window.frames['myiframe'].document.getElementById(actualPayerIdList[i]);
            if(field != null && field.value != ''){
                document.getElementById(hiddenPayerIdList[i]).value = field.value;
            }
        }
    }

    for(i = 0; i < hiddenCheckIdList.length; i++) {
        if(window.frames['myiframe']) {
            field = window.frames['myiframe'].document.getElementById(actualCheckIdList[i]);
            if(field != null && field.value != ''){
                document.getElementById(hiddenCheckIdList[i]).value = field.value;
            }
        }
    }
}


function setAlternatePayerName(checked){
    if(checked){
        var agree = confirm("This will apply the selected repricer to all the claims in the check. Are you sure?")
        if (agree == true){
            document.getElementById('apply_to_all_checked_or_not').value = true;
            document.getElementById('alternate_payer_name_id').disabled = true;
            document.getElementById('apply_to_all_claims_hidden_field').value = true;
        }
        else{
            document.getElementById('apply_to_all_checked_or_not').value = false;
            document.getElementById('alternate_payer_name_id').disabled = false;
            document.getElementById('apply_to_all_claims').checked = false;
            document.getElementById('apply_to_all_claims_hidden_field').value = false;
        }
    }
    else{
        document.getElementById('apply_to_all_checked_or_not').value = false;
        document.getElementById('alternate_payer_name_id').disabled = false;
        document.getElementById('apply_to_all_claims_hidden_field').value = false;
    }
}

function setAlternatePayerNameInProcView(checked){
    if(checked){
        var agree = confirm("This will apply the selected repricer to all the claims in the check. Are you sure?")
        if (agree == true){
            document.getElementById('apply_to_all_checked_or_not').value = true;
            document.getElementById('alternate_payer_name_id').disabled = true;
            document.getElementById('apply_to_all_claims').disabled = false
            document.getElementById('apply_to_all_claims_hidden_field').value = true;
        }
        else{
            document.getElementById('apply_to_all_checked_or_not').value = false;
            document.getElementById('alternate_payer_name_id').disabled = false;
            document.getElementById('apply_to_all_claims').checked = false
            document.getElementById('apply_to_all_claims_hidden_field').value = false
        }
    }
    else{
        document.getElementById('apply_to_all_checked_or_not').value = false;
        document.getElementById('alternate_payer_name_id').disabled = false;
        document.getElementById('apply_to_all_claims_hidden_field').value = false;
    }
}
 
function updateTextFieldWithAltternateValue(){
    $('alternate_payer_name_for_eob').value = document.getElementById('alternate_payer_name_id').value
}

function updateTextFieldWithAltternateValueInProcView(){
    if( document.getElementById('alternate_payer_name_id').value != ""){
        document.getElementById('apply_to_all_claims').disabled = false
    }
    else{
        document.getElementById('apply_to_all_claims').disabled = true
    }
    $('alternate_payer_name_for_eob').value = document.getElementById('alternate_payer_name_id').value
}

function changeReadOnlyAttributeOfMicrLineInformation(itemId) {
    if($(itemId)) {
        var fieldName = itemId.split('_');
        fieldName.pop();
        fieldName = fieldName.join(' ').capitalize();
        if($(itemId).readOnly == true) {
            var result = confirm("Do you want to edit " + fieldName + " ?");
            if(result) {
                unmakeTextFieldsReadOnly([itemId]);
                if($('edit_' + itemId))
                    $('edit_' + itemId).checked = false;
                setTimeout(function() {
                    $(itemId).focus();
                }, 20);
            }
        }
        else {
            makeTextFieldsReadOnly([itemId]);
        }
    }
}

function setDefaultValuesForJobIncompletion() {
    if(setDefaultValuesForJobIncompletionToggle != true) {
        needToValidateAdjustmentLine = false;
        setDefaultPatientNameFromFcui();
        if($('fc_def_ac_num') && $('patient_account_id') && $F('patient_account_id').strip() == "")
            $('patient_account_id').value = $F('fc_def_ac_num').strip().toUpperCase();
        if($('tab_type')) {
            if($F('tab_type') == 'Patient') {
                if($('date_service_from_1') && $('fc_def_sdate') &&
                    ($F('date_service_from_1').strip() == "" || $F('date_service_from_1').strip().toLowerCase() == "mm/dd/yy"))
                    setFromDate('date_service_from_1');
                if($('date_service_to_1') && $('fc_def_sdate') &&
                    ($F('date_service_to_1').strip() == "" || $F('date_service_to_1').strip().toLowerCase() == "mm/dd/yy"))
                    setToDate('date_service_from_1');
                
                if($('total_charge_id') && $F('total_charge_id').strip() == "")
                    $('total_charge_id').value = '0.00';
                if($('service_procedure_charge_amount_id1') && $F('service_procedure_charge_amount_id1').strip() == "")
                    $('service_procedure_charge_amount_id1').value = '0.00';
                if($('total_allowable_id') && $F('total_allowable_id').strip() == "")
                    $('total_allowable_id').value = '0.00';
                if($('total_payment_id') && $F('total_payment_id').strip() == "")
                    $('total_payment_id').value = '0.00';
                if($('total_service_balance_id') && $F('total_service_balance_id').strip() == "")
                    $('total_service_balance_id').value = '0.00';
                if($('service_balance_id1') && $F('service_balance_id1').strip() == "")
                    $('service_balance_id1').value = '0.00';

                if($('payer_popup')) {
                    if($('patient_address_one') && $F('patient_address_one').strip() == "")
                        $('patient_address_one').value = $F('payer_pay_address_one').strip();
                    if($('patient_address_two') && $F('patient_address_two').strip() == "")
                        $('patient_address_two').value = $F('payer_address_two').strip();
                    if($('patient_city_id') && $F('patient_city_id').strip() == "")
                        $('patient_city_id').value = $F('payer_city_id').strip();
                    if($('patient_state_id') && $F('patient_state_id').strip() == "")
                        $('patient_state_id').value = $F('payer_payer_state').strip();
                    if($('patient_zipcode_id') && $F('patient_zipcode_id').strip() == "")
                        $('patient_zipcode_id').value = $F('payer_zipcode_id').strip();
                }
            }
            else if($F('tab_type') == 'Insurance') {
                if($('dateofservicefrom') && $('fc_def_sdate') &&
                    ($F('dateofservicefrom').strip() == "" || $F('dateofservicefrom').strip().toLowerCase() == "mm/dd/yy"))
                    setFromDate('dateofservicefrom');
                if($('date_service_to_1') && $('fc_def_sdate') &&
                    ($F('dateofserviceto').strip() == "" || $F('dateofserviceto').strip().toLowerCase() == "mm/dd/yy"))
                    setToDate('dateofservicefrom');

                if($('charges_id') && $F('charges_id').strip() == "")
                    $('charges_id').value = '0.00';
                if($('allowable_id') && $F('allowable_id').strip() == "")
                    $('allowable_id').value = '0.00';
                if($('payment_id') && $F('payment_id').strip() == "")
                    $('payment_id').value = '0.00';
                if($('balance_id') && $F('balance_id').strip() == "")
                    $('balance_id').value = '0.00';
                if($('claim_level_eob') != null && $F('claim_level_eob') == "true") {
                    if($('claim_from_date_id') && $('fc_def_sdate') &&
                        ($F('claim_from_date_id').strip() == "" || $F('claim_from_date_id').strip().toLowerCase() == "mm/dd/yy"))
                        setFromDate('claim_from_date_id');
                    if($('claim_to_date_id') && $('fc_def_sdate') &&
                        ($F('claim_to_date_id').strip() == "" || $F('claim_to_date_id').strip().toLowerCase() == "mm/dd/yy"))
                        setToDate('claim_from_date_id');
                    if($('total_charge_id') && $F('total_charge_id').strip() == "")
                        $('total_charge_id').value = '0.00';
                    if($('total_payment_id') && $F('total_payment_id').strip() == "")
                        $('total_payment_id').value = '0.00';
                    if($('total_service_balance_id') && $F('total_service_balance_id').strip() == "")
                        $('total_service_balance_id').value = '0.00';
                }
            }
        }
        setDefaultValuesForJobIncompletionToggle = true;
    }
    else {
        needToValidateAdjustmentLine = true;
        resetDefaultPatientNameFromFcui();
        if($('fc_def_ac_num') && $('patient_account_id') && $F('patient_account_id').strip() == $F('fc_def_ac_num').strip().toUpperCase())
            $('patient_account_id').value = "";
        if($('total_service_balance_id') && parseInt($F('total_service_balance_id').strip()) == 0)
            $('total_service_balance_id').value = '';

        if($('payer_popup')) {
            if($('patient_address_one') && $F('patient_address_one').strip() == $F('payer_pay_address_one').strip())
                $('patient_address_one').value = "";
            if($('patient_address_two') && $F('patient_address_two').strip() == $F('payer_address_two').strip())
                $('patient_address_two').value = "";
            if($('patient_city_id') && $F('patient_city_id').strip() == $F('payer_city_id').strip())
                $('patient_city_id').value = "";
            if($('patient_state_id') && $F('patient_state_id').strip() == $F('payer_payer_state').strip())
                $('patient_state_id').value = "";
            if($('patient_zipcode_id') != null && $F('patient_zipcode_id').strip() == $F('payer_zipcode_id').strip())
                $('patient_zipcode_id').value = "";
        }
        setDefaultValuesForJobIncompletionToggle = false;
    }
}

function validateRoutingNumberAndMakeReadOnly(id, isMicrConfigured) {
    var isValid = isAbaValid(id, isMicrConfigured);
    if(isValid) {
        makeTextFieldsReadOnly([id]);
    }
    else {
        setTimeout(function() {
            $(id).focus();
        }, 20);
    }
    return isValid;
}

function validatePayerAccountNumberAndMakeReadOnly(id, isMicrConfigured) {
    var isValid = isPayerAccNumValid(id, isMicrConfigured);
    if(isValid) {
        makeTextFieldsReadOnly([id]);
    }
    else {
        setTimeout(function() {
            $(id).focus();
        }, 20);
    }
    return isValid;
}

function showAdditionalJobCreationRequest(fieldId) {
    if($(fieldId) && $('additional_job_creation_request_div')) {
        if($(fieldId).checked == '1')
            $('additional_job_creation_request_div').style.display = 'block';
        else
            $('additional_job_creation_request_div').style.display = 'none';
    }
}

function functionsToSubmitAdditionalJobRequest() {
    return (validateAdditionalJobRequest() && setJobButtonValue('Additional Job Request') &&
        confirm('Are you sure ?'));
}

function validateAdditionalJobRequest() {
    var resultOfValidation = true;

    if(anyEobPresent() == true) {
        resultOfValidation = false;
        alert("There are EOBs saved. Please delete them and proceed.");
    }
    else {
        if($('additional_job_request_comment')) {
            if($F('additional_job_request_comment').strip() == "") {
                resultOfValidation = false;
                alert("Please enter the request comment");
                setTimeout(function() {
                    $('additional_job_request_comment').focus();
                }, 20);
            }
        }
    }
    return resultOfValidation;
}

function anyEobPresent() {
    var result = false;
    if($('check_id')) {
        var parameters = 'check_information_id=' + $F('check_id');
        var url = relative_url_root() + "/insurance_payment_eobs/any_eob_present";
        new Ajax.Request(url, {
            method: 'get',
            asynchronous: false,
            parameters: parameters,
            onComplete: function(savedEob) {
                var anyEobSaved = savedEob.responseText;
                if(anyEobSaved == "true" || anyEobSaved == true){
                    result = true;
                }
            }
        });
    }
    return result;
}

function confrimHipaaCodes(uniqueCodeObjects) {
    var resultOfValidation = true;
    if($('hipaa_adjustment_codes_field')) {
        var standardHipaaAdjustmentCodes = $F('hipaa_adjustment_codes_field').split(',');
        if(standardHipaaAdjustmentCodes != '') {
            var hipaaCodeIds = [];
            for(var i = 0; i < uniqueCodeObjects.length; i++) {
                if(uniqueCodeObjects[i] != null) {
                    var uniqueCodeId = uniqueCodeObjects[i].id;
                    var uniqueCodeValue = uniqueCodeObjects[i].value;
                    if(uniqueCodeValue.strip() != '') {
                        setHighlight([uniqueCodeId], "blank");
                        if(standardHipaaAdjustmentCodes.indexOf(uniqueCodeValue) != -1) {
                            hipaaCodeIds.push(uniqueCodeId);
                        }
                    }
                }
            }
            if(hipaaCodeIds.length > 0) {
                setHighlight(hipaaCodeIds, "uncertain");
                resultOfValidation = confirm("You have entered ANSI HIPAA Adjustment codes in the highlighted fields. Are you sure?");
                if(resultOfValidation) {
                    setHighlight(hipaaCodeIds, "blank");
                }
            }
        }
    }
    
    return resultOfValidation;
}

function confirmHipaaCodesForAddServiceLine() {
    var uniqueCodeIds = ['reason_code_noncovered_unique_code', 'reason_code_denied_unique_code',
    'reason_code_discount_unique_code', 'reason_code_coinsurance_unique_code',
    'reason_code_deductible_unique_code', 'reason_code_copay_unique_code',
    'reason_code_primary_payment_unique_code', 'reason_code_prepaid_unique_code',
    'reason_code_patient_responsibility_unique_code', 'reason_code_contractual_unique_code',
    'reason_code_miscellaneous_one_unique_code', 'reason_code_miscellaneous_two_unique_code'];
    var uniqueCodeObjects = [];
    for(var i = 0; i < uniqueCodeIds.length; i++) {
        uniqueCodeObjects.push($(uniqueCodeIds[i]));
    }
    return confrimHipaaCodes(uniqueCodeObjects);
}

function setPaymentMethodOnCheckNumberEdit(has_system_generated_check_number, check_number_from_db){
    result = true;
    payment_method_of_check = $F('payment_method');
    check_no_from_ui = $F('checknumber_id');
    if(has_system_generated_check_number && payment_method_of_check == 'COR' &&
        (check_number_from_db != check_no_from_ui)){
        $('payment_method').value = 'EFT';
    }
    return result;
}

function validateDenialServiceLineForUpmcOnAddRow(){
    var unique_code = [];
    var return_flag  = true;
    if( $('client_name') != null  && $F('client_name').strip().toUpperCase() == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'){
        if($('payment_id') != null  && ($F('payment_id') == '' || $F('payment_id') == 0 ) && !($F('charges_id') < 0)){
            $$('.proprietary_code').each(
                function(item) {
                    if(item.value != '' ){
                        unique_code.push(item.value)
                    }
                });
            if(unique_code.length <= 0){
                alert("Denial Service line should contain atleast one Proprietary Code.")
                return_flag = false;
            }
        }
    }
    return return_flag;
}

function validateDenialServiceLineForUpmcOnSave(){
    var totalLine = parseInt($F('total_line_count'))
    var lineCount;
    var return_flag = true;
    var unique_code = [];
    var service_line_number = []
    if( $('client_name') != null  && $F('client_name').strip().toUpperCase() == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'){
        for(lineCount = 2; lineCount <= totalLine; lineCount++) {
            var unique_code = [];
            var payment = 'service_paid_amount_id'+ lineCount
            var charge  = 'service_procedure_charge_amount_id' + lineCount
            if($(payment) != null  && ($F(payment) == '' || $F(payment) == 0 ) && !($F(charge) < 0)){
                var unique_code_class = '.proprietary_code_' + lineCount.toString()
                $$(unique_code_class).each(
                    function(item) {
                        if($(item) != null){
                            if(item.value != '' ){
                                unique_code.push(item.id)
                            }
                        }
                    });
                if(unique_code.length <= 0){
                    var service_row = 'service_row' + lineCount
                    if($(service_row) != null)
                        service_line_number.push(lineCount - 1)
                }
            }
        }
        if(service_line_number.length > 0){
            alert("Service line(s) " + service_line_number + " found to be Denial. Please add atleast one Proprietary Code.")
            var payment_id = 'service_paid_amount_id'+ (parseInt(service_line_number[0]) + 1)
            $(payment_id).focus();
            return_flag = false;
        }
    }

    return return_flag;
}

function checkJobAllocationQueue(){
    var return_value = true
    if(document.getElementById('current_user_role') != null) {
        var role = document.getElementById('current_user_role').value.toUpperCase();
        if(role == 'PROCESSOR') {
            if(parent.myiframe  != "undefined" && parent.myiframe  != null && parent.myiframe.document.getElementById('job_id') != null){
                var job_id = parent.myiframe.document.getElementById('job_id').value;
            }
            var parameters = 'job_id=' + job_id;
            var url = relative_url_root() + "/insurance_payment_eobs/get_job_allocation_queue";
            new Ajax.Request(url, {
                method: 'get',
                asynchronous: false,
                parameters: parameters,
                onComplete: function(saved_tt) {
                    var job_allocation_queue =  saved_tt.responseText;
                    if(job_allocation_queue == "false" ){
                        alert("This job is re-allocated to another. Please contact Shift Managers for the details. For getting new jobs, go to Home page and click My Task")
                        return_value = false
                    }
                }
            });
        }
    }
    return return_value
}

function validateProviderDetails(){
    var default_provider_fcui_config = $F('default_provider_configuration')
    var result = true;
    if(default_provider_fcui_config == 'true' && $('provider_provider_npi_number') != null && $('provider_tin_id') != null){
        var prov_npi =   $F('provider_provider_npi_number');
        var prov_tin = $F('provider_tin_id');
        if(prov_npi == '' && prov_tin == ''){
            var confirm_flag  = confirm("Rendering provider NPI/TIN is blank do you want to key it from images?");
            if(confirm_flag){
                $('provider_provider_npi_number').focus();
                result= false;
            }
            else{
                $('provider_provider_npi_number').value  = $F('facility_npi')
                $('provider_tin_id').value = $F('facility_tin')
            }
        }
    }
    return result;
}

function validateEobCorrectness() {
    var resultOfValidation = true;
    if($('user_role')) {
        var role = $('user_role').value.toUpperCase();
        if(role == 'QA' && $('incorrect')) {
            var incorrectFieldCount = $F('incorrect').strip();
            var selectedErrorCount = 0;
            $$('.eob_error_list').each(
                function(item) {
                    if($(item) != null)
                        if(item.checked) {
                            selectedErrorCount++;
                        }
                });
            var incorrectFieldCountMustBePresent = (incorrectFieldCount == '');
            var incorrectFieldCountMoreThanOneButErrorTypeIsBlank = (
                parseInt(incorrectFieldCount) > 0 && selectedErrorCount == 0);
            if(incorrectFieldCountMustBePresent || incorrectFieldCountMoreThanOneButErrorTypeIsBlank) {
                resultOfValidation = false;
            }
        }
    }
    if(!resultOfValidation) {
        alert("Please enter Incorrect Field Count OR Error Type");
    }
    return resultOfValidation;
}

function validateAccountNumberForChoc(accountNumberId) {
    var resultOfValidation = true;
    var message = "";
    if($(accountNumberId) && $('facility')) {
        var facilityName = $F('facility').strip().toUpperCase();
        var accountNumber = $F(accountNumberId).strip().toUpperCase();
        if(accountNumber != "" && facilityName == "CHILDRENS HOSPITAL OF ORANGE COUNTY") {
            var firstLetter = accountNumber[0];
            if((firstLetter == 'C' && !accountNumber.startsWith('CS'))  ||  firstLetter == 'S' && accountNumber.startsWith('SC')) {
                message = "Are you sure the account number is not starting with CS?";
            }
            else if((firstLetter != 'C' && firstLetter != 'P' && firstLetter != 'Y') && accountNumber[0].match(/[a-zA-Z]/) != null) {
                message = "Are you sure the account number is valid? Please confirm with the image";
            }
            else if(accountNumber.match(/^[0-9]+$/) != null && accountNumber.length < 9) {
                message = "Are you sure the account number is valid? Please confirm with the image";
            }
            else {
                if(accountNumber.startsWith('CS'))
                    var accountNumberWithNoPrefix = accountNumber.replace(/CS/i, '') ;
                else if(firstLetter == 'P')
                    accountNumberWithNoPrefix = accountNumber.replace(/P/i, '') ;
                else if(firstLetter == 'Y')
                    accountNumberWithNoPrefix = accountNumber.replace(/Y/i, '') ;
                else
                    accountNumberWithNoPrefix = accountNumber;
                if(accountNumberWithNoPrefix != "" && accountNumberWithNoPrefix != null) {
                    if(accountNumberWithNoPrefix.match(/[a-zA-Z]/) ) {
                        message = "Are you sure the account number is valid? Please confirm with the image";
                    }
                }
            }
        }
    }

    if(message != "") {
        resultOfValidation = confirm(message);
        if(!resultOfValidation) {
            setTimeout(function(){
                $(accountNumberId).focus();
            }, 10);
        }
    }
    return resultOfValidation;
}