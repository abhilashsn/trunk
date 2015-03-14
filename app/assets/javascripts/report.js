bshowAlert = false;
//This is for showing some user friendly messages while doing search.
function showUserMessages() {
    if ($F('to_find') == "" && bshowAlert) {
        switch($F('criteria')) {
            case "Arrival Date":
                document.getElementById("message1").innerHTML = "Please enter the arrival date in format 'dd/mm/yy' (E.g. 27/07/10)"
                break;
            case "Status":
                document.getElementById("message1").innerHTML = "Search options - 'Success','Failure'"
                break;
            case "Date":
                document.getElementById("message1").innerHTML = "Please enter the date in format 'mm/dd/yy' (E.g. 07/27/11)"
                break;
        }
        $('to_find').focus();
    }
    if(!bshowAlert) {
        bshowAlert = true;
        $('criteria').focus();
    }
}

//This is for clearing user message
function clearUserMessages() {
    document.getElementById("message1").innerHTML = ""
}

//This is for clearing Find field on change of criteria.
function clearFindField(){
    $('to_find').value = '';
}

//Search popup
function searchPopup(){
    var searchInput = document.getElementById("search_input").value;
    window.open("search?search_input="+searchInput,"popup","width=600,height=400,scrollbars=1");
}

function showUserMessagesOnJobAllocation(){
    if ($F('to_find') == "") {
        switch($F('criteria')) {
            case "Processor Status":
                document.getElementById("message1").innerHTML = "Search options - 'NEW', 'ALLOCATED', 'COMPLETED', 'INCOMPLETED'"
                break;
            case "QA Status":
                document.getElementById("message1").innerHTML = "Search options - 'NEW', 'ALLOCATED', 'PROCESSING', 'COMPLETED', 'INCOMPLETED', 'REJECTED'"
                break;
        }
        $('to_find').focus();
    }
}

function setSearchDetails(){
    var toFind = $('to_find');
    $('findBy').value = '';
    $('searchBy').value = '';
    $('compareBy').value = '';
    if(toFind != null && toFind.value != ''){
        var criteria = $F('criteria');
        var compare = $F('compare');
        $('findBy').value = toFind.value;
        $('searchBy').value = criteria;
        $('compareBy').value = compare;
    }
    return true;
}

function alertForProcessorStatus(){
var status_return = checkProcessingStatus() && checkProcessorStatus()
return status_return
}

function checkProcessingStatus(checkboxes){
   var checkboxes = document.getElementsByClassName('checkbox_processing')
    var count = 0
    var return_confirm = true
    for (i = 0; i < checkboxes.length; i++)
    {
    if(checkboxes[i].checked == true){
count++
    }
    }
    if(count >0){
        return_confirm =  confirm("Processor status is Allocated , are you sure to deallocate the selected jobs?")
    }
    return return_confirm
}

function checkProcessorStatus(checkboxes){
       var checkboxes = document.getElementsByClassName('checkbox_completed')

var count = 0
    var return_confirm = true
    for (i = 0; i < checkboxes.length; i++)
    {
    if(checkboxes[i].checked == true){
count++
    }
    }
    if(count >0){
        return_confirm =  confirm("Processor status is Completed , are you sure to deallocate the selected jobs?")
    }
    return return_confirm
}


   