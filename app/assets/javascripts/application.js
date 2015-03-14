// Idle time session expiry time. This should match the server side session expiry time.
function getSessionExpiryTime() {
    // Time in seconds
    return 1200;
}

// getSessionPollIntervalTime should be nearly (getSessionExpiryTime / 6)
function getSessionPollIntervalTime() {
    // Time in seconds
    return 180;
}

function getFocus() {
    window.isActive = true;
    window.userIsActive = true;
}

function removeFocus() {
    window.isActive = false;
    window.userIsActive = false;
}

function keepServerAlive() {
    if(parent.window.isActive && parent.window.userIsActive) {
        setInterval(function() {
            if(parent.window.isActive && parent.window.userIsActive && window.keepServerAliveCount < 5) {
                var url = relative_url_root() + "/keep_alive";
                new Ajax.Request(url, {
                    asynchronous: true,
                    onComplete: function() {
                        window.keepServerAliveCount = window.keepServerAliveCount + 1;
                    }
                });
            }
        }, 1000 * getSessionPollIntervalTime());
    }
}

function sessionTimeOut() {
    jQuery.noConflict();
    var relativeUrlRoot = relative_url_root();
    jQuery(document).ready(function($){
        $.idleTimeout('#idletimeout', '#idletimeout a', {
            idleAfter: getSessionExpiryTime(),
            pollingInterval: getSessionPollIntervalTime(),
            keepAliveURL: relativeUrlRoot + '/keep_alive',
            serverResponseEquals: 'OK',
            onTimeout: function(){
                $(this).slideUp();
                var parameter = '';
                if($('user_id') != null) {
                    parameter = '?user_id=' + $F('user_id');
                }
                window.location = relativeUrlRoot + "/logout" + parameter;
            },
            onIdle: function(){
                $(this).slideDown(); // show the warning bar
            },
            onCountdown: function( counter ){
                $(this).find("span").html( counter ); // update the counter
            },
            onResume: function(){
                $(this).slideUp(); // hide the warning bar
            }
        });
    });

    window.isActive = false;
    window.userIsActive = false;

    window.onmouseover = function () {
        window.isActive = true;
        window.userIsActive = true;
    };

    window.onblur = function () {
        window.isActive = false;
        window.userIsActive = false;
    };
}

function sessionTimeOutOnBrowserClose(e) {
    jQuery.noConflict();
    e = window.event || e;
    myOnKeyDownHandler(e)
    if($('user_role') != null) {
        var role = $F('user_role').toUpperCase();
        if(role == 'PROCESSOR' || role == 'QA') {
            if ($('refresh_page') && $F('refresh_page') == 'false') {
                if (e.clientX < 0 || e.clientY < 0) {
                    e.cancelBubble = true;
                    var parameter = '';
                    if($('user_id') != null) {
                        parameter = '?user_id=' + $F('user_id');
                    }
                    jQuery.ajax({
                        type: 'GET',
                        async: false,
                        url: relative_url_root() + '/logout' + parameter
                    });
                }
            }
        }
    }
}


function sessionTimeOutOnBrowserCloseInIframe(e) {
    jQuery.noConflict();
    e = window.event || e;
    myOnKeyDownHandler(e)
    if($('user_role') != null) {
        var role = $F('user_role').toUpperCase();
        if(role == 'PROCESSOR' || role == 'QA') {
            if (($('refresh_page') && $F('refresh_page') == 'false') ||
                ($('refresh_page_iframe') && $F('refresh_page_iframe') == 'false') ||
                (parent.myiframe &&  parent.myiframe.document.getElementById('refresh_page_iframe') &&
                    parent.myiframe.document.getElementById('refresh_page_iframe').value == 'false')) {
                if (e.clientX < 0 || e.clientY < 0)  {
                    e.cancelBubble = true;
                    var parameter = '';
                    if($('user_id') != null) {
                        parameter = '?user_id=' + $F('user_id');
                    }
                    jQuery.ajax({
                        type: 'GET',
                        async: false,
                        url: relative_url_root() + '/logout' + parameter
                    });
                }
            }
        }
    }
}

function myOnKeyDownHandler(e) {
    if(e.keyCode == 115 || e.keyCode == 116) {
        if($('refresh_page')) {
            $('refresh_page').value = 'true';
        }
        if($('refresh_page_iframe')) {
            $('refresh_page_iframe').value = 'true';
        }
        if(parent.myiframe) {
            var refreshPageObject = parent.myiframe.document.getElementById('refresh_page_iframe');
            if(refreshPageObject) {
                parent.myiframe.document.getElementById('refresh_page_iframe').value = 'true';
            }
        }
    }
}

function setPointerAboveImage() {
    if($('refresh_page_iframe')) {
        $('refresh_page_iframe').value = 'true';
    }
    if($('refresh_page')) {
        $('refresh_page').value = 'true';
    }
    if(parent.myiframe) {
        var refreshPageObject = parent.myiframe.document.getElementById('refresh_page_iframe');
        if(refreshPageObject) {
            parent.myiframe.document.getElementById('refresh_page_iframe').value = 'true';
        }
    }
}

function resetPointerAboveImage() {
    if($('refresh_page_iframe')) {
        $('refresh_page_iframe').value = 'false';
    }
    if($('refresh_page')) {
        $('refresh_page').value = 'false';
    }
    if(parent.myiframe) {
        var refreshPageObject = parent.myiframe.document.getElementById('refresh_page_iframe');
        if(refreshPageObject) {
            refreshPageObject.value = 'false';
        }
    }
}



var alphaExp = /^[a-zA-Z]+$/;
function checkAll(formId){
    var checkboxes = $(formId);
    for (i = 0; i < checkboxes.length; i++) {
        checkboxes[i].checked = !checkboxes[i].checked;
    }
}

var availableList = document.getElementById("availableOptions");
var selectedList = document.getElementById("selectedOptions");

function delAttribute(event) {
    event.preventDefault();
    var selIndex = selectedList.selectedIndex;
    if (selIndex < 0)
        return;
    availableList.appendChild(selectedList.options.item(selIndex))
    selectNone(selectedList, availableList);
    setSize(availableList, selectedList);
}

function addAttribute(event) {
    event.preventDefault();
    var addIndex = availableList.selectedIndex;
    if (addIndex < 0)
        return;
    selectedList.appendChild(availableList.options.item(addIndex));
    selectNone(selectedList, availableList);
    setSize(selectedList, availableList);
}

function setSize(list1, list2) {
    list1.size = getSize(list1);
    list2.size = getSize(list2);
}

function selectNone(list1, list2) {
    list1.selectedIndex = -1;
    list2.selectedIndex = -1;
    addIndex = -1;
    selIndex = -1;
}

function getSize(list) {
    /* Mozilla ignores whitespace,
      IE doesn't - count the elements
      in the list */
    var len = list.childNodes.length;
    var nsLen = 0;
    //nodeType returns 1 for elements
    for (i = 0; i < len; i++) {
        if (list.childNodes.item(i).nodeType == 1)
            nsLen++;
    }
    if (nsLen < 2)
        return 2;
    else
        return nsLen;
}

function showSelected(field) {
    var list = document.getElementById('selectedOptions');
    var data = []
    for (var i = 0; i < list.options.length; ++i)
    {
        data += list.options[i].value;
        data += " ";
    }
    document.getElementById("tiff_number").value = "";
    document.getElementById("tiff_number").value = data;
//        field.value = (field.value).replace(/[^a-zA-Z 0-9]+\s+/g, "" );
}
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function popup_image(id){
    url =relative_url_root() + "/archive/viewimage" + "?job_id=" + id
    if(isNaN(id))
        alert("There's no parent job for this job!");
    else
        var pop_w = window.open(url, "mywindow", "width=900,height=500");
}

