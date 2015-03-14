// when we click on check box,named Payer, in Balancing Record Tab, the fields
// Patient First Name and Patient Last Name will be blank.
function clearPatientNames(isPayerThePatientId, rowId){
    if($(isPayerThePatientId).checked == true){
        if(rowId != '' && rowId != null) {
            rowId = '_' + rowId;
        }
        else
            rowId = '';
        $('balancing_record_first_name' + rowId).value = "";
        $('balancing_record_last_name' + rowId).value = "";
    }
}

function validateBalancingRecord() {
    var result = true;
    var invalidFields = [];
    var messages = [];
    var payer_name_or_patient_name_must_be_present = ( $('balancing_record_is_payer_the_patient').checked ||
        ( $F('balancing_record_first_name').strip() != "" && $F('balancing_record_last_name').strip() != "" ) )
    var source_of_adjustment_must_be_present = ($('balancing_record_source_of_adjustment_check').checked ||
        $('balancing_record_source_of_adjustment_balance').checked)
    var is_claim_level_eob_must_be_present = ($('balancing_record_is_claim_level_claim').checked ||
        $('balancing_record_is_claim_level_standard').checked)

    if($F('balancing_record_category').strip() == "" || ($F('balancing_record_category').match(/^[a-zA-Z0-9\s]+$/) == null)) {
        invalidFields.push('balancing_record_category');
        messages.push('valid Balancing Record Type');
    }
    if(!payer_name_or_patient_name_must_be_present) {
        invalidFields.push('balancing_record_first_name');
        messages.push('either Patient first name and last name OR choose Payer');
    }
    if(!source_of_adjustment_must_be_present) {
        invalidFields.push('balancing_record_source_of_adjustment_check');
        messages.push('choose Charge/Payment');
    }
    if($F('balancing_record_account_number').strip() == "") {
        invalidFields.push('balancing_record_account_number');
        messages.push('Account Number');
    }
    if(!is_claim_level_eob_must_be_present) {
        invalidFields.push('balancing_record_is_claim_level_claim');
        messages.push('choose EOB Type');
    }
    if(invalidFields.length > 0) {
        result = false;
        setTimeout(function() {
            document.getElementById(invalidFields[0]).focus();
        }, 20);
        var alert_message = "Please enter " + messages.join(', ');
        alert(alert_message);
    }
    result = result && validateUniquenessOfCategory($F('balancing_record_category').strip());
    result = result && validatePatientNameField('balancing_record_first_name', $('details_patient_name_format_validation').checked);
    result = result && validatePatientNameField('balancing_record_last_name', $('details_patient_name_format_validation').checked)   
    result = result && validateBalanceRecordAccountNumber('balancing_record_account_number');

    return result;
}

function validateUniquenessOfCategory(categoryToAdd) {
    var result = true;
    var values = [];
    var allFields = [];
    var invalidFields = [];
    if(categoryToAdd != '' && categoryToAdd != null) {
        values.push(categoryToAdd.toUpperCase());
    }
    $$(".category").each(
        function(item) {
            values.push(item.value.strip().toUpperCase());
            allFields.push(item.id);
            if(item.value.match(/^[a-zA-Z0-9\s]+$/) == null) {
                invalidFields.push(item.id);
            }
        });
    if(allFields.length > 0) {
        setHighlight(allFields, "blank");
    }
    var original_length = values.length
    var normalized_length = values.uniq().length;
    var isInvalid = (invalidFields.length > 0);
    if(isInvalid) {
        setHighlight(invalidFields, "uncertain");
    }
    var notUnique = (original_length != 0 && original_length != normalized_length);
    if (notUnique || isInvalid) {
        result = false;
        alert('Please provide unique and valid balance record types.')
    }
    return result;
}

