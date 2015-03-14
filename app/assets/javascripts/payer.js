var clientSpecificPayerIndex = 0;
var paymentOrAllowanceIndex = 0;

function validateEobsPerImage() {
    var validation = true;
    var value = $F('payer_eobs_per_image');
    if(value != '') {
        if(((value.match(/^[0-9]+(\.[0-9]+)?$/)) == null) ||  parseFloat(value) == '0') {
            validation = false;
            alert('Please enter a positive number ');
            setTimeout(function() {
                $('payer_eobs_per_image').focus();
            }, 50);
        }
    }
    return validation;
}

function getFacilityForClient(url, client, index, name) {
    if(url!=""){
        url = "/" + url;
    }
    var client_name = client.value;
    var parameters = 'client_name=' + client_name +
    '&index=' + index +
    '&name=' + name;
    var new_url = url + "/admin/payer/get_facility_for_client";
    new Ajax.Request(new_url, {
        method: 'get',
        asynchronous: false,
        parameters: parameters
    });
}

function checkMicrIsPresentForClientSpecificPayerInfo(){
    var result = true;
    var facilityIds = $('facility_ids_for_client_specific_payer_details');
    if (facilityIds != null && facilityIds.value != ''){
        var payerAccountNumber = $F('micr_line_information_payer_account_number');
        var abaAccountNumber = $F('micr_line_information_aba_routing_number');
        if (payerAccountNumber == '' || abaAccountNumber == ''){
            result = false;
            alert("Client Specific Payer Name cannot be added without MICR!");
        }
    }
    return result;
}

function addFacilityPlanType(){
    var currentTime = jQuery.now();
    var planType = jQuery('#plan_type_code').val();
    var clientId = jQuery('select#plan_type_client option:selected').val();
    var facilityId = jQuery('select#plan_type_facility option:selected').val();
    var clientName = jQuery('select#plan_type_client option:selected').text();
    var facilityName = jQuery('select#plan_type_facility option:selected').text();

    if(facilityId == undefined){
        facilityId = ''
    }
    if(facilityId == '' || facilityId == undefined){
        facilityName = ''
    }

    var validation = checkPlanTypeValidation(planType, clientId, facilityId);

    if(validation){
        jQuery('#facility_plan_type tr:last').after("<tr class="+currentTime+"><td>"+planType+"</td>\n\
            <td>"+clientName+"</td><td>"+facilityName+"</td><td><input type='checkbox' id='delete_new_facility_plan_types' \n\
            onclick= 'removeNewFacilityPlanTypes("+currentTime+")'</td></tr>");
        jQuery('#facility_plan_types_list').append('<input type="hidden" name="facility_plan_type['+currentTime+'][plan_type]" class='+currentTime+' value='+planType+'>');
        jQuery('#facility_plan_types_list').append('<input type="hidden" name="facility_plan_type['+currentTime+'][client_id]" class='+currentTime+' value='+clientId+' plan_identifier='+clientId+'-'+facilityId+'>');
        jQuery('#facility_plan_types_list').append('<input type="hidden" name="facility_plan_type['+currentTime+'][facility_id]" class='+currentTime+' value='+facilityId+'>');
        jQuery('#plan_type_code').val('');
        jQuery("#plan_type_client").find('option').removeAttr("selected");
        jQuery("#plan_type_facility").find('option').removeAttr("selected");
        jQuery('.'+currentTime+'').css({
            'font-weight': 'bold'
        });
    }


}

function checkPlanTypeValidation(planType, clientId, facilityId){
    if(planType == '' || planType.length > 2 || planType.length < 2){
        alert('Please enter a 2 digit Plan Type');
        return false
    }
    if(/^[a-zA-Z0-9]*$/.test(planType) == false) {
        alert('Plan Type should be alphanumeric.');
        return false
    }
    if(clientId == ''){
        alert('Please select a Client');
        return false
    }

    var savedClientFacilityId = jQuery("input[id='saved_plan_type_details'][value='"+clientId+","+facilityId+"']").val();
    if(savedClientFacilityId != undefined){
        alert('Plan Type already added for this Client/Facility combination ');
        return false
    }

    var newClientFacilityId = jQuery("input[plan_identifier="+clientId+"-"+facilityId+"]").val();
    if(newClientFacilityId != undefined){
        alert('Plan Type already added for this Client/Facility combination ');
        return false
    }
    return true
}

function removeSavedFacilityPlanTypes(facility_plan_id){
    var fc_plan_ids = jQuery('#plan_ids_to_delete').val();
    jQuery('#plan_ids_to_delete').val(fc_plan_ids+','+facility_plan_id);
    jQuery('#facility_plan_type_'+facility_plan_id+'').remove();
}

function removeNewFacilityPlanTypes(timestamp){
    jQuery('.'+timestamp+'').remove();
}

function addClientSpecificPayerInformation() {
    $('add_client_specific_information').style.visibility = "hidden";
    var validation = (checkPresenceOfClientSpecificPayerDetails() &&
        validateUniqueClientAndFacility());
    if(validation) {
        addOnbaseNameRows();
        addOutputPayidRows();
        clearClientSpecificPayerDetails();
    }

    $('add_client_specific_information').style.visibility = "visible";
}

