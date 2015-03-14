$(function() {
    $('#provider_provider_last_name').autocomplete({

        source: '/insurance_payment_eobs/autocomplete'
    });
});


var rcode_window = new Window("rcode_win", {
    className: "alphacube",
    top:40,
    left:0,
    width:400,
    height:100,
    title:"Reason Codes",
    maximizable: false,
    minimizable: true
});

if($('claim_level_service_lines_container')) {
    var claim_level_service_lines_window = new Window("claim_level_service_lines_win", {
        className : "alphacube",
        top : 40,
        left : 0,
        width : 600,
        height : 150,
        title : "Claim Level Service Details",
        maximizable : false,
        minimizable : true
    });
}
window.history.forward(1);
jQuery(document).keydown(my_onkeydown_handler);
ctrl_pressed = false;

function my_onkeydown_handler() {
    if(event.ctrlKey){
        ctrl_pressed = true
    }
    else{
        switch (event.keyCode) {
            case 116 : // 'F5'
                if (ctrl_pressed == false){
                    event.returnValue = false;
                    alert("F5 is disabled, use CRTL+F5");                    
                    break;
                }
                ctrl_pressed = false;
        }
    }
    setTimeout('ctrl_pressed = false', 500);
    if(event.keyCode == 113){
        var field =  document.activeElement.name
        var val = false
        var facility = $F('facility')
        var faci = facility.toLowerCase().split(' ').join('_');
        var client = $F('client_name')
        var cli = client.toLowerCase().split(' ').join('_');
        var payer = $F('payer_popup')
        var pay = payer.toLowerCase().split(' ').join('_');
        var start_index = field.indexOf("[")+1
        var end_index = field.indexOf("]")
        var fields = field.substring(start_index,end_index)
        var url = $F('cms_url')
        var  arrayOfUrl = []
        arrayOfUrl[0]= url+cli+"/"+faci+"/"+pay+"/"+fields
        arrayOfUrl[1] = url+cli+"/"+faci+"/"+fields
        arrayOfUrl[2] = url+cli+"/"+faci+"/"+pay
        arrayOfUrl[3] = url+cli+"/"+faci
        arrayOfUrl[4] = url+cli
        for(i=0;i< 5; i++){
           
            val= checkPresenceOfUrl(arrayOfUrl[i])
            if(val == 'true'){
                window.open(arrayOfUrl[i],'_blank');
                break;
            }

        }
    }
}

function checkPresenceOfUrl(url_for){
    var return_value = "false";
    var url = relative_url_root() + "/insurance_payment_eobs/check_presence_of_url";
    var parameters = 'url_for=' + url_for
    new Ajax.Request(url, {
        asynchronous: false,
        method: 'get',
        parameters: parameters,
        onComplete: function(response_test) {
            return_value = response_test.responseText;
        }
    });
    return return_value;
}

//This will return the sub-uri if any
function relative_url_root() {

    return "<%= @app_root -%>"
}

