module OutputNextgen::TemplateVariableTranslations
  def batch_id_sliced
    OutputNextgen.log.info "\n\n\n\n Starting 835 output generation at #{Time.now}"
    OutputNextgen.log.info "for batch id #{batch.batchid}"
    batchid = batch.batchid
    len = batchid.length
    # Obtaining the actual batch id excluding the date and '_'.
    # Date and '_' makes up the last 9 characters of the batchid.
    normalized_batchid = batchid.slice(0 ... len - 9)
    OutputNextgen.log.info "batch id without date #{batchid}"
    # Obtaining the first 3 characters of the batchid.
    normalized_batchid = normalized_batchid.slice(0, 3)
    # Padding with zeroes to obtain batchid having 3 characters.
    pad_left(normalized_batchid, 3, '0')
  end

  def batch_date
    batch.date.strftime("%m%d%y") if batch.date
  end

  def check_info
    result = ''
    OutputNextgen.log.info "This batch has #{checks.length} checks"
    checks.each do |check|
      OutputNextgen.log.info "\n\n Processing check number #{check.check_number}"
      OutputNextgen.log.info "\n check amount : #{to_cents(check.check_amount)} cents"
      last_check = check == checks.last
      look_ahead = last_check ? '' : "\n"
      @check = check
      result += eob_info + look_ahead
    end
    result
  end

  def eob_info
    str = ''

    get_ordered_patient_payment_eobs(check).each_with_index do |patient_eob, i|
      last_eob = patient_eob == check.patient_pay_eobs.last
      look_ahead = last_eob ? '' : "\n"
      @eob = patient_eob
      patient_last_name = last_name
      if patient_last_name.length > 8
        patient_last_name.slice!( 8, patient_last_name.length )
      end
      str += 'S' + pad_left(account_num.to_s, 16, '0') +
        pad_left(transac_date, 13, '0') +
        pad_left(stub_amt, 9, '0') +
        pad_left(check_amt, 9, '0') +
        pad_left(statmt_amt, 9, '0') +
        pad_left(check_num, 14, '0') +
        pad_right(patient_last_name, 8) + look_ahead
    end
    str
  end
  
  def account_num
    OutputNextgen.log.info "\n\n Processing Acc. Num. : #{eob.account_number}"
    eob.account_number
  end

  def transac_date
    OutputNextgen.log.info "\n Transaction Date : #{eob.transaction_date}"
    eob.transaction_date.strftime("%m%d%y") if eob.transaction_date
  end

  def stub_amt
    to_cents(eob.stub_amount)
  end

  def check_amt
    to_cents(check.check_amount)
  end

  def statmt_amt
    to_cents(eob.statement_amount)
  end

  def check_num
    check.check_number.to_s
  end

  def last_name
    OutputNextgen.log.info "\n Patient Last Name : #{eob.patient_last_name}"
    eob.patient_last_name.strip.upcase
  end

  def batch_amt
    batch_amount = 0
    checks.each do |check|
      check.patient_pay_eobs.collect do |eob|
        batch_amount += eob.stub_amount.to_f
      end
    end
    OutputNextgen.log.info "\n Batch Amount : #{to_cents(batch_amount)} cents"
    OutputNextgen.log.info "\n Output generation complete \n\n"
    to_cents(batch_amount)
  end
end