self.onerror = function(){
    return true;
}

function eventHandler(id, text)
{
    if (text=="Escape")
    {
        parent.top.frames["btmFrame"].document.getElementById('checkamount_id').focus();
    }
}

function console_logger(id, text) {
// for future event handling/ debugging if any
//    console.log("Text :"+text+" Id :"+id);
}
	
function imagedisply(singlepagetiff, multipagetiff, pageno, imageCountInJob, appletcontrol){
    var pageNumber;
    var k = 0;
    var sub_uri = relative_url_root()
    var path1 = '<APPLET CODEBASE = "'
    var path2 = '/v1/v1files" ARCHIVE = "ji.jar,daeja2.jar,daeja1.jar,daeja1s.jar" CODE = "ji.applet.jiApplet.class" id= "viewONE" NAME = "ViewONE" WIDTH = "100%" HEIGHT = "100%" HSPACE = "0" VSPACE = "0" ALIGN = "middle" accesskey="Z" MAYSCRIPT="true" >'
    var fullPath = path1+sub_uri+path2
    document.write(fullPath)
    document.write('<param name="type" value="application/x-java-applet;version=1.4">');
    document.write('<PARAM NAME="cabbase" VALUE="/v1files/ji.cab, daeja1.cab, daeja2.cab, daeja3.cab">');
    if (appletcontrol != 1) {
        document.write('<PARAM NAME="printKeys" value="false">');
        document.write('<PARAM NAME="printMenus" value="false">');
        document.write('<PARAM NAME="cabbase" VALUE=“ViewONE.cab”>');
        document.write('<PARAM NAME="scale" value="ftow">');
        document.write('<PARAM NAME="fileButtonSave" value="false">');
        document.write('<PARAM NAME="fileButtonOpen" value="false">');
        document.write('<PARAM NAME="fileButtonClose" value="false">');
        document.write('<PARAM NAME="printButtons" value="false">');
    }
    document.write('<PARAM NAME="prefetchPages" value="5">');
    document.write('<PARAM NAME="obfuscate" value="false">');
    document.write('<param name="version3Features" value="true">');
    document.write('<param name="eventhandler" value="console_logger">');
    document.write('<param name="eventInterest" value="0, 9, 22, 30, 34, 35, 37, 38, 39, 41, 43">');
    document.write('<param name="ProcessKeys" value = "true">');
    document.write('<param name="annotationEncoding" value="UTF8">');
    document.write('<param name="annotate" value="true">');
    document.write('<param name="annotateEdit" value="true">');
    document.write('<PARAM NAME="initialFocus" value="false">');
    document.write('<PARAM NAME="focusBorder" value="false">');
    document.write('<PARAM NAME="annotationJavascriptExtensions" value="true">');
    document.write('<PARAM NAME="hideAnnotationToolbar" value="true">');
    if (singlepagetiff != "") {
        var single_page_tiff_array = singlepagetiff.split("*");
        for (newcount = 0; newcount < single_page_tiff_array.length; newcount++)
        {
            if (single_page_tiff_array[newcount] == "") {
                var k = 1
            }
            else {
                image = single_page_tiff_array[newcount];
                splits = image.split(".");
                splits[(splits.length-2)] = splits[(splits.length-2)] + "_medium";
                thumb_image = splits.join(".");
                /*thumb_image = single_page_tiff_array[newcount].replace('original','medium');*/
                document.write('<param name="page' + (k) + '" value="' + sub_uri + single_page_tiff_array[newcount] + '">')
                document.write('<param name="thumb' + (k) + '" value="' + sub_uri + thumb_image + '">')
                k = k + 1
            }
        }
    }
    else {
        var l = 1
        var multi_page_tiff_array = multipagetiff.split("*");
        var imagename = multi_page_tiff_array[0];
        imagename = sub_uri+imagename
        var pagefrom = multi_page_tiff_array[1];
        var pageto = multi_page_tiff_array[2];
        a = multi_page_tiff_array[2] - multi_page_tiff_array[1]
        document.write('<PARAM NAME="filename" value=' + imagename + '>')
    }
    imageCountInJob = parseInt(imageCountInJob);
    if(imageCountInJob != 0 && imageCountInJob > 1) {
        if(pageno > imageCountInJob) {
            pageNumber = pageno % imageCountInJob;
            if(pageNumber == 0)
                pageno = imageCountInJob;
            else
                pageno = pageNumber;
        }
    }
    if(pageno != null && pageno != 'undefined' && pageno != ""){
        document.write('<param name="pageNumber" value="' + pageno + '">')
    }

    document.write('</APPLET>');
}
function setuserdetails(){
    userid = document.getElementById('userid').value
    set_cookie("userid", userid, 7);
}

