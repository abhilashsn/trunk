require 'csv'

class OutputCsv::ClientFCheck < OutputCsv::Check
  # Method to create the column header
  def csv_header
    csv_string = CSV.generate do |csv|
      #CSV file column headers
      csv << ["Check Number", "Service-Charge", "Service-Payment", "Carrier Code", "Patient Number", "Invoice Number", "Check Date", "Charge Amount", "Payment Amount",
        "Bank Acct Number", "Bank Routing Number", "HLSC Image Number", "IMAGE_URL", "Carrier Reason Code", "Date of Service", "Exception Indicator",
        "Reason Msg", "HCPCS Over Indicator", "Lockbox Number", "Insurer R'cvd Date", "Insurer Chk Mail Dt", "MSC Code", "Carrier Description", "ICN Number"]
    end
    return csv_string unless csv_string.blank?
  end

  # Method to create the content for CSV file
  def csv_content(check)
    # Collecting parameter values for the input check object
    lockbox_number = check.job.batch.facility.lockbox_number
    micr_line_information = check.micr_line_information
    unless micr_line_information.blank?
      aba_routing_number = micr_line_information.aba_routing_number
    end
    payer = check.payer
    unless payer.blank?
      payer_id = payer.id
    end
    unless check.check_date.blank?
      check_date = check.check_date.strftime("%m%d%y")
    else
      check_date = ""
    end
    csv_string = ""

    check.insurance_payment_eobs.each do |insurance_payment|
      
      claim_information = insurance_payment.claim_information
      check_number = ""
      unless check.check_number.blank?
        check_number = check.check_number.to_s 
        unless claim_information.blank? || claim_information.iplan.blank?
          check_number += ";" + claim_information.iplan.to_s
        end
      else
        check_number = "999999999"
      end
      #  The url of the image => HLSC hostname + the url of image viewed in RevRemit Application
      image_url = "http://www.hlsc.com/archive/viewimage?jobid=#{insurance_payment.check_information.job_id}&eob_id=#{insurance_payment.id}&eob_check_number=#{insurance_payment.check_information.id}&image_number=#{insurance_payment.image_page_no}"

      insurance_payment.service_payment_eobs.each do |service_payment|
        service_line_dates = ""
        service_line_dates = (service_payment.date_of_service_from.strftime("%m%d%y") unless service_payment.date_of_service_from.blank?) + ";" + (service_payment.date_of_service_to.strftime("%m%d%y") unless service_payment.date_of_service_to.blank?)
        
        # The CPT code mismatch is denoted when modifier4 = 99
        if service_payment.service_modifier4.to_s == "99"
          hcpcs_over_indicator = "YES"
        else
          hcpcs_over_indicator = "NO"
        end
        reason_message = service_payment.reason_code_descriptions               # Obtain all the reason_code_descriptions of the service_payment
        carrier_reason_code = service_payment.reason_codes                      # Obtain all the reason_codes of the service_payment
        msc_code, carrier_description = service_payment.hipaa_codes(payer_id)   # Obtain all the hipaa_codes of the reason_codes of the service_payment
        
        csv = ""
        #Writing a row for csv file
        csv = [check_number,service_payment.service_procedure_charge_amount, service_payment.service_paid_amount, insurance_payment.carrier_code,
          insurance_payment.patient_account_number, insurance_payment.patient_account_number, check_date, insurance_payment.total_submitted_charge_for_claim,
          insurance_payment.total_amount_paid_for_claim, check.check_number, aba_routing_number, insurance_payment.image_page_no, image_url,
          carrier_reason_code, service_line_dates, "2", reason_message, hcpcs_over_indicator, lockbox_number, insurance_payment.date_received_by_insurer,
          check_date, msc_code, carrier_description, insurance_payment.claim_number].join(",") + "\n"
        csv_string = csv_string + csv
      end
      
    end

    return csv_string unless csv_string.blank?

  end
end
