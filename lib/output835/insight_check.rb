class Output835::InsightCheck < Output835::NavicureCheck
  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    if payer
      trn_elements = []
      trn_elements << 'TRN'
      trn_elements << '1'
      trn_elements <<  ref_number
      if @check_amount.to_f > 0 && check.payment_method == "EFT"
        unless facility.facility_tin.blank?
          trn_elements <<  '1' + facility.facility_tin
        end
      else
        trn_elements <<  '1999999999'
      end
      trn_elements << "#{check.job.batch.facility.lockbox_number}_#{check.job.batch.batchid}"
      trn_elements = Output835.trim_segment(trn_elements)
      trn_elements.join(@element_seperator)
    end
  end

end