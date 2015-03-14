//Search popup
function siteSearchPopup(){
  var siteName = document.getElementById("site_name").value;
  var siteTin = document.getElementById("site_tin").value;
  var siteNpi = document.getElementById("site_npi").value;
  var siteAddress1 = document.getElementById("site_address_1").value;
  var siteAddress2 = document.getElementById("site_address_2").value;
  var siteCity = document.getElementById("site_city").value;
  var siteState = document.getElementById("site_state").value;
  var siteZip = document.getElementById("site_zip").value;
  var jobId = document.getElementById("job_id").value;
  var chkId = document.getElementById("chk_id").value;
  window.open("site_search?site_name="+siteName+"&site_tin="+siteTin+"&site_npi="+siteNpi+"&site_address_1="+siteAddress1+"&site_address_2="+siteAddress2+"&site_city="+siteCity+"&site_state="+siteState+"&site_zip="+siteZip+"&job_id="+jobId+"&chk_id="+chkId,"popup","width=600,height=400,scrollbars=1");
}

function rejectSite(){
  var msg = confirm("Rejecting a site will quarantine all it's ERA transactions. Do you wish to proceed?");
  var chkId = document.getElementById("chk_id").value;
  if (msg == true){
    window.location.href = "site_search?reject_site_button=true&chk_id="+chkId;
  }
}

function payerSearchPopup(){
  var payerName = document.getElementById("payer_name").value;
  var payerAddress1 = document.getElementById("payer_address_1").value;
  var payerAddress2 = document.getElementById("payer_address_2").value;
  var payerCity = document.getElementById("payer_city").value;
  var payerState = document.getElementById("payer_state").value;
  var payerZip = document.getElementById("payer_zip").value;
  var payerId = document.getElementById("payer_id").value;
  var payerPlanId = document.getElementById("payer_plan_id").value;
  var payerTin = document.getElementById("payer_tin").value;
  var chkId = document.getElementById("chk_id").value;
  window.open("payer_search?payer_name="+payerName+"&payer_address_1="+payerAddress1+"&payer_address_2="+payerAddress2+"&payer_city="+payerCity+"&payer_state="+payerState+"&payer_zip="+payerZip+"&payer_id="+payerId+"&payer_plan_id="+payerPlanId+"&payer_tin="+payerTin+"&chk_id="+chkId,"popup","width=600,height=400,scrollbars=1");
}

function createPayer(){
  var msg = confirm("Do you want to Create a New Payer with this information?");
  var chkId = document.getElementById("chk_id").value;
  if (msg == true){
    window.location.href = "payer_search?create_payer_button=true&chk_id="+chkId;
  }
}


