
var claim_info_id = []
function store_value(record_id){
    if((document.getElementById(record_id).checked) == true){
        claim_info_id.push(record_id)
    }
    else{
        claim_info_id.splice(claim_info_id.indexOf(record_id), 1);
    }
}
//DC REFACTOR Begin
function renderMpi(qa_flag, id,mpi_start_time,mpi_found_time,mpi_used_time,
    service_line_count,account_number,patient_last_name,patient_first_name,
    date_of_service_from,page_no,claimleveleob,job_id,mode, proc_start_time) {
    var params_hash = {
        claim_info_id_array: claim_info_id,
        patient_id: id,
        mpi_start_time: mpi_start_time,
        mpi_found_time: mpi_found_time,
        mpi_used_time: mpi_used_time,
        account_number: account_number,
        patient_last_name: patient_last_name,
        patient_first_name: patient_first_name,
        date_of_service_from: date_of_service_from,
        page: page_no,
        claimleveleob: claimleveleob,
        job_id: job_id,
        mode: mode,
        proc_start_time: proc_start_time
    };
    stripEmpty(params_hash);

    // Use anchor element to parse the opener href to make search relative.
    // See http://james.padolsey.com/javascript/parsing-urls-with-the-dom/
    var parser = document.createElement("a");
    parser.href = window.opener.location.href;
    parser.search = "?" + jQuery.param(params_hash);
    self.close();
    window.opener.location.href = parser.href;
}

function validateSearchInput() {
    var success = false;
    if (RevRemit.settings.claim_lookup_service != "rms") {
        success = validateSearchInputStandard();
    } else {
        success = validateSearchInputRms();
    }

    return success;
}

function validateSearchInputRms() {
    var patientAccountNumber = $F('patient_account_id').trim();
    if (patientAccountNumber.length >0)  {
        return true;
    } else {
        alert("Please provide values (WITHOUT wildcard) for Patient Account Number.");
        return false;
    }
}

function validateSearchInputStandard() {
    var patientAccountNumber = $F('patient_account_id').trim();
    var patientLastName = $F('patient_last_name_id').trim();
    var patientFirstName = $F('patient_first_name_id').trim();
    var dateofServiceFrom = "";
    if ($('dateofservice_from_status') !== null && $F('dateofservice_from_status') == 'true') {
        dateofServiceFrom = $F('dateofservicefrom').trim();
        if (dateofServiceFrom == "mm/dd/yy" || dateofServiceFrom == "MM/DD/YY")
        {
            dateofServiceFrom = "";
        }
    }
    if (  patientAccountNumber.length >0 || patientLastName.length >0 ||
        patientFirstName.length >0 || dateofServiceFrom.length >0)  {
        return true;
    } else {
        alert("Please provide values with or without wildcard (*) for at least one of the following fields: [Patient Account Number, Last Name, First Name, Service From Date] ");
        return false;
    }
}

function stripEmpty(obj) {
    for (var i in obj) {
        if (obj[i] === null || obj[i] === "" || obj[i] === "0.00") {
            delete obj[i];
        }
    }
}

/**
 * Extracts the date of service from the claim form. Checks first to determine
 * whether this is a claim-level EOB. If not, tries the standard insurance pay
 * location. If that fails, tries the patient pay location.
 * 
 * @return {string} Returns the date string in "mm/dd/yy" format.
 */

function dateOfServiceFrom() {
    var dateOfService = "";

    if (jQuery('#claimleveleob').val() == "true") {
        dateOfService = jQuery('#claim_from_date_id').val();
    } else {
        // FIXME: Should probably do something more robust than try and catch
        try {
            dateOfService = $F('dateofservicefrom').trim();
        } catch(err) {
            dateOfService = $F('date_service_from_1');
        }
    }

    return (dateOfService == "mm/dd/yy") ? null : dateOfService;
}