function change_payer(){
    document.forms[0].submit();
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

function pop(jobid, id, checkid){
    url =relative_url_root() + "/archive/view_log" + "?jobid=" + jobid + "&eob_id=" + id + "&eob_check_number=" + checkid
    var pop_w = window.open(url, "mywindow3", "top=300,left=200,width=400,height=300,toolbar=0,statusbar=0,menubar=0,resizable=0");
    
}

function popup_eob_summary(jobid){
    url = relative_url_root() +"/archive/eob_information_summary" + "?jobid=" + jobid
    if(isNaN(jobid))
        alert ("Pass me a valid Job ID!");
    else
        var pop_w = window.open(url, "mywindow8", "top=300,left=200,width=1600,height=300,toolbar=0,statusbar=0,menubar=0,resizable=0");
}

function popup_prov_adjustment_summary(job_id){
    url = relative_url_root() +"/provider_adjustments/provider_adjustment_summary" + "?job_id=" + job_id
    if(isNaN(job_id))
        alert ("Pass me a valid Job ID!");
    else
        var pop_w = window.open(url, "mywindow_plb", "top=300,left=200,width=700,height=300,toolbar=0,statusbar=0,menubar=0,resizable=0,scrollbars=yes");
}

function checkAll(formId){
    var checkboxes = $(formId);
    for (i = 2; i < checkboxes.length; i++) {
        checkboxes[i].checked = !checkboxes[i].checked;
    }
}

function getImagePageNumber(){
    var imagePageNo = (parent.document.getElementById("viewONE").getPage());
    if(imagePageNo.isNaN){
        imagePageNo = (document.getElementById("viewONE").getPage());
    }
    if($('pages_from') != null && $('image_type') != null) {
        var pageFrom = $F('pages_from');
        var imageType = $F('image_type');
        if(parseInt(imageType) == 1){
            $('image_page_number_id').value = parseInt(imagePageNo);
        }
        else{
            if(pageFrom.length == 0){
                $('image_page_number_id').value = parseInt(imagePageNo);
            }
            else{
                $('image_page_number_id').value = (parseInt(pageFrom) + parseInt(imagePageNo)) - 1;
            }
        }
    }
    else{
        $('image_page_number_id').value = parseInt(imagePageNo);
    }
}

function show_or_hide_image_page_no_field(){
    if (parent.document.getElementById("resizable") != null){
        image_page_number_obj = parent.myiframe.document.getElementById('image_page_number_id');
        page_no_header_div_obj = parent.myiframe.document.getElementById('page_no_header_div');
        image_page_number_obj.disabled = false;
        image_page_number_obj.type = "hidden";
        page_no_header_div_obj.style.display = 'none';
    }
    else{
        image_page_number_obj = document.getElementById('image_page_number_id');
        page_no_header_div_obj = document.getElementById('page_no_header_div');
        image_page_number_obj.disabled = false;
        image_page_number_obj.type = "text";
        page_no_header_div_obj.style.display = 'block';
    }
}

function getCurrentProviderAdjustmentamount(){
    $('current_provider_adjustment_amount').value = $F('prov_adjustment_amount_id');
}
 
//Calculation of balance and provider adjustment amounts in QA as well as in Processor view
//on deleting a provider adjustment record from provider adjustment summary popup.
 
function balanceAmountAfterProvAdjAmountDelete(deleted_prov_adj_amount){
    if(window.opener.document.getElementById('resizable') != null){
        balance_obj = window.opener.parent.myiframe.document.getElementById('balance');
    }
    else{
        balance_obj = window.opener.document.getElementById('balance');
        provider_adjustment_obj = window.opener.document.getElementById('provider_adjustment');
        updated_provider_adjustment = parseFloat(provider_adjustment_obj.value) - parseFloat(deleted_prov_adj_amount);
        provider_adjustment_obj.value = updated_provider_adjustment.toFixed(2);
    }
    balance_amount_in_grid = parseFloat(balance_obj.value);
    updated_balance = balance_amount_in_grid + parseFloat(deleted_prov_adj_amount);
    balance_obj.value = updated_balance.toFixed(2);
}

//Calculation of balance and provider adjustment amounts in QA as well as in Processor view
//on adding a provider adjustment record from DC grid.

function balanceAmountAfterProvAdjAmountCreate(){
    var adjustmentAmount = parseFloat($F('provider_adjustment_amount'));
    var new_adjustmentAmount = parseFloat($F('current_provider_adjustment_amount'));
    final_adjustmentAmount = adjustmentAmount + new_adjustmentAmount;
    $('provider_adjustment_amount').value = final_adjustmentAmount;
    view_type = $F('view');
    if(view_type == 'proc_view'){
        balance_obj = parent.myiframe.document.getElementById('balance');
    }
    else{
        balance_obj = document.getElementById('balance');
        provider_adjustment_obj = document.getElementById('provider_adjustment');
        updated_provider_adjustment = parseFloat(provider_adjustment_obj.value) + parseFloat(new_adjustmentAmount);
        provider_adjustment_obj.value = updated_provider_adjustment.toFixed(2);
    }
    balance = balance_obj.value;
    var updated_balance = parseFloat(balance) - parseFloat(new_adjustmentAmount);
    updated_balance = parseFloat(updated_balance).toFixed(2);
    balance_obj.value = updated_balance;
    if (parent.document.getElementById("resizable") != null)
        provider_adjustment_grid_obj = parent.myiframe.document.getElementById('provider_adjustment_grid');
    else
        provider_adjustment_grid_obj = document.getElementById('provider_adjustment_grid');
    //provider adjustment capture grid is visible only when the job is
    //unbalanced ie: when balance == 0.00 after provider adjustment saving,
    //the provider adjustment capture grid become hidden.
    var parentJobId = parent.document.getElementById('child_job_parent_job_id');

    if (parentJobId != null && parentJobId.value == '' && balance_obj.value == 0.00){
        provider_adjustment_grid_obj.style.visibility = 'hidden';
    }
    else
        provider_adjustment_grid_obj.style.visibility = 'visible';
    
}

function show_prov_adjustment_grid(prov_adjustment_checked_status, view){
    if(view == 'processor'){
        provider_adjustment_grid_obj = parent.myiframe.document.getElementById('provider_adjustment_grid');
        balance_obj = parent.myiframe.document.getElementById('balance');
    }
    else{
        provider_adjustment_grid_obj = document.getElementById('provider_adjustment_grid');
        balance_obj = document.getElementById('balance');
    }
    if(balance_obj != null){
        balance = balance_obj.value;
        var parent_job_id = parent.document.getElementById('child_job_parent_job_id').value
        //provider adjustment capture grid is visible only when the job is
        //unbalanced ie: balance != 0.00 and when the Enable Provider Adjustment
        //checkbox is checked.
        if(prov_adjustment_checked_status && (parent_job_id != '' || balance != 0.00)){
            provider_adjustment_grid_obj.style.visibility = 'visible';
        }
        else{
            provider_adjustment_grid_obj.style.visibility = 'hidden';
        }
    }
}

//This method is for getting image page no when tabout from patient_account_number field
function getImagePage(){
    if($('image_page_number') != null && $('pages_from') != null && $('image_type') != null) {
        var image_page_number = $F('image_page_number');
        var pages_from = $F('pages_from');
        var image_type = $F('image_type');
        var imagePageNo = (parent.document.getElementById("viewONE").getPage());
        if(imagePageNo.isNaN){
            imagePageNo = (document.getElementById("viewONE").getPage());
        }
        if(parseInt(image_type) == 1){
            $('image_page_number').value = parseInt(imagePageNo);
        }
        else{
            if(pages_from.length == 0){
                $('image_page_number').value = parseInt(imagePageNo);
            }
            else{
                $('image_page_number').value = (parseInt(pages_from) + parseInt(imagePageNo)) - 1;
            }
        }
        // Provides an alert if the Page# is changed in the 'Qa view or Completed EOB view'
        if(image_page_number != imagePageNo && $('qa_view')) {
            alert("Page# has been changed");
        }
    }

}
   
//This method is for getting the page number on which the EOB is saved for GCBS only.
//We get page no when we click on SAVE EOB button.
function setImagePageToNumber(){
    if($('image_page_to_number') != null && $('pages_from') != null && $('image_type') != null) {
        var pages_from = $F('pages_from');
        var image_type = $F('image_type');
        try {
            var imagePageNo = (parent.document.getElementById("viewONE").getPage());
        } catch (e) { }
        if(parseInt(image_type) == 1){
            $('image_page_to_number').value = parseInt(imagePageNo);
        }
        else{
            if(pages_from.length == 0){
                $('image_page_to_number').value = parseInt(imagePageNo);
            }
            else{
                $('image_page_to_number').value = (parseInt(pages_from) + parseInt(imagePageNo)) - 1;
            }
        }
    }
// console_logger('setImagePageToNumber', imagePageNo);
}

function choose_facility(id){
    Element.hide('partner_div');
    Element.hide('client_div');
    Element.hide('fac_div');
    if($F(id) == "client" && $(id).checked == true)
    {
        Element.show('client_div');
        $('opartner').checked = false;
        $('ofacility').checked = false;
        //alert("Please choose which facility does the user belong to.");
        return;
    }
    if($F(id) == "facility" && $(id).checked == true)
    {
        Element.show('fac_div');
        $('opartner').checked = false;
        $('oclient').checked = false;
        //alert("Please choose which lockbox does the user belong to.");
        return;
    }
    if($F(id) == "partner" && $(id).checked == true)
    {
        $('oclient').checked = false;
        $('ofacility').checked = false;
        Element.show('partner_div');
        //alert("Please choose which client does the user belong to.");
        return;
    }
    $('opartner').checked = false;
    $('oclient').checked = false;
    $('ofacility').checked = false;
    Element.show('fac_div');
}

var user_location = '';
// When the user tabs out of an element,
// "remember" the element id by storing it in a js global variable
function setUserLocation(item_id){
    user_location = item_id;
}
// Get the focus back on the last element
function resumeFocus(){
    if(user_location != ''){
        if ($(user_location) != null)
            $(user_location).focus();
    }
}

//The following functions expand the text boxes as the user types in
// and collapse them after the user tabs out
function enlargeTextbox(id){
    $(id).size = ($(id).size) + 4
}

function resetTextboxSize(id){
    $(id).size = 2
}

function resetTextfieldSize(id,actualwidth){
    $(id).size = actualwidth
}

function enlargeTextfieldSize(id,actualsize){
    var text_length = $(id).value.length
    if (text_length >= actualsize){
        $(id).size = ($(id).value.length) + 4
    }
}

function increaseFieldWidth(id, requiredLength){
  if($(id) != null)
        $(id).style.width = requiredLength + 'px';
}

function decreaseFieldWidth(id, requiredLength){
  if($(id) != null)
        $(id).style.width = requiredLength + 'px';
}

function increaseFieldSize(id, requiredLength){
    if($(id) != null)
        $(id).size = requiredLength;
}

function decreaseFieldSize(id, requiredLength){
    if($(id) != null)
        $(id).size = requiredLength;
}

// This finds out the elements from 'arrayA' which are not in 'arrayB'
// set A('arrayA') - set B('arrayB')
// 'arrayA' is like a Master List and 'arrayB' is like a given List of item
function arrayElementsWithoutElementsFromAnotherArray(arrayA, arrayB) {
    var normalizedArrayA = [];
    var arrayALength = arrayA.length;
    var arrayBLength = arrayB.length;
    var elementOfAFoundInB;
    if (arrayALength > 0) {
        if(arrayBLength > 0) {
            for(i = 0; i < arrayALength; i++) {
                elementOfAFoundInB = false;
                for(j = 0; j < arrayBLength; j++) {
                    if(arrayA[i] == arrayB[j]) {
                        elementOfAFoundInB = true;
                        break;
                    }
                    else {
                        elementOfAFoundInB = false;
                    }
                }
                if(!elementOfAFoundInB) {
                    normalizedArrayA.push(arrayA[i]);
                }
            }
        }
        else {
            normalizedArrayA = arrayA;
        }
    }
    return normalizedArrayA;
}

// This finds out the elements from 'arrayA' which are found in 'arrayB'
// set A('arrayA') intersection set B('arrayB')
// 'arrayA' is like a Master List and 'arrayB' is like a given List of item
function arrayElementsFoundInAnotherArray(arrayA, arrayB) {
    var normalizedArrayA = [];
    var arrayALength = arrayA.length;
    var arrayBLength = arrayB.length;
    var elementOfAFoundInB;
    if (arrayALength > 0 && arrayBLength > 0) {
        for(i = 0; i < arrayBLength; i++) {
            elementOfAFoundInB = false;
            for(j = 0; j < arrayALength; j++) {
                if(arrayB[i] == arrayA[j]) {
                    elementOfAFoundInB = true;
                    break;
                }
                else {
                    elementOfAFoundInB = false;
                }
            }
            if(elementOfAFoundInB) {
                normalizedArrayA.push(arrayA[j]);
            }
        }
    }
    return normalizedArrayA;
}

// The function 'insertToArray' takse an array and a value as inputs.
// If the value is not blank, the value is inserted to the array and returns the array
function insertToArray(array, value){
    if(value != ""){
        array.push(value);
    }
    return array;
}

// This finds out the elements from 'arrayB' which are not in 'arrayA'
// set B('arrayB') - set  A('arrayA')
// 'arrayA' is like a Master List and 'arrayB' is like a given List of item
function compareTwoArrays(arrayA, arrayB) {
    var invalidElements = [];
    var count;
    var element;
    var indexOfElement;
    for(count = 0; count < arrayB.length; count++) {
        element = arrayB[count].strip();
        indexOfElement = arrayA.indexOf(element);
        if(indexOfElement == -1) {
            invalidElements.push(element);
        }
    }
    return invalidElements;
}

// Find any element of B in A
function findAnyElement(arrayA, arrayB) {
    var elementFound = false;
    var count;
    var element;
    var indexOfElement;
    for(count = 0; count < arrayB.length; count++) {
        element = arrayB[count].strip();
        indexOfElement = arrayA.indexOf(element);
        if(indexOfElement != -1) {
            elementFound = true;
            break;
        }
    }
    return elementFound;
}

function sanitizeArray(array) {
    array = array.flatten();
    array = array.without("");
    array = array.uniq();
    return array;
}

// This function opens a popup window when the admin incompletes a job
function callPopUpIncomplete(page, back_page) {
    var sJobIds = ""
    if(page == '')
        page = "1";
    for(i=0; i<document.forms[1].elements.length;i++) {
        if(document.forms[1].elements[i].type == "checkbox" && document.forms[1].elements[i].checked) {
            sControlName = document.forms[1].elements[i].name;
            if(sControlName.split("jobs_to_allocate").length > 1) {

                sjobIdValue = sControlName.split("jobs_to_allocate[")[1].toString();
                sJobIds = sJobIds + "," + sjobIdValue.slice(0, sjobIdValue.length - 1);

            }

        }

    }
    jobIds = sJobIds.slice(1, sJobIds.length)
    if(jobIds.length == 0){
        alert("Please select the job required to be incompleted");
    }
    else{
        window.open(relative_url_root() + "/admin/job/incomplete?jobs="+jobIds+"&page="+page+"&back_page="+back_page,'mywindow','width=500,height=400')
    }
}
//refreshes the parent window after closing popup
function refresh_parent(batchID, page, back_page){
    window.close();
    url = relative_url_root() + "/admin/job/allocate/"+batchID+"?page="+page+"&back_page="+back_page;
    window.opener.location.href = url;
}

// An 'array' is inserted with an 'element' in the positions
// specified from 'fromLength' & 'toLength'.
function arrayInsertionForAParticlularLength(array, element, fromLength, toLength) {
    for(i = fromLength; i < toLength; i++) {
        array[i] = element;
    }
    return array;
}

// Set the class name of the fields with a validation method
// 'itemIds' is an array which contain the ids of all fields which are to be validated.
// 'validation' is the validation method to be given as a string.
function setFieldsValidateAgainstCustomMethod(itemIds, validation){
    var validated = true;
    var item;
    var count;
    var class_names;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count];
        if($(item) != null){
            class_names = $(item).className.split(' ');
            for(i = 0; i < class_names.length; i++){
                if(class_names[i] != validation){
                    validated = false;
                }
                else validated = true;
            }
            if(validated == false){
                class_names.push(validation);
            }
            $(item).className = class_names.join(' ');
        }
    }
}