Event.observe(window, 'load', function() {
    var twice_keying_fields = [];
    twice_keying_fields = ($F('twice_keying_fields').split(','))
    var allFields = $$('input:text')
    var allFieldIds = [];
    for(i = 0; i < allFields.length; i++) {
        if(!((allFields[i].id).startsWith('confirm'))) {
            allFieldIds.push(allFields[i].id);
        }
    }
    for (var i = 0; i < twice_keying_fields.length; i++) {
        for (var j = 0; j < allFieldIds.length; j++){
            if($(allFieldIds[j]) != null && $(allFieldIds[j]).readOnly != true && (allFieldIds[j]).strip() != '' && twice_keying_fields[i].strip() != '' &&
                $(allFieldIds[j]).disabled != true &&  allFieldIds[j].include(twice_keying_fields[i]) ==  true){
                $(allFieldIds[j]).oncopy = function (){
                    return false;
                }
                $(allFieldIds[j]).onpaste = function (){
                    return false;
                }
                $(allFieldIds[j]).oncut = function (){
                    return false;
                }
            }
        }
    }
    rcode_window.setContent("reason_code_grid_container");
    rcode_window.setLocation(50, 100);
    if($('claim_level_service_lines_container') && claim_level_service_lines_window) {
        claim_level_service_lines_window.setContent("claim_level_service_lines_container");
        claim_level_service_lines_window.setLocation(30, 300);
    }
    if(parent.document.getElementById('prov_adjustment_grid') != null){
        prov_adjustment_checked_status = parent.document.getElementById('prov_adjustment_grid').checked;
        show_prov_adjustment_grid(prov_adjustment_checked_status, 'processor');
    }
    total_charge_mpi('service_procedure_charge_amount_id','total_charge_id');
    total_charge_mpi('service_allowable_id','total_allowable_id');
    total_charge_mpi('service_allowable_id','total_allowable_id');
    total_charge_mpi('service_paid_amount_id','total_payment_id');
    total_charge_mpi('service_non_covered_id','total_non_covered_id');

    dragAndDropTable('service_line_details');

    // set the tab index of all elements with class as 'imported' to a very high number,
    // so that the user tabs thru them in the very end
    $$(".imported").each(
        function(item) {
            item.tabIndex = '800';
            item.observe('change', function() {
                var old_class_name = item.className;
                var class_names = new Array();
                class_names = old_class_name.split(' ');
                var length = class_names.length;
                class_names[length-1] = 'edited';
                item.className = class_names.join(' ');
            });
        });
    //set the tab index of all elements with class as 'certain' to a very high number,
    // so that the user tabs thru them in the very end
    $$(".certain").each(
        function(item) {
            item.tabIndex = '800';
            item.observe('change', function() {
                var old_class_name = item.className;
                var class_names = new Array();
                class_names = old_class_name.split(' ');
                var length = class_names.length;
                class_names[length-1] = 'edited';
                item.className = class_names.join(' ');
            });
        });
    $$(".uncertain").each(
        function(item) {
            item.observe('change', function() {
                var old_class_name = item.className;
                var class_names = new Array();
                class_names = old_class_name.split(' ');
                var length = class_names.length;
                class_names[length-1] = 'edited';
                item.className = class_names.join(' ');
            });
        });
    //extract the coordinates and page attributes from each element and highlight corresponding area in the image
    count = 0;
    $$(".ocr_data").each(
        // in OCR mode, set the tabIndex of MPI search button to zero
        function(item) {
            if (item.id == 'patient_account_id'){
                class_names = item.className.split(' ');
                blank_index = class_names.indexOf('blank');
                if($('mpi_button') != null && blank_index == -1 )
                    $('mpi_button').tabIndex = '0';
            }
            try {
                myHandler = new ViewOneHandler(parent.document.getElementById("viewONE"));
            } catch (e) { }
            item.observe('focus', function(event) {
                element = event.findElement();
                coordinates = element.getAttribute('coordinates');
                var x, y;
                if(coordinates != null )
                {
                    var coordinates_array = coordinates.split(',');
                    x = parseFloat(coordinates_array[0]);
                    y = parseFloat(coordinates_array[1]);
                    height= parseFloat(coordinates_array[2]);
                    width = parseFloat(coordinates_array[3]);
                    page = parseFloat(element.getAttribute('page'));
                    imageCountInJob = parseFloat(parent.document.getElementById('image_count_in_a_job').value)
                    var  xresolution = myHandler.getXResolution();
                    var yresolution = myHandler.getYResolution();
                    x = x*xresolution
                    y = y*yresolution
                    height = height*yresolution
                    width = width*xresolution
                    
                    if((!isNaN(page)) && (page !="") && (page !=null )){
                        if((!isNaN(imageCountInJob)) && (imageCountInJob !="") && (imageCountInJob !=null )){
                            if(imageCountInJob== 1){
                                page = 1
                            }
                            else if(imageCountInJob>1){
                                if(page > imageCountInJob) {
                                    pageNumber = page % imageCountInJob;
                                    if(pageNumber == 0)
                                        page = imageCountInJob;
                                    else
                                        page = pageNumber;
                                }
                            }
                        }
                    }
                    if((!isNaN(page)) && (page !="") && (page !=null))
                    {
                        if( x > 0 && y > 0 && page != null)
                        {
                            try {
                                myHandler.setPage(page);
                                myHandler.highlightArea( page, x, y, width, height, true, -1, count++);
                                //adjust the position of the scroll bar to show the highlighted area
                                image_height = myHandler.getImageHeight();
                                image_width = myHandler.getImageWidth();
                                y = ( y - (image_height * 0.1));
                                x = ( x - (image_width * 0.2));
                                
                                myHandler.setXYScroll( x , y );
                            } catch (e) { }
                        }
                    }
                }
            });
            item.observe('blur', function(){
                try {
                    myHandler.removeHighlight();
                } catch (e) { }
            });
            item.observe('mouseover', function(event) {
                element = event.findElement();
                var classNames = element.className.split(' ');
                for( var i=0; i<classNames.length; i++)
                {
                    switch (classNames[i] ) {
                        case "imported":
                            element.title = "Imported from 837 or Index File"
                            break
                        case "certain":
                            element.title = "OCR Certain"
                            break
                        case "uncertain":
                            element.title = "OCR Uncertain"
                            break
                        case "edited":
                            element.title = "OCR data edited by user"
                            break
                        default:
                            element.title = "Not read by OCR"
                    }
                }

            });
            if (item.id == 'checkdate_id' && (item.getAttribute('coordinates') != null)){
                setTimeout("$('checkdate_id').focus();", 100);
            }
        }
        );

    $$('input', 'select').each(function (item){
        // When the user tabs out of an element,
        // "remember" the element id by storing it in a js global variable
        item.observe("blur", function() {
            setUserLocation(item.readAttribute('id'));
        });
        item.observe('focus', function() {
            setUserLocation("");
        });
    });
    hideAdjustmentLine();
    if($F('tab_type') == "Insurance"){
        // If the EOB capturing is a Claim Level EOB type then hide all the service lines. Only the Totals should be shown.
        hide_for_claim_level_eob();

        // For multi page tiff the Transaction Type field is to be disabled after saving first EOB in a check
        if($('transaction_type')){
            if($F('image_type') == "1"){   // Multi tiff image
                if($('any_eob_processed') != null && $F('any_eob_processed') == "true"){
                    $("transaction_type").disabled = true;
                }
            }
        }
    }
    disablePaymentMethod();
    // This aims at providing a confirmation box to all $amount fields( alias 'Fields')(have class as 'amount') if each of them have amount >= $10,000 on 'change' & 'double click' event of the 'Fields'.
    // If the user does not confirm it, the background color of 'Fields' changes to red color, else yellow color.
    $$(".amount").each(
        function(item) {
            item.observe('change', function() {
                amountCheck(item.id);
                if(item.id.search('id') > 0){
                    //                  Ex:  service_allowable_id1 - from this element id, extract the index i.e. '1'
                    start_position = item.id.lastIndexOf('id')
                    if(start_position != null && item.id.length >= start_position + 2){
                        index = item.id.slice(start_position + 2, item.id.length);
                        if(index != null && !isNaN(parseInt(index)))
                            serviceBalance(index);
                    }
                }
            });
            item.observe('dblclick', function() {
                amountCheck(item.id);
            });
            if ($F('charge_amount_in_denied') == 'true'){
                item.observe('blur', function() {
                    getConfirmationToCaptureChargeAmountInOtherAmounts(item.id);
                });
            }
            setFieldsValidateAgainstCustomMethod([item.id], 'validate-currency-dollar');
        });
        
    $$('.unique_code').each(
        function(item) {
            item.observe('blur', function() {
                var uniqueCodeId = item.id
                setReasoncodeId(uniqueCodeId);
            });
            setFieldsValidateAgainstCustomMethod([item.id], 'validate-unique-code validate-confirm-hippa-code validate-presence-of-adjustment-amount');
        }
        );

    $$(".disable-double-keying").each(
        function(item) {

            item.observe('change', function() {
                if($(item.id).className.include('disable-double-keying')){
                    var arr =[]
                    if($F('837_changed_fields').strip() != ''){
                        arr = $F('837_changed_fields').split(',')
                    }
                    arr.push(item.id)
                    removeCustomValidations([item.id], 'disable-double-keying');
                    $('837_changed_fields').value = arr
                }
            });
        });

    $$('.datebox').each(
    
        function(item) {
            var dateField = item.id;
            if (dateField.search(/dateofservice/) == -1 && !($(dateField).readOnly)) {
                setFieldsValidateAgainstCustomMethod([item.id], 'validate-date');
                setFieldsValidateAgainstCustomMethod([item.id], 'required');
            }
            if($('correspondence_check') != null &&
                $F('correspondence_check') == "true") {
                if(dateField == 'checkdate_id'){
                    removeCustomValidations([dateField], 'required');
                    removeCustomValidations([dateField], 'validate-check-date');
                }
            }
            if (dateField == 'check_mailed_date_id' || dateField == 'check_received_date_id'){
                if ($(dateField).value == 'mm/dd/yy' || $(dateField).value == ""){
                    $(dateField).value = ""
                    removeCustomValidations([dateField], 'required');
                }
            }
            item.observe('focus', function() {
                removeDefaultDateValue(dateField);
            });
            item.observe('blur', function() {
                applyDateValidation(dateField, 0);
                if ((dateField.search(/dateofservice/) == -1) || (dateField.search(/claim_from_date/) == -1))
                    setToDateForOcr(dateField);
            });
            item.observe('change', function() {
                addSlashToDate(dateField);
                setToDate(dateField);
            });
            item.observe('dblclick', function() {
                var svcLineSerialNo = dateField.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                var isAdjustmentLineId = 'is_adjustment_line_' + svcLineSerialNo;
                if($(isAdjustmentLineId) != null && $F(isAdjustmentLineId) == 'true')
                    var allow = false;
                else
                    allow = true;
                if((dateField.search(/service/) != -1 && dateField.search(/from/) != -1 && allow) || (dateField.search(/claim_from_date/) != -1))
                    setFromDate(dateField);
                if(dateField.search(/from/) != -1 && allow)
                    setToDate(dateField);
            });
        });
    $$('popping_up_link').each(
        function(item){
            item.observe('click', function(event) {
                event.stop();
                var newwindow = window.open(this.href,'true','height=400,width=400');
                newwindow.focus();
                return false
            });
        });

    setValuesForTransactionTypePatPay();   
    displayRejectionComment();
});

