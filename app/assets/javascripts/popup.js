// Global boolean variable which confirms if the payer name is selected from typeahead or a newly entered payer
var isPayerFromTypeAhead = false;
// Global boolean variable which confirms if payer type selection prompt is to be displayed in onBlur event of either payer state field or payer type field
var isPromptFromPayerType = false;

function populatePayerInfo(element_id){

    if ($(element_id).value.include('+')) { //Block to avoid exception at runtime

        var url = relative_url_root() + '/datacaptures/payer_informations';
        var parameters = 'payer=' + $(element_id).value.replace(/\+/g,"%2B") + '&job_id=' + $F('job_id');
        
        var payer1 = $(element_id).value;
        var payer_name = $(element_id).value.split("+")
        $('payer_popup').value = payer_name[0]
        var payerAjax = new Ajax.Request(url, {
            method: 'get',
            parameters: parameters,
            onComplete: function(payer){

                var payerInformations = eval("(" + payer.responseText + ")");
                if (payerInformations) {
                    //this is to programmetically set the payer_type based on the payer selection done through type ahead
                    if (payerInformations.payer_type != null) {
                        // Checking if the current tab selection is for Simplified Grid for Patpay
                        if ($F('tab_type') != "Patient") {
                            var payerTypeObject = document.form1.payer_type;
                            var getSelectedIndex = payerTypeObject.selectedIndex;
                            var payerType = payerTypeObject[getSelectedIndex].value;
                            var countOfOptions = payerTypeObject.length;
                            // Iterating through the payer type dropdown box to find the index of -- option
                            for (i = 0; i < countOfOptions; i++) {
                                if (payerTypeObject[i].value == "--") {
                                    payerTypeObject[i].selected = true;
                                }
                            }
                        }

                    }

                    if (payerInformations.payer_address_one != null)
                        $("payer_pay_address_one").value = payerInformations.payer_address_one
                    else
                        $("payer_pay_address_one").value = ""
                    if (payerInformations.payer_address_two != null)
                        $("payer_address_two").value = payerInformations.payer_address_two
                    else
                        $("payer_address_two").value = ""
                    if (payerInformations.payer_state != null)
                        $("payer_payer_state").value = payerInformations.payer_state
                    else
                        $("payer_payer_state").value = ""
                    if (payerInformations.payer_city != null)
                        $("payer_city_id").value = payerInformations.payer_city
                    else
                        $("payer_city_id").value = ""
                    if (payerInformations.payer_zip != null)
                        $("payer_zipcode_id").value = payerInformations.payer_zip
                    else
                        $("payer_zipcode_id").value = ""
                    if (payerInformations.status != null)
                        $("payer_status").value = payerInformations.status
                    else
                        $("payer_status").value = ""
                    if (payerInformations.payid != null)
                        $("payer_payid").value = payerInformations.payid
                    else
                        $("payer_payid").value = ""
                    ctlObjectValue = ""
                    ctlObjectValue = $("payer_tin_id")
                    if (payerInformations.payer_tin != null) {
                        if (ctlObjectValue != null)
                            $("payer_tin_id").value = payerInformations.payer_tin
                    }
                    else {
                        if (ctlObjectValue != null) {
                            $("payer_tin_id").value = ""
                        }
                    }
                    $("payer_id").value = payerInformations.payer_id;

                    disablePayerAddressForApprovedPayers();
                    payerIndicatorForCorrespondenceCheck();
                    setTwiceKeyingFields(payerInformations.reason_code_set_name_id);
                    if(payerInformations.payer_type!= null) {
                        $('type_of_payer_created_by_admin').value = payerInformations.payer_type;
                    }
                    else
                        $('type_of_payer_created_by_admin').value = '';
                    if ($("fc_plan_type").value == "Payer specific only") {
                        if (payerInformations.plan_type != null) {
                            $("plan_type_id").value = payerInformations.plan_type
                        }
                    }
                    if (payerInformations.plan_type == null ||
                        (payerInformations.plan_type != null && payerInformations.plan_type.strip() == '')) {
                        $("plan_type_id").value = "";
                    }

                    document.getElementById("payer_details_string").value = payer1

                    isPayerFromTypeAhead = true;
                }
            }
        });
    }
    else {
        if(isPayerFromTypeAhead != true) {
            isPayerFromTypeAhead = false;
        }
    }
}