// Remove the class name of the fields with a validation method
// 'itemIds' is an array which contain the ids of all fields whose
//  validations are to be removed.
// 'validation' is the validation method to be given as a string.
function removeCustomValidations(itemIds, validation) {
    var item;
    var count;
    var class_names;
    var class_length;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count]
        if($(item) != null) {
            class_length = $(item).className.length
            if (class_length > 0){
                class_names = $(item).className.split(' ')
                for(i = 0; i < class_names.length; i++){
                    if(class_names[i] == validation){
                        class_names[i] = ""
                    }
                }
                $(item).className = class_names.join(' ')
            }
            else{
                $(item).className = ""
            }
        }
    }
}

function bypass_micr_validation(){
    check_num_int = parseInt($F('job_check_number'))
    check_amount_int = parseInt($F('check_information_check_amount'))
    if (check_num_int == 0 && check_amount_int == 0){
        itemIds = ['micr_line_information_payer_account_number', 'micr_line_information_aba_routing_number']
        removeCustomValidations(itemIds, 'required')
    }
}
function negativeValidationForcheckAmount(){
    check_amount = $F('check_information_check_amount')
    if(check_amount < 0){
        alert ("The Check / EFT amount should always be a positive number. Please enter the correct value.");
        setTimeout(function() {
            $('check_information_check_amount').focus();
        }, 10);
        return false;
    }
    else{
        return true;
    }
}