function addOnbaseNameRows() {
    var onbaseName = $F('fac_micr_onbase_name').strip();
    if(onbaseName != '') {
        var clientSpecificPayerIndex = parseInt($F('client_specific_payer_details_last_serial_num')) + 1;
        $('client_specific_payer_details_last_serial_num').value = clientSpecificPayerIndex;
        var tbody = $('client_specific_payer_details').getElementsByTagName("TBODY")[0];
        var row1 = document.createElement("TR");
        row1.setAttribute('valign','top');
        row1.setAttribute('class', 'client_specific_payer_details_row');
        row1.vAlign="top";
        row1.setAttribute('id', 'client_specific_payer_details_' + clientSpecificPayerIndex);
    
        var td1 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute('for',"label_onbase_name" + clientSpecificPayerIndex + "]");
        labelField.innerHTML = onbaseName;
        td1.appendChild(labelField);

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        hiddenField.setAttribute('id', 'onbaseName_' + clientSpecificPayerIndex)
        hiddenField.setAttribute('name', "facilities_micr_information[onbase_name" + clientSpecificPayerIndex + "]")
        hiddenField.setAttribute('value', onbaseName)
        hiddenField.setAttribute('readOnly', true)
        td1.appendChild(hiddenField);
        row1.appendChild(td1);

        var td2 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute('for',"label_output_payid" + clientSpecificPayerIndex + "]");
        labelField.innerHTML = '';
        td2.appendChild(labelField);
        row1.appendChild(td2);

        var td3 = document.createElement("TD");
        labelField = document.createElement("Label");
        var ddlClient = document.getElementById("client_of_onbase");
        var clientName = ddlClient.options[ddlClient.selectedIndex].text;
        labelField.setAttribute("for",'label_for_client'+clientSpecificPayerIndex);
        labelField.innerHTML = clientName;
        td3.appendChild(labelField);
        row1.appendChild(td3);

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        var clientId = $('client_of_onbase').value;
        hiddenField.setAttribute('id', 'facilities_micr_information_client_id_' + clientSpecificPayerIndex)
        hiddenField.setAttribute('name', "facilities_micr_information[client_id" + clientSpecificPayerIndex + "]")
        hiddenField.setAttribute('value', clientId)
        hiddenField.setAttribute('readOnly', true)
        td3.appendChild(hiddenField);
        row1.appendChild(td3);

        var td4 = document.createElement("TD");
        labelField = document.createElement("Label");
        var ddlFacility = document.getElementById("facility_of_onbase");
        var facilityName = ddlFacility.options[ddlFacility.selectedIndex].text;
        labelField.setAttribute("for",'label_for_facility'+clientSpecificPayerIndex);
        if(ddlFacility.value != '')
            labelField.innerHTML = facilityName;
        td4.appendChild(labelField);

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        var facilityId = $('facility_of_onbase').value;
        hiddenField.setAttribute('id', 'facilities_micr_information_facility_id_' + clientSpecificPayerIndex)
        hiddenField.setAttribute('name', "facilities_micr_information[facility_id" + clientSpecificPayerIndex + "]")
        hiddenField.setAttribute('value', facilityId)
        hiddenField.setAttribute('readOnly', true)
        td4.appendChild(hiddenField);
        row1.appendChild(td4);

        var clientAndFacilityId = clientId + ':' + facilityId;

        var td5 = document.createElement("TD");
        var buttonnode = document.createElement('input');
        buttonnode.setAttribute('type', 'checkbox');
        buttonnode.setAttribute('id', 'delete_client_specific_payer_details_' + clientSpecificPayerIndex);
        buttonnode.setAttribute('value', clientSpecificPayerIndex);
        buttonnode.setAttribute('title', "Delete");
        buttonnode.onclick = function(){
            removeAddedOnbaseNameRow(this.value, "client_specific_payer_details", clientAndFacilityId);
        }
        td5.appendChild(buttonnode);
        row1.appendChild(td5);
        tbody.appendChild(row1);

        if($('onbase_name_client_and_facility_ids') != null){
            var clientAndFacilityIds = $F('onbase_name_client_and_facility_ids');           
            $('onbase_name_client_and_facility_ids').value = concatenateIntegerWithString(clientAndFacilityIds, clientAndFacilityId);
        }
    
        //Adding index
        if($('serial_numbers_for_adding_onbase_name') != null){
            var serialNumbers = $F('serial_numbers_for_adding_onbase_name');
            $('serial_numbers_for_adding_onbase_name').value = concatenateIntegerWithString(serialNumbers, clientSpecificPayerIndex);
        }
    }

}

