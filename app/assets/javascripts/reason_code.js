/**
 * @author shrisowdhaman
 */
function validationForCasAndLqheConfig(){
    if ($('facility_enable_crosswalk_1').checked || $('facility_enable_crosswalk_0').checked) {
        if ($('is_partner_bac') != null && $F('is_partner_bac') == 'true') {
            if ($('details_str_cas_01').value == "Group Code") {
					
                if (($('details_str_cas_02').value == "HIPAA Code") &&
                    ($('details_str_lq_he').value == "Client Code" ||
                        $('details_str_lq_he').value == "Reason Code" ||
                        $('details_str_lq_he').value == "")) {
                    return true;
                }else if (($('details_str_cas_02').value == "Client Code") &&
                    ($('details_str_lq_he').value == "Reason Code" ||
                        $('details_str_lq_he').value == "")) {
                    return true;
                }else if (($('details_str_cas_02').value == "") &&
                    ($('details_str_lq_he').value == "Reason Code" ||
                        $('details_str_lq_he').value == "")) {
                    return true;
                }else {
                    alert("The combination of CAS and LQHE values does not match");
                    return false;
                }
						
            }else {
						
                if ($('details_str_cas_01').value == "Client Code") {
                    if (($('details_str_cas_02').value == "HIPAA Code") &&
                        ($('details_str_lq_he').value == "Reason Code" ||
                            $('details_str_lq_he').value == "")) {
                        return true;
                    }else {
                        alert("The combination of CAS and LQHE values does not match");
                        return false;
                    }
                }else {
                    alert("The combination of CAS and LQHE values does not match");
                    return false;
                }
            }
        }
        else {
            if ($('details_str_cas_01').value == "Group Code") {
                if (($('details_str_cas_02').value == "HIPAA Code") && ($('details_str_lq_he').value == "Remark Code")) {
                    return true;
                }else if (($('details_str_cas_02').value == "Reason Code") && ($('details_str_lq_he').value == "")) {
                    return true;
                }else if(($('details_str_cas_02').value == "HIPAA Code") &&
                    ($('details_str_lq_he').value == "Reason Code" ||
                        $('details_str_lq_he').value == "")){
                    return true;
					 	
                } else {
                    alert("The combination of CAS and LQHE values does not match");
                    return false;
                }
						
            }else {
                alert("The combination of CAS and LQHE values does not match");
                return false;
            }
        }
    }else{
        alert("Enable crosswalk is not checked");
        return false;
				
    }
				
				
}

function setDefaultValuesForOutputElements(value){
	
    if (value == 1){
			
        $('details_str_cas_01').value = ""
        $('details_str_cas_02').value = ""
        $('details_str_lq_he').value = ""
		 	 
    }else{
		
		
        if ($('is_partner_bac').value == 'true') {
            $('details_str_cas_01').value = "Group Code"
            $('details_str_cas_02').value = "HIPAA Code"
            $('details_str_lq_he').value = "Reason Code"
        }else {
            $('details_str_cas_01').value = "Group Code"
            $('details_str_cas_02').value = "Reason Code"
            $('details_str_lq_he').value = ""
        }
    }
}

//used to toggle the adjustment code
function toggle_adjustment_table(){
    $('toggle_adjustment_table').toggle();
    if($('toggle_adjustment_table').style.display == "block") {
        if ($('details_str_default_cas_code').value != "") {
            $('default_codes_for_adjustment_reasons_non_covered_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_non_covered_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_contractual_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_contractual_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_denied_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_denied_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_ppp_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_ppp_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_copay_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_copay_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_coinsurance_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_coinsurance_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_deductible_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_deductible_hippa_default').value = "";
            $('default_codes_for_adjustment_reasons_discount_hippa_default').readOnly = true;
            $('default_codes_for_adjustment_reasons_discount_hippa_default').value = "";
        }else{
            $('details_str_default_cas_code').readOnly =true;
        }
		
    }else{
        $('details_str_default_cas_code').readOnly =false;
        $('default_codes_for_adjustment_reasons_non_covered_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_contractual_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_denied_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_ppp_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_copay_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_coinsurance_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_deductible_hippa_default').readOnly = false;
        $('default_codes_for_adjustment_reasons_discount_hippa_default').readOnly = false;
    }
	
}