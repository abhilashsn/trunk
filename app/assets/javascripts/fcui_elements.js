function addOption(theSel, theText, theValue)
{
    var newOpt = new Option(theText, theValue);
    var selLength = theSel.length;
    theSel.options[selLength] = newOpt;
    theSel.options[selLength].selected = true
}


function move(list_box, text_area)
{
    var value = list_box.value;
    text_area.value += value;
    text_area.focus();
}

function enable_zip_ins_file_name()
{
    var checkBox = document.getElementById('details_insu_zip_output');
    if(checkBox.checked)
        $('zip_ins').show();
    else
        $('zip_ins').hide();
}

function enable_ins_folder_name()
{
    var checkBox = document.getElementById('details_insu_output_folder');
    if(checkBox.checked)
        $('folder_ins').show();
    else
        $('folder_ins').hide();
}

function enable_pat_folder_name()
{
    var checkBox = document.getElementById('details_pat_pay_output_folder');
    if(checkBox.checked)
        $('folder_patpay').show();
    else
        $('folder_patpay').hide();
}


function enable_zip_pat_file_name()
{
    var checkBox = document.getElementById('details_pat_pay_zip_output');
    if(checkBox.checked)
        $('zip_patpay').show();
    else
        $('zip_patpay').hide();
}

function enable_nextgen_zip_file_name()
{
    var checkBox = document.getElementById('details_pat_pay_zip_nextgen_output');
    if(checkBox.checked)
        $('zip_nextgen').show();
    else
        $('zip_nextgen').hide();
}

function enable_nextgen_folder_name()
{
    var checkBox = document.getElementById('details_pat_pay_nextgen_output_folder');
    if(checkBox.checked)
        $('folder_nextgen').show();
    else
        $('folder_nextgen').hide();
}

function deleteOption(theSel, theIndex)
{
    var selLength = theSel.length;
    if(selLength>0)
    {
        theSel.options[theIndex] = null;
    }
}

function moveOptions(theSelFrom, theSelTo)
{
    var selLength = theSelFrom.length;
    var selectedText = new Array();
    var selectedValues = new Array();
    var selectedCount = 0;

    var i;

    // Find the selected Options in reverse order
    // and delete them from the 'from' Select.
    for(i=selLength-1; i>=0; i--)
    {
        if(theSelFrom.options[i].selected)
        {
            selectedText[selectedCount] = theSelFrom.options[i].text;
            selectedValues[selectedCount] = theSelFrom.options[i].value;
            deleteOption(theSelFrom, i);
            selectedCount++;
        }
    }

    // Add the selected text/values in reverse order.
    // This will add the Options to the 'to' Select
    // in the same order as they were in the 'from' Select.
    for(i=selectedCount-1; i>=0; i--)
    {
        addOption(theSelTo, selectedText[i], selectedValues[i]);
    }
    if(selLength>1){
        for(i=0;i<selLength;i++)
            if(theSelFrom.options[i])
                theSelFrom.options[i].selected = true;
    }
    if(theSelTo.length>0){
        for(i=0;i<theSelTo.length;i++)
            if(theSelTo.options[i])
                theSelTo.options[i].selected = true
    }
    if(NS4) history.go(0);
}

function displayOPER(){
    var checkBox = document.getElementById('supple_Operation Log');
    if(checkBox.checked)
        document.getElementById('op_log').style.visibility="visible";
    else
        document.getElementById('op_log').style.visibility="hidden";
}

function codename() {

    if(document.formname.checkboxname.checked)
    {
        document.formname.textname.disabled=false;
    }

    else
    {
        document.formname.textname.disabled=true;
    }
}


function displayPAT(){
    document.getElementById('patpay2').style.display="block";
}


// function to enable patient pay ID text box with default value and also display
// patient payment processing section in output section when patient payer checkbox is checked
function displayPATPAY(){
    var checkbox_value= document.getElementById('facil_patient_payer');
    var radio_button = document.getElementById('details_pat_pay_isa_06_other')
    if(checkbox_value.checked){
        document.getElementById('facility_patient_payerid').value="P9998";
        document.getElementById('facility_patient_payerid').disabled=false;
        document.getElementById('patpay_div_id').style.display="block";
        if(radio_button.checked)
            document.getElementById('show_other_div_id1').style.visibility="visible";
        else
            document.getElementById('show_other_div_id1').style.visibility="hidden";
    }
    else{
        document.getElementById('facility_patient_payerid').value="";
        document.getElementById('facility_patient_payerid').disabled=true;
        document.getElementById('patpay_div_id').style.display="none";
        document.getElementById('patpay2').style.display="none";
        document.getElementById('show_other_div_id1').style.visibility="hidden";
    }
}

// function to enable commercial pay ID text box with default value
function displayCOMPAY(){
    var checkbox_value= document.getElementById('facil_commercial_payer');
    if(checkbox_value.checked){
        document.getElementById('facility_commercial_payerid').value="D9998";
        document.getElementById('facility_commercial_payerid').disabled=false;
    }
    else{
        document.getElementById('facility_commercial_payerid').value = "";
        document.getElementById('facility_commercial_payerid').disabled=true;
    }
}

function showMultipleSVLines() {
    if(document.getElementById('facility_patient_pay_format').value == "Simplified Format")
        document.getElementById('span_multiple_svline').style.visibility='visible'
    else
        document.getElementById('span_multiple_svline').style.visibility='hidden'
}

 