function addOutputPayidRows() {
    var outputPayid = $F('fac_payer_output_payid').strip();
    if(outputPayid != '') {
        var clientSpecificPayerIndex = parseInt($F('client_specific_payer_details_last_serial_num')) + 1;
        $('client_specific_payer_details_last_serial_num').value = clientSpecificPayerIndex;
        
        var tbody = $('client_specific_payer_details').getElementsByTagName("TBODY")[0];
        var row1 = document.createElement("TR");
        row1.setAttribute('valign','top');
        row1.setAttribute('class', 'client_specific_payer_details_row');
        row1.vAlign="top";
        row1.setAttribute('id', 'client_specific_payer_details_' + clientSpecificPayerIndex);

        var td1 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute('for',"label_onbase_name" + clientSpecificPayerIndex + "]");
        labelField.innerHTML = '';
        td1.appendChild(labelField);
        row1.appendChild(td1);

   
        var td2 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute('for',"label_output_payid" + clientSpecificPayerIndex + "]");
        labelField.innerHTML = outputPayid;
        td2.appendChild(labelField);

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        hiddenField.setAttribute('id', 'outputPayid_' + clientSpecificPayerIndex)
        hiddenField.setAttribute('name', "facilities_payers_information[output_payid" + clientSpecificPayerIndex + "]")
        hiddenField.setAttribute('value', outputPayid)
        hiddenField.setAttribute('readOnly', true)
        td2.appendChild(hiddenField);
        row1.appendChild(td2);

        var td3 = document.createElement("TD");
        labelField = document.createElement("Label");
        var ddlClient = document.getElementById("client_of_onbase");
        var clientName = ddlClient.options[ddlClient.selectedIndex].text;
        labelField.setAttribute("for",'label_for_client'+clientSpecificPayerIndex);
        labelField.innerHTML = clientName;
        td3.appendChild(labelField);
        row1.appendChild(td3);

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        var clientId = $('client_of_onbase').value;
        hiddenField.setAttribute('id', 'facilities_payers_information_client_id_' + clientSpecificPayerIndex)
        hiddenField.setAttribute('name', "facilities_payers_information[client_id" + clientSpecificPayerIndex + "]")
        hiddenField.setAttribute('value', clientId)
        hiddenField.setAttribute('readOnly', true)
        td3.appendChild(hiddenField);
        row1.appendChild(td3);

        var td4 = document.createElement("TD");
        labelField = document.createElement("Label");
        var ddlFacility = document.getElementById("facility_of_onbase");
        var facilityName = ddlFacility.options[ddlFacility.selectedIndex].text;
        labelField.setAttribute("for",'label_for_facility'+clientSpecificPayerIndex);
        if(ddlFacility.value != '')
            labelField.innerHTML = facilityName;
        td4.appendChild(labelField);

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        var facilityId = $('facility_of_onbase').value;
        hiddenField.setAttribute('id', 'facilities_payers_information_facility_id_' + clientSpecificPayerIndex)
        hiddenField.setAttribute('name', "facilities_payers_information[facility_id" + clientSpecificPayerIndex + "]")
        hiddenField.setAttribute('value', facilityId)
        hiddenField.setAttribute('readOnly', true)
        td4.appendChild(hiddenField);
        row1.appendChild(td4);
        
        var clientAndFacilityId = clientId + ':' + facilityId;

        var td5 = document.createElement("TD");
        var buttonnode = document.createElement('input');
        buttonnode.setAttribute('type', 'checkbox');
        buttonnode.setAttribute('id', 'delete_client_specific_payer_details_' + clientSpecificPayerIndex);
        buttonnode.setAttribute('value', clientSpecificPayerIndex);
        buttonnode.setAttribute('title', "Delete");
        buttonnode.onclick = function(){
            removeAddedOutputPayidRow(this.value, "client_specific_payer_details", clientAndFacilityId);
        }
        td5.appendChild(buttonnode);
        row1.appendChild(td5);
        tbody.appendChild(row1);

        if($('output_payid_client_and_facility_ids') != null){
            var clientAndFacilityIds = $F('output_payid_client_and_facility_ids');
            $('output_payid_client_and_facility_ids').value = concatenateIntegerWithString(clientAndFacilityIds, clientAndFacilityId);
        }

        //Adding index
        if($('serial_numbers_for_adding_output_payid') != null){
            var serialNumbers = $F('serial_numbers_for_adding_output_payid');
            $('serial_numbers_for_adding_output_payid').value = concatenateIntegerWithString(serialNumbers, clientSpecificPayerIndex);
        }
    }
}

function clearClientSpecificPayerDetails(){
    $('fac_micr_onbase_name').value = "";
    $('fac_payer_output_payid').value = "";
    $('client_of_onbase').value = '';
    $('facility_of_onbase').value = '';
    $('fac_micr_onbase_name').focus();
}

function removeAddedOnbaseNameRow(index, tableId, clientAndFacilityId){
    var tableObject = $(tableId);
    if(index != null && index != '') {
        tableObject.deleteRow($('client_specific_payer_details_' + index).rowIndex);
    }
    removeClientAndFacilityId('onbase_name_client_and_facility_ids', clientAndFacilityId);

    //removing index
    if($('serial_numbers_for_adding_onbase_name') != null){
        var serialNumbers = $F('serial_numbers_for_adding_onbase_name');
        $('serial_numbers_for_adding_onbase_name').value = removeIntegerFromString(serialNumbers, index);
    }
}

function removeAddedOutputPayidRow(index, tableId, clientAndFacilityId){
    var tableObject = $(tableId);
    if(index != null && index != '') {
        tableObject.deleteRow($('client_specific_payer_details_' + index).rowIndex);
    }
    removeClientAndFacilityId('output_payid_client_and_facility_ids', clientAndFacilityId);

    //removing index
    if($('serial_numbers_for_adding_output_payid') != null){
        var serialNumbers = $F('serial_numbers_for_adding_output_payid');
        $('serial_numbers_for_adding_output_payid').value = removeIntegerFromString(serialNumbers, index);
    }
}