function addBalancingRecord() {
    var resultOfValidation = validateBalancingRecord();
    if(resultOfValidation) {
        var rowId = parseInt($F('balancing_record_last_serial_num')) + 1;
        $('balancing_record_last_serial_num').value = rowId;
        var tbody = $('balancing_record_table_id').getElementsByTagName("TBODY")[0];
        var row = document.createElement("TR");
        row.setAttribute('id', 'balancing_record_row_' + rowId);
        row.setAttribute('valign', 'top');
        row.vAlign = "top";

        // category
        var td = document.createElement("TD");
        var inputType = document.createElement('INPUT');
        inputType.type = 'text';
        var value = $F('balancing_record_category').strip().toUpperCase();
        var id = 'balancing_record_category_' + rowId;
        inputType.setAttribute('value', value);
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[category_" + rowId + "]");
        inputType.className = "category nonblank";
        inputType.setAttribute('readOnly', true);
        td.appendChild(inputType);
        row.appendChild(td);

        // first_name
        td = document.createElement("TD");
        inputType = document.createElement('INPUT');
        inputType.type = 'text';
        value = $F('balancing_record_first_name').strip().toUpperCase();
        id = 'balancing_record_first_name_' + rowId;
        inputType.setAttribute('value', value);
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[first_name_" + rowId + "]");
        inputType.className = "patient_name";
        inputType.setAttribute('readOnly', true);
        td.appendChild(inputType);
        row.appendChild(td);

        // last_name
        td = document.createElement("TD");
        inputType = document.createElement('INPUT');
        inputType.type = 'text';
        value = $F('balancing_record_last_name').strip().toUpperCase();
        id = 'balancing_record_last_name_' + rowId;
        inputType.setAttribute('value', value);
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[last_name_" + rowId + "]");
        inputType.className = "patient_name";
        inputType.setAttribute('readOnly', true);
        td.appendChild(inputType);
        row.appendChild(td);

        // account_number
        td = document.createElement("TD");
        inputType = document.createElement('INPUT');
        inputType.type = 'text';
        value = $F('balancing_record_account_number').strip().toUpperCase();
        id = 'balancing_record_account_number_' + rowId;
        inputType.setAttribute('value', value);
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[account_number_" + rowId + "]");
        inputType.className = "nonblank valid_balance_record_account_number";
        inputType.setAttribute('readOnly', true);
        td.appendChild(inputType);
        row.appendChild(td);

        // is_payer_the_patient
        td = document.createElement("TD");
        inputType = document.createElement('INPUT');
        inputType.type = 'checkbox';
        value = $('balancing_record_is_payer_the_patient').checked;
        id = 'balancing_record_is_payer_the_patient_' + rowId;
        inputType.setAttribute('id', id);
        if(value)
            inputType.setAttribute('checked', value);
        inputType.setAttribute('name', "balancing_record[is_payer_the_patient_ui_field" + rowId + "]");
        inputType.setAttribute('value', value);
        inputType.className = "required_with_dependent_on_patient_name";        
        inputType.setAttribute('disabled', true);
        td.appendChild(inputType);

        inputType = document.createElement('INPUT');
        inputType.type = 'hidden';
        id = 'balancing_record_is_claim_level_eob_hidden_' + rowId;
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[is_payer_the_patient_" + rowId + "]");
        inputType.setAttribute('value', value);
        td.appendChild(inputType);
        
        row.appendChild(td);

        // source_of_adjustment
        td = document.createElement("TD");
        var inputType1 = document.createElement('LABEL');
        inputType1.innerText = 'Check';
        td.appendChild(inputType1);
        
        inputType = document.createElement('INPUT');
        inputType.type = 'radio';
        value = $('balancing_record_source_of_adjustment_check').checked;
        id = 'balancing_record_source_of_adjustment_' + rowId + '_check';
        inputType.setAttribute('id', id);
        if(value) {
            inputType.setAttribute('checked', value);
            var source_of_adjustment = 'check';
        }
        else
            source_of_adjustment = 'balance';
        inputType.setAttribute('name', "balancing_record[source_of_adjustment_" + rowId + "]");
        inputType.setAttribute('value', source_of_adjustment);
        inputType.className = "nonblank";
        inputType.setAttribute('disabled', true);
        td.appendChild(inputType);

        inputType = document.createElement('LABEL');
        inputType.innerText = 'Balance';
        td.appendChild(inputType);

        inputType = document.createElement('INPUT');
        inputType.type = 'radio';
        value = $('balancing_record_source_of_adjustment_balance').checked;
        id = 'balancing_record_source_of_adjustment_' + rowId + '_balance';
        inputType.setAttribute('id', id);
        if(value) {
            inputType.setAttribute('checked', value);
            source_of_adjustment = 'balance';
        }
        else
            source_of_adjustment = 'check';
        inputType.setAttribute('name', "balancing_record[source_of_adjustment_ui_field" + rowId + "]");
        inputType.setAttribute('value', source_of_adjustment);
        inputType.className = "nonblank";
        inputType.setAttribute('disabled', true);
        td.appendChild(inputType);

        inputType = document.createElement('INPUT');
        inputType.type = 'hidden';
        id = 'balancing_record_source_of_adjustment_' + rowId;
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[source_of_adjustment_" + rowId + "]");
        inputType.setAttribute('value', source_of_adjustment);
        td.appendChild(inputType);

        row.appendChild(td);

        // is_claim_level_eob
        td = document.createElement("TD");        
        inputType = document.createElement('LABEL');
        inputType.innerText = 'Claim';
        td.appendChild(inputType);
        
        inputType = document.createElement('INPUT');
        inputType.type = 'radio';
        value = $('balancing_record_is_claim_level_claim').checked;
        id = 'balancing_record_is_claim_level_' + rowId + '_claim';
        inputType.setAttribute('id', id);
        if(value) {
            inputType.setAttribute('checked', value);
            var is_claim_level_eob = 'claim';
        }
        inputType.setAttribute('name', "balancing_record[is_claim_level_eob_" + rowId + "]");
        inputType.setAttribute('value', is_claim_level_eob);
        inputType.className = "nonblank";
        inputType.setAttribute('disabled', true);
        td.appendChild(inputType);

        inputType = document.createElement('LABEL');
        inputType.innerText = 'Standard';
        td.appendChild(inputType);
        
        inputType = document.createElement('INPUT');
        inputType.type = 'radio';
        value = $('balancing_record_is_claim_level_standard').checked;
        id = 'balancing_record_is_claim_level_' + rowId + '_standard';
        inputType.setAttribute('id', id);
        if(value) {
            inputType.setAttribute('checked', value);
            is_claim_level_eob = 'standard';
        }
        inputType.setAttribute('name', "balancing_record[is_claim_level_eob_ui_field" + rowId + "]");
        inputType.setAttribute('value', is_claim_level_eob);
        inputType.className = "nonblank";
        inputType.setAttribute('disabled', true);
        td.appendChild(inputType);

        inputType = document.createElement('INPUT');
        inputType.type = 'hidden';
        id = 'balancing_record_is_claim_level_eob_' + rowId;
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[is_claim_level_eob_" + rowId + "]");
        inputType.setAttribute('value', is_claim_level_eob);
        td.appendChild(inputType);

        row.appendChild(td);

        td = document.createElement("TD");
        td.setAttribute('id', 'td_delete_' + rowId);
        td.align = "center"
        td.valign = "middle"
        
        inputType = document.createElement('INPUT');
        inputType.type = 'hidden';
        serviceLineRecordId = '';
        value = rowId + '_' + serviceLineRecordId;
        inputType.setAttribute('value', value);
        id = 'balancing_record_id_' + rowId;
        inputType.setAttribute('id', id);
        inputType.setAttribute('name', "balancing_record[record_id_" + rowId + "]");
        inputType.className = 'balancing_record_ids_to_add';
        td.appendChild(inputType);

        // remove_button
        var buttonnode = document.createElement('input');
        buttonnode.setAttribute('type', 'button');
        buttonnode.setAttribute('id', 'td_id_' + rowId);
        buttonnode.setAttribute('value', '-');
        buttonnode.className = 'submit_add'
        buttonnode.setAttribute('style','width:20px');
        buttonnode.onclick = function(){
            removeBalancingRecord(rowId);
        }
        td.appendChild(buttonnode);
        row.appendChild(td);
        
        tbody.appendChild(row);
         
        $('balancing_record_category').value = '';
        $('balancing_record_first_name').value = '';
        $('balancing_record_last_name').value = '';
        $('balancing_record_account_number').value = '';
        $('balancing_record_is_payer_the_patient').checked = false;
        $('balancing_record_source_of_adjustment_check').checked = false;
        $('balancing_record_source_of_adjustment_balance').checked = false;
        $('balancing_record_is_claim_level_claim').checked = false;
        $('balancing_record_is_claim_level_standard').checked = false;
        setTimeout(function() {
            $('balancing_record_category').focus();
        }, 10);
    }
}

