function save_charge(id, total) {
    var mpi_total = 0
    var net_total = 0
    totalLineCount = ($('total_line_count_remove').value);
    for( i = 1; i <= totalLineCount; i++) {
        var amount = id + i;
        if($(amount) != null) {
            if($F(amount) == 'NaN' || $F(amount) == 0 || $F(amount) == '')
                amount = 0
            else
                amount = $F(amount)
            mpi_total = mpi_total + parseFloat(amount)
        }
    }
    if($(total) != null) {
        total = $F(total)
    } else
        total = 0
    var decimal = Math.pow(10, 2);
    mpi_total = Math.round(mpi_total * decimal) / decimal;
    $('mpi_total').value = mpi_total.toFixed(2)
    net_total = net_total + parseFloat(total)
    net_total = Math.round(net_total * decimal) / decimal;
    $('net_total').value = net_total.toFixed(2)
}

function total_charge_mpi(id, total) {
    if($('mpi_total') != null && $('net_total') != null) {
        if(($F('mpi_total') == '') || ($F('mpi_total') == 'NaN'))
            $('mpi_total').value = 0;
        if(($F('net_total') == '') || ($F('net_total') == 'NaN'))
            $('net_total').value = 0;
        var add_row_total = parseFloat($F('net_total')) - parseFloat($F('mpi_total'));
        var totalSum = 0;
        var netSum = 0;
        var sum;
        var totalLineCount = 0;
        if($('total_line_count_remove') != null)
            totalLineCount = ($F('total_line_count_remove'));
        for( i = 1; i <= totalLineCount; i++) {
            var amount = id + i;
            if($(amount) != null) {
                if($F(amount) == 'NaN' || $F(amount) == 0 || $F(amount) == '')
                    sum = 0;
                else
                    sum = $F(amount);
                totalSum = totalSum + parseFloat(sum);
                netSum = totalSum + add_row_total;
                var decimal = Math.pow(10, 2);
                netSum = Math.round(netSum * decimal) / decimal;
                if($(total) != null)
                    $(total).value = netSum.toFixed(2);
            }
        }
        totalSum = 0;
    }
}

function total_coinsurance_mpi(id, hipaa_code) {
    coinsurance_id = "service_co_insurance_id" + id
    coinsuranceAmount = parseFloat($(coinsurance_id).value)
    if(coinsuranceAmount > 0) {
        coinsuranceReasoncodeId = "coinsurance_" + id + "_adjustment_code"
        coinsuranceReasoncodeDescriptionId = "coinsurance_desc_" + id + "_adjustment_desc"
        if(hipaa_code == false) {
            $(coinsuranceReasoncodeId).value = 2
            $(coinsuranceReasoncodeDescriptionId).value = 'Coinsurance Amount'
        }
    }
    if(($('mpi_total').value == '') || ($('mpi_total').value == 'NaN') || ($('mpi_total').value != '')) {
        $('mpi_total').value = 0
    }
    if(($('net_total').value == '') || ($('net_total').value == 'NaN') || ($('net_total').value != '')) {
        $('net_total').value = 0
    }
    var add_row_total = parseFloat($('net_total').value) - parseFloat($('mpi_total').value)
    var totalSum = 0
    var netSum = 0
    var sum
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_co_insurance_id" + i;
        if($(data) != null) {
            if($(data).value == 0 || $(data).value == '')
                sum = 0
            else
                sum = $(data).value
            totalSum = totalSum + parseFloat(sum)
            netSum = totalSum + add_row_total
            var decimal = Math.pow(10, 2);
            netSum = Math.round(netSum * decimal) / decimal;
            $('total_coinsurance_id').value = netSum.toFixed(2);
        }
    }
    totalSum = 0;
}