function validateUniqueClientAndFacility() {
    var resultOfValidation = true;
    if($F('fac_micr_onbase_name') != '') {
        resultOfValidation = uniqueClientAndFacility('onbase_name_client_and_facility_ids');
    }
    if(!resultOfValidation) {
        objName = 'Onbase Name';
    }
    else if($F('fac_payer_output_payid') != '') {
        resultOfValidation = uniqueClientAndFacility('output_payid_client_and_facility_ids');
        var objName = 'output ID';
        
    }
    if(!resultOfValidation) {
        alert('The client / facility level is already existing for ' + objName);
    }
    return resultOfValidation;
}

function uniqueClientAndFacility(clientAndFacilityIds) {
    var resultOfValidation = true;
    var facilityId = $F('facility_of_onbase').strip();
    var clientId = $F('client_of_onbase').strip();

    if($(clientAndFacilityIds) && $F(clientAndFacilityIds) != '') {
        clientAndFacilityIds = $F(clientAndFacilityIds).strip().split(',');
        var clientAndFacilityIdsLength = clientAndFacilityIds.length;
        var clientAndFacilityId = [];
        var existingClientId, existingFacilityId;
        if(clientAndFacilityIdsLength > 0) {
            for(var i = 0; i < clientAndFacilityIdsLength; i++) {
                if(clientAndFacilityIds[i] != '') {
                    clientAndFacilityId = clientAndFacilityIds[i].strip().split(':');
                    existingClientId = clientAndFacilityId[0];
                    existingFacilityId = clientAndFacilityId[1];
                    if(existingClientId == clientId && existingFacilityId == facilityId) {
                        resultOfValidation = false;
                        break;
                    }
                }
            }
        }
    }
    return resultOfValidation;
}