// This validates the mandatory fields.
// The mandatory fields are those with className as 'requied'.
// The mandatory fields which are blank are caught and an alert is provided to
//  enter them to continue with the process.
// Input :
// itemIds : Id of the mandatory fields.
// Output :
// proceed : true if passed the validation else false.
function validatePresenceOfRequiredFields(itemIds) {
    var found, proceed = false;
    var item;
    var count;
    var class_names;
    var i;
    var emptyFieldIds = [];
    var emptyFieldNames = [];
    var itemName;
    for (count = 0; count < itemIds.length; count++) {
        item = itemIds[count];
        if($(item)) {
            found = false;
            class_names = $(item).className.split(' ');
            for(i = 0; i < class_names.length; i++) {
                if(class_names[i].capitalize() == 'Required') {
                    found = true;
                }
            }
            if(found == true) {
                var itemValue = ($F(item)).strip();
                if(itemValue == '' || (item == 'checkdate_id' && itemValue == "mm/dd/yy")) {
                    if(item == 'payer_popup')
                        item = 'payer_name';
                    itemName = item.gsub('_', ' ').capitalize();
                    if(itemName.endsWith('id'))
                        itemName = itemName.gsub(' id', '');
                    emptyFieldNames.push(itemName);
                    emptyFieldIds.push(item);
                }
            }
            else proceed = true;
        }
    }
    if(emptyFieldNames.length > 0) {
        alert("Please enter the following fields and proceed. \n\
        " + emptyFieldNames);
        $(emptyFieldIds[0]).focus();
        proceed = false;
    }
    return proceed;
}

// This validates a Zip Code.
// Input :
// fieldId : Id of the Zip Code field.
// Output :
// validation : true if passed the validation else false.
function validateZipCode(fieldId) {
    var validation = true;
    if($(fieldId) != null) {
        if (!($F(fieldId).match(/(^\d{5}$)|(^\d{9}$)/))) {
            validation = false;
            alert("Please enter the correct Zip Code having 5 or 9 digits");
            $(fieldId).focus();
        }
    }
    return validation;
}

// This makes the text fields readonly when their content is not blank.
// Also, it sets the background color to grey.
// Input :
// itemIds : Array of the IDs of the text fields.
function makeTextFieldsReadOnly(itemIds) {
    var item;
    var count;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count];
        if($(item) != null) {
            if($F(item).strip().length > 0) {
                $(item).readOnly = true;
                $(item).style.backgroundColor = '#A9A9A9';
            }
            else {
                $(item).readOnly = false;
                $(item).style.backgroundColor = '#FFFFFF';
            }
        }
    }
}

// This makes the text fields readonly when their content is not blank.
// Also, it sets the background color to grey.
// Input :
// itemIds : Array of the IDs of the text fields.
function makeTextFieldsReadOnlyIrrespectiveOfContent(itemIds) {
    var item;
    var count;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count];
        if($(item) != null) {
            $(item).readOnly = true;
            $(item).style.backgroundColor = '#A9A9A9';
        }
    }
}

// This unmakes the text fields readonly.
// Also, it sets the background color to white.
// Input :
// itemIds : Array of the IDs of the text fields.
function unmakeTextFieldsReadOnly(itemIds) {
    var item;
    var count;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count];
        if($(item) != null) {
            $(item).readOnly = false;
            $(item).style.backgroundColor = '#FFFFFF';
        }
    }
}

// This validates for required fields
// Input :
// itemIds : Array of the IDs of the mandatory fields.
// Output :
// validation : true if passed the validation else false.
function validateRequiredFields(itemIds) {
    var item;
    var count;
    var validate = true;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count];
        if($(item) != null) {
            if(($F(item)).strip() == '') {
                validate = false;
            }
        }
    }
    return validate;
}

// This verifies fields to contain a value that satisfies the 'condition'.
// Input :
// itemIds : Array of the IDs of the mandatory fields.
// condition : condition that the value has to satisfy.
// Output :
// validation : true if passed the validation else false.
function verifyRegexPrecondition(itemIds, condition) {
    var item;
    var count;
    var validate = true;
    for (count = 0; count < itemIds.length; count++){
        item = itemIds[count];
        if($(item) != null) {
            if($F(item).match(condition) == null || $F(item).match(condition) == false) {
                validate = false;
            }
        }
    }
    return validate;
}

function getFacilityByClientForPayerRelatedData(clientFieldObj, span_id) {
    jQuery.noConflict();
    if(span_id == 'facility_span') {
        method = 'get_facility_for_output_payid_and_onbase_name';
    }
    else if(span_id == 'facility_span_of_payment_or_allowance_code') {
        method = 'get_facility_for_payment_and_allowance_code';
    }

    var client_id = clientFieldObj.value;
    url = relative_url_root() +  '/admin/payer/' + method;
    if (client_id != '')
    {
        $(span_id).innerHTML = 'Loading.. ';
        new Ajax.Request(url, {
            parameters: {
                id: client_id,
                method: 'get'
            },
            onComplete: function (method) {
                $(span_id).innerHTML = method.responseText;
            }
        });
    }
    else {
        $(span_id).innerHTML = '';
    }
    return false;
}

function getFacilityByClient(url,obj, name)
{
    client_id = obj.value;
    if(url!=""){
        url = "/" + url;
    }
    if (client_id != '')
    {
        url = relative_url_root() +  '/admin/payer/get_facility'
        new Ajax.Request(url, {
            parameters: {
                id: client_id,
                name: name,
                method: 'get'
            }
        });
    }
    return false;
}

function getFacilitiesByClientForAlert(client_id, span_id)
{
    jQuery.noConflict();
    url = relative_url_root() +  '/admin/pop_up/get_facilities_by_client'
    if (client_id != '')
    {
        $(span_id).innerHTML = 'Loading.. ';
        new Ajax.Request(url, {
            parameters: {
                id: client_id,
                method: 'get'
            },
            onComplete: function (method) {
                $(span_id).innerHTML = method.responseText
            }
        });
    }
    else {
        $(span_id).innerHTML = '';
    }
    return false;
}

function validateAlertData(){
    var validationsResult = false;
    validationsResult = (validateComment() && validateFieldName() &&
        validateQuestion());
    if(validationsResult)
        return true;
    else
        return false;
}

function validateQuestion()
{
    var result = true;
    question = $F('question_id');
    choice1 = $F('choice1_id');
    choice2 = $F('choice2_id');
    choice3 = $F('choice3_id');
    answer = $F('answer_id');
    if(question == '' && choice1 == '' && choice2 == '' && choice3 == '' && answer == '')
        result = true;
    else{
        if(question != '' && choice1 != '' && choice2 != '' && choice3 != '' && answer != '')
            result = true;
        else{
            if(question == '')
                id = 'question_id'
            else if(choice1 == '')
                id = 'choice1_id'
            else if(choice2 == '')
                id = 'choice2_id'
            else if(choice3 == '')
                id = 'choice3_id'
            else if(answer == '')
                id = 'answer_id'
            alert("Please Enter a question with 3 choices and answer!");
            setTimeout(function() {
                document.getElementById(id).focus();
            }, 10);
            result = false;
        }
    }
    return result;
}

function validateComment()
{
    var result = true;
    comment = $F('comment_id');
    if(comment != '')
        result = true;
    else{
        alert("Please Enter Comment");
        setTimeout(function() {
            document.getElementById('comment_id').focus();
        }, 10);
        result = false;
    }
    return result;
}

