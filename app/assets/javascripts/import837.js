//= require jquery
//= require jquery_ujs


//function validate_form(){
//  var filename = document.getElementById("file_name");
//  var filename_txt = filename.options[filename.selectedIndex].value;
//  if (filename_txt == ""){
//   alert("Please select a file name");
//   return false;
//  }
//  //var download_date = document.getElementById("download_date");
//  //if (download_date.value == ""){
//  // alert("Please select a valid date");
//  // return false;
//  //}
//  return true;
//}

function vali_type(){
 var id_value = document.getElementById('upload_datafile').value;

 if(id_value != '')
 {
  var valid_extensions = /(.zip)$/i;
  if(valid_extensions.test(id_value))
   return true;
  else
   return false;
 }
  return true;
}
function validate_form(){
  var facility = document.getElementById("facility_name");
  var facility_name_txt = facility.options[facility.selectedIndex].value;
  if (facility_name_txt == "Select"){
   alert("Please select a facility name");
   return false; 
  }
  var id_value = document.getElementById('upload_datafile').value;
  if(id_value == ''){
    alert("Please select a file");
    return false;
  }
  //if(!vali_type()){
  //  alert("Invalid File type,Not a Zip file");
  //  return false;
  //}
  return true;
}

