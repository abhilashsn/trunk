# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

module Admin::JobHelper
  

  def get_interest_in_service_line_from_facility_details_column(facility_details_column)
    interest_in_service_line = false
    key_value_array = facility_details_column.to_s.split("\n")
    key_value_array.each do |item|
      if item.strip == "interest_in_service_line: true"
        interest_in_service_line = true
        break
      end
    end
    interest_in_service_line
  end
  
  def amount_so_far_for_job(amount_so_far, total_interest_amount, interest_in_service_line)
    if interest_in_service_line
      amount_so_far -= total_interest_amount
    end
    amount_so_far
  end

  def sort_header(text, field)
    key = field
    unless params[:sort].blank?
      params[:sort] = (params[:sort].class == String ? params[:sort] : params[:sort].keys[0])      
      key += "_reverse"  if params[:sort] == field
    end
    link_to "#{text}" , {:action => 'allocate', :page => params[:page],
      :back_page => params[:back_page], :sort => key,
      :criteria => params[:criteria], :compare => params[:compare],
      :to_find => params[:to_find], :jobs => @batch.id, :tab => params[:tab] }
  end
  
  def get_check_number job_id
    Job.find(job_id).check_number
  end

end

def filter_jobs(condition, tab_specific_condition)
  comp = params[:compare]
  search = params[:to_find].to_s.strip
  if params[:jobs].nil?
    @job_batchid = @batch.id
  else
    @job_batchid = params[:jobs]
  end
  condition << "batch_id = #{@job_batchid}" if condition.blank?
  condition << " and #{tab_specific_condition}"
  case params[:criteria]
  when 'Check Number'
    case comp
    when '='
      condition << " and check_informations.check_number like '%#{search}%'"
    else
      condition << " and check_informations.check_number #{comp} #{search}"
    end
  when 'Tiff Number'
    condition << " and tiff_number #{comp} '#{search}'"
  when 'Processor'
    condition << " and users.name like '%#{search}%'"
  when 'QA'
    condition << " and qa_users.name like '%#{search}%'"
  when 'Job Status'
    condition << " and job_status like '#{search}%'"
  when 'Processor Status'
    condition << " and jobs.processor_status like '#{search}%'"
  when 'QA Status'
    condition << " and jobs.qa_status like '#{search}%'"
  when 'Payer'
    condition << " and ((payers.payer IS NOT NULL and payers.payer like '#{search}%') OR (micr_payers.payer IS NOT NULL and micr_payers.payer like '#{search}%') OR (payers.payer IS NULL and micr_payers.payer IS NULL and '#{search.upcase}' = '#{"NO PAYER"}'))"
  when 'Check Amount'
    condition << " and check_informations.check_amount #{comp} '#{search.to_f}'"
  when 'Page To'
    condition << " and jobs.pages_to #{comp} '#{search.to_i}'"
  end
  return condition
end

def having_condition
  comp = params[:compare]
  search = params[:to_find].to_s.strip
  case params[:criteria]
  when 'Amount So Far'
    condition = " amount_so_far #{comp} '#{search.to_f}'"
  when 'Job ID'
    condition = " id #{comp} '#{search.to_f}'"
  when 'Balance'
    condition = " (check_amount_value - amount_so_far) #{comp} '#{search.to_f}'"
  when 'Completed EOBs'
    condition = " completed_eobs #{comp} #{search.to_i}"
  end
  return condition
end

def frame_order(field)
  case field
  when 'check_number'
    "check_informations.check_number"
  when 'processor_name'
    "users.name"
  when 'qa_name'
    "qa_users.name"
  when 'check_amount_value'
    "CASE WHEN parent_job_id IS NULL
      THEN check_informations.check_amount
      ELSE NULL
      END"
  when 'amount_so_far'
    "(CASE WHEN jobs.parent_job_id IS NOT NULL
       THEN SUM(((IFNULL(ins1.total_amount_paid_for_claim,0)) - (IFNULL(ins1.over_payment_recovery, 0))) +
       IFNULL(ins1.claim_interest,0) +
       IFNULL(ins1.late_filing_charge,0) + IFNULL(patient_pay_eobs.stub_amount,0) )
       ELSE
       SUM(((IFNULL(ins2.total_amount_paid_for_claim, 0)) - (IFNULL(ins2.over_payment_recovery, 0))) +
       IFNULL(ins2.claim_interest, 0) +
       IFNULL(ins2.late_filing_charge,0) + IFNULL(patient_pay_eobs.stub_amount,0) )
       END)"
  when 'balance'
    "((CASE WHEN parent_job_id IS NULL
      THEN check_informations.check_amount
      ELSE NULL
      END) - (CASE WHEN jobs.parent_job_id IS NOT NULL
       THEN SUM(((IFNULL(ins1.total_amount_paid_for_claim,0)) - (IFNULL(ins1.over_payment_recovery, 0))) +
       IFNULL(ins1.claim_interest,0) +
       IFNULL(ins1.late_filing_charge,0) + IFNULL(patient_pay_eobs.stub_amount,0) )
       ELSE
       SUM(((IFNULL(ins2.total_amount_paid_for_claim, 0)) - (IFNULL(ins2.over_payment_recovery, 0))) +
       IFNULL(ins2.claim_interest, 0) +
       IFNULL(ins2.late_filing_charge,0) + IFNULL(patient_pay_eobs.stub_amount,0) )
       END))"
  when 'name_payer'
    "(CASE WHEN payers.payer IS NOT NULL
      THEN payers.payer
      ELSE
      CASE WHEN micr_payers.payer IS NOT NULL
      THEN micr_payers.payer
      ELSE 'No Payer'
      END
      END)"
  else
    "jobs." + field
  end  
end