function removeBalancingRecord(lineCount, recordId) {
    var svcSerialAndRecordId;
    var svcLineSerialNum;
    if(recordId != '') {
        var recordIdsToDelete = $F('balancing_record_ids_to_delete') + ',' + recordId;
        $('balancing_record_ids_to_delete').value = recordIdsToDelete;
    }
    var serialAndRecordIds = $F('balancing_record_serial_and_record_ids');
    serialAndRecordIds = serialAndRecordIds + ',';
    var serialAndRecordIdsArray = serialAndRecordIds.split(',');
    for(i = 0; i < serialAndRecordIdsArray.length; i++) {
        svcSerialAndRecordId = serialAndRecordIdsArray[i];
        svcSerialAndRecordId = svcSerialAndRecordId.split('_');
        svcLineSerialNum = svcSerialAndRecordId[0];
        if(svcLineSerialNum == lineCount) {
            serialAndRecordIdsArray[i] = '';
        }
    }
    serialAndRecordIds = serialAndRecordIdsArray.join(',');
    $('balancing_record_serial_and_record_ids').value = serialAndRecordIds;

    var table = $('balancing_record_table_id');
    table.deleteRow($('balancing_record_row_' + lineCount).rowIndex);
}

function setBalancingRecordSerialNumbers() {
    var serialNumberAndRecordId = "";
    $$(".balancing_record_ids_to_add").each(
        function(item) {
            serialNumberAndRecordId = serialNumberAndRecordId + ',' + item.value;
        });
    $('balancing_record_serial_and_record_ids').value = serialNumberAndRecordId;
}