function total_deduct_mpi(id, hipaa_code) {
    service_deductible_id = "service_deductible_id" + id
    serviceDeductibleAmount = parseFloat($(service_deductible_id).value)
    if(serviceDeductibleAmount > 0) {
        deductubleReasoncodeId = "deductuble_" + id + "_adjustment_code"
        deductubleReasoncodeDescriptionId = "deductuble_desc_" + id + "_adjustment_desc"
        if(hipaa_code == false) {
            $(deductubleReasoncodeId).value = 1
            $(deductubleReasoncodeDescriptionId).value = 'Deductible Amount'
        }
    }
    if(($('mpi_total').value == '') || ($('mpi_total').value == 'NaN') || ($('mpi_total').value != '')) {
        $('mpi_total').value = 0
    }
    if(($('net_total').value == '') || ($('net_total').value == 'NaN') || ($('net_total').value != '')) {
        $('net_total').value = 0
    }
    var add_row_total = parseFloat($('net_total').value) - parseFloat($('mpi_total').value)
    var totalSum = 0
    var netSum = 0
    var sum
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_deductible_id" + i;
        if($(data) != null) {
            if($(data).value == 0 || $(data).value == '')
                sum = 0
            else
                sum = $(data).value
            totalSum = totalSum + parseFloat(sum)
            netSum = totalSum + add_row_total
            var decimal = Math.pow(10, 2);
            netSum = Math.round(netSum * decimal) / decimal;
            $('total_deductable_id').value = netSum.toFixed(2);
        }
    }
    totalSum = 0;
}

function total_copay_mpi(id, hipaa_code) {
    service_copay_id = "service_co_pay_id" + id
    service_copay_amount = parseFloat($(service_copay_id).value)
    if(service_copay_amount > 0) {
        copayReasoncodeId = "copay_" + id + "_adjustment_code"
        copayReasoncodeDescriptionId = "copay_desc_" + id + "_adjustment_desc"
        if(hipaa_code == false) {
            $(copayReasoncodeId).value = 3
            $(copayReasoncodeDescriptionId).value = 'Co-payment Amount'
        }
    }
    if(($('mpi_total').value == '') || ($('mpi_total').value == 'NaN') || ($('mpi_total').value != '')) {
        $('mpi_total').value = 0
    }
    if(($('net_total').value == '') || ($('net_total').value == 'NaN') || ($('net_total').value != '')) {
        $('net_total').value = 0
    }
    var add_row_total = parseFloat($('net_total').value) - parseFloat($('mpi_total').value)
    var totalSum = 0
    var netSum = 0
    var sum
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_co_pay_id" + i;
        if($(data) != null) {
            if($(data).value == 0 || $(data).value == '')
                sum = 0
            else
                sum = $(data).value
            totalSum = totalSum + parseFloat(sum)
            netSum = totalSum + add_row_total
            var decimal = Math.pow(10, 2);
            netSum = Math.round(netSum * decimal) / decimal;
            if($('total_copay_id') != null)
                $('total_copay_id').value = netSum.toFixed(2);
        }
    }
    totalSum = 0;
}

function total_primary_amount_mpi(id) {
    primary_amount_id = "service_submitted_charge_for_claim_id" + id
    service_primary_amount = parseFloat($(primary_amount_id).value)
    if(service_primary_amount > 0) {
        service_primary_reasoncode_id = "primary_" + id + "_adjustment_code"
        service_primary_reasoncode_description_id = "primary_desc_" + id + "_adjustment_desc"
        if($F('facility') == 'HORIZON EYE') {
            $(service_primary_reasoncode_id).value = 46
            $(service_primary_reasoncode_description_id).value = 'This service is not covered'
        } else {
            $(service_primary_reasoncode_id).value = 23
            $(service_primary_reasoncode_description_id).value = 'The impact of prior payer(s) adjudication including payments and/or adjustments'
        }
    }
    if(($('mpi_total').value == '') || ($('mpi_total').value == 'NaN') || ($('mpi_total').value != '')) {
        $('mpi_total').value = 0
    }
    if(($('net_total').value == '') || ($('net_total').value == 'NaN') || ($('net_total').value != '')) {
        $('net_total').value = 0
    }
    var add_row_total = parseFloat($('net_total').value) - parseFloat($('mpi_total').value)
    var totalSum = 0
    var netSum = 0
    var sum
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_submitted_charge_for_claim_id" + i;
        if($(data) != null) {
            if($(data).value == 0 || $(data).value == '')
                sum = 0
            else
                sum = $(data).value
            totalSum = totalSum + parseFloat(sum)
            netSum = totalSum + add_row_total
            var decimal = Math.pow(10, 2);
            netSum = Math.round(netSum * decimal) / decimal;
            $('total_primary_payment_id').value = netSum.toFixed(2);
        }
    }
    totalSum = 0;
}