function formatPayerState(){
    if($("payer_payer_state") != null && $("payer_payer_state").value.length > 1)
        $("payer_payer_state").value = $F("payer_payer_state").substr(-2, 2);
}

//If A/c # and Routing # not present in the Index file and Processor manually indexes A/c # and Routing #,
//system match up successful – ie. finds payer details,
//then Payer details auto populated on focus of payer name field.
function micrwise_payerInformations(check_string){
    micr_exists = $('aba_routing_number_id') != null && $('payer_account_number_id') != null &&
    $F('aba_routing_number_id').strip() != '' && $F('payer_account_number_id').strip() != '';
    if(micr_exists){
        var url = relative_url_root() + '/datacaptures/micrwise_payer_informations';
        var parameters = 'micr_information=' + $('aba_routing_number_id').value + ',' + $('payer_account_number_id').value +
        '&job_id=' + $F('job_id');
        var payerAjax = new Ajax.Request(url, {
            method: 'get',
            parameters: parameters,
            onComplete: function(micr_information){
                var payerInformations = eval("(" + micr_information.responseText + ")");
                if(payerInformations){
                    if(payerInformations.payer != null){
                        if (check_string == "check payer"){
                            alert("Payer Associated with this MICR data is: "+payerInformations.payer);
                        }
                        $("payer_popup").value = payerInformations.payer
                    }else
                    if (check_string == "set payer")
                        $("payer_popup").value = ""
                    if(payerInformations.payer_address_one != null)
                        $("payer_pay_address_one").value = payerInformations.payer_address_one
                    else
                    if (check_string == "set payer")
                        $("payer_pay_address_one").value = ""
                    if(payerInformations.payer_address_two != null)
                        $("payer_address_two").value = payerInformations.payer_address_two
                    else
                    if (check_string == "set payer")
                        $("payer_address_two").value = ""
                    if(payerInformations.payer_state != null)
                        $("payer_payer_state").value = payerInformations.payer_state
                    else
                    if (check_string == "set payer")
                        $("payer_payer_state").value = ""
                    if(payerInformations.payer_city != null)
                        $("payer_city_id").value = payerInformations.payer_city
                    else
                    if (check_string == "set payer")
                        $("payer_city_id").value = ""
                    if(payerInformations.payer_zip != null)
                        $("payer_zipcode_id").value = payerInformations.payer_zip
                    else
                    if (check_string == "set payer")
                        $("payer_zipcode_id").value = ""

                    $("payer_id").value = payerInformations.payer_id;
                    $("payer_status").value = payerInformations.payer_status;

                    if (payerInformations.payer_id == null) {
                        $("payer_id").value = null;
                    }
                    resetPayerAssociatedData();
                    disablePayerAddressForApprovedPayers();
                    setTwiceKeyingFields(payerInformations.reason_code_set_name_id);
                    if($F('payer_popup').strip() == '') {
                        $('payer_popup').readOnly = false;
                        $('payer_popup').style.backgroundColor = '#FFFFFF';
                    }
                    ctlObjectValue = ""
                    ctlObjectValue = $("payer_tin_id")
                    if (ctlObjectValue != null){
                        if(payerInformations.payer_tin != null)
                            $("payer_tin_id").value = payerInformations.payer_tin
                        else if (check_string == "set payer")
                            $("payer_tin_id").value = ""
                    }
                    if ($("fc_plan_type").value == "Payer specific only") {
                        if (payerInformations.plan_type != null) {
                            $("plan_type_id").value = payerInformations.plan_type;
                        }                        
                    }
                    if (payerInformations.plan_type == null ||
                        (payerInformations.plan_type != null && payerInformations.plan_type.strip() == '')) {
                        $("plan_type_id").value = "";
                    }

                    //this is to programmetically set the payer_type based on the payer selection done through type ahead
                    var payerTypeObject = document.form1.payer_type;
                    var getSelectedIndex = payerTypeObject.selectedIndex;
                    var payerType = payerTypeObject[getSelectedIndex].value;
                    var countOfOptionOfPayerType = payerTypeObject.length;
                    if(payerInformations.payer_type!= null) {
                        $('type_of_payer_created_by_admin').value = payerInformations.payer_type;
                        if (payerInformations.payer_type =="Commercial") {
                            // Iterating through the payer type dropdown box to find the index of Commercial option
                            for(i=0;i<countOfOptionOfPayerType;i++) {
                                if(payerTypeObject[i].value == "Commercial") {
                                    payerTypeObject[i].selected = true;
                                }
                            }
                        }
                        else {

                            // Iterating through the payer type dropdown box to find the index of -- option
                            for(i=0; i < countOfOptionOfPayerType; i++) {
                                if(payerTypeObject[i].value == "--") {
                                    payerTypeObject[i].selected = true;
                                }
                            }
                        }

                    }
                    else
                        $('type_of_payer_created_by_admin').value = '';

                }
            }
        });
    }
}