function validateFieldName()
{
    var result = true;
    field_name = $F('field_name_id');
    if(field_name != '')
        result = true;
    else{
        alert("Please Select Field Name");
        setTimeout(function() {
            document.getElementById('field_name_id').focus();
        }, 10);
        result = false;
    }
    return result;
}

var validHipaaAndUniqueCodes = '';
function setValidUniqueCodes(values){
    console_logger('setValidUniqueCodes', 'setValidUniqueCodes')
    if(values != null) {
        validHipaaAndUniqueCodes = values;
    }
}

//This is for validationg Reason Code.
//Valid  data contain Alphabets, Numeric, Hyphen, Peroid and Underscore only.
// It won't allow consecutive valid special characters.
function validateReasonCode(id){
    var data = $F(id);
    if(data.match(/^[A-Za-z0-9\-\.\_]*$/) && data.match(/\.{2}|\_{2}|\-{2}|^[\-\.\_]+$/) == null){
        return true;
    }
    else{
        alert("Invalid Reason Code - Required alphabet, numeric, hyphen, underscore and period only.");
        $(id).value = "";
        setTimeout(function() {
            document.getElementById(id).focus();
        }, 10);
        return false;
    }
}

// This is for validating Patient Name(first and last) and
// account number(Provider adjustment section in DC grid, Default Acc# in FC ui
// and account number in Balance Record Tab) for BAC.
// Valid  data contain Alphabets, Numeric, Hyphen and Peroid only.
// It won't allow consecutive occurrence of valid special characters.
function validateData(id, name, noAlert){
    var data = $F(id);
    if(data.match(/^[A-Za-z0-9\-\.]*$/) &&
        data.match(/\.{2}|\-{2}|^[\-\.]+$|^\s+$/) == null){
        return true;
    }
    else{
        if(noAlert == false) {
            if(name == "")
                alert("Required alphabet, numeric, hyphen and period only.");
            else
                alert(name + ": Required alphabet, numeric, hyphen and period only.");
        }
        setTimeout(function() {
            document.getElementById(id).focus();
        }, 10);
        return false;
    }
}

// Validate the State of Payer, Patient etc
// Input :
// fieldId : Id of the State field.
// Output :
// validation : true if passed the validation, else false.
function validateState(fieldId) {
    var required = false;
    var need_to_validate = false;
    var classNames = $(fieldId).className.split(' ');
    for( var i=0; i < classNames.length; i++){
        if (classNames[i] == 'required'){
            required = true;
            break;
        }
    }
    var fieldValue = $F(fieldId);
    if (required == true || fieldValue.strip() != '')
        need_to_validate = true
    if (need_to_validate){
        if (fieldValue.length != 2){
            alert("Invalid State");
            $(fieldId).focus();
            return false;
        }
        else{
            if(fieldValue.match(alphaExp))
                return true;
            else{
                alert("Invalid State");
                $(fieldId).value = "";
                $(fieldId).focus();
                return false;
            }
        }
    }
    else
        return true;
}

//Function to capitalize entries in text box
function changeToCapital(text_id){
    var captial_string = $F(text_id).toUpperCase();
    $(text_id).value = captial_string
}

function validate_presence_of(field_id, field_name){
    var isValid = true;
    if($F(field_id).strip() == ''){
        isValid = false;
        alert(field_name +' is mandatory');
        $(field_id).focus();
    }
    else
        isValid = true;
    return isValid;
}
function checkOrUncheckAll(checkboxes){
    for (i = 0; i < checkboxes.length; i++)
    {
        checkboxes[i].checked=!checkboxes[i].checked
    }
}

function displayRejectionComment(){
    if($('populate_default_values') != null) {
        if($F('populate_default_values') == 1) {
            if($('rejection_comment') != null)
                $('rejection_comment').style.display = "block";
        }
    }
}

// This is for validating Patient account number for non bank.
// Valid  data contain Alphabets, Numeric, Hyphen, Peroid and forward slash only.
// It won't allow consecutive occurrence of valid special characters.
// This is reused in Parivider Adjustment section in DC grid, Def Acc # in FC ui
// and Acc number in Balance Record Config Tab.
// Max no: of forward slahes = 3
function validateAlphanumericHyphenPeriodForwardSlash(id){
    var data = $F(id);
    var invalidAccNo = /^((\.\/\-|\-\/\.|\.\-\/|\-\.\/|\/\.\-|\/\-\.|\-\.|\.\-|\-\/|\/\-|\/\.|\.\/)[A-Za-z0-9\-\.\/]*)|([A-Za-z0-9\-\.\/]*(\.\/\-|\-\/\.|\.\-\/|\-\.\/|\/\.\-|\/\-\.|\-\.|\.\-|\-\/|\/\-|\/\.|\.\/))|([A-Za-z0-9\-\.\/]*(\.\/\-|\-\/\.|\.\-\/|\-\.\/|\/\.\-|\/\-\.|\-\.|\.\-|\-\/|\/\-|\/\.|\.\/)[A-Za-z0-9\-\.\/]*)$/
    var result = true;
    var messageForInvalidAccountNumber = "Not allowed consecutive special characters!";
    var messageForInvalidCharacter = "Required alphabet, numeric, hyphen, period and forward slash only";
    var messageForSpecialCharacterLimit = "Not allowed more than two hyphens or periods or forward slashes!";

    if(data.match(/^[A-Za-z0-9\-\.\/]*$/)){
        if(data.match(/\.{2}|\-{2}|\/{2}|^[\-\.\/]+$|^\s+$/) == null && data.match(invalidAccNo) == null){
            if (data.match(/\//g) != null && (data.match(/\//g).length > 2) ){
                alert(messageForSpecialCharacterLimit);
                result = false;
            }
            else if(data.match(/\./g) != null && (data.match(/\./g).length > 2)){
                alert(messageForSpecialCharacterLimit);
                result = false;
            }
            else if(data.match(/\-/g) != null && (data.match(/\-/g).length > 2)){
                alert(messageForSpecialCharacterLimit);
                result = false;
            }
        }
        else{
            alert(messageForInvalidAccountNumber);
            result = false;
        }
    }
    else{
        alert(messageForInvalidCharacter);
        result = false;
    }

    if (result == false){
        setTimeout(function() {
            document.getElementById(id).focus();
        }, 10);
    }
    return result;
}

//This function is for setting default patient account number for sitecode = 896.
//If payid is P1873, then Pat Acc# will be "0000000"(7 zeroes).
// For other payers , it wil be "000000000"(9 zeroes).
//This will invoke on double click of Patient Acc#.
function defaultPatientAccountNumber(defaultFcAccountNumber){
    var defaultFcAccNo = $F(defaultFcAccountNumber);
    var payid = $('payer_payid');
    var sitecode = $('sitecode');
    //  sitecode = sitecode.replace(/^[0]+/,'')//sitecode after trimming left padded zeroes
    if(sitecode != null && sitecode.value == "896" ){
        if(payid != null && payid.value != ''){
            if(payid == "P1873")
                $('patient_account_id').value = "0000000";
            else
                $('patient_account_id').value = "000000000";
        }
        return true;
    }
    else{
        if(defaultFcAccNo != ""){
            var agree = confirm("Do you Want to populate Default Account Number: "+defaultFcAccNo+"?");
            if (agree == true){
                $('patient_account_id').value = defaultFcAccNo;
                return true;
            }
            else{
                setTimeout(function() {
                    document.getElementById('patient_account_id').focus();
                }, 20);
                return false;
            }
        }
        else
            return true;
    }
}

function setFCDefaultPatNameForNextgen(fid, id){
    var fval = $(fid).value
    if (fval == null || fval == "")
        return true;
    else{
        if (fval != 'Payer Name'){
            var agree = confirm("Do you Want to populate Default Patient Name?");
            if (agree == true){
                var patientName = fval.toUpperCase();
                patientName = patientName.split(",");
                if (patientName.size() > 1) {
                    $('patient_last_name_id').value = patientName[0];
                    $('patient_first_name_id').value = patientName[1];
                } else {
                    $('patient_last_name_id').value = patientName[1];
                }
                return true;
            }
            else{
                setTimeout(function() {
                    document.getElementById(id).focus();
                }, 20);
                return false;
            }
        }
        else
            return true;
    }
}

// This is for validating Patient Name(first and last) in
// FCUI Balance Record Tab and Image Type Tab in Grid).
// Valid data contain Alphabets, Numeric, Hyphen, Space and Peroid only for NBAC
// if patient_name_format_validation is checked in FCUI.
// It won't allow consecutive occurrence of valid special characters.
function validatePatientNameField(id, format_validn_flag, noAlert){
    var data = $F(id);
    var result = true;
    
    if((format_validn_flag == true)){
        if((data.match(/^[A-Za-z0-9\-\s\.]*$/)) &&
            (data.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) == null))
            result = true;
        else{
            if(noAlert != false) {
                alert("Required alphanumeric, hyphen, space or period only");
            }
            result = false;
        }
    }
    else{
        result = true;
    }
    if (result == false){
        setTimeout(function() {
            document.getElementById(id).focus();
        }, 10);
    }
    return result;
}

