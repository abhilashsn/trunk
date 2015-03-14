// Contains the functions related to Payment Method feature.

function setValidationForPaymentMethod() {
    var item_ids;
    var paymentMethod;
    if($('payment_method') != null)
        paymentMethod = $F('payment_method');
    else if($('check_information_payment_method') != null)
        paymentMethod = $F('check_information_payment_method');
    if(paymentMethod == 'CHK' || paymentMethod == 'OTH' ) {
        if($('client_type') != null && $F('client_type').strip().toUpperCase() == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'){
            item_ids = ["checknumber_id", "checkamount_id", 'checkdate_id'];
            removeCustomValidations(["aba_routing_number_id", "payer_account_number_id"], "required");
        }
        else{
            item_ids = ["checknumber_id", "checkamount_id", 'checkdate_id', 'aba_routing_number_id', 'payer_account_number_id'];
        }
        if(isCheckNumberAutoGenerated() == true) {
            $('checknumber_id').value = '';
            $('checknumber_id').readOnly = false;
        }
        setFieldsValidateAgainstCustomMethod(["checknumber_id"], "validate-nonzero-alphanum");
        setFieldsValidateAgainstCustomMethod(item_ids, "required");
        setFieldsValidateAgainstCustomMethod(["checkamount_id"], "validate-nonzero-checkamount");
        setFieldsValidateAgainstCustomMethod(["checkdate_id"], "validate-check-date");
        removeCustomValidations(["checknumber_id"], "validate-zero-number");
        removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
        removeCustomValidations(["checkdate_id"], "validate-cor-date");
        if(($('aba_routing_number_id')) && ($('aba_routing_number_id').value.strip() == "")) {
            $('aba_routing_number_id').readOnly = false;
        }
        if(($('payer_account_number_id')) && ($('payer_account_number_id').value.strip() == "")) {
            $('payer_account_number_id').readOnly = false;
        }
    }
    else if(paymentMethod == 'COR') {
        item_ids = ["checknumber_id", "checkamount_id", 'checkdate_id', 'aba_routing_number_id', 'payer_account_number_id'];
        removeCustomValidations(item_ids, "required");
        removeCustomValidations(["checknumber_id"], "validate-nonzero-alphanum");
        removeCustomValidations(["checkamount_id"], "validate-nonzero-checkamount");
        if($('client_type') != null && ($F('client_type').strip().toUpperCase() == "PACIFIC DENTAL SERVICES" || $F('client_type').strip().toUpperCase() == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'|| ( $('facility') != null && $F('facility').strip().toUpperCase() == 'SOUTH NASSAU COMMUNITY HOSPITAL' ))){
            if($('checkdate_id') != null && $F('checkdate_id') != ''){
                setFieldsValidateAgainstCustomMethod(["checkdate_id"], "validate-check-date");
                removeCustomValidations(["checkdate_id"], "validate-cor-date");
            }
            else{
                removeCustomValidations(["checkdate_id"], "validate-check-date");
            }
        }
        else{
            removeCustomValidations(["checkdate_id"], "validate-check-date");
            removeCustomValidations(["checkdate_id"], "validate-date");
            setFieldsValidateAgainstCustomMethod(["checkdate_id"], "validate-cor-date");
        }
        if($('aba_routing_number_id')){
            $('aba_routing_number_id').value = ''
            $('aba_routing_number_id').readOnly = true;
        }
        if($('payer_account_number_id')){
            $('payer_account_number_id').value = ''
            $('payer_account_number_id').readOnly = true;
        }
        if(isCheckNumberAutoGenerated() == false)
            setFieldsValidateAgainstCustomMethod(["checknumber_id"], "validate-zero-number");
            
        setFieldsValidateAgainstCustomMethod(['checkamount_id'], "validate-zero-check-amount");
    }
    else if(paymentMethod == 'EFT' || paymentMethod == 'ACH') {
        item_ids = ["checknumber_id", "checkamount_id", 'checkdate_id', 'aba_routing_number_id', 'payer_account_number_id'];
        removeCustomValidations(item_ids, "required");
        removeCustomValidations(["checkdate_id"], "validate-check-date");
        removeCustomValidations(["checkdate_id"], "validate-cor-date");
        removeCustomValidations(["checknumber_id"], "validate-nonzero-alphanum");
        if($('aba_routing_number_id')){
            $('aba_routing_number_id').readOnly = true;
        }
        if($('payer_account_number_id')){
            $('payer_account_number_id').readOnly = true;
        }
        setRequiredOnChecknumberOrCheckAmount();
    }
//console_logger("In setValidationForPaymentMethod", paymentMethod);
}

function setRequiredOnChecknumberOrCheckAmount() {
    var paymentMethod, item_ids;
    if($('payment_method') != null)
        paymentMethod = $F('payment_method');
    else if($('check_information_payment_method') != null)
        paymentMethod = $F('check_information_payment_method');
    if(paymentMethod == 'EFT' || paymentMethod == 'ACH') {
        item_ids = ['checknumber_id', 'checkamount_id'];
        var checkNumber = $F('checknumber_id').strip();
        var isCheckNumberValid = (checkNumber != '' &&
            checkNumber.match(/^[\w]+$/) != null &&
            checkNumber.match(/[^0]/) != null &&
            (($('client_type') != null &&
                $F('client_type').toUpperCase() == "ASCEND CLINICAL LLC" &&
                isCheckNumberAutoGenerated() == true)|| ($('client_type') != null &&
                $F('client_type').toUpperCase() == "PACIFIC DENTAL SERVICES" &&
                isCheckNumberAutoGenerated() == true) || isCheckNumberAutoGenerated() == false));
        var isCheckAmountValid = ($F('checkamount_id').strip() != '' && parseFloat($F('checkamount_id')) != 0);

        if(isCheckNumberValid != true && isCheckAmountValid != true) {
            setFieldsValidateAgainstCustomMethod(item_ids, "required");
            setFieldsValidateAgainstCustomMethod(["checknumber_id"], "validate-nonzero-alphanum");
            setFieldsValidateAgainstCustomMethod(["checkamount_id"], "validate-nonzero-checkamount");
        }
        else if(isCheckNumberValid == true && isCheckAmountValid == true) {
            removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
            removeCustomValidations(["checknumber_id"], "validate-zero-number");
            setFieldsValidateAgainstCustomMethod(["checknumber_id"], "validate-nonzero-alphanum");
            setFieldsValidateAgainstCustomMethod(["checkamount_id"], "validate-nonzero-checkamount");
        }
        else if(isCheckNumberValid == true) {
            removeCustomValidations(["checknumber_id"], "validate-zero-number");
            setFieldsValidateAgainstCustomMethod(["checknumber_id"], "validate-nonzero-alphanum");
            setFieldsValidateAgainstCustomMethod(["checkamount_id"], "validate-zero-check-amount");
            removeCustomValidations(["checkamount_id"], "validate-nonzero-checkamount");
            removeCustomValidations(["checkamount_id"], "required");
        }
        else if(isCheckAmountValid == true) {
            removeCustomValidations(["checkamount_id"], "validate-zero-check-amount");
            setFieldsValidateAgainstCustomMethod(["checkamount_id"], "validate-nonzero-checkamount");
            if(isCheckNumberAutoGenerated() == false)
                setFieldsValidateAgainstCustomMethod(["checknumber_id"], "validate-zero-number");
            removeCustomValidations(["checknumber_id"], "validate-nonzero-alphanum");
            removeCustomValidations(["checknumber_id"], "required");
        }
    }
}

function validateCheckDetailsWithValueOfPaymentMethod(payment_method_flag){
    var validateResult = true;
    if (payment_method_flag) {
        var paymentMethod = true;
        if($('payment_method') != null)
            paymentMethod = $F('payment_method');
        else if($('check_information_payment_method') != null)
            paymentMethod = $F('check_information_payment_method');
        if(paymentMethod == "CHK" || paymentMethod == "OTH")
        {
            validateResult = validateChkMethod()
        }
        else if(paymentMethod == "COR")
        {
            validateResult = validateCorMethod()
        }
        else if(paymentMethod == "EFT")
        {
            validateResult = validateEftMethod()
        }
        else if(paymentMethod == 'ACH')
        {
            validateResult = validateAchMethod()
        }
    }
    //    console_logger(validateResult, 'validateCheckDetailsWithValueOfPaymentMethod');
    return validateResult;
}

//if the payment method is 'chk' function will check whether all the check values are entered or not
function validateChkMethod(){
    var blankFieldsNames = [];
    var invalidFieldIds = [];
    if($('checknumber_id') != null) {
        var checkNumber = $F('checknumber_id').strip();
        if(checkNumber == '' || checkNumber.match(/^[\w]+$/) == null ||
            checkNumber.match(/[^0]/) == null || isCheckNumberAutoGenerated() == true) {
            blankFieldsNames.push(' Check Number');
            invalidFieldIds.push('checknumber_id');
        }
    }
    if($('client_type') != null && $F('client_type').strip().toUpperCase() != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' ) {
        if($('aba_routing_number_id') != null) {
            var routingNumber = $F('aba_routing_number_id').strip();
            if(routingNumber == '' || routingNumber.match(/^[\w]+$/) == null ||
                routingNumber.match(/[^0]/) == null) {
                blankFieldsNames.push(' ABA Routing #');
                invalidFieldIds.push('aba_routing_number_id');
            }
        }
        if($('payer_account_number_id') != null) {
            var accountNumber = $F('payer_account_number_id'.strip());
            if(accountNumber == '' || accountNumber.match(/^[\w]+$/) == null ||
                accountNumber.match(/[^0]/) == null) {
                blankFieldsNames.push(' Payer Account #');
                invalidFieldIds.push('payer_account_number_id');
            }
        }
    }
    if($F("checkamount_id").strip() == '' || parseFloat($F("checkamount_id")) == 0){
        blankFieldsNames.push(" Check Amount");
        invalidFieldIds.push('checkamount_id');
    }
   
    if($("checkdate_id") != null && $("checkdate_id").type != 'hidden') {
        var checkDate = $F("checkdate_id").strip().toUpperCase();
        if(checkDate == '' || checkDate == "MM/DD/YY"){
            blankFieldsNames.push(" Check Date");
            invalidFieldIds.push('checkdate_id');
        }
    }
    if(blankFieldsNames.length > 0){
        if($F('payment_method') == 'CHK')
            alert("The Payment Method is selected as CHK. Please enter value in : " + blankFieldsNames);
        else if($F('payment_method') == 'OTH')
            alert("The Payment Method is selected as OTH. Please enter value in : " + blankFieldsNames);
        setTimeout(function(){
            $(invalidFieldIds[0]).focus();
        },50);
        return false;
    }
    else {
        return true;
    }
}

//if the payment method is cor function will alert if a non zero value present in the check details
function validateCorMethod(){
    var invalidFields = [];
    var invalidFieldIds = [];
    var blankFieldsNames = [];
    
    var checkAmount = $F("checkamount_id").strip();
    var isCheckAmountInvalid = (checkAmount != '' &&  parseFloat(checkAmount) != 0);
    if (isCheckAmountInvalid == true) {
        invalidFields.push(' Check Amount');
        invalidFieldIds.push('checkamount_id');
    }

    var checkNumber = $F("checknumber_id").strip();
    var isCheckNumberInvalid = (checkNumber != '' && (checkNumber.match(/^[\w]+$/) == null ||
        checkNumber.match(/[^0]/) != null && isCheckNumberAutoGenerated() == false))
    if (isCheckNumberInvalid == true) {
        invalidFields.push(' Check Number');
        invalidFieldIds.push('checknumber_id');
    }

    if($('client_type') != null && ($F('client_type').strip().toUpperCase() != "PACIFIC DENTAL SERVICES" && $F('client_type').strip().toUpperCase() != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' && ( $('facility') != null && $F('facility').strip().toUpperCase() != 'SOUTH NASSAU COMMUNITY HOSPITAL' ))){
        if($("checkdate_id") != null && $("checkdate_id").type != 'hidden') {
            var checkDate = $F("checkdate_id").strip();
            var isCheckDateInvalid = (checkDate != ''&& checkDate.toUpperCase() != "MM/DD/YY");
            if (isCheckDateInvalid == true) {
                invalidFields.push(' Check Date');
                invalidFieldIds.push('checkdate_id');
            }
        }
    }

    if($("aba_routing_number_id") != null) {        
        var abaRouting = $F("aba_routing_number_id").strip();
        var isAbaNumberInvalid = (abaRouting != '' && abaRouting.match(/^[\w]+$/) == null ||
            abaRouting.match(/[^0]/) != null);
        if (isAbaNumberInvalid == true) {
            invalidFields.push(' ABA Routing #');
            invalidFieldIds.push('aba_routing_number_id');
        }
    }

    if($("payer_account_number_id") != null) {       
        var payerAccountNo = $F("payer_account_number_id").strip();
        var isPayerNumberInvalid = (payerAccountNo != '' && payerAccountNo.match(/^[\w]+$/) == null ||
            payerAccountNo.match(/[^0]/) != null)
        if (isPayerNumberInvalid == true) {
            invalidFields.push(' Payer Account #');
            invalidFieldIds.push('payer_account_number_id');
        }
    }
    if(invalidFields.length > 0){
        alert("The Payment Method is selected as COR. Please do not enter value in : " + invalidFields);
        setTimeout(function(){
            $(invalidFieldIds[0]).focus();
        },50);
        return false;
    }
    else{
        return true;
    }
}

// function check either check number or check amount is entered
function validateEftMethod(){
    var checkNumber = $F("checknumber_id").strip();
    var checkAmount = $F("checkamount_id").strip();
    if(((checkNumber.match(/[\!\@\#\$\%\^\&\*\(\)\_\_\+\=\{\}\[\]\|\\\:\;\"\'\<\,\>\.\?\/]+/) != null) || checkAmount == '' || parseFloat($F("checkamount_id")) == 0 ) &&
        (checkNumber == ''  ||  checkNumber.match(/^[\w]+$/) == null ||
            checkNumber.match(/[^0]/) == null) ){
            
        alert("The Payment Method is selected as EFT. Please enter Check Number / Check Amount");
        return false;
    }
    else if(checkNumber == '' || checkNumber.match(/^[\w]+$/) == null ||
        checkNumber.match(/[^0]/) == null){
        return confirm("The Payment Method is selected as EFT. Please confirm Check Number is not available on the image")
    }
    else{
        return true;
    }
}

function validateAchMethod(){
    var checkNumber = $F("checknumber_id").strip();
    var checkAmount = $F("checkamount_id").strip();
    if(((checkNumber.match(/[\!\@\#\$\%\^\&\*\(\)\_\_\+\=\{\}\[\]\|\\\:\;\"\'\<\,\>\.\?\/]+/) != null) || checkAmount == '' || parseFloat($F("checkamount_id")) == 0 ) &&
        (checkNumber == ''  ||  checkNumber.match(/^[\w]+$/) == null ||
            checkNumber.match(/[^0]/) == null) ){

        alert("The Payment Method is selected as ACH. Please enter Check Number / Check Amount");
        return false;
    }
    else if(checkNumber == '' || checkNumber.match(/^[\w]+$/) == null ||
        checkNumber.match(/[^0]/) == null){
        return confirm("The Payment Method is selected as ACH. Please confirm Check Number is not available on the image")
    }
    else{
        return true;
    }
}

function disablePaymentMethod() {
    if($('payment_method')) {
        var anyEobProcessed = ($('any_eob_processed') != null && $F('any_eob_processed') == "true");
        var qaView;
        if($('qa_view') == null)
            qaView = false;
        else
            qaView = true;
        if((qaView == false && anyEobProcessed)) {
            $('payment_method').disabled = true;
        }
    }
}

function alertForValidPaymentMethod(){
    var payment_method_flag = isValidPaymentMethod()
    if (payment_method_flag == false){
        alert("Payment method should be either OTH or CHK");
        setTimeout(function() {
            $('payment_method').focus();
        }, 10);
        return false;
    }
    else{
        return true;
    }
  
}

function isValidPaymentMethod() {
    if($('payment_method')) {
        //        var anyEobProcessed = ($('any_eob_processed') != null && $F('any_eob_processed') == "true");
  
        if($('aba_routing_number_id') != null && $('payer_account_number_id') != null) {
            var isMicrNumbersValid = isMicrFormatValid('aba_routing_number_id') &&
            isMicrFormatValid('payer_account_number_id');
        }
        else
            isMicrNumbersValid = false;
        if( isMicrNumbersValid) {
            if(($F('payment_method') == 'COR') || ($F('payment_method') == 'EFT') || ($F('payment_method') == 'ACH')){
                return false;
            }
            else
                return true;
             
        }
        else
            return true;
    }
    else
        return true;
}

function setPaymentMethodHiddenField() {
    if($('payment_method') != null && $('check_information_payment_method') != null) {
        $('check_information_payment_method').value = $F('payment_method');
    }
}

function setPaymentMethodInRelationToMicr() {
    var toProceed = true;
    var paymentMethod;
    if($('payment_method') != null)
        paymentMethod = $F('payment_method');
    else if($('check_information_payment_method') != null)
        paymentMethod = $F('check_information_payment_method');
    var anyEobProcessed = ($('any_eob_processed') != null && $F('any_eob_processed') == "true");
    if($('aba_routing_number_id') != null && $('payer_account_number_id') != null && anyEobProcessed && $('client_type') != null && $F('client_type').strip().toUpperCase() != 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER') {
        if($F('aba_routing_number_id').strip() == '' && $F('payer_account_number_id').strip() == '') {
            if(paymentMethod == 'CHK' || paymentMethod == 'OTH') {
                alert('Please continue after deleting all the EOBs for choosing CHK/OTH');
                toProceed = false;
            }
        }        
    }
    //    console_logger(toProceed, 'setPaymentMethodInRelationToMicr');
    return toProceed;
}