// This file contains the validations written for date fields.

//Global variables that stores the details about the previous date field.
var prevDateValid = true;
var prevDateFieldId = null;

// This method clears the date fields with formats displayed
function removeDefaultDateValue(fieldId){
    if($(fieldId) != null) {
        if($(fieldId).value == "MM/DD/YY" || $(fieldId).value == "mm/dd/yy")
            $(fieldId).value = "";
    }
}

//Function to add default slashes in date field.
function addSlashToDate(fieldId) {
    if($(fieldId) != null) {
        var dateValue = $F(fieldId);
        if ((dateValue.indexOf("/")==-1) && (dateValue.length==6)){
            $(fieldId).value = dateValue.substring(0,2)+"/" + dateValue.substring(2,4) +
            "/" + dateValue.substring(4,6);
        }
        else if((dateValue.charAt(2)=="/") && (dateValue.charAt(5)!="/") &&
            ((dateValue.length==7) || (dateValue.length==5))){
            dateValue = dateValue.slice(0,2) + dateValue.slice(3,5) + dateValue.slice(5,7);
            $(fieldId).value = dateValue.substring(0,2) + "/" + dateValue.substring(2,4) +
            "/" + dateValue.substring(4,6);
        }
        else if((dateValue.charAt(4)=="/") && (dateValue.charAt(2)!="/") &&
            (dateValue.length==7)){
            dateValue = dateValue.slice(0,2) + dateValue.slice(2,4) + dateValue.slice(5,7);
            $(fieldId).value = dateValue.substring(0,2) + "/" + dateValue.substring(2,4) +
            "/" + dateValue.substring(4,6);
        }
    }
}
function setToDateForOcr(fieldId){
    if($(fieldId) != null) {
        var isValid = validateDate(fieldId);
        if(isValid == true) {
            var fromDateId = fieldId;
            var toDateId = fieldId.replace('from', 'to');
            var  dateValue = $F(toDateId)
            if($(toDateId) != null && (dateValue == "MM/DD/YY" || dateValue == "mm/dd/yy" || dateValue== '') )
                $(toDateId).value = $F(fromDateId);
        }
    }
}


// This copies the value present in 'from date' to 'to date'
function setToDate(fieldId){
    if($(fieldId) != null) {
        var isValid = validateDate(fieldId);
        if(isValid == true) {
            var fromDateId = fieldId;
            var toDateId = fieldId.replace('from', 'to');
            if($(toDateId) != null)
                $(toDateId).value = $F(fromDateId);
        }
    }
}

// This provides the configured date for 'from date'
function setFromDate(fieldId){
    if($F('fc_def_sdate_choice') == "Check Date"){
        $(fieldId).value = $F('checkdate_id')
    } else if($('fc_def_sdate') != null){
        var date = $F('fc_def_sdate');
        if(date.strip().length == 10) {
            var dateArray = date.split('/');
            var year = dateArray[2].slice(2); // extracting last two digits of year
            var newDate = dateArray[0] + '/' + dateArray[1] + '/' + year; // combining into date
        }
        else {
            newDate = date;
        }
        $(fieldId).value = newDate;
    }
}

// This validates for a mandatory date field.
function dateRequired(fieldId) {
    var isValidated = false;
    if($(fieldId) != null) {
        if($F(fieldId) == "") {
            isValidated = false;
            alert("Please enter a valid date.");
            $(fieldId).focus();
        }
        else
            isValidated = applyDateValidation(fieldId, 1);
    }
    else
        isValidated = true;
    return isValidated;
}

