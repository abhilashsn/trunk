class Output835::ShepherdEyeSurgicenterEob < Output835::Eob
  
   #Supplies the full name of an individual or organizational entity
   #Required when the insured or subscriber is different from the patient
  def service_prov_name
    Output835.log.info "Printing NM1*82 for Patient Acc Num : #{eob.patient_account_number}"
    service_prov_name_elements = []
    service_prov_name_elements << 'NM1'
    service_prov_name_elements << '82'
    service_prov_name_elements << (eob.rendering_provider_last_name.strip.blank? ? '2': '1')
    service_prov_name_elements << prov_last_name_or_org
    service_prov_name_elements << eob.rendering_provider_first_name
    service_prov_name_elements << eob.rendering_provider_middle_initial
    service_prov_name_elements << ''
    service_prov_name_elements << ''
    service_prov_name_elements << 'FI' unless eob.provider_tin.blank?
    service_prov_name_elements << eob.provider_tin 
    service_prov_name_elements = Output835.trim_segment(service_prov_name_elements)
    service_prov_name_elements.join(@element_seperator)
  end
  
  def other_claim_related_id
    images = @job.images_for_jobs
    eob_image =  images.select{|image|image.image_number == eob.image_page_no}.first
    eob_image = images.first if images.length < 2
    if eob_image
      elem = []
      elem << 'REF'
      elem << 'F8'
      elem << eob_image.original_file_name
      elem.join(@element_seperator)
    end
  end
  
end