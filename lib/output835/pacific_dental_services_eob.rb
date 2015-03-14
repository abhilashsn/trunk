class Output835::PacificDentalServicesEob < Output835::Eob

  def claim_payment_information
    claim_weight = claim_type_weight
    clp_elements = ['CLP', patient_account_number, claim_weight, eob.amount('total_submitted_charge_for_claim'),
        eob.payment_amount_for_output(facility, facility_output_config),
        (claim_weight == 22 ? "" : eob.patient_responsibility_amount), plan_type,
        claim_number, (facility_type_code || "13"), (claim_freq_indicator || "1") ]

    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  def service_prov_name
    prov_id, qualifier = service_prov_identification
    service_prov_name_elements = [ 'NM1', '82', (eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
        prov_last_name_or_org, eob.rendering_provider_first_name, eob.rendering_provider_middle_initial,
        '', '', qualifier, prov_id]
    service_prov_name_elements = Output835.trim_segment(service_prov_name_elements)
    service_prov_name_elements.join(@element_seperator)
  end

  def image_page_name_bac
    image = @job.images_for_jobs.first.image_file_name
    job_start_page = @job.starting_page_number
    image_name = 'PDS' + image.split('PDS')[1]
    output_image_name = "#{image_name}#{job_start_page - 1 + eob.image_page_no.to_i}_#{job_start_page - 1 + eob.image_page_to_number.to_i}"
    ['REF','ZZ', output_image_name].join(@element_seperator)
  end

  def claim_from_date
    from_date = eob.claim_from_date
    unless from_date.blank?
      from_date = from_date.strftime("%Y%m%d")
      claim_date_elements = ['DTM', '232', (from_date == "20000101" ? '19700101' : from_date)]
      claim_date_elements.join(@element_seperator)
    end
  end

  #Specifies pertinent To dates of the claim
  def claim_to_date
    to_date = eob.claim_to_date
    unless to_date.blank?
      to_date = to_date.strftime("%Y%m%d")
      claim_date_elements = ['DTM', '233', (to_date == "20000101" ? '19700101' : to_date)]
      claim_date_elements.join(@element_seperator)
    end
  end
  
end