function total_charge(id, total) {
    var totalSum = 0
    var sum
    totalLineCount = ($('total_line_count_remove').value)
    for( i = 1; i <= totalLineCount; i++) {
        var amount = id + i;
        if($(amount) != null) {
            if($(amount).value == 0 || $(amount).value == '')
                sum = 0
            else
                sum = $(amount).value
            totalSum = totalSum + parseFloat(sum)
            var decimal = Math.pow(10, 2);
            totalSum = Math.round(totalSum * decimal) / decimal;
            $(total).value = totalSum.toFixed(2)
        }
    }
    totalSum = 0;
}

function total_coinsurance(id) {
    coinsurance_id = "service_co_insurance_id" + id
    coinsuranceAmount = parseFloat($(coinsurance_id).value)
    if(coinsuranceAmount > 0) {
        coinsuranceReasoncodeId = "coinsurance_" + id + "_adjustment_code"
        coinsuranceReasoncodeDescriptionId = "coinsurance_desc_" + id + "_adjustment_desc"
        $(coinsuranceReasoncodeId).value = 2
        $(coinsuranceReasoncodeDescriptionId).value = 'Coinsurance Amount'
    }
    var totalSum = 0
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_co_insurance_id" + i;
        if($(data).value == '') {
            $(data).value = 0
        }
        totalSum = totalSum + parseFloat($(data).value)
        var decimal = Math.pow(10, 2);
        totalSum = Math.round(totalSum * decimal) / decimal;
        $('total_coinsurance_id').value = totalSum.toFixed(2);
    }
    totalSum = 0;
}

function total_deduct(id) {
    service_deductible_id = "service_deductible_id" + id
    serviceDeductibleAmount = parseFloat($(service_deductible_id).value)
    if(serviceDeductibleAmount > 0) {
        deductubleReasoncodeId = "deductuble_" + id + "_adjustment_code"
        deductubleReasoncodeDescriptionId = "deductuble_desc_" + id + "_adjustment_desc"
        $(deductubleReasoncodeId).value = 1
        $(deductubleReasoncodeDescriptionId).value = 'Deductible Amount'
    }
    var totalSum = 0
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_deductible_id" + i;
        if($(data).value == '') {
            $(data).value = 0
        }
        totalSum = totalSum + parseFloat($(data).value)
        var decimal = Math.pow(10, 2);
        totalSum = Math.round(totalSum * decimal) / decimal;
        $('total_deductable_id').value = totalSum.toFixed(2);
    }
    totalSum = 0;
}

function total_copay(id) {
    service_copay_id = "service_co_pay_id" + id
    service_copay_amount = parseFloat($(service_copay_id).value)
    if(service_copay_amount > 0) {
        copayReasoncodeId = "copay_" + id + "_adjustment_code"
        copayReasoncodeDescriptionId = "copay_desc_" + id + "_adjustment_desc"
        $(copayReasoncodeId).value = 3
        $(copayReasoncodeDescriptionId).value = 'Co-payment Amount'
    }
    var totalSum = 0
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_co_pay_id" + i;
        if($(data).value == '') {
            $(data).value = 0
        }
        totalSum = totalSum + parseFloat($(data).value)
        var decimal = Math.pow(10, 2);
        totalSum = Math.round(totalSum * decimal) / decimal;
        $('total_copay_id').value = totalSum.toFixed(2);
    }
    totalSum = 0;
}