function providerInformations(){
    if($('provider_provider_npi_number') != null && !($F('provider_provider_npi_number').blank())) {
        var url =relative_url_root() + '/provider/provider_npi_informations';
        var parameters = 'provider_npi=' + $('provider_provider_npi_number').value;
        var providerAjax = new Ajax.Request(url, {
            method: 'get',
            parameters: parameters,
            onComplete: function(provider){
                var providerInformations = eval("(" + provider.responseText + ")");
                if(providerInformations != null) {
                    $("provider_provider_npi_number").value = providerInformations.provider_npi_number
                    $("provider_provider_last_name").value = providerInformations.provider_last_name
                    if (providerInformations.provider_last_name != "") {
                        $("provider_organisation_id").readOnly = true
                        $("provider_organisation_id").value = ""
                        $("prov_firstname_id").readOnly = false
                        $("provider_provider_last_name").readOnly = false
                        $("prov_suffix_id").readOnly = false
                        $("prov_initial_id").readOnly = false
                    }
                    $("prov_firstname_id").value = providerInformations.provider_first_name
                    if (providerInformations.provider_middle_initial != null) {
                        $("prov_initial_id").value = providerInformations.provider_middle_initial
                    }
                    if (providerInformations.provider_suffix != null) {
                        $("prov_suffix_id").value = providerInformations.provider_suffix
                    }
                    if (providerInformations.provider_tin_number != null) {
                        $("provider_tin_id").value = providerInformations.provider_tin_number
                    }
                    else
                    {
                        $("provider_tin_id").value = ""
                    }
                }
            }
        });
    }

}

function providerNameInformations(){
    var url =relative_url_root() + '/provider/provider_name_informations';
    var parameters = 'provider_last_name=' + $('provider_provider_last_name').value;
    var providerAjax = new Ajax.Request(url, {
        method: 'get',
        parameters: parameters,
        onComplete: function(provider){
            var providerInformations = eval("(" + provider.responseText + ")");
            $("provider_provider_npi_number").value = providerInformations.provider_npi_number
            $("provider_provider_last_name").value = providerInformations.provider_last_name
            $("prov_firstname_id").value = providerInformations.provider_first_name
            if (providerInformations.provider_middle_initial != null) {
                $("prov_initial_id").value = providerInformations.provider_middle_initial
            }
            if (providerInformations.provider_suffix != null) {
                $("prov_suffix_id").value = providerInformations.provider_suffix
            }
            if (providerInformations.provider_tin_number != null) {
                $("provider_tin_id").value = providerInformations.provider_tin_number
            }
            else
            {
                $("provider_tin_id").value = ""
            }
        }
    });
}

function enableOrganisation(){
    var checkBox = $("provider_check")
    if($('default_provider_configuration') != null && $F('default_provider_configuration') != 'true'){
        if (checkBox.checked) {
            $("provider_provider_last_name").readOnly = false
            $("prov_suffix_id").readOnly = false
            $("prov_firstname_id").readOnly = false
            $("prov_initial_id").readOnly = false
            $("provider_organisation_id").readOnly = true
            $("provider_organisation_id").value = ""
        }
        else {
            $("provider_provider_last_name").readOnly = true
            $("prov_suffix_id").readOnly = true
            $("prov_firstname_id").readOnly = true
            $("prov_initial_id").readOnly = true
            $("provider_organisation_id").readOnly = false
        }

    }
}

/*
     * Function to notify user to select appropriate payer type from commercial/--/patpay options if the user entered a new payer in payer typeahead field.
     * If the available options combination is either commercial/-- or patpay/--, then the selection will automatically change from -- to the other option.
     * Notification will not take place in this case.
     */