function validateAlphaNumeric(id, needAlert){
    var data = $F(id);
    if(data.match(/^[A-Za-z0-9]*$/))
        return true
    else{
        if(needAlert != false)
            alert("Required alphanumeric only!");
        setTimeout(function() {
            document.getElementById(id).focus();
        }, 40);
        return false;
    }
}

//This method is for getting image page no when tabout from patient_account_number
//field and onclick of save eob button - in NextGen Patpay grid
function getNextgenImagePage(){
    if($('nextgen_image_page_number') != null) {
        var imagePageNo = (parent.document.getElementById("viewONE").getPage());
        if(imagePageNo.isNaN)
            imagePageNo = (document.getElementById("viewONE").getPage());
        $('nextgen_image_page_number').value = parseInt(imagePageNo);
    }
}

function enableMicrFields(){
    document.getElementById("job_aba_routing_number_id").disabled = false;
    document.getElementById("job_payer_account_number_id").disabled = false
}

function isMicrFormatValid(micrId) {
    var isMicrFormatValid = true;
    if($(micrId) != null) {
        var micrData = $F(micrId).strip();
        isMicrFormatValid = (micrData != '' && micrData.match(/^[\w]+$/) != null &&
            micrData.match(/[^0]/) != null);
    }
    return isMicrFormatValid;
}

function validateMicrData(abaId, payerAccId, checkNumberValue, isMicrConfigured){
    var isMicrValid = true;
    var abaValue = $F(abaId);
    var payerAccValue = $F(payerAccId);
    
    if(validCorrCheckNumber(checkNumberValue)){
        if(abaValue != "" || payerAccValue != ""){
            alert("Correspondence transactions should not have micr details");
            if (abaValue != "")
                setTimeout(function() {
                    document.getElementById(abaId).focus();
                }, 20);
            else if(payerAccValue != "")
                setTimeout(function() {
                    document.getElementById(payerAccId).focus();
                }, 20);
            isMicrValid = false;
        }
    }
    else if(isMicrConfigured == true && !validCorrCheckNumber(checkNumberValue)){
        if(abaValue == "" || payerAccValue == ""){
            
            if (abaValue == ""){
                alert("Required ABA routing number");
                setTimeout(function() {
                    document.getElementById(abaId).focus();
                }, 20);
            }
            else if (payerAccValue == ""){
                alert("Required Payer Account number");
                setTimeout(function() {
                    document.getElementById(payerAccId).focus();
                }, 20);
            }
            isMicrValid = false;
        }
        else{
            isMicrValid = isAbaValid(abaId, isMicrConfigured, checkNumberValue);
            if(isMicrValid == true)
                isMicrValid = isPayerAccNumValid(payerAccId, isMicrConfigured, checkNumberValue);
        }
    }
    return isMicrValid;
}

function enableMicrEdit(eobCount){
    var enableMicrEdit = true;
    if(parseInt(eobCount) > 0){
        enableMicrEdit = false;
        alert("One or more EOBs are processed in this job, Please delete those to continue with this edit");
    }
    else{
        enableMicrEdit = false;
        enableMicrFields();
    }
    return enableMicrEdit;
}
function disableButton(button_id) {
    if($(button_id) != null)
        $(button_id).hidden = true;
}

function validCorrCheckNumber(checkNumber) {
    if((parseInt(checkNumber, 10) == 0) && (checkNumber.match(/[^0]/) == null))
        return true;
    else
        return false;
}

function dragAndDropTable(tableId) {
    var table = $(tableId);
    var tableDnD = new TableDnD();
    tableDnD.init(table);
}
function isAbaLengthValid(abaId){
    var isAbaLengthValid = true;
    var abaValue = $F(abaId);
    if(abaValue != ''){
        if(abaValue.match(/(^\d{9}$)/)){
            isAbaLengthValid = true;
        }
        else{
            isAbaLengthValid = false;
        }
    }
    return isAbaLengthValid;
}

function isPayerAccNumLengthValid(payerAccId){
    var isPayerAccNumLengthValid = true;
    var payerAccValue = $F(payerAccId);
    var payerAccValueLength = payerAccValue.length;
    var minLength = 3;
    var maxLength = 15;
    if(payerAccValue != ''){
        if(!isNaN(payerAccValue) && payerAccValueLength >= minLength && payerAccValueLength <= maxLength){
            isPayerAccNumLengthValid = true;
        }
        else{
            isPayerAccNumLengthValid = false;
        }
    }
    return isPayerAccNumLengthValid;
}

function isAbaValid(abaId, isMicrConfigured, checkNumberValue){
    var isAbaValid = true;
    if($(abaId) != null) {
        var abaValue = $F(abaId);
        if(abaValue != ''){
            if((checkNumberValue == '') || (isMicrConfigured == '') || (isMicrConfigured == true && checkNumberValue != '' && !validCorrCheckNumber(checkNumberValue))){
                if(isMicrFormatValid(abaId) && isAbaLengthValid(abaId)){
                    isAbaValid = true;
                }
                else{
                    alert("Required 9 digit numeric only and cannot consist of all zeroes");
                    setTimeout(function() {
                        document.getElementById(abaId).focus();
                    }, 20);
                    isAbaValid = false;
                }
            }
        }
    }
    return isAbaValid;
}

function isPayerAccNumValid(payerAccId, isMicrConfigured, checkNumberValue){
    var isPayerAccValid = true;
    if($(payerAccId) != null) {
        var payerAccValue = $F(payerAccId);
        if(payerAccValue != ''){
            if((checkNumberValue == '') || (isMicrConfigured == '') || (isMicrConfigured == true && checkNumberValue != '' && !validCorrCheckNumber(checkNumberValue))){
                if(isMicrFormatValid(payerAccId) && isPayerAccNumLengthValid(payerAccId)){
                    isPayerAccValid = true;
                }
                else{
                    alert("Required 3-15 digit numeric only and cannot consist of all zeroes");
                    setTimeout(function() {
                        document.getElementById(payerAccId).focus();
                    }, 20);
                    isPayerAccValid = false;
                }
            }
        }
    }
    return isPayerAccValid;
}

