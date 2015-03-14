namespace :productivity do
  desc "Calculates Avg Processing Productivity per month per facility"
  
  # This rake task will be scheduled through cron job to triggered on every last day of the month.
  # It is run as rake productivity:avg_processing["facility_name"]
  # Logic used :
  # Average Processing productivity is a value calculated over a month, and it reflects how much time a processor would take, on an avg. to complete an EOB from a given Facility.
  # Completed EOBs in last 30 days = Total EOBs from the batches that were 'completed' during (today-30 day) period, belonging to the given facility.
  # Average Processing productivity = Total Completed EOBs in last 30 days/(Total time taken in minutes to complete Completed EOBs in last 30 days)
  # Average Processing productivity is calculated for Patient Pay EOB and Insurance EOB

  task :avg_processing, [:facility_name] => [:environment] do |t, args|
    begin
      facility = Facility.find(:first, :conditions => ["name=?",args.facility_name])
      facility_id = facility.id
    rescue Exception => e
      puts "The facility '#{args.facility_name}' does not exist. \nPlease give a correct facility name."
    else
      month_ago = 1.months.ago  # DateTime a month ago
      today = Time.now
      total_insurance_eobs, total_patient_pay_eobs = 0, 0

      # Initiating the variables total_time_insurance_eobs & total_time_patient_pay_eobs with a 'zero' time to sum up the total time taken in minutes to complete Completed EOBs in last 30 days
      time = Time.now - Time.new
      total_time_insurance_eobs = time
      total_time_patient_pay_eobs = time
    
      # Completed batches in a month of the facility
      completed_batches = Batch.find(:all, :conditions => ["facility_id = ? and status = ? and completion_time >= ? and completion_time <= ?", facility_id, BatchStatus::COMPLETED, month_ago, today])
      if completed_batches.blank?
        puts "There are no completed batches for this facility in this month."
      else
        completed_batches.each do |batch|
          batch.jobs.each do |job|

            # Finds the Insurance Payment EOBs processed and the processed time
            insurance_checks = CheckInformation.find(:all, :conditions =>["job_id=? and payers.payer_type!=?", job.id, 'PatPay'], :include => [:payer])
            insurance_checks.each do |check|
              total_insurance_eobs += check.insurance_payment_eobs.size
              check.insurance_payment_eobs.each do |insurance_payment_eob|
                unless (insurance_payment_eob.end_time.blank? || insurance_payment_eob.start_time.blank? || ((insurance_payment_eob.end_time.to_time - insurance_payment_eob.start_time) / 60) <= 0)
                  # Difference of the time gives seconds in a  float number
                  # Division by 60 gives the time in minutes
                  total_time_insurance_eobs += ((insurance_payment_eob.end_time.to_time - insurance_payment_eob.start_time) / 60)
                end
              end
            end
            
            # Finds the Patient Payment EOBs processed and the processed time
            patpay_checks = CheckInformation.find(:all, :conditions =>["job_id=? and payers.payer_type=?", job.id, 'PatPay'], :include => [:payer])
            patpay_checks.each do |check|
              # Patient Payment EOBs in insurance_payment_eobs
              total_patient_pay_eobs += check.insurance_payment_eobs.size
              check.insurance_payment_eobs.each do |patient_pay_eob|
                unless (patient_pay_eob.end_time.blank? || patient_pay_eob.start_time.blank?  || ((patient_pay_eob.end_time.to_time - patient_pay_eob.start_time) / 60) <= 0)
                  # Difference of the time gives seconds in a  float number
                  # Division by 60 gives the time in minutes
                  total_time_patient_pay_eobs += ((patient_pay_eob.end_time.to_time - patient_pay_eob.start_time) / 60)
                end
              end
              # Patient Payment EOBs in patient_pay_eobs
              total_patient_pay_eobs += check.patient_pay_eobs.size
              check.patient_pay_eobs.each do |patient_pay_eob|
                unless (patient_pay_eob.end_time.blank? || patient_pay_eob.start_time.blank?  || ((patient_pay_eob.end_time.to_time - patient_pay_eob.start_time) / 60) <= 0)
                  # Difference of the time gives seconds in a  float number
                  # Division by 60 gives the time in minutes
                  total_time_patient_pay_eobs += ((patient_pay_eob.end_time.to_time - patient_pay_eob.start_time) / 60)
                end
              end
            end
          end
        end
      end
      begin
        facility.average_insurance_eob_processing_productivity = total_insurance_eobs / total_time_insurance_eobs
        facility.save
      rescue Exception => e    # From division by zero
        facility.average_insurance_eob_processing_productivity = 0
        facility.save
      end
      begin
        facility.average_patient_pay_eob_processing_productivity = total_patient_pay_eobs / total_time_patient_pay_eobs
        facility.save
      rescue Exception => e    # From division by zero
        facility.average_patient_pay_eob_processing_productivity = 0
        facility.save
      end
    end
  end
end  



