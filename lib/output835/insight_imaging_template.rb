class Output835::InsightImagingTemplate < Output835::Template

  def reciever_id
    [ 'REF', 'EV', @job.original_file_name.to_s[0...50]].trim_segment.join(@element_seperator) if @job.initial_image_name
  end

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    trn_elements = ['TRN', '1',  ref_number]
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      trn_elements <<  '1' + @facility.facility_tin if @facility.facility_tin.present?
    else
      trn_elements <<  '1999999999'
    end
    original_batchid = @batch.batchid.split("_")[0]
    trn_elements << "#{@facility.lockbox_number}_#{original_batchid}"
    trn_elements.trim_segment.join(@element_seperator)
  end

  def service_date_reference
    svc_date_segments = []
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?

    if from_date == to_date || to_date.nil?
      from_date = '99999999' if from_date == '20000101' || from_date == '99990909'
      can_print_date = (from_date == '99999999') ? true : can_print_service_date(from_date)
      ['DTM', '472', from_date].join(@element_seperator) if can_print_date
    else
      svc_date_segments <<  ['DTM',  '150', from_date].join(@element_seperator) if can_print_service_date(from_date)
      svc_date_segments << ['DTM', '151', to_date].join(@element_seperator) if can_print_service_date(to_date)
      svc_date_segments unless svc_date_segments.blank?
    end
  end

end