function total_primary_amount(id) {
    primary_amount_id = "service_submitted_charge_for_claim_id" + id
    service_primary_amount = parseFloat($(primary_amount_id).value)
    if(service_primary_amount > 0) {
        service_primary_reasoncode_id = "primary_" + id + "_adjustment_code"
        service_primary_reasoncode_description_id = "primarypaymentreasoncodedesc_id" + id
        $(service_primary_reasoncode_id).value = 23
        $(service_primary_reasoncode_description_id).value = 'The impact of prior payer(s) adjudication including payments and/or adjustments'
    }
    var totalSum = 0
    totalLineCount = ($('total_line_count').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_submitted_charge_for_claim_id" + i;
        if($(data).value == '') {
            $(data).value = 0
        }
        totalSum = totalSum + parseFloat($(data).value)
        var decimal = Math.pow(10, 2);
        totalSum = Math.round(totalSum * decimal) / decimal;
        $('total_primary_payment_id').value = totalSum.toFixed(2);
    }
    totalSum = 0;
}

function total_balance() {
    var totalSum = 0;
    totalLineCount = ($('total_line_count_remove').value)
    for( i = 1; i <= totalLineCount; i++) {
        var data = "service_balance_id" + i;
        if($(data) != null) {
            if($(data).value != '') {
                totalSum = totalSum + parseFloat($(data).value)
                var decimal = Math.pow(10, 2);
                totalSum = Math.round(totalSum * decimal) / decimal;
                $('total_service_balance_id').value = totalSum.toFixed(2);
            }
        }
    }
    totalSum = 0;
}

