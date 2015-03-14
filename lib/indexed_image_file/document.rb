#Represents an Indexed Image document
class IndexedImageFile::Document
  attr_reader :checks
  def initialize(checks)
    @checks = checks
  end

  # Generate method for indexed image file creation
  def generate
    index_image_string = ""
    index_image_string << transactions
    index_image_string unless index_image_string.blank?
  end

  # Wrapper for each check in this Indexed Image
  def transactions
    index_image_string = ""
    incomplete_checks = []
    incomplete_payers = []
    aggregate_incomplete_checks = []
    final_checks = []
    index = 0
    
    #Grouped the checks on payid as of operation log and displayed the checks 
    #in that order to make this report also same as that of operation log.
    grouped_checks = checks.group_by{|check| get_payer_cpid_criteria(check).to_s}
    group_keys = grouped_checks.keys.sort
    
    group_keys.each do |group_key|
      final_checks << grouped_checks[group_key]
    end
    final_checks = final_checks.flatten.compact
    final_checks.each do |check|
      if !check.insurance_payment_eobs.blank?
        get_ordered_insurance_payment_eobs(check).each_with_index do |eob, eob_index|
          if eob.patient_account_number && eob.patient_account_number.upcase == "CORR" && check.job.job_status == "#{JobStatus::INCOMPLETED}" && check.correspondence?
            incomplete_checks << check
            incomplete_payers << check.payer.payer.strip unless check.payer.blank?
          end
          if eob.patient_account_number && (check.job.job_status == "#{JobStatus::COMPLETED}" || check.job.job_status == "#{JobStatus::INCOMPLETED}")  && !check.correspondence?
            if eob_index == 0
               index += 1
              check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
              check_obj = check_klass.new(check, index, nil)
              index_image_string += check_obj.generate
            end
            check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
            check_obj = check_klass.new(check, index, eob)
            index_image_string += check_obj.generate
          end
        end

        elsif !check.patient_pay_eobs.blank?
        get_ordered_patient_payment_eobs(check).each_with_index do |eob, eob_index|
          if eob.account_number && (check.job.job_status == "#{JobStatus::COMPLETED}" || check.job.job_status == "#{JobStatus::INCOMPLETED}")  && !check.correspondence?
            if eob_index == 0
               index += 1
              check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
              check_obj = check_klass.new(check, index, nil)
              index_image_string += check_obj.generate
            end
            check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
            check_obj = check_klass.new(check, index, eob)
            index_image_string += check_obj.generate
          end
        end

      else
         index += 1
        check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
        check_obj = check_klass.new(check, index, nil)
        index_image_string += check_obj.generate
      end
    end
    
    incomplete_payers = incomplete_payers.uniq
    incomplete_payers.each do |payer|
      count = 0
      incomplete_checks.each do |check|
        if check.payer.payer.strip == payer
          count+=1
          aggregate_incomplete_checks << check if count == 1
        end
      end
     end
    
    if aggregate_incomplete_checks.length >= 1
      aggregate_incomplete_checks.each do |check| 
        index += 1       
        if check.job.job_status == "#{JobStatus::INCOMPLETED}" && check.payer
          check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
          check_obj = check_klass.new(check, index, nil)
          index_image_string += check_obj.generate
        end
      end       
    end
    
    index_image_string unless index_image_string.blank?
  end
  
  def get_payer_cpid_criteria check
    batch = check.batch
    facility = batch.facility
    check_payer = check.payer
    if check.micr_line_information
      payer = check.micr_line_information.payer 
      payer ? payer.output_payid(facility) : nil
    elsif check_payer
      check_payer.output_payid(facility)
    else
      nil
    end
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("balance_record_type asc, image_page_no, end_time asc")
  end

  def get_ordered_patient_payment_eobs(object)
    object.patient_pay_eobs.order(:image_page_no, :end_time)
  end


end

