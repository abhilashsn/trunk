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
if($('claim_level_service_lines_container') && claim_level_service_lines_window) {
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
function selectTheValue(){
    if (document.getElementById("page").value){
        return true;
    }
    else{
        alert("Please enter the page number");
        return false;
    }
}

Event.observe(window, 'load', function() {
    // If the EOB capturing is a Claim Level EOB type then hide all the service lines. Only the Totals should be shown.
    hide_for_claim_level_eob();
      
    rcode_window.setContent("reason_code_grid_container");
    rcode_window.setLocation(550, 100);
    if($('claim_level_service_lines_container')) {
        claim_level_service_lines_window.setContent("claim_level_service_lines_container");
        claim_level_service_lines_window.setLocation(400, 300);
    }
    dragAndDropTable('service_line_details');
    
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
                    removeCustomValidations([dateField], 'validate-date');
                    removeCustomValidations([dateField], 'required');
                    removeCustomValidations([dateField], 'validate-check-date');
                }
            }
            item.observe('focus', function() {
                removeDefaultDateValue(dateField);
            });
            item.observe('blur', function() {
                applyDateValidation(dateField, 0);
            });
            item.observe('change', function() {
                addSlashToDate(dateField);
                if ((dateField.search(/dateofservice/) != -1) || (dateField.search(/claim_from_date/) != -1))
                    setToDate(dateField);
            });
            item.observe('dblclick', function() {
                var svcLineSerialNo = dateField.replace(/[A-Za-z\_\(\)\.\-\s,]/g, "");
                var isAdjustmentLineId = 'is_adjustment_line_' + svcLineSerialNo;
                if($(isAdjustmentLineId) != null && $F(isAdjustmentLineId) == 'true')
                    var allow = false;
                else
                    allow = true;
                if(dateField.search(/service/) != -1 && dateField.search(/from/) != -1 && allow)
                    setFromDate(dateField);
                if(dateField.search(/from/) != -1 && allow)
                    setToDate(dateField);
            });
        });

    if($('prov_adjustment_grid') != null){
        prov_adjustment_checked_status = $('prov_adjustment_grid').checked;
        show_prov_adjustment_grid(prov_adjustment_checked_status, 'qa');
    }
    total_charge_mpi('service_procedure_charge_amount_id','total_charge_id');
    total_charge_mpi('service_allowable_id','total_allowable_id');
    total_charge_mpi('service_allowable_id','total_allowable_id');
    total_charge_mpi('service_paid_amount_id','total_payment_id');
    total_charge_mpi('service_non_covered_id','total_non_covered_id');
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
            try {
                myHandler = new ViewOneHandler(document.getElementById("viewONE"));
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
                    height = parseFloat(coordinates_array[2]);
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
                        if( x != 0 && y != 0 && page != null)
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
            if (item.id == 'checkdate_id' &&  (item.getAttribute('coordinates') != null)){
                setTimeout("$('checkdate_id').focus();", 100);
            }
        }
        );


    //hideRCGrid();
  
    $$('input', 'select', 'textarea').each(function(item){
        // When the user tabs out of an element,
        // "remember" the element id by storing it in a js global variable
        item.observe("blur", function() {
            setUserLocation(item.readAttribute('id'));
        });
        item.observe('focus', function() {
            setUserLocation("");
        });

    });
    $$('.unique_code').each(
        function(item) {
            item.observe('blur', function() {
                var uniqueCodeId = item.id
                setReasoncodeId(uniqueCodeId);
            });
            setFieldsValidateAgainstCustomMethod([item.id], 'validate-unique-code validate-presence-of-adjustment-amount');
        }
        );

    disablePaymentMethod();

    // This aims at providing a confirmation box to all $amount fields( alias 'Fields')(have class as 'amount') if each of them have amount >= $10,000 on 'change' & 'double click' event of the 'Fields'.
    // If the user does not confirm it, the background color of 'Fields' changes to red color, else yellow color.
    $$(".amount").each(
        function(item) {
            item.observe('change', function() {
                amountCheck(item.id);
                setDefaultClaimTypeForQAView(item.id);
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
    setValuesForTransactionTypePatPay();
    hideAdjustmentLine();
    displayRejectionComment();
});

window.history.forward(1);
document.attachEvent("onkeydown", my_onkeydown_handler);
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
}
