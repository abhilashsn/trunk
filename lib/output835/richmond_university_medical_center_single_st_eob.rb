class Output835::RichmondUniversityMedicalCenterSingleStEob < Output835::SingleStEob


  # For Richmond University Medical Center SingleSt Eob CLP07 should be Check number +batchdate+sequence number if check number duplicates
  def claim_number
    str = eob.check_information.check_number.to_s if eob.check_information
    job = check.job
    if payer
      if job.payer_group == "PatPay"
        str += "#{check.batch.date.strftime("%m%d%y")}" unless str.blank?
        str += "#{@count}" if @count
      end
    end
    str
  end
end
