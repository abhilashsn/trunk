module Output835ConfigSingleStHelper

 def payment_indicator
    @is_correspndence_check ? (@check.payment_method == 'EFT' ? 'NON' : 'ACH') : 'CHK'
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("balance_record_type asc, image_page_no, end_time asc")
  end

  def check_total_amount_truncate
    amount = @check_amount.to_f
    check_amount = (amount == (amount.truncate)? amount.truncate : amount)
    return check_amount
  end

  def get_ordered_patient_payment_eobs(object)
    object.patient_pay_eobs.order(:image_page_no, :end_time)
  end

end
