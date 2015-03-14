// Provides a confirmation when the batches are in the Payer Wise auto allocation queue
// Displays the list of BatchIDs belonging to Payer Wise Queue
function validateForAddingToFacilityWiseAllocationQueue() {
    var resultOfValidation = true;
    var checkboxes = document.getElementsByClassName('checkbox');
    var enteredBatchIds = [], batchIdsToAlert = [];
    var batchPrimaryKey, typeId, batchId;
    for (var i = 0; i < checkboxes.length; i++) {
        if(checkboxes[i].checked == 1) {
            enteredBatchIds.push(checkboxes[i].id);
        }
    }
    for(i = 0; i < enteredBatchIds.length; i++) {
        batchPrimaryKey = enteredBatchIds[i];
        typeId = 'allocation_type_' + batchPrimaryKey;
        batchId = 'batchid_' + batchPrimaryKey;
        if($(typeId) != null && $(batchId) != null) {
            if($F(typeId) == 'Payer Wise') {
                batchIdsToAlert.push($F(batchId));
            }
        }
    }
    if(batchIdsToAlert.length > 0) {
        resultOfValidation = confirm("The following batches are in Payer Wise allocatiion queue. Are you sure?\n\
" + batchIdsToAlert);
    }
    if(resultOfValidation)
        return true;
    else
        return false;
}

// Provides a confirmation when the batches are in the Client Wise auto allocation queue
// Displays the list of BatchIDs belonging to Client Wise Queue
function validateForAddingToPayerWiseAllocationQueue() {
    var resultOfValidation = true;
    var checkboxes = document.getElementsByClassName('checkbox');
    var enteredBatchIds = [], batchIdsToAlert = [];
    var batchPrimaryKey, typeId, batchId;
    for (var i = 0; i < checkboxes.length; i++) {
        if(checkboxes[i].checked == 1) {
            enteredBatchIds.push(checkboxes[i].id);
        }
    }
    for(i = 0; i < enteredBatchIds.length; i++) {
        batchPrimaryKey = enteredBatchIds[i];
        typeId = 'allocation_type_' + batchPrimaryKey;
        batchId = 'batchid_' + batchPrimaryKey;
        if($(typeId) != null && $(batchId) != null) {
            if($F(typeId) == 'Facility Wise') {
                batchIdsToAlert.push($F(batchId));
            }
        }
    }
    if(batchIdsToAlert.length > 0) {
        resultOfValidation = confirm("The following batches are in Facility Wise allocatiion queue. Are you sure?\n\
" + batchIdsToAlert);
    }
    if(resultOfValidation)
        return true;
    else
        return false;
}

// Batches are to be in the 'COMPLETED' status for making it to 'OUTPUT_READY'.
// Provides an alert for the batches which are not in 'COMPLETED' status.
function validateForChangingStatusToComplete() {
    var checkboxes = document.getElementsByClassName('checkbox');
    var enteredBatchIds = [], batchIdsToAlert = [];
    var batchPrimaryKey, statusId, batchId;
    for (var i = 0; i < checkboxes.length; i++) {
        if(checkboxes[i].checked == 1) {
            enteredBatchIds.push(checkboxes[i].id);
        }
    }
    for(i = 0; i < enteredBatchIds.length; i++) {
        batchPrimaryKey = enteredBatchIds[i];
        statusId = 'status_' + batchPrimaryKey;
        batchId = 'batchid_' + batchPrimaryKey;
        if($(statusId) != null && $(batchId) != null) {
            if($F(statusId) != 'COMPLETED') {
                batchIdsToAlert.push($F(batchId));
            }
        }
    }
    if(batchIdsToAlert.length > 0) {
        alert("The following batches will not be made as Output Ready. Since it is not in Completed status.\n\
" + batchIdsToAlert );
    }
}

// In Batch Administration UI, Confirmation alert will display in the foll. scenarios:
// If the user tries to bring a batch to COMPLETED, OUTPUT_READY, OUTPUT_GENERATING, OUTPUT_GENERATED status , system should restrict
// if jobs in it are not in completed/incompleted status
function validateBatchStatusChange() {
    var  flag = true;
    var batch_status_from_ui = $F('batch_status_id_from_ui');
    if(batch_status_from_ui == 'COMPLETED' || batch_status_from_ui == 'OUTPUT_READY' || batch_status_from_ui == 'OUTPUT_GENERATING' || batch_status_from_ui == 'OUTPUT_GENERATED'){     
        if($F('processed_and_new_job_count') != 0){
            alert("The batch status cannot be changed unless all jobs are in COMPLETE/INCOMPLETE status");
            $('batch_status_id_from_ui').focus();
            flag = false;
        }
    }
    return flag;
}
function setIdForDelete(check,id){
    if(check == true){
        elemen= document.getElementById(id)
        elemen.setAttribute("class","checked_check check_box_client" )
    }
    else{
        elemen.className ='check_box_client'
    }
    
}
function checkAlertAndFacilityPresences(checkboxes){
    var return_faclity = true
    var enteredBatchIds = []
    for (i = 0; i < checkboxes.length; i++)
    {
        if(checkboxes[i].checked == true){
            enteredBatchIds.push(checkboxes[i].value)
        }
    }
    if(enteredBatchIds.length>0){

        return_faclity = checkFacilityPresent(enteredBatchIds)&&checkAlertPresent(enteredBatchIds)
        if(return_faclity == true){
            return_faclity =  confirm("Client is not associated with any facility/Pop-up. Do you want to delete?")
        }
        else
        {
            return_faclity = false
        }
    }
    else{
        alert("Select atleast one client")
        return_faclity = false
    }
    return return_faclity
}


function checkFacilityPresent(enteredBatchIds){
    return_value = true
    var parameters = 'client_id=' + enteredBatchIds;
    var url = relative_url_root() + "/admin/client/check_presence_of_facility";
    new Ajax.Request(url, {
        method: 'get',
        asynchronous: false,
        parameters: parameters,
        onComplete: function(facility_count) {
            var facility_count_client =  facility_count.responseText;
            facility_count_client = facility_count_client.gsub('"',' ').trim()

            if(facility_count_client != "nothing"){                     
                alert("Client(s) "+facility_count_client+" cannot be deleted, since it has got reference to facilities.")
                return_value = false
            }
            else{
                return_value = true
            }
        }
    });
    return return_value
}

function checkAllCheckboxes(checkboxes){
    alert("tyrtyrty")
    for (i = 0; i < checkboxes.length; i++)
    {
        checkboxes[i].checked=!checkboxes[i].checked
        
    }
}

function checkAlertPresent(enteredBatchIds){
    return_value = true
    var parameters = 'client_id=' + enteredBatchIds;
    var url = relative_url_root() + "/admin/client/check_presence_of_alert";
    new Ajax.Request(url, {
        method: 'get',
        asynchronous: false,
        parameters: parameters,
        onComplete: function(facility_count) {
            var facility_count_client =  facility_count.responseText;
            facility_count_client = facility_count_client.gsub('"',' ').trim()

            if(facility_count_client != "nothing"){
                alert("Client(s) "+facility_count_client+" cannot be deleted, since it has got reference to pop-up.")
                return_value = false
            }
            else{
                return_value = true
            }
        }
    });
    return return_value
}

function freeSaveButton(){
    var retrun_value = confirm("Are You Sure ?")
    if(retrun_value == true)
    {
        $('save').disabled = true;
        document.forms["form1"].submit();
    }
    return retrun_value
}

function changeButtonLabel(){
    $('enable_ocr_autoallocation_button_id').value = "Disable Ocr job Auto Allocation"
}
