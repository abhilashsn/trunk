class Output835::RichmondUniversityMedicalCenterSingleStTemplate < Output835::SingleStTemplate

  def claim_number
    str = @check.check_number.to_s
    if @check.payer
      if @check.job.payer_group == "PatPay"
        str += "#{@batch.date.strftime("%m%d%y")}" unless str.blank?
        str += "#{@count}" if @count
      end
    end
    str
  end

  def patpay_specific_lq_segment
    if @check.eob_type == 'Patient'
      lq_elements = ['LQ', 'RX', '202614']
      lq_elements.join(@element_seperator)
    end
  end
  
end