function removeByValue(arr, val) {
    for(var i=0; i<arr.length; i++) {
        if(arr[i] == val) {
            arr.splice(i, 1);
            break;
        }
    }
    return arr;
}

function validateNumericality(id){
    var value = $F(id);
    var result = true;
    if(value != '' && value.match(/[^\d]/) != null){
        alert("Required numeric only");
        setTimeout(function() {
            $(id).focus();
        }, 20);
        result = false;
    }
    return result;
}

function showQaEdit(eob_id) {
    var eob_type;
    if($('eob_type') != null)
        eob_type = $F('eob_type');
    url = relative_url_root() + "/qa_edits/list?" + "eob_id=" + eob_id + "&eob_type=" + eob_type
    window.open(url, "qa_edits", "top=100,left=50,width=1600,height=300,toolbar=0,statusbar=0,menubar=0,resizable=1,scrollbars=yes");
}

function hideRCGrid() {
    $('reason_code_grid_container').toggle();
}

function showRCGrid() {
    /*  if($('reason_code_grid_container').style.display == "none"){
        display_footnote_payer_alert($('is_footnote_payer_id').value);
    }
    $('reason_code_grid_container').toggle(); */
    if (rcode_window.isVisible())
    {
        rcode_window.hide();
    }else{
        rcode_window.show();
        setTimeout(function() {
            document.getElementById('reason_code_reason_code').focus();
        }, 100);
    }
}

function messageForGenerateOutputButton(){
    alert('This is the Beta version of new Output generation module. It is undergoing testing. In case the output generated is not correct use the “Generate Output” option');
}

// Validate the presence of payer name, Payer Id, Eobs Per Image and its address fields
function validatePayerDetails(stringOfIdsOfPayerDetails) {
    var resultOfValidation = true;
    if(stringOfIdsOfPayerDetails != "")
        var idsOfPayerDetails = stringOfIdsOfPayerDetails.split(',');
    var payerId = idsOfPayerDetails[0];
    var payerName = idsOfPayerDetails[1];
    var eobsPerImage = idsOfPayerDetails[6];
    var payerStatus;

    if(window.frames['myiframe']) {
        payerName = window.frames['myiframe'].document.getElementById(payerName);
        payerStatus = window.frames['myiframe'].document.getElementById('payer_status');
    }
    else{
        payerName = document.getElementById(payerName);
        payerStatus = document.getElementById('payer_status');
    }

    if(payerId != '' && $(payerId) != null && $F(payerId) == ''){
        alert("Payer Id cannot be blank!");
        setTimeout(function() {
            $(payerId).focus();
        }, 50);
        resultOfValidation = false;
    }
    else if (payerName != null && payerName.value.strip() == ''){
        alert("Payer name cannot be blank!");
        setTimeout(function() {
            payerName.focus();
        }, 50);
        resultOfValidation = false;
    }
    else if(eobsPerImage != '' && $(eobsPerImage) != null && $F(eobsPerImage).strip() == ''){
        alert("EOBs Per Image cannot be blank!");
        setTimeout(function() {
            $(eobsPerImage).focus();
        }, 50);
        resultOfValidation = false;
    }
    else{
        if(payerStatus != null) {
            var payerStatusValue = payerStatus.value.toUpperCase();
            if(payerStatusValue != 'MAPPED') {
                var addressFields = [idsOfPayerDetails[2], idsOfPayerDetails[3], idsOfPayerDetails[4], idsOfPayerDetails[5]]
                if($('is_partner_bac') != null && $F('is_partner_bac') == "true") {
                    resultOfValidation = validatePresenceOfAllOrNoPayerAddressFields(addressFields);
                }
                else
                    resultOfValidation = validatePresenceOfAllPayerAddressFields(addressFields);
            }
        }
    }
    //    console_logger(resultOfValidation, 'validatePayerDetails');
    return resultOfValidation;
}

function validatePresenceOfAllPayerAddressFields(addressFields){
    var resultOfValidation = true;
    var blankAddressFields = [];
    var blankAddressFieldNames = [];
    var field;
    if(addressFields != null) {
        for(i = 0; i < addressFields.length; i++) {
            if(window.frames['myiframe']) {
                field = window.frames['myiframe'].document.getElementById(addressFields[i]);
            }
            else{
                field = document.getElementById(addressFields[i]);
            }

            if(field != null) {
                if(field.value.strip() == '' && field.value.readOnly != true) {
                    var splitted_field = addressFields[i].split('_');
                    if(addressFields[i] == 'payer_city_id' ||
                        addressFields[i] == 'payer_payer_state' ||
                        addressFields[i] == 'payer_zipcode_id'){
                        splitted_field[2] = "";
                    }
                    splitted_field = sanitizeArray(splitted_field);
                    splitted_field = splitted_field.join(' ');
                    if(splitted_field == "payer pay address one")
                        splitted_field = "Payer address one";
                    blankAddressFieldNames.push(splitted_field.capitalize());
                    blankAddressFields.push(addressFields[i]);
                }
            }
        }
    }
    if(blankAddressFields.length > 0) {
        resultOfValidation = false;
        alert('Please Enter the following fields : ' + blankAddressFieldNames);

        if(window.frames['myiframe']) {
            field = window.frames['myiframe'].document.getElementById(blankAddressFields.first());
        }
        else{
            field = document.getElementById(blankAddressFields.first());
        }
        field.focus();
    }
    else
        resultOfValidation = true;
    return resultOfValidation;
}



// If any of the address field is partially entered, then all the address fields should be entered
function validatePresenceOfAllOrNoPayerAddressFields(addressFields) {
    var resultOfValidation = true;
    if(addressFields != null) {
        var blankAddressFields = [];
        var blankAddressFieldNames = [];
        var lengthOfAddressFields = addressFields.length;
        for(i = 0; i < lengthOfAddressFields; i++) {
            if($(addressFields[i]) != null) {
                if($F(addressFields[i]).strip() == '' && $(addressFields[i]).readOnly != true) {
                    var splits = addressFields[i].split('_');
                    splits[0] = "";
                    blankAddressFieldNames.push(splits.join(' '));
                    blankAddressFields.push(addressFields[i]);
                }
            }
        }
        var lengthOfBlankAddressFields = blankAddressFields.length;
        if(lengthOfBlankAddressFields > 0 && lengthOfBlankAddressFields != lengthOfAddressFields) {
            resultOfValidation = false;
            alert("Please enter the full address or leave all the address fields blank: " +
                blankAddressFieldNames);
            $(blankAddressFields.first()).focus();
        }
    }
    return resultOfValidation;
}

// Highlights the fields with a color.
// 'item_ids' is an array which contain the ids of all fields whose
//  fields are to be colored.
// 'color' is the color with which 'item_ids' are to be colored.
function setHighlight(item_ids, color){
    var item;
    var count;
    var class_names;
    for (count = 0; count < item_ids.length; count++){
        item = item_ids[count];
        if($(item)){
            class_names = $(item).className.split(' ');
            for(i = 0; i < class_names.length; i++){
                if( class_names[i] == "blank" ||
                    class_names[i] == "edited" ||
                    class_names[i] == "certain" ||
                    class_names[i] == "uncertain" ||
                    class_names[i] == "normalized_uncertain" ||
                    class_names[i] == "blue-color") {

                    class_names[i] = ""
                }
            }
            class_names = sanitizeArray(class_names);
            class_names.push(color);
            $(item).className = class_names.join(' ');
        }
    }
}