// this method is called on tab as well as on click of 'add service line' button
// flag indicates the event which triggered this method
function applyDateValidation(fieldId, add_service_line_click) {
    var validation;
    // This condition checks if the user has stepped into 'service to date' field after having stepped out of 
    // 'service from date', having entered an invalid date there. In this scenario, validation should not be triggered on 
    // 'service to date' or the code will go into an infinite loop, since on blur events will occur back to back
    // not giving a chance to the user to correct the date
    tabbed_out_from_service_from_date_to_to_date_with_invalid_from_date = ((fieldId.search(/service/) > 0 || fieldId.search(/claim/) >= 0) &&
        fieldId.search(/to/) > 0 &&
        prevDateValid == false &&
        prevDateFieldId != null &&
        prevDateFieldId.search(/from/) > 0 && 
        (prevDateFieldId.search(/service/) > 0 || prevDateFieldId.search(/claim/) >= 0))
    if (tabbed_out_from_service_from_date_to_to_date_with_invalid_from_date && add_service_line_click != 1){
        prevDateFieldId = fieldId;
        prevDateValid = false
    }
    else{
        prevDateFieldId = fieldId;
        if($(fieldId) != null) {
            if(fieldId == 'checkdate_id'){
                validation = validateCheckDate(fieldId);
            }
            else {
                validation = validateDate(fieldId);
            }
            if(validation == false) {
                alert("Invalid date is not allowed. Please correct the date and try again.");
            }
            else {
                validation = confirmYear(fieldId);
                if(validation == true){
                    validation = compareDates(fieldId);
                    if(validation == true){
                        validation = isFutureDate(fieldId);
                    }
                }
            }
            prevDateValid = validation;
            if(prevDateValid == false) {
                setTimeout(function() {
                    $(fieldId).focus();
                }, 30);
            }
        }
    }
    return prevDateValid;
}

// validate check date
function validateCheckDate(fieldId){
    if($('correspondence_check') != null && $F('correspondence_check') == "true"){
        var dateValue = $F(fieldId);
        if(dateValue == "MM/DD/YY" || dateValue == "mm/dd/yy")
            return true;
        else
            return validateDate(fieldId);
    }
    else
        return validateDate(fieldId);
}

/************************************************
DESCRIPTION: Validates that a  date field contains only
    valid dates with 2 digit month, 2 digit day,
    2 digit year. Date separator is /.
    Year and date separator data can be extended as explained in REMARKS
    Uses combination of regular expressions and
    string parsing to validate date.
    Ex. mm/dd/yy
RETURNS:
   True if valid, otherwise false.
REMARKS:
   Avoids some of the limitations of the Date.parse()
   method such as the date separator character.
   The RegEx for checking the format of date is /^\d{1,2}(\/)\d{1,2}\1\d{2}$/
   This can be extended to receive different date separator and 4 digit year as:
    /^\d{1,2}(\-|\/|\.)\d{1,2}\1\d{4}$/
    Date separator can be ., -, or /.
 *************************************************/
function validateDate(fieldId) {
    var validation = false;    
    if($(fieldId) != null) {
        var objRegExp = /^\d{1,2}(\/)\d{1,2}\1\d{2}$/
        var dateValue = $F(fieldId);
        if(dateValue == "")
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
    }
    return validation;
}

// Validates against Future date
// Assumption : In mm/dd/yy date, If yy is entered as '00' then yyyy is '2000'
function isFutureDate(fieldId) {
    var validation = true;
    if($(fieldId) != null && $F(fieldId) != "") {
        var dateValue = $F(fieldId);
        var dateSeparator = dateValue.substring(2, 3);
        var arrayDate = dateValue.split(dateSeparator);
        var date = new Date();
        var currentMonth = date.getMonth() + 1;
        var currentDay = date.getDate();
        var currentYear = "" + date.getFullYear();
        var month = arrayDate[0];
        var day = arrayDate[1];
        var year = arrayDate[2];
        var centuryNumber = getCentury(dateValue);
        year = centuryNumber + year;
        validation = false;

        if(year == '99' && month == '99' && day == '99') {
            validation = true;
        }
        else {
            if(year == currentYear) {
                if(month == currentMonth) {
                    if(day == currentDay) {
                        validation = true;
                    }
                    else if(day > 0 && day < currentDay)
                        validation = true;
                }
                else if(month > 0 && month < currentMonth)
                    validation = true;
            }
            else if(year > 0 && year < currentYear)
                validation = true;
        }

        if(!validation) {
            if(fieldId == 'checkdate_id') {
                var needToContinue = confirm("You have entered a future date. Do you want to continue?");
                if (needToContinue == false) {
                    validation = false;
                    $('checkdate_id').focus();

                }
                else
                    validation = true;
            }
            else{
                alert("Future date is not allowed. Please correct the date and try again.");
                $(fieldId).focus();
            }
        }
    }
    return validation;
}

