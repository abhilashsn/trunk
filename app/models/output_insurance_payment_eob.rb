module OutputInsurancePaymentEob

  def is_patient_differ_from_subscriber?
    patient_subscriber_details = [
      [patient_last_name, subscriber_last_name],
      [patient_first_name, subscriber_first_name],
      [patient_middle_initial, subscriber_middle_initial],
      [patient_suffix, subscriber_suffix]
      ]
      difference = patient_subscriber_details.detect{|detail| detail[0].to_s.strip != detail[1].to_s.strip}
      difference.nil? ? false : true
  end

  def get_place_of_service_for_orbo_client
    place_of_service.blank? ? '11' : place_of_service
  end

end