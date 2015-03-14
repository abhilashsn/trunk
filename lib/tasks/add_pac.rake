namespace :db do
  task :add_pac => :environment do
    @insurance_payment_eob= InsurancePaymentEob.find(:all)
    @insurance_payment_eob.each do |insurancepayment|
      unless insurancepayment.patient_account_number
        service_dates_array=[]
        service_array_count=0
        insurancepayment.service_payment_eobs.each do |servicepayment|
          if  servicepayment.date_of_service_from
            service_dates_array[service_array_count]=servicepayment.date_of_service_from
            service_array_count+=1
          end
        end
        if service_dates_array[0]
          year_split = service_dates_array[0].strftime("%y").split("")
          if year_split[0].to_i == 0
            year = year_split[1]
          else
            year = service_dates_array[0].strftime("%y")
          end
          insurancepayment.patient_account_number=("00000-"+year+service_dates_array[0].strftime("%m")+service_dates_array[0].strftime("%d"))
        else
          insurancepayment.patient_account_number="00000"
        end
      end
      unless insurancepayment.patient_first_name
        insurancepayment.patient_first_name="RX"
      end
      unless insurancepayment.patient_last_name
        insurancepayment.patient_last_name =insurancepayment.service_payment_eobs.first.rx_number.to_s unless insurancepayment.service_payment_eobs.first.nil?
      end
      insurancepayment.save(:validate => false)
    end
    @service_payment_eob= ServicePaymentEob.find(:all)
    @service_payment_eob.each do|servicepayment|
      unless servicepayment.service_procedure_code
        servicepayment.service_procedure_code="ZZE01"
      end
      unless servicepayment.service_provider_control_number
        servicepayment.service_provider_control_number  ="001-FA1"
      end
      servicepayment.save(:validate => false)
    end
  end
end