function addPaymentOrAllowanceCode(){
    $('add_payment_or_allowance_code').style.visibility = "hidden";
    var validation = (checkPresenceOfPaymentOrAllowanceCodes() &&
        checkFacility('facility_ids_for_payment_or_allowance_codes', 'facility_of_code', 'Payment / Allowance Code'));
    if(validation){
        paymentOrAllowanceIndex = parseInt($F('payment_or_allowance_details_last_serial_num')) + 1;
        $('payment_or_allowance_details_last_serial_num').value = paymentOrAllowanceIndex;

        var tbody = $('payment_or_allowance_code_details').getElementsByTagName("TBODY")[0];
        var row1 = document.createElement("TR");
        row1.setAttribute('valign','top');
        row1.setAttribute('class', 'payment_or_allowance_code_row');
        row1.vAlign="top";
        row1.setAttribute('id', 'payment_or_allowance_code_row_' + paymentOrAllowanceIndex);

        var inPatientPaymentCode = $F('fac_payer_in_patient_payment_code')
        var td1 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute("for",'label_in_patient_payment_code_' + paymentOrAllowanceIndex +']');
        labelField.innerHTML = inPatientPaymentCode;
        td1.appendChild(labelField);

        textField = document.createElement('INPUT')
        textField.type = 'hidden' 
        textField.className = "code"
        textField.setAttribute('value', inPatientPaymentCode)
        textField.setAttribute('id', "in_patient_payment_code_" + paymentOrAllowanceIndex)
        textField.setAttribute('name', "facilities_payers_information[in_patient_payment_code" + paymentOrAllowanceIndex + "]")
        textField.setAttribute('readOnly', true)
        td1.appendChild(textField)
        row1.appendChild(td1);

        var outPatientPaymentCode = $F('fac_payer_out_patient_payment_code');
        var td2 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute("for",'label_out_patient_payment_code_' + paymentOrAllowanceIndex + ']');
        labelField.innerHTML = outPatientPaymentCode;
        td2.appendChild(labelField);
        
        textField = document.createElement('INPUT')
        textField.type = 'hidden'
        textField.className = "code"
        textField.setAttribute('value', outPatientPaymentCode)
        textField.setAttribute('id', "out_patient_payment_code_" + paymentOrAllowanceIndex)
        textField.setAttribute('name', "facilities_payers_information[out_patient_payment_code" + paymentOrAllowanceIndex + "]")
        textField.setAttribute('readOnly', true)
        td2.appendChild(textField)
        row1.appendChild(td2);

        var inPatientAllowanceCode = $F('fac_payer_in_patient_allowance_code');
        var td3 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute("for",'label_in_patient_allowance_code_' + paymentOrAllowanceIndex + ']');
        labelField.innerHTML = inPatientAllowanceCode;
        td3.appendChild(labelField);

        textField = document.createElement('INPUT')
        textField.type = 'hidden'
        textField.className = "code"
        textField.setAttribute('value', inPatientAllowanceCode)
        textField.setAttribute('id', "in_patient_allowance_code_" + paymentOrAllowanceIndex)
        textField.setAttribute('name', "facilities_payers_information[in_patient_allowance_code" + paymentOrAllowanceIndex + "]")
        textField.setAttribute('readOnly', true)
        td3.appendChild(textField)
        row1.appendChild(td3);

        var outPatientAllowanceCode = $F('fac_payer_out_patient_allowance_code');
        var td4 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute("for",'label_out_patient_allowance_code_' + paymentOrAllowanceIndex + ']');
        labelField.innerHTML = outPatientAllowanceCode;
        td4.appendChild(labelField);

        textField = document.createElement('INPUT')
        textField.type = 'hidden'
        textField.className = "code"
        textField.setAttribute('value', outPatientAllowanceCode)
        textField.setAttribute('id', "out_patient_allowance_code_" + paymentOrAllowanceIndex)
        textField.setAttribute('name', "facilities_payers_information[out_patient_allowance_code" + paymentOrAllowanceIndex + "]")
        textField.setAttribute('readOnly', true)
        td4.appendChild(textField)
        row1.appendChild(td4);

        var capitationCode = $F('fac_payer_capitation_code');
        var td5 = document.createElement("TD");
        labelField = document.createElement("Label");
        labelField.setAttribute("for",'label_capitation_code_' + paymentOrAllowanceIndex + ']');
        labelField.innerHTML = capitationCode;
        td5.appendChild(labelField);

        textField = document.createElement('INPUT')
        textField.type = 'hidden'
        textField.className = "code"
        textField.setAttribute('value', capitationCode)
        textField.setAttribute('id', "capitation_code_" + paymentOrAllowanceIndex)
        textField.setAttribute('name', "facilities_payers_information[capitation_code" + paymentOrAllowanceIndex + "]")
        textField.setAttribute('readOnly', true)
        td5.appendChild(textField)
        row1.appendChild(td5);
        
        var td6 = document.createElement("TD");
        labelField = document.createElement("Label");
        var ddlClient = document.getElementById("client_of_code");
        var clientName = ddlClient.options[ddlClient.selectedIndex].text;
        labelField.setAttribute("for",'label_for_client'+paymentOrAllowanceIndex);
        labelField.innerHTML = clientName;
        td6.appendChild(labelField);        

        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        var clientId = $('client_of_code').value;
        hiddenField.setAttribute('id', 'facilities_payers_information_client_id_' + paymentOrAllowanceIndex)
        hiddenField.setAttribute('name', "facilities_payers_information[client_id" + paymentOrAllowanceIndex + "]")
        hiddenField.setAttribute('value', clientId)
        hiddenField.setAttribute('readOnly', true)
        td6.appendChild(hiddenField);
        row1.appendChild(td6);
        
        var td7 = document.createElement("TD");
        labelField = document.createElement("Label");
        var ddlFacility = document.getElementById("facility_of_code");
        var facilityName = ddlFacility.options[ddlFacility.selectedIndex].text;
        labelField.setAttribute("for",'label_for_facility'+paymentOrAllowanceIndex);
        labelField.innerHTML = facilityName;
        td7.appendChild(labelField);
        
        hiddenField = document.createElement('INPUT')
        hiddenField.type = 'hidden'
        var facilityId = $('facility_of_code').value;
        hiddenField.setAttribute('id', 'facilities_payers_information_facility_id_' + paymentOrAllowanceIndex)
        hiddenField.setAttribute('name', "facilities_payers_information[facility_id" + paymentOrAllowanceIndex + "]")
        hiddenField.setAttribute('value', facilityId)
        hiddenField.setAttribute('readOnly', true)
        td7.appendChild(hiddenField);
        row1.appendChild(td7);
        
        var td8 = document.createElement("TD");
        var buttonnode = document.createElement('input');
        buttonnode.setAttribute('type', 'checkbox');
        buttonnode.setAttribute('id', 'delete_payment_or_allowance_code_details_' + paymentOrAllowanceIndex);
        buttonnode.setAttribute('value', paymentOrAllowanceIndex);
        buttonnode.setAttribute('title', "Delete");
        buttonnode.onclick = function(){
            removeAddedPaymentOrAllowanceCode(this.value, "payment_or_allowance_code_details", facilityId);
        }
        td8.appendChild(buttonnode);
        row1.appendChild(td8);
        tbody.appendChild(row1);

        //Adding facility_id
        if($('facility_ids_for_payment_or_allowance_codes') != null){
            var facilityIdsForPaymentOrAllowanceCodes = $F('facility_ids_for_payment_or_allowance_codes');
            $('facility_ids_for_payment_or_allowance_codes').value = concatenateIntegerWithString(facilityIdsForPaymentOrAllowanceCodes, facilityId);
        }

        //Adding index
        if($('serial_numbers_for_adding_payment_or_allowance_codes') != null){
            var serialNumbers = $F('serial_numbers_for_adding_payment_or_allowance_codes');
            $('serial_numbers_for_adding_payment_or_allowance_codes').value = concatenateIntegerWithString(serialNumbers, paymentOrAllowanceIndex);
        }
        clearPaymentOrAllowanceCodeDetails();
    }

    $('add_payment_or_allowance_code').style.visibility = "visible";
}

function clearPaymentOrAllowanceCodeDetails(){
    $('fac_payer_in_patient_payment_code').value = "";
    $('fac_payer_out_patient_payment_code').value = "";
    $('fac_payer_in_patient_allowance_code').value = "";
    $('fac_payer_out_patient_allowance_code').value = "";
    $('fac_payer_capitation_code').value = "";
    $('client_of_code').value = '';
    $('facility_of_code').value = '';
    $('fac_payer_in_patient_payment_code').focus();
}