function notifyUserForPayerType(flag) {
    // The flag is provided so as to ensure that the alert will be displayed only when the dropdown box is selected after the validation prompt from payer state field.
    // This validation will not be executed if the user goes for the payer type selection first.
    var payerTypeObject = document.form1.payer_type;
    var getSelectedIndex = payerTypeObject.selectedIndex;
    if(payerTypeObject[getSelectedIndex] != null) {
        var payerType = payerTypeObject[getSelectedIndex].value;
        var countOfOptions = payerTypeObject.length;
        var payerTypeOfSavedPayer = $F('type_of_payer_created_by_admin');
        var payerId = $F('payer_id');
        var payer_from_check_or_micr = ''
        if($('payer_from_check_or_micr') != null)
            payer_from_check_or_micr = $F('payer_from_check_or_micr');
        else
            payer_from_check_or_micr = ''
        var result = true;
        if(flag) {
            isPromptFromPayerType = true;
        }

        if(isPromptFromPayerType) {
            if(payerId != "" && payerTypeOfSavedPayer != "" && payerTypeOfSavedPayer == payerId ){
                isPromptFromPayerType = false;
                result = true;
            }
            else{
                if(!isPayerFromTypeAhead && $("payer_popup").value != "" && payer_from_check_or_micr != 'true') {
                    if(payerType == "--") {
                        if(countOfOptions == 3 || countOfOptions == 1) {
                            alert("Select Payer Type");
                            payerTypeObject.focus();
                            result = false;
                            $("payer_id").value = null
                        } else if(countOfOptions == 2) {
                            for(i=0; i < countOfOptions; i++) {
                                if(payerTypeObject[i].value == "Commercial" || payerTypeObject[i].value == "PatPay") {
                                    payerTypeObject[i].selected = true;
                                    setTransactionType();
                                    isPromptFromPayerType = false;
                                    result = true;
                                }
                            }
                        } else {
                            alert("Select Payer Type");
                            payerTypeObject.focus();
                            result = false;
                            $("payer_id").value = null
                        }
                    } else {
                        isPromptFromPayerType = false;
                        result = true;
                    }
                }
            }
        }
        return result;
    }
}
function uploadDocument(){
    url = relative_url_root() +"/admin/pop_up/upload_document"
    window.open(url, "mywindow","height=700,width=600,resizable=1,scrollbars=yes, menubar=no,toolbar=no,footer=no");
}

function populateFileDetails(document_id,document_name){
    window.opener.document.getElementById("data_file_id").value  = document_id
    window.opener.document.getElementById("document_name").value  = document_name

    window.close();
}

function validateTwiceKeyingRecord() {
    var validation = true;
    var validationMessage = '';
    if($('client_id') != null && $F('client_id').strip() == ''){
        validation = false;
        validationMessage = "Please select a client";
    }
    if(validation) {
        if($('duration_number') != null && $F('duration_number').strip() == '') {
            validation = false;
            validationMessage = "Please select duration";
        }
        if(validation) {
            if($('example_1') != null && $('example_1').value.strip() == '') { // $('example_1').value should be used to obtain the field value
                validation = false;
                validationMessage = "Please select a field name";
            }
            if(validation) {
                if($('start_date') != null && $('end_date') != null ) {
                    var fromDate = $F('start_date');
                    var toDate = $F('end_date');
                    var objRegExp = /^\d{4}(\-)\d{1,2}\-\d{1,2}$/
                    if(!objRegExp.test(fromDate)) {
                        validation = false; //doesn't match pattern, bad date
                        validationMessage = "Wrong Date Format";
                    }
                    if(!objRegExp.test(toDate)) {
                        validation = false; //doesn't match pattern, bad date
                        validationMessage = "Wrong Date Format";
                    }
                    if(validation) {
                        var normalizedFromDate = DateFormatFromYMDToMDY(fromDate);
                        var normalizedToDate = DateFormatFromYMDToMDY(toDate);
                        if(normalizedFromDate != '' && normalizedToDate != '') {
                            validation = validateDateRange(normalizedFromDate, normalizedToDate);
                            if(!validation) {
                                validationMessage = "The Start Date should be less than End Date.\n\
             Please correct the date and try again.";
                            }
                        }
                    }
                }
            }
        }
    }
    if(!validation && validationMessage != '') {
        alert(validationMessage);
    }
    return validation;
}

function DateFormatFromYMDToMDY(date) {
    var normalizedDate = '';
    if(date != '') {
        var dateArray = date.split("-");
        var normalizedDateArray = [];
        normalizedDateArray.push(dateArray[1]);
        normalizedDateArray.push(dateArray[2]);
        normalizedDateArray.push(dateArray[0].slice(2));
        normalizedDate = normalizedDateArray.join('/')
    }
    return normalizedDate;
}

