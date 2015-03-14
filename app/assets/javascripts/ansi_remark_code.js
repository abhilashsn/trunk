var count1 = 0;
var count2 = 0;

function insertOptionBefore3(num)
{
    var value3= $('ansi_code').value;
    var elOptNew = document.createElement('option');
    elOptNew.text = value3;
    elOptNew.value = value3;
    var elSel = $('ansi_remark_codes');

    try {
        elSel.add(elOptNew, null); // standards compliant; doesn't work in IE
        $('ansi_code').value = "";
    }
    catch(ex) {
        elSel.add(elOptNew); // IE only
        $('ansi_code').value = "";
    }

}

function removeOptionSelected3()
{
    var elSel = $('ansi_remark_codes');
    var i;
    for (i = elSel.length - 1; i>=0; i--) {
        if (elSel.options[i].selected) {
            elSel.remove(i);
        }
    }
}

function getTheOptionalValues()
{
    var options_chosen = new Array;
    for (i=0;i<$('ansi_remark_codes').options.length;i++)
    {
        options_chosen[i] = $('ansi_remark_codes').options[i].value;

    }
    $('optional_ansi_remark_codes').value = options_chosen;
}

function toggleVisibility() {
    $("toggleMe").style.display = "";
    if($("toggleMe").style.visibility == "hidden" ) {
        $("toggleMe").style.visibility = "visible";
    }
    else {
        $("toggleMe").style.visibility = "hidden";
    }
}
function toggleDisplay() {
    $("toggleMe").style.visibility = "visible";
    if($("toggleMe").style.display == "none" ) {
        $("toggleMe").style.display = "";
    }
    else {
        $("toggleMe").style.display = "none";
    }
}

function getTheReasoncode() {
    if ($("reason_code").value == "")
    {
        alert("Reason code is mandatory");
        return false
    }
    else if ($('reason_code').value.match(/^\s+$/))
    {
        alert("Reason code is mandatory");
        return false;
    }
    else
        return true
}

function getgroupcode(){
    if ($('group_code').value == 'Select'){
        alert("Select any of the Hippa Group Code");
        return false
    }
    else
        return true;
}

function toggleEditForReasonCode() {
    if($('reason_code') != null && $('reason_code_description') != null &&
        $('existing_code') != null && $('existing_description') != null) {
        if($('reason_code').readOnly == true || $('reason_code').readOnly == 'readonly') {
            $('reason_code').value = $F('existing_code');
            $('reason_code').readOnly = false;
        }
        else {
            $('reason_code').value = $F('existing_code');
            $('reason_code').readOnly = true;
        }
        
        if($('reason_code_description').readOnly == true || $('reason_code_description').readOnly == 'readonly') {
            $('reason_code_description').value = $F('existing_description');
            $('reason_code_description').readOnly = false;
        }    
        else {
            $('reason_code_description').value = $F('existing_description');
            $('reason_code_description').readOnly = true;
        }            
    }
}