function removeAddedPaymentOrAllowanceCode(index, tableId, facilityId){
    var tableObject = $(tableId);
    if(index != null && index != '') {
        tableObject.deleteRow($('payment_or_allowance_code_row_' + index).rowIndex);
    }

    //Removing facility_id
    if($('facility_ids_for_payment_or_allowance_codes') != null){
        var facilityIdsForPaymentOrAllowanceCodes = $F('facility_ids_for_payment_or_allowance_codes');
        $('facility_ids_for_payment_or_allowance_codes').value = removeIntegerFromString(facilityIdsForPaymentOrAllowanceCodes, facilityId);
    }

    //removing index
    if($('serial_numbers_for_adding_payment_or_allowance_codes') != null){
        var serialNumbers = $F('serial_numbers_for_adding_payment_or_allowance_codes');
        $('serial_numbers_for_adding_payment_or_allowance_codes').value = removeIntegerFromString(serialNumbers, index);
    }
}

function removeSavedOnbaseNameRow(facilityMicrId, clientId, facilityId, index){
    //delete the row
    var tableObject = $('client_specific_payer_details');
    if(index != null && index != '') {
        tableObject.deleteRow($('saved_facility_micr_info_' + index).rowIndex);
    }
    //Adding facility_micr_information_id for deleting the record
    if($('fac_micr_info_ids_to_delete') != null && facilityMicrId != "null"){
        var facilityMicrInfoIdsToBeDeleted = $F('fac_micr_info_ids_to_delete');
        $('fac_micr_info_ids_to_delete').value = concatenateIntegerWithString(facilityMicrInfoIdsToBeDeleted, facilityMicrId);
    }
    
    var clientAndFacilityId = clientId + ':' + facilityId;
    removeClientAndFacilityId('onbase_name_client_and_facility_ids', clientAndFacilityId);

}

function removeSavedOutputPayidRow(facilityPayerId, clientId, facilityId, index){
    //delete the row
    var tableObject = $('client_specific_payer_details');
    if(index != null && index != '') {
        tableObject.deleteRow($('saved_facility_micr_info_' + index).rowIndex);
    }

    //Adding facility_payer_information_id for deleting the record
    if($('fac_payer_info_ids_to_delete_for_output_payid') != null && facilityPayerId != "null"){
        var facilityPayerInfoIdsToBeDeleted = $F('fac_payer_info_ids_to_delete_for_output_payid');
        $('fac_payer_info_ids_to_delete_for_output_payid').value = concatenateIntegerWithString(facilityPayerInfoIdsToBeDeleted, facilityPayerId);
    }

    var clientAndFacilityId = clientId + ':' + facilityId;
    removeClientAndFacilityId('output_payid_client_and_facility_ids', clientAndFacilityId);

}

function removeSavedPaymentOrAllowanceCode(id, facilityId, index){
    //delete the row
    var tableObject = $('payment_or_allowance_code_details');
    if(index != null && index != '') {
        tableObject.deleteRow($('saved_facility_payer_info_' + index).rowIndex);
    }
    //Adding facility_micr_information_id for deleting the record
    if($('fac_payer_info_ids_to_delete') != null){
        var facilityPayerInfoIdsToBeDeleted = $F('fac_payer_info_ids_to_delete');
        $('fac_payer_info_ids_to_delete').value = concatenateIntegerWithString(facilityPayerInfoIdsToBeDeleted, id);
    }

    //Removing facility_id
    if($('facility_ids_for_payment_or_allowance_codes') != null){
        var facilityIdsForPaymentOrAllowanceCodes = $F('facility_ids_for_payment_or_allowance_codes');
        $('facility_ids_for_payment_or_allowance_codes').value = removeIntegerFromString(facilityIdsForPaymentOrAllowanceCodes, facilityId);
    }
}

function concatenateIntegerWithString(string, number){
    if(string == '')
        string = number;
    else
        string = string + ',' + number;
    return string;
}

function removeIntegerFromString(string, number){
    var data = ''
    if(string != ''){
        var collectionOfNumbers;
        if(string.match(/,/) == null)
            collectionOfNumbers = [string];
        else
            collectionOfNumbers = string.split(",");
        collectionOfNumbers = removeByValue(collectionOfNumbers, number);
        data = collectionOfNumbers.toString();
    }
    return data
}

function payerNameSearch(payer_id){
    var parser = window.location.href;
    var new_val = parser.indexOf("admin/payer/new") != -1
    
    url = relative_url_root() +"/admin/payer/payer_name_search"+"?new_or_id="+new_val+'&payer_id=' + payer_id

    window.open(url, "mywindow","height=700,width=700,resizable=1,scrollbars=yes, menubar=no,toolbar=no,footer=no");
}

function validatePayerName (){
    var result = true;
    search_value = $F('search_string');
    if(search_value == null || search_value.length < 5){
        result = false;
        alert("Please enter atlest 5 characters to search")
    }
    return result;
}

function autoPopulateRCSetName(){
    payer_type = $F('payer_type')
    if(payer_type == "Insurance"){
        $('rc_set_name').value = $F('payer_payid').toUpperCase();
    }
    else if(payer_type == "Patpay"){
        if ($('payers_id').value != ""){
            $('rc_set_name').value = "DEFAULT_"+$F('payers_id');
        }
        else {
            $('rc_set_name').value = "";
        }
    }
}
function clearPayIdOnChangeOfPayerType(){
    $('payer_payid').value = "";
    autoPopulateRCSetName()
}