//Displays alert popups while navigating through each field in the grid
//These popups were created field wise by the admin using popup administration
Event.observe(window, 'load', function() {
  
    var userCommentIdArray = [];
    var userFieldArray = [];
    var alertQnsArray = [];
    var alertCommentsArray = [];
    var alertedPosition = [];
    var alert_display_flag = true;
    var  client_id = "";
    var  facility_id = "";
    var rc_set_name_id ="";
    var prev_item_id ="";
    $$('select','input').each(function(item){
        if(item.id != 'payer_pay_address_one'){
            item.observe("focus", function() {
                var payers = new Array();
                if($("error_popup_ids") != null)
                    userCommentIdArray = ($("error_popup_ids").value).split("--")
                if($("error_popup_fields") != null)
                    userFieldArray = ($("error_popup_fields").value).split("-")
                if($("alert_qns") != null)
                    alertQnsArray = ($("alert_qns").value).split("-")
                if($("alert_comments") != null)
                    alertCommentsArray = ($("alert_comments").value).split("-")
                var width = 700;
                var height = 200;
                var left = (screen.width - width) / 2;
                var top = (screen.height - height) / 2;
                var params = 'width=' + width + ', height=' + height;
                params += ', top=' + top + ', left=' + left;
                params += ', directories=no';
                params += ', location=no';
                params += ', menubar=no';
                params += ', resizable=no';
                params += ', scrollbars=no';
                params += ', channelmode=no';
                params += ', titlebar=no';
                params += ', status=no';
                params += ', toolbar=no';
                client_id = $F("client_id")
                if($("rc_set_name_id") != null)
                    rc_set_name_id = $F("rc_set_name_id")
                facility_id =$F("facility_id")
                
                if ($("error_popup_ids") != null){
                    for(i=0; i<userFieldArray.length;i++){
                        if(item.parentNode.parentNode.getAttribute('id') == null)
                            alert_display_flag = true;
                        else{
                            if(((item.parentNode.parentNode.getAttribute('id') == 'adding_row') ||
                                (item.parentNode.parentNode.getAttribute('id') == 'service_total') ||
                                ((item.parentNode.parentNode.getAttribute('id').slice(0,11) == 'service_row'))) &&
                            (alertedPosition.indexOf(item.parentNode.cellIndex) == -1))
                                alert_display_flag = true;
                           
                            else if(((item.parentNode.parentNode.getAttribute('id') == 'adding_row') ||
                                (item.parentNode.parentNode.getAttribute('id') == 'service_total') ||
                                ((item.parentNode.parentNode.getAttribute('id').slice(0,11) == 'service_row'))) &&
                            (alertedPosition.indexOf(item.parentNode.cellIndex) != -1))
                                alert_display_flag = false;
                       
                        }
                        if(((item.id).search(userFieldArray[i])== 0) && (alert_display_flag == true)){
                            item_id = item.id;
                        
                            document.getElementById("popup_params").value = params;
                            document.getElementById("relative_url").value = relative_url_root();
                            if(document.getElementById("insurance").value == 1 && prev_item_id != "" && item_id == prev_item_id)
                                document.getElementById("insurance").value = 1
                            else
                                document.getElementById("insurance").value = 0
                          
                            var url1 = relative_url_root() + "/datacaptures/popup" + "?field_id=" +userFieldArray[i] + "&facility_id=" + facility_id + "&rc_set_name_id=" + rc_set_name_id +"&client_id=" + client_id
                         
                          
                            if (document.getElementById("insurance").value == 0) {
                                  
                                alertedPosition.push(item.parentNode.cellIndex);
                                window.open(url1, "alertwindow", params);
                           
                            }
                            prev_item_id = item.id
                            
                        }
                    }
                }
            });
        }
    });
});

