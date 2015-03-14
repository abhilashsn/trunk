function displayPayerWiseAutoAllocation(id){
    var role = $F(id);
    if (role == "processor")
        display_payer_wise_auto_allocation.style.visibility = 'visible';
    else
        display_payer_wise_auto_allocation.style.visibility = 'hidden';
}