function closePayerNamePopup(){
    window.close();
}

function checkPresenceOfClientSpecificPayerDetails(){
    var abaRoutingNumber = $F('micr_line_information_aba_routing_number');
    var payerAccountNumber = $F('micr_line_information_payer_account_number');
    var onbaseName = $F('fac_micr_onbase_name');
    var outputPayid = $F('fac_payer_output_payid');
    var validation = true;

    if(onbaseName == '' && outputPayid == ''){
        alert("Please Enter Client Specific Payer Name / ID");
        validation = false;
    }
    else if($('client_of_onbase') == null || $F('client_of_onbase') == ''){
        alert("Please Select Client/Facility values");
        validation = false;
    }
    else{
        if(onbaseName != ''){
            if(abaRoutingNumber != "" && payerAccountNumber != ""){
                validation = true;
            }
            else{
                alert("Client Specific Payer Name cannot be added without MICR");
                validation = false;
            }
        }
        
    }
    return validation
}

function checkPresenceOfPaymentOrAllowanceCodes(){
    var inPatientPaymentCode = $F('fac_payer_in_patient_payment_code');
    var outPatientPaymentCode = $F('fac_payer_out_patient_payment_code');
    var inPatientAllowanceCode = $F('fac_payer_in_patient_allowance_code');
    var outPatientAllowanceCode = $F('fac_payer_out_patient_allowance_code');
    var capitationCode = $F('fac_payer_capitation_code');
    var validation = true;
    
    if(inPatientPaymentCode == '' && outPatientPaymentCode == '' &&
        inPatientAllowanceCode == '' && outPatientAllowanceCode == '' && capitationCode == ''){
        alert("Please Enter Payment / Allowance Code");
        validation = false;
    }
    else{
        if($('facility_of_code') == null || $F('facility_of_code') == ''){
            alert("Please Select Client/Facility values");
            validation = false;
        }
    }
    return validation
}

function checkFacility(idOfFacilityList, idOfNewFacilty, label) {
    var facility = $(idOfNewFacilty);
    var facilityName = facility.options[facility.selectedIndex].text;
    var facilityId = facility.value;
    var facilistyIdList = $F(idOfFacilityList);
    var result = true;
    
    if(facilistyIdList != ''){
        if(facilistyIdList.match(/,/) == null)
            facilistyIdList = [facilistyIdList];
        else
            facilistyIdList = facilistyIdList.split(",");

        for(var i=0; i<facilistyIdList.length; i++) {
            if(facilistyIdList[i] == parseInt(facilityId, 10)) {
                alert("Not Allowed more than one " + label + " for " + facilityName);
                result = false;
                break;
            }
        }
    }
    return result;
}

function validatePresenceOfMicr(){
    var validation = true;
    var micr = $('micr_id');
    if(micr != null && micr.value != ''){
        var abaRoutingNumber = $F('micr_line_information_aba_routing_number');
        var payerAccountNumber = $F('micr_line_information_payer_account_number');
        if(abaRoutingNumber != "" && payerAccountNumber != ""){
            validation = true;
        }
        else{
            alert('ABA Routing # and/or Payer Acc # can not be blank');
            validation = false;
        }
    }
    return validation;
}

function mustPassValidationsForPayer(BlankOppayidRecords, 
        NumberOfBlankOppayidRecords, PayerSpecificRecords, 
        NumberOfPayerSpecificRecords, clientidsWithOutputPayidMandatory,
        NumberOfClientidsWithOutputPayidMandatory, payer_type){

    var idsOfPayerAddress = "payer_payid,payer_payer,payer_pay_address_one,payer_payer_city,payer_payer_state,payer_payer_zip,payer_eobs_per_image";
    var validation = (validatePayerDetails(idsOfPayerAddress) &&
        validatePresenceOfMicr() && validateEobsPerImage() &&
        isAbaValid('micr_line_information_aba_routing_number', '') &&
        isPayerAccNumValid('micr_line_information_payer_account_number', '') &&
        checkFacilityCriteria('facility_ids_for_client_specific_payer_details', "Client Specific Payer Name / ID") &&
        checkFacilityCriteria('facility_ids_for_payment_or_allowance_codes', "Payment / Allowance Codes") &&
        validateBlankOutputPayidForPayer(PayerSpecificRecords, NumberOfPayerSpecificRecords, clientidsWithOutputPayidMandatory, NumberOfClientidsWithOutputPayidMandatory, payer_type) &&
        validateBlankOutputPayidForClient(BlankOppayidRecords, NumberOfBlankOppayidRecords, NumberOfClientidsWithOutputPayidMandatory));
    if(validation){
        var agree = confirm("Are you sure ?");
        if (agree == true)
            return true;
        else
            return false;
    }
    else
        return false;
}