function validateRequiredItems() {
    var result = true;
    var inValidFields = [];
    var allFields = [];
    $$(".nonblank").each(
        function(item) {
            allFields.push(item.id);
            if(item.value.strip() == "") {
                inValidFields.push(item.id);
            }
        });
    if(allFields.length > 0) {
        setHighlight(allFields, "blank");
    }
    if(inValidFields.length > 0) {
        setHighlight(inValidFields, "uncertain");
        result = false;
        alert('Please enter the highlighted fields in Balanace Record Tab.');
    }
    return result;
}

function validateIsPayerThePatient() {
    var result = true;
    var fields = [];
    var nonHighLightFields = [];
    var  patientFirstName;
    var  patientLastName;    

    $$(".patient_name").each(
        function(item) {
            nonHighLightFields.push(item.id);
        });
    if(nonHighLightFields.length > 0) {
        setHighlight(nonHighLightFields, "blank");
    }        
    $$(".required_with_dependent_on_patient_name").each(
        function(item) {
            console_logger(item.checked, 'item.checked')
            if(item.checked == false) {
                var lineCount = item.id.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "")
                patientFirstName = "balancing_record_first_name_" + lineCount;
                patientLastName = "balancing_record_last_name_" + lineCount;
                if($(patientFirstName) && $(patientLastName)) {
                    if($F(patientFirstName).strip() == "" || $F(patientLastName).strip() == "") {
                        fields.push(patientFirstName);
                        fields.push(patientLastName);
                    }
                }
            }
        });
    if(fields.length > 0) {
        setHighlight(fields, "uncertain");
        result = false;
        alert('Please enter the highlighted fields in Balanace Record Tab if Payer Checkbox is not chosen.');
    }
    return result;
}


function validateBalanceRecordPatientNames() {
    var result = true;
    var allFields = [];
    var invalidFields = [];
    $$(".patient_name").each(
        function(item) {
            allFields.push(item.id);
            if(validatePatientFirstAndLastName(item.id) != true) {
                invalidFields.push(item.id);
            }
        });
    if(allFields.length > 0) {
        setHighlight(allFields, "blank");
    }
    if (invalidFields.length > 0) {
        setHighlight(invalidFields, "uncertain");
        result = false;
        alert('Please provide valid Patient Name in Balance Record Tab.')
    }
    return result;
}


function validateBalanceRecordPatientAccountNumber() {
    var result = true;
    var allFields = [];
    var invalidFields = [];
    $$(".valid_balance_record_account_number").each(
        function(item) {
            allFields.push(item.id);
            if((validateBalanceRecordAccountNumber(item.id, false)) != true) {
                invalidFields.push(item.id);
            }
        });
    if(allFields.length > 0) {
        setHighlight(allFields, "blank");
    }
    if (invalidFields.length > 0) {
        setHighlight(invalidFields, "uncertain");
        result = false;
        alert('Please provide valid Account Number in Balance Record Tab.')
    }
    return result;
}

function validateBalanceRecordAccountNumber(fieldId, needAlert) {
    var result = true;
    if($('details_patient_account_number_hyphen_format') && $('details_patient_account_number_hyphen_format').checked) {
        result = validateAlphanumericHyphenPeriodForwardSlash(fieldId);
    }
    else
        result = validateAlphaNumeric(fieldId, needAlert);
    return result;
}