function mpiPopup(role, time, claimleveleob,proc_start_time,mode){
    if (!validateSearchInput()) {
        return;
    }

    var dateofService = dateOfServiceFrom();

    var patientAccountNumber = $F('patient_account_id').trim();
    var patientLastName = $F('patient_last_name_id').trim();
    var patientFirstName = $F('patient_first_name_id').trim();
    var mpi_apply = $F('mpi_apply_id');
    var insured_id = $F('member_id');
    var page_no = $F('page_no');
    var total_charges = $F('total_charge_id');
    var provider_id = $F('provider_id');
    var facility_id = $F('facility_id');
    var client_id = $F('client_id');
    var mpi_search_type = $F('mpi_search_type');
    var mpi_serach_facility_group = $F('mpi_serach_facility_group');
    var exact_serach_val = "1"
    $('mpi_search_start_time_id').value = time;
    $('mpi_search_acc_no_id').value = patientAccountNumber;
    $('mpi_search_pln_id').value = patientLastName;
    $('mpi_search_pfn_id').value = patientFirstName;
    $('mpi_search_dos_id').value = dateofService;
    var  job_id = $F('job_id');
    var params_hash = {
        mpi_apply: mpi_apply,
        page_no: page_no,
        patient_no: patientAccountNumber,
        patient_lname: patientLastName,
        patient_fname: patientFirstName,
        date_of_service_from: dateofService,
        role: role,
        claimleveleob: claimleveleob,
        total_charges: total_charges,
        pid: provider_id,
        job_id: job_id,
        mode: mode,
        proc_start_time: proc_start_time,
        facility_id: facility_id,
        client_id: client_id,
        mpi_search_type: mpi_search_type,
        exact_serach: exact_serach_val,
        mpi_serach_facility_group: mpi_serach_facility_group
    };
    stripEmpty(params_hash);
    var mpi_window = window.open(relative_url_root() + "/mpi_searches?" + jQuery.param(params_hash), "mywindow", "top=500,left=200,width=900,height=400,scrollbars=1");
    mpi_window.onBeforeUnload = onMpiWindowClose();
}

function onMpiWindowClose() {
    if($('refresh_page')) {
        $('refresh_page').value = 'true';
    }
    if($('refresh_page_iframe')) {
        $('refresh_page_iframe').value = 'true';
    }
    if(parent.myiframe) {
        var refreshPageObject = parent.myiframe.document.getElementById('refresh_page');
        if(refreshPageObject) {
            parent.myiframe.document.getElementById('refresh_page').value = 'true';
            console_logger(refreshPageObject.value, 'refresh_page')
        }
    }     
}
//DC Refactor END
function render_patpay_Mpi(id,patpay_mpi_start_time,patpay_mpi_found_time,patpay_mpi_used_time){
    set_cookie("patpay_patient_id", id, 7);
    set_cookie("patpay_mpi_start_time", patpay_mpi_start_time, 7);
    set_cookie("patpay_mpi_found_time", patpay_mpi_found_time, 7);
    set_cookie("patpay_mpi_used_time", patpay_mpi_used_time, 7);
    self.close();
    window.opener.location.href = window.opener.location.href;
}

function validatePatpaySearchInput() {
    var patientAccountNumber = $F('patient_account_id').trim();
    if (  patientAccountNumber.length >0 )  {
        return true;
    } else {
        alert("Please provide value with or without wildcard (*) for Patient AccountNumber ");
        return false;
    }
}


function patpay_mpiPopup(){
 
    if (!validatePatpaySearchInput()) {
        return;
    }
    var job_id = $F('job_id');
    patientAccountNumber_patpay = $('patient_account_id').value;
    set_cookie("patpay_account_number", patientAccountNumber_patpay, 7);
    var pop_patpay = window.open("mpi_search_patpay"+"?job_id="+job_id, "mywindow", "top=500,left=200,width=900,height=300");
}

function set_payer(){
    if ($('payer_id') !== null){
        var payer_id = $('payer_id').value;
        set_cookie("payer_id", payer_id, 7);
    }
}

function set_cookie(cookie_name, cookie_value, lifespan_in_days){
    document.cookie = cookie_name +
    "=" +
    encodeURIComponent(cookie_value) +
    "; max-age=" +
    60 * 60 *
    24 *
    lifespan_in_days +
    "; path=/";
}
function show_claim_level_grid(status,processor){
    if (processor == "qa") {
        url = "claimqa";
    }else{
        url = "show_eob_grid";
    }
    document.getElementById('myiframe').src = relative_url_root() + "/insurance_payment_eobs/"+url+"?claimleveleob="+status+"&job_id="+$F('job_id');

   
}
function setReasonCode(){
    var reasonCodeDescription = $F('reason_code_reason_code_description');
    if(reasonCodeDescription !== null){
        if(reasonCodeDescription.match(/\+/) !== null){
            var reasonCodeDetails = reasonCodeDescription.split("+");
            $('reason_code_reason_code').value = reasonCodeDetails[1].trim();
            $('reason_code_reason_code_description').value = reasonCodeDetails[0].trim();
        }
        validateReasonCode('reason_code_reason_code');
    }
}