function validateBlankOutputPayidForPayer(PayerSpecificRecords, 
        NumberOfPayerSpecificRecords, clientidsWithOutputPayidMandatory,
        NumberOfClientidsWithOutputPayidMandatory, payer_type) {
    var validation = true;
    if(NumberOfClientidsWithOutputPayidMandatory > 0){
    PayerSpecificRecords = PayerSpecificRecords.split(',');
    var listOfPayerSpecificRecords = sanitizeArray(PayerSpecificRecords);
    deletedOutputPayids = $('fac_payer_info_ids_to_delete_for_output_payid').value
    deletedOutputPayids = deletedOutputPayids.split(',');
    var listOfdeletedOutputPayids = sanitizeArray(deletedOutputPayids);
    listOfdeletedOutputPayidLength = listOfdeletedOutputPayids.length
    if(listOfdeletedOutputPayidLength > 0){
        for(var i = 0; i < listOfdeletedOutputPayidLength; i++) {
            valueToBeChecked = listOfdeletedOutputPayids[i];
            indexOfValueToBeChecked = listOfPayerSpecificRecords.indexOf(valueToBeChecked);
            if(indexOfValueToBeChecked > -1)
                NumberOfPayerSpecificRecords = NumberOfPayerSpecificRecords - 1
        }
    }
    

    clientAndFacilityIdString = $('output_payid_client_and_facility_ids').value
    if(clientAndFacilityIdString != ""){
        clientAndFacilityIdStringSplitted = clientAndFacilityIdString.split(',');
        var clientAndFacilityIdStringSplittedArray = sanitizeArray(clientAndFacilityIdStringSplitted);
        if(clientAndFacilityIdStringSplittedArray.length > 0){
            for(var i = 0; i < clientAndFacilityIdStringSplittedArray.length; i++) {
                value = clientAndFacilityIdStringSplittedArray[i];
                indexOfColon = value.indexOf(':');
                addedFacilityId = value.substring(parseInt(indexOfColon) + 1, value.length)
                addedClientId = value.substring(0,indexOfColon);
            
                if((addedClientId.toString() == clientidsWithOutputPayidMandatory.toString()) &&
                      (addedFacilityId == ""))
                    NumberOfPayerSpecificRecords = parseInt(NumberOfPayerSpecificRecords) + 1;
            }
        }
    }

    if(NumberOfPayerSpecificRecords == 0 && payer_type != 'PatPay'){
        alert("Client Specific Payer id is mandatory");
        validation = false;
    }
    }
    return validation;
}

function validateBlankOutputPayidForClient(BlankOppayidRecords, NumberOfBlankOppayidRecords,
                        NumberOfClientidsWithOutputPayidMandatory){
    var validation = true;
    if(NumberOfClientidsWithOutputPayidMandatory > 0){
    BlankOppayidRecords = BlankOppayidRecords.split(',');
    var listOfBlankOppayidRecords = sanitizeArray(BlankOppayidRecords);
        
    deletedOutputPayids = $('fac_payer_info_ids_to_delete_for_output_payid').value
    deletedOutputPayids = deletedOutputPayids.split(',');
    var listOfdeletedOutputPayids = sanitizeArray(deletedOutputPayids);
    
    for(var i = 0; i < listOfdeletedOutputPayids.length; i++) {
        valueToBeRemoved = listOfdeletedOutputPayids[i];
        indexOfValueToBeRemoved = listOfBlankOppayidRecords.indexOf(valueToBeRemoved);
        if(indexOfValueToBeRemoved > -1)
            finalListOfBlankOppayidRecords = listOfBlankOppayidRecords.splice(indexOfValueToBeRemoved, 1);
        NumberOfBlankOppayidRecords = listOfBlankOppayidRecords.length
    }
    if(NumberOfBlankOppayidRecords > 0){
        alert("Client Specific Payer id is mandatory");
        validation = false;
    }
    }
    return validation;
}

//Checking there should be only one Client Specific Payer Details and Payment
//or Allowance record for a given facility.
function checkFacilityCriteria(facilityIds, label){
    var validation = true;
    if($(facilityIds) != null){
        var listOffacilityIds = $F(facilityIds);
        if(listOffacilityIds != ""){
            listOffacilityIds = listOffacilityIds.split(',');
            var listOfUniquefacilityIds = sanitizeArray(listOffacilityIds);
            if(listOffacilityIds.length != listOfUniquefacilityIds.length){
                alert(label + ": Only one record per facility");
                validation = false;
            }
        }
    }
    return validation;
}

function removeClientAndFacilityId(existingIdsField, toRemove){
    if($(existingIdsField) && $F(existingIdsField) != '' && toRemove != ''){
        var existingIds = $F(existingIdsField).split(',');
        existingIds = existingIds.without(toRemove);
        $(existingIdsField).value = existingIds;
    }
}


function mapWithThisPayer(old_payer_id){
    var agree = confirm("Do you Want to Map with this payer?");
    var  payer_id = $F('payer_id')
    var par = "map_payer/"+payer_id+'?old_payer_id=' +old_payer_id
    if (agree == true){
        self.close();
        window.opener.location.href = par
    }
    return agree
}


function validateFootnote(current_foot_note_indicator){
    
    var return_val = true
    var approved_foot_note_indicator = window.opener.document.getElementById("payer_footnote_indicator").value
    if(approved_foot_note_indicator != current_foot_note_indicator){
        alert("Please select a Payer having same Foot-note Indicator")
        return_val = false
    }
    return return_val
}

function useThisPayId(approved_payer_id,approved_reasoncode_setname){
    var agree = confirm("Do you Want Use this payer's payid and Set name?");
    if(agree == true){
        window.opener.document.getElementById("payer_payid").value = approved_payer_id
        window.opener.document.getElementById("rc_set_name").value = approved_reasoncode_setname
        self.close();
    }
    return agree
}