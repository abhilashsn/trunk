class InputBatch::IdxCsvNavicureBasicParser < InputBatch::IndexCsvTransformer
  def transform cvs
    process_csv cvs
  end

  def find_batchid
    batchid = parse(conf['BATCH']['batchid'])+"_"+Time.now.strftime("%m%d%Y")
    "#{batchid}"
  end

  def update_job job
    job.estimated_eob = job.estimated_no_of_eobs(nil, nil, job.check_number)
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
    return job
  end

  def update_check chk
    chk.check_number = '0' if chk.check_number.blank?
    chk.check_amount = 0.0 if chk.check_amount.blank?
    chk.check_amount = chk.check_amount.to_f
    check_date = parse(conf['BATCH']['date'][0])
    chk.check_date = format_date check_date
    return chk
  end

end