// Compares the 'from date' and 'to date'. 'From date' should be < 'to date'.
// Obtains the from date & to date from the fieldId.
function compareDates(fieldId) {
    var fromDateId;
    var toDateId;
    if(fieldId.search(/from/) != -1) {
        fromDateId = fieldId;
        toDateId = fieldId.replace('from', 'to');
    }
    else if(fieldId.search(/to/) != -1) {
        toDateId = fieldId;
        fromDateId = fieldId.replace('to', 'from');
    }
    var validation = true;
    if($(fromDateId) != null && $(toDateId) != null && validateDate(fromDateId)) {
        var fromDate = $F(fromDateId);
        var toDate = $F(toDateId);
        validation = validateDateRange(fromDate, toDate);
    }
    if(!validation) {
        alert("The From Date should be less than To Date.\n\
             Please correct the date and try again.")
    }
    return validation;
}

// Compares if 'From date' is < 'to date'.
function validateDateRange(fromDate, toDate){
    var validation = true;
    if(fromDate != "" && toDate != "" ) {
        validation = false;
        var arrayFromDate = fromDate.split("/");
        var arrayToDate = toDate.split("/");
        if(arrayFromDate[2] == arrayToDate[2]) {
            if(arrayFromDate[0] == arrayToDate[0]) {
                if(arrayFromDate[1] == arrayToDate[1])
                    validation = true;
                else if(arrayFromDate[1] < arrayToDate[1])
                    validation = true;
            }
            else if(arrayFromDate[0] < arrayToDate[0])
                validation = true;
        }
        else if(arrayFromDate[2] < arrayToDate[2])
            validation = true;
    }
    return validation;
}

// This provides a confirmation for years eneterd less than the previos year.
function confirmYear(fieldId) {
    var validation = true;
    if($(fieldId) != null) {
        var dateValue = $F(fieldId);
        if(dateValue != "") {
            var dateSeparator = dateValue.substring(2, 3);
            var arrayDate = dateValue.split(dateSeparator);
            var year = arrayDate[2];
            var date = new Date();
            var currentYear = "" + date.getFullYear();
            currentYear = currentYear.substring(2, 4);
            if(year < currentYear - 1) {
                var agree = confirm("The entered year is less than the previous year.\n\
                                 Are you sure about this year?");
                if(agree)
                    validation = true;
                else
                    validation = false;
            }
        }
    }
    return validation;
}

function getCentury(givenDate) {
    var centuryNumber = '';
    if($('fc_def_sdate') && $F('fc_def_sdate') != '') {        
        var defaultDate = $F('fc_def_sdate').strip();
        if(defaultDate.length == 10) {
            var defaultDateSeparator = defaultDate.substring(2, 3);
            var defaultDateArray = defaultDate.split(defaultDateSeparator);
            var defaultDateMonth = defaultDateArray[0];
            var defaultDateDay = defaultDateArray[1];
            if(defaultDateArray[2].length == 4) {
                var defaultDateYear = defaultDateArray[2].substring(2, 4);
            }
            else if(defaultDateArray[2].length == 2) {
                defaultDateYear = defaultDateArray[2];
            }
            var givenDateSeparator = givenDate.substring(2, 3);
            var givenDateArray = givenDate.split(givenDateSeparator);
            var givenDateMonth = givenDateArray[0];
            var givenDateDay = givenDateArray[1];
            var givenDateYear = givenDateArray[2];
            if(defaultDateMonth == givenDateMonth && defaultDateDay ==  givenDateDay && defaultDateYear == givenDateYear) {
                centuryNumber = defaultDate.slice(6, 8);
            }
        }
    }
    if(centuryNumber == '') {
        date = new Date();
        var year = "" + date.getFullYear();
        centuryNumber = year.slice(0, 2);
    }
    if(centuryNumber == '')
        centuryNumber = '20';
    return centuryNumber;
}