function setReasonCodeDescription(){
    var reasonCode = $F('reason_code_reason_code');
    if(reasonCode !== null){
        if(reasonCode.match(/\+/) !== null){
            var reasonCodeDetails = reasonCode.split("+");
            $('reason_code_reason_code').value = reasonCodeDetails[0].trim();
            $('reason_code_reason_code_description').value = reasonCodeDetails[1].trim();
        }
        validateReasonCode('reason_code_reason_code');
    }
}

function validateDate() {
    var validation = false;
    var objRegExp = /^\d{1,2}(\/)\d{1,2}\1\d{2}$/
    var dateValue =  document.getElementById('mpi_search_date_of_service_from').value
    if(dateValue == "" ||  dateValue.toUpperCase() == 'MM/DD/YY')
        validation = true;
    else if(dateValue != "") {
        //check to see if in correct format
        if(!objRegExp.test(dateValue)) {
            validation = false; //doesn't match pattern, bad date
        }
        else{
            var dateSeparator = dateValue.substring(2, 3);
            var arrayDate = dateValue.split(dateSeparator);
            var day = parseInt(arrayDate[1], 10);
            var month = parseInt(arrayDate[0], 10);
            var year = arrayDate[2];

            if(year == '99' && month == 99 && day == 99) {
                validation = true;
            }
            else {
                //A Lookup for months and its max days except for February.
                var dateLookup = {
                    '01' : 31,
                    '03' : 31,
                    '04' : 30,
                    '05' : 31,
                    '06' : 30,
                    '07' : 31,
                    '08' : 31,
                    '09' : 30,
                    '10' : 31,
                    '11' : 30,
                    '12' : 31
                };

                //check if month value and day value agree
                if(dateLookup[arrayDate[0]] != null) {
                    if(day <= dateLookup[arrayDate[0]] && day > 0)
                        validation = true; //found in lookup table, good date
                }

                //validation for February
                if (month == 2) {
                    var centuryNumber = getCentury(dateValue);
                    var fullYear = centuryNumber + year;
                    fullYear = parseInt(fullYear);
                    if (day > 0 && day < 29) {
                        validation = true;
                    }
                    else if (day == 29) {
                        if ((fullYear % 4 == 0) && (fullYear % 100 != 0) ||
                            (fullYear % 400 == 0)) {
                            // Condition for Leap year
                            // year div by 4 and ((not div by 100) or div by 400)
                            validation = true;
                        }
                    }
                }
            }
        }
    }
    
    return validation;
}


function addSlash() {
    var dateValue = document.getElementById('mpi_search_date_of_service_from').value ;
    if ((dateValue.indexOf("/")==-1) && (dateValue.length==6)){
        document.getElementById('mpi_search_date_of_service_from').value  = dateValue.substring(0,2)+"/" + dateValue.substring(2,4) +
        "/" + dateValue.substring(4,6);
    }
    else if((dateValue.charAt(2)=="/") && (dateValue.charAt(5)!="/") &&
        ((dateValue.length==7) || (dateValue.length==5))){
        dateValue = dateValue.slice(0,2) + dateValue.slice(3,5) + dateValue.slice(5,7);
        document.getElementById('mpi_search_date_of_service_from').value  = dateValue.substring(0,2) + "/" + dateValue.substring(2,4) +
        "/" + dateValue.substring(4,6);
    }
    else if((dateValue.charAt(4)=="/") && (dateValue.charAt(2)!="/") &&
        (dateValue.length==7)){
        dateValue = dateValue.slice(0,2) + dateValue.slice(2,4) + dateValue.slice(5,7);
        document.getElementById('mpi_search_date_of_service_from').value  = dateValue.substring(0,2) + "/" + dateValue.substring(2,4) +
        "/" + dateValue.substring(4,6);
       
    }
    var validation = validateDate()
    if(validation == false) {
        alert("Invalid date is not allowed. Please correct the date and try again.");
        document.getElementById('mpi_search_date_of_service_from').focus();
    }
    return  validation
}

function removeDefualtDate(){
    if(document.getElementById('mpi_search_date_of_service_from').value == "MM/DD/YY" || document.getElementById('mpi_search_date_of_service_from').value == "mm/dd/yy")
        document.getElementById('mpi_search_date_of_service_from').value = "";
    
}


function clearForm(){
    var  frm_elements = document.getElementById('mpi_search').elements
    for(i=0; i<frm_elements.length; i++)
    {
        if(frm_elements[i].type != "submit" && frm_elements[i].type != "button" && frm_elements[i].type != "checkbox"  && frm_elements[i].id != "mpi_search_date_of_service_from"){
            frm_elements[i].value = "";
        }
        else if(frm_elements[i].id == "mpi_search_date_of_service_from"){
            frm_elements[i].value = "mm/dd/yy";
        }
    }
}