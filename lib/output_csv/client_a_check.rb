class OutputCsv::ClientACheck < OutputCsv::Check
  # Method to create the column header
  def csv_header
    #CSV file column headers

    csv_string =  ["IMG_TYPE", "Account Num","Patient Name","HCPCS 1","HCPCS 2","HCPCS 3","HCPCS 4","HCPCS 5","HCPCS 6","Svc Dates 1","Svc Dates 2","Svc Dates 3","Svc Dates 4",
      "Svc Dates 5","Svc Dates 6","Total Chg 1","Total Chg 2","Total Chg 3","Total Chg 4","Total Chg 5","Total Chg 6","Non-cvd Chg 1","Non-cvd Chg 2","Non-cvd Chg 3",
      "Non-cvd Chg 4","Non-cvd Chg 5","Non-cvd Chg 6","Payer Name","HIC","Deductible 1","Deductible 2","Deductible 3","Deductible 4","Deductible 5","Deductible 6",
      "Coinsurance 1","Coinsurance 2","Coinsurance 3","Coinsurance 4","Coinsurance 5","Coinsurance 6","NDA_A","NDA_B","NDA_C","NDA_D","NDA_E","NDA_F","Con Adj 1",
      "Con Adj 2","Con Adj 3","Con Adj 4","Con Adj 5","Con Adj 6", "Payment Amt 1", "Payment Amt 2", "Payment Amt 3", "Payment Amt 4", "Payment Amt 5", "Payment Amt 6",
      "Denied Amt 1","Denied Amt 2","Denied Amt 3","Denied Amt 4","Denied Amt 5","Denied Amt 6","Prior Pmt 1","Prior Pmt 2","Prior Pmt 3","Prior Pmt 4","Prior Pmt 5",
      "Prior Pmt 6","ABA number","Chk Acct No","Check Num","Patient Resp","Image Name","Lockbox ID","Rsn Code Adj 1","Rsn Code Adj 2","Rsn Code Adj 3","Rsn Code Adj 4",
      "Rsn Code Adj 5","Rsn Code Adj 6","Rsn Code Adj Total","Batch ID","Batch Date"].join(",") + "\n"
    return csv_string unless csv_string.blank?
  end

  # Method to create the content for CSV file
  def csv_content(check)
    #variable to check the max 6 service line logic while making CSV
    counter = 0
    # String corresponding to one row in CSV
    csv = ""
    # Collecting parameter values for the input check object
    batch = check.job.batch
    batchid = batch.batchid
    batch_date = batch.date
    facility = check.job.batch.facility
    lockbox_number = facility.lockbox_number
    # The image type will be EOB in all cases
    image_types = "EOB"
    filename = ""
    images_for_jobs = check.job.images_for_jobs

    unless images_for_jobs.blank?
      filename = images_for_jobs.first.filename
    end
    payer = check.payer
    unless payer.blank?
      payer_name = payer.payer
    end

    micr_line_information = check.micr_line_information
    unless micr_line_information.blank?
      aba_routing_number = micr_line_information.aba_routing_number
    end
    check_number = check.check_number
    csv_string = ""
    # Querying data for claim and service line details
    csv_query = "select ins.patient_account_number, ins.patient_first_name,ins.patient_middle_initial,ins.patient_last_name, svc.service_procedure_code, "
    csv_query += "svc.date_of_service_from, svc.service_procedure_charge_amount, svc.service_no_covered, ins.patient_identification_code,"
    csv_query += "svc.service_deductible, svc.service_co_insurance, svc.service_discount, svc.contractual_amount, svc.service_paid_amount, svc.denied,"
    csv_query += "svc.primary_payment, svc.service_co_insurance, svc.service_co_pay, svc.service_deductible, svc.noncovered_code, svc.denied_code, svc.discount_code,  "
    csv_query += "svc.coinsurance_code, svc.deductuble_code, svc.copay_code, svc.primary_payment_code, svc.contractual_code from service_payment_eobs svc "
    csv_query += "inner join insurance_payment_eobs ins on svc.insurance_payment_eob_id = ins.id "
    csv_query += "inner join check_informations chk on ins.check_information_id = chk.id "
    csv_query += "where chk.id = #{check.id}"
    csv_records = ServicePaymentEob.find_by_sql(csv_query)
    records_size = csv_records.size

    unless csv_records.blank?
      service_procedure_code = []
      date_of_service_from = []
      service_procedure_charge_amount = []
      service_no_covered = []
      service_deductible = []
      co_insurance = []
      service_discount = []
      contractual_amount = []
      service_paid_amount = []
      denied = []
      primary_payment = []
      reason_code_adjustment = []
      csv_records.each do |record|
        service_procedure_code[counter] = record.service_procedure_code
        date_of_service_from[counter] = record.date_of_service_from.strftime("%m%d%y")
        service_procedure_charge_amount[counter] = record.service_procedure_charge_amount
        service_no_covered[counter] = record.service_no_covered
        service_deductible[counter] = record.service_deductible
        co_insurance[counter] = record.service_co_insurance.to_f + record.service_co_pay.to_f
        service_discount[counter] = record.service_discount
        contractual_amount[counter] = record.contractual_amount
        service_paid_amount[counter] = record.service_paid_amount
        denied[counter] =  record.denied
        primary_payment[counter] = record.primary_payment
        reason_code_adjustment[counter] = ""

        unless record.noncovered_code.blank?
          reason_code_adjustment[counter] = record.get_mapped_codes(facility, 'PAYER CODE', 'noncovered') + ";"
        end
        unless record.denied_code.blank?
          reason_code_adjustment[counter] = reason_code_adjustment[counter] + record.get_mapped_codes(facility, 'PAYER CODE', 'denied') + ";"
        end
        unless record.discount_code.blank?
          reason_code_adjustment[counter] = reason_code_adjustment[counter] + record.get_mapped_codes(facility, 'PAYER CODE', 'discount') + ";"
        end
        unless record.coinsurance_code.blank?
          reason_code_adjustment[counter] = reason_code_adjustment[counter] + record.get_mapped_codes(facility, 'PAYER CODE', 'coinsurance') + ";"
        end
        unless record.deductuble_code.blank?
          reason_code_adjustment[counter] = reason_code_adjustment[counter] + record.get_mapped_codes(facility, 'PAYER CODE', 'deductible') + ";"
        end
        unless record.primary_payment_code.blank?
          reason_code_adjustment[counter] = reason_code_adjustment[counter] + record.get_mapped_codes(facility, 'PAYER CODE', 'primary_payment') + ";"
        end
        unless record.contractual_code.blank?
          reason_code_adjustment[counter] = reason_code_adjustment[counter] + record.get_mapped_codes(facility, 'PAYER CODE', 'contractual') + ";"
        end
        reason_code_adjustment[counter].slice!(reason_code_adjustment[counter].size-1)
        counter += 1
        patient_name = record.patient_first_name + " " + record.patient_middle_initial  +  " " + record.patient_last_name
        pat_resposibility = record.service_co_insurance.to_f + record.service_co_pay.to_f + record.service_deductible.to_f
        if counter == 6 || counter == records_size
          #Writing a row for csv file
          csv = [image_types, record.patient_account_number, patient_name, service_procedure_code[0], service_procedure_code[1], service_procedure_code[2], service_procedure_code[3],
            service_procedure_code[4], service_procedure_code[5], date_of_service_from[0], date_of_service_from[1], date_of_service_from[2], date_of_service_from[3],
            date_of_service_from[4], date_of_service_from[5], service_procedure_charge_amount[0], service_procedure_charge_amount[1], service_procedure_charge_amount[2],
            service_procedure_charge_amount[3], service_procedure_charge_amount[4], service_procedure_charge_amount[5], service_no_covered[0],service_no_covered[1],
            service_no_covered[2],service_no_covered[3],service_no_covered[4],service_no_covered[5], payer_name, record.patient_identification_code, service_deductible[0],
            service_deductible[1],service_deductible[2],service_deductible[3],service_deductible[4],service_deductible[5], co_insurance[0], co_insurance[1],
            co_insurance[2], co_insurance[3], co_insurance[4], co_insurance[5], service_discount[0],service_discount[1],service_discount[2],service_discount[3],
            service_discount[4],service_discount[5], contractual_amount[0], contractual_amount[1], contractual_amount[2], contractual_amount[3], contractual_amount[4], contractual_amount[5],
            service_paid_amount[0],service_paid_amount[1] ,service_paid_amount[2], service_paid_amount[3], service_paid_amount[4], service_paid_amount[5], denied[0], denied[1], denied[2],
            denied[3], denied[4], denied[5], primary_payment[0], primary_payment[1], primary_payment[2], primary_payment[3], primary_payment[4], primary_payment[5], aba_routing_number,
            record.patient_account_number, check_number, pat_resposibility, filename, lockbox_number, reason_code_adjustment[0], reason_code_adjustment[1], reason_code_adjustment[2],
            reason_code_adjustment[3], reason_code_adjustment[4], reason_code_adjustment[5], "", batchid, batch_date.strftime("%m%d%Y")].join(",") + "\n"
          csv_string = csv_string + csv
          break
        end

      end
    end

    return csv_string unless csv_string.blank?
  end
end