function serviceBalance(id) {
    if($('service_procedure_charge_amount_id' + id) != null && $('service_procedure_charge_amount_id' + id).value != "")
        chargeAmount = parseFloat($('service_procedure_charge_amount_id' + id).value)
    else
        chargeAmount = 0
    if($('service_non_covered_id' + id) != null && $('service_non_covered_id' + id).value != "")
        noncovamount = parseFloat($('service_non_covered_id' + id).value)
    else
        noncovamount = 0
    if($('service_non_covered_id' + id) != null && $('service_non_covered_id' + id).value != "")
        noncovamount = parseFloat($('service_non_covered_id' + id).value)
    else
        noncovamount = 0
    if($('denied_status') != null && $F('denied_status') == "true") {
        if($('denied_id' + id) != null && $F('denied_id' + id) != "")
            deniedamount = parseFloat($('denied_id' + id).value)
        else
            deniedamount = 0
    }
    if($('miscellaneous_one_id' + id) != null && $F('miscellaneous_one_id' + id) != "")
        var miscellaneousOneAmount = parseFloat($F('miscellaneous_one_id' + id));
    else
        miscellaneousOneAmount = 0;
    if($('miscellaneous_two_id' + id) != null && $F('miscellaneous_two_id' + id) != "")
        var miscellaneousTwoAmount = parseFloat($F('miscellaneous_two_id' + id));
    else
        miscellaneousTwoAmount = 0;
        if($('miscellaneous_balance_id' + id) != null && $F('miscellaneous_balance_id' + id) != "")
        var miscellaneousBalanceAmount = parseFloat($F('miscellaneous_balance_id' + id));
    else
        miscellaneousBalanceAmount = 0;
    if($('service_discount_id' + id) != null && $('service_discount_id' + id).value != "")
        discountamount = parseFloat($('service_discount_id' + id).value)
    else
        discountamount = 0
    if($('service_contractual_amount_id' + id) != null && $('service_contractual_amount_id' + id).value != "")
        contractualamt = parseFloat($('service_contractual_amount_id' + id).value)
    else
        contractualamt = 0
    if($('service_co_insurance_id' + id) != null && $('service_co_insurance_id' + id).value != "")
        coinsamt = parseFloat($('service_co_insurance_id' + id).value)
    else
        coinsamt = 0
    if($('service_deductible_id' + id) != null && $('service_deductible_id' + id).value != "")
        deductamt = parseFloat($('service_deductible_id' + id).value)
    else
        deductamt = 0
    if($('service_co_pay_id' + id) != null && $('service_co_pay_id' + id).value != "")
        copayamt = parseFloat($('service_co_pay_id' + id).value)
    else
        copayamt = 0
    if($('service_paid_amount_id' + id) != null && $('service_paid_amount_id' + id).value != "")
        paidamt = parseFloat($('service_paid_amount_id' + id).value)
    else
        paidamt = 0
    if($('service_submitted_charge_for_claim_id' + id) != null && $('service_submitted_charge_for_claim_id' + id).value != "")
        primaryamt = parseFloat($('service_submitted_charge_for_claim_id' + id).value)
    else
        primaryamt = 0
    if($('prepaid_status') != null && $F('prepaid_status') == "true") {
        if($('service_prepaid_id' + id) != null && $F('service_prepaid_id' + id) != "")
            prepaidAmount = parseFloat($('service_prepaid_id' + id).value)
        else
            prepaidAmount = 0
    }
    if($('patient_responsibility_status') != null && $F('patient_responsibility_status') == "true") {
        if($('patient_responsibility_id' + id) != null && $F('patient_responsibility_id' + id) != "")
            patientResponsibilityAmount = parseFloat($('patient_responsibility_id' + id).value)
        else
            patientResponsibilityAmount = 0
    }
    total_value = (noncovamount + discountamount + coinsamt + deductamt + copayamt + paidamt + primaryamt + contractualamt)
    if($('denied_status') != null && $F('denied_status') == "true") {
        total_value += deniedamount
    }
    if($('miscellaneous_one_id' + id)) {
        total_value += miscellaneousOneAmount;
    }
    if($('miscellaneous_two_id' + id)) {
        total_value += miscellaneousTwoAmount;
    }
        if($('miscellaneous_balance_id' + id)) {
        total_value += miscellaneousBalanceAmount;
    }
    
    if($('prepaid_status') != null && $F('prepaid_status') == "true") {
        total_value += prepaidAmount
    }

    if($('patient_responsibility_status') != null && $F('patient_responsibility_status') == "true") {
        total_value += patientResponsibilityAmount
    }
    total_amount_value = total_value.toFixed(2);
    charg_amount_value = chargeAmount.toFixed(2);
    line_balance = (charg_amount_value) - (total_amount_value)
    $('service_balance_id' + id).value = line_balance.toFixed(2)
    if($('claim_level_eob') != null && $F('claim_level_eob') != "true") {
        total_balance()
    }

}

// If the there is only one service line present in the grid (which will be the adjustment line)
// And if it does not contain the payment value (a mandatory field for adjsutment line)
// Then the balance will be zero.
// For other conditions the balance will be the total balance from all the service lines.
function setTotalBalance(totalBalance) {
    isInterestPaymentCheck = false;
    if($('interest_id') != null && $('client_type') != null) {
        clientName = $F('client_type');
        if(clientName.toUpperCase() == 'QUADAX' && parseFloat($F('checkamount_id')) == parseFloat($F('interest_id')))

            isInterestPaymentCheck = true;
    }
    if(isInterestPaymentCheck == true)
        $('total_service_balance_id').value = '0.00';
    else {
        if(($F('total_existing_number_of_svc_lines') == 1 && $F('service_paid_amount_id' + '1') == ''))
            $('total_service_balance_id').value = '';
        else if(($F('total_existing_number_of_svc_lines') == 1 && $F('service_paid_amount_id' + '1') != ''))
            $('total_service_balance_id').value = totalBalance.toFixed(2);
        else
            $('total_service_balance_id').value = totalBalance.toFixed(2);
    }

}