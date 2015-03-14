require 'will_paginate/array'
class ReportController < ApplicationController

  require_role "processor"
  layout 'standard'
  PER_PAGE = 30

  def listing_my_jobs
    @total_ins_eobs = 0
    @total_nextgen_eobs = 0
    @total_pat_eobs = 0
    @total_corres_eobs = 0

    @total_ins_service_lines = 0
    @total_pat_service_lines = 0
    @total_corres_service_lines = 0

    @total_ins_normalised_eob = 0
    @total_ins_normalised_svc = 0
    @total_pat_normalised_eob = 0
    @total_pat_normalised_svc= 0
    @total_corres_normalised_eob = 0
    @total_corres_normalised_svc = 0
    @total_nextgen_normalised_eob = 0

    #Insurance Payment EOB
    join = "LEFT OUTER JOIN service_payment_eobs ON service_payment_eobs.insurance_payment_eob_id = insurance_payment_eobs.id
                    LEFT OUTER JOIN check_informations ON check_informations.id = insurance_payment_eobs.check_information_id
                    LEFT OUTER JOIN jobs ON jobs.id = check_informations.job_id
                    LEFT OUTER JOIN batches ON batches.id = jobs.batch_id
                    LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id
                    LEFT OUTER JOIN clients ON clients.id = batches.client_id
                    LEFT OUTER JOIN payers ON payers.id = check_informations.payer_id"
    
    select =  "batches.batchid as batchid , batches.date as date,
                    jobs.id as job_id,
                    insurance_payment_eobs.created_at as created_at,
                    insurance_payment_eobs.patient_account_number as account_number,
                    check_informations.check_number as check_number,
                    check_informations.id as id,
                    facilities.name as facility_name,
                    clients.name as client_name,
                    insurance_payment_eobs.id as eob_id,
                    insurance_payment_eobs.category,
                    insurance_payment_eobs.start_time as start_time,
                    insurance_payment_eobs.end_time as end_time,
                    CASE 
                    WHEN (insurance_payment_eobs.category = 'claim')
                      THEN #{1}
                    ELSE 
                      count(service_payment_eobs.id)
                    END as service_payment_eobs_count"
 
    
    condition1 = "insurance_payment_eobs.processor_id = #{@current_user.id}"
    if params[:processing_completed]
      condition2 = " and insurance_payment_eobs.processing_completed like '#{params[:processing_completed]}%'"
    else
      condition2 = " and insurance_payment_eobs.end_time >= '#{(Time.now - 12.hours).strftime("%Y-%m-%d %H:%M:%S").to_s}'"
    end
    condition3 = " and payers.payer_type != 'PatPay'"

    @allcorres_eobs = @allins_eobs = InsurancePaymentEob.where(condition1 + condition2 + condition3).
      select(select).
      joins(join).
      group("insurance_payment_eobs.id")
      
    @all_corres_eobs = []
    @all_ins_eobs = []
    
    unless @allins_eobs.nil?
      @allins_eobs.each do |eob|
        if CheckInformation.find(eob.id).correspondence?
          @all_corres_eobs << eob
        else
          @all_ins_eobs << eob
        end
      end
      #Insurance
      unless @all_ins_eobs.nil?
        @ins_eobs = @all_ins_eobs.paginate(:page => params[:page], :per_page => PER_PAGE)
        @total_ins_eobs = @all_ins_eobs.length
        @all_ins_eobs.each do |ins_eob|
          @total_ins_service_lines += ins_eob.service_payment_eobs_count.to_i
          @total_ins_normalised_eob += ins_eob.normalised_eob(ins_eob.facility_name).to_f
          @total_ins_normalised_svc += normalised_svc_calculation(ins_eob)
        end
      end
      #Correspondence
      unless @all_corres_eobs.nil?
        @corres_eobs = @all_corres_eobs.paginate(:page => params[:page], :per_page => PER_PAGE)
        @total_corres_eobs = @all_corres_eobs.length
        @all_corres_eobs.each do |corres_eob|
          @total_corres_service_lines += corres_eob.service_payment_eobs_count.to_i
          @total_corres_normalised_eob += corres_eob.normalised_eob(corres_eob.facility_name).to_f
          @total_corres_normalised_svc += normalised_svc_calculation(corres_eob)
        end
      end
    end

    #Patient Payment EOB
    condition3 = " and payers.payer_type = 'PatPay'"
    @all_pat_eobs = InsurancePaymentEob.where(condition1 + condition2 + condition3).
      select(select).
      joins(join).
      group("insurance_payment_eobs.id").
      paginate(:page => params[:page], :per_page => PER_PAGE)
    unless @all_pat_eobs.nil?
      @pat_eobs = @all_pat_eobs
      @total_pat_eobs = @all_pat_eobs.length
      @all_pat_eobs.each do |pat_eob|
        @total_pat_service_lines +=  pat_eob.service_payment_eobs_count.to_i
        @total_pat_normalised_eob +=  pat_eob.normalised_eob(pat_eob.facility_name).to_f
        @total_pat_normalised_svc +=  normalised_svc_calculation(pat_eob)
      end
    end

    
    #NextGen
    join1 = "LEFT OUTER JOIN check_informations ON check_informations.id = patient_pay_eobs.check_information_id
                    LEFT OUTER JOIN jobs ON jobs.id = check_informations.job_id
                    LEFT OUTER JOIN batches ON batches.id = jobs.batch_id
                    LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id
                    LEFT OUTER JOIN clients ON clients.id = batches.client_id"

    select =  "batches.batchid as batchid , batches.date as date,
                    jobs.id as job_id,
                    patient_pay_eobs.created_at as created_at,
                    patient_pay_eobs.account_number as account_number,
                    check_informations.check_number as check_number,
                    facilities.name as facility_name,
                    check_informations.id as id,
                    clients.name as client_name,
                    patient_pay_eobs.id as eob_id,
                    patient_pay_eobs.start_time as start_time,
                    patient_pay_eobs.end_time as end_time"

    condition1 = "patient_pay_eobs.processor_id = #{@current_user.id}"
    if params[:processing_completed]
      condition2 = " and patient_pay_eobs.processing_completed like '#{params[:processing_completed]}%'"
    else
      condition2 = " and patient_pay_eobs.end_time >= '#{(Time.now - 12.hours).strftime("%Y-%m-%d %H:%M:%S").to_s}'"
    end
    @all_nextgen_eobs = PatientPayEob.where(condition1 + condition2).
      select(select).
      joins(join1).
      group("patient_pay_eobs.id").
      paginate(:page => params[:page], :per_page => PER_PAGE)
    unless @all_nextgen_eobs.nil?
      @nextgen_eobs = @all_nextgen_eobs
      @total_nextgen_eobs = @all_nextgen_eobs.length
      @all_nextgen_eobs.each do |nextgen_eob|
        @total_nextgen_normalised_eob += nextgen_eob.normalised_eob(nextgen_eob.facility_name).to_f
      end
    end
    
  end

  def completed_eobs_report
    @ins_eobs = nil
    @pat_eobs = nil
    flash[:notice] = nil
    if params[:commit].eql?('View')
      if (!(params[:date_from].blank?) and !(params[:date_to].blank?))
        @date_from = params[:date_from]
        @date_to = params[:date_to]
        from = Date.strptime(params[:date_from].to_s,"%m/%d/%Y").to_date
        to = Date.strptime(params[:date_to].to_s, "%m/%d/%Y").to_date
        from_date_time = from.strftime("%Y-%m-%d") + ' 00:00:00'
        to_date_time = to.strftime("%Y-%m-%d") + ' 23:59:59'

        if from < (to - 3.days)
          flash[:notice] = "The From Date and To Date range should not exceed 3 days."
        end
      elsif ((params[:date_from].blank?) and (not params[:date_to].blank?))
        flash[:notice] = "From Date Mandatory"
      elsif ((not params[:date_from].blank?) and (params[:date_to].blank?))
        flash[:notice] = "To Date Mandatory"
      else
        if (( params[:date_from].blank?) and (params[:date_to].blank?))
          flash[:notice] = "Dates are Mandatory"
        end
      end
    else
      from_date_time = (Date.today - 1.month).to_s + ' 00:00:00'
      to_date_time = (Date.today).to_s + ' 23:59:59'
    end
    
    sql =   "SELECT
              processing_completed AS processing_completed ,
              facility_id, category,
              insurance_payment_eobs.processor_id AS processor_id,
              COUNT(distinct insurance_payment_eobs.id) AS eob_count,
              CASE
                WHEN (insurance_payment_eobs.category = 'claim')
                THEN count(insurance_payment_eobs.id)
                ELSE
                   count(service_payment_eobs.id)
                END as svc_count,
              CASE
                WHEN (SUBSTRING_INDEX(SUBSTRING(facilities.details,LOCATE('claim_normalized_factor: ',facilities.details)+26), '\"\"', 1)
                REGEXP '[0-9]')
                THEN
                (
                 CAST(SUBSTRING_INDEX(SUBSTRING(facilities.details,LOCATE('claim_normalized_factor: ',facilities.details)+26), '\"\"', 1) AS DECIMAL(4,2)) *
                 COUNT(distinct insurance_payment_eobs.id)
                )
                ELSE
                 0
                END AS normalized_eob_count,
              CASE
                WHEN (SUBSTRING_INDEX(SUBSTRING(facilities.details,LOCATE('service_line_normalised_factor: ',facilities.details)+33), '\"\"', 1)
                REGEXP '[0-9]')
                THEN
                (
                  CAST(SUBSTRING_INDEX(SUBSTRING(facilities.details,LOCATE('service_line_normalised_factor: ',facilities.details)+33), '\"\"', 1) AS DECIMAL(4,2)) *
                  CASE
                  WHEN (insurance_payment_eobs.category = 'claim')
                  THEN count(insurance_payment_eobs.id)
                  ELSE
                   count(service_payment_eobs.id)
                  END
                )
                ELSE
                 0
                END
                 AS normalized_svc_count
        FROM `insurance_payment_eobs`
        LEFT OUTER JOIN service_payment_eobs ON service_payment_eobs.insurance_payment_eob_id = insurance_payment_eobs.id
        LEFT OUTER JOIN check_informations ON check_informations.id = insurance_payment_eobs.check_information_id
        LEFT OUTER JOIN jobs ON jobs.id = check_informations.job_id
        LEFT OUTER JOIN batches ON batches.id = jobs.batch_id
        LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id
        WHERE (insurance_payment_eobs.processor_id = #{@current_user.id} and insurance_payment_eobs.processing_completed BETWEEN '#{from_date_time}' AND '#{to_date_time}')
        GROUP BY processing_completed,facility_id,category
        ORDER BY processing_completed,facility_id,category"

    @ins_pat_corres_eobs = InsurancePaymentEob.find_by_sql(sql)

    sql1 =   "SELECT processing_completed AS processing_completed ,
                    facility_id,
                    patient_pay_eobs.processor_id AS processor_id,
                    COUNT(patient_pay_eobs.id) AS eob_count,
                    0 AS svc_count,
             CASE
             WHEN (SUBSTRING_INDEX(SUBSTRING(facilities.details,LOCATE('claim_normalized_factor: ',facilities.details)+26), '\"\"', 1)
             REGEXP '[0-9]')
             THEN
              (
               CAST(SUBSTRING_INDEX(SUBSTRING(facilities.details,LOCATE('claim_normalized_factor: ',facilities.details)+26), '\"\"', 1) AS DECIMAL(4,2)) *
               COUNT(patient_pay_eobs.id)
              )
             ELSE
              0
             END
            AS normalized_eob_count,
            0 AS normalized_svc_count
            FROM `patient_pay_eobs`
        LEFT OUTER JOIN check_informations ON check_informations.id = patient_pay_eobs.check_information_id
        LEFT OUTER JOIN jobs ON jobs.id = check_informations.job_id
        LEFT OUTER JOIN batches ON batches.id = jobs.batch_id
        LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id
        WHERE (patient_pay_eobs.processor_id = #{@current_user.id} and patient_pay_eobs.processing_completed BETWEEN '#{from_date_time}' AND '#{to_date_time}')
        GROUP BY processing_completed,facility_id
        ORDER BY processing_completed,facility_id"
    
    @nextgen_eobs = PatientPayEob.find_by_sql(sql1)
    
    @all_eobs = (@ins_pat_corres_eobs + @nextgen_eobs).sort_by(&:processing_completed)

  end

  def normalised_svc_calculation(eob)
    if eob.category == 'claim'
      count = eob.normalised_svc(eob.facility_name).to_f * 1
    else
      count = eob.normalised_svc(eob.facility_name).to_f * (eob.service_payment_eobs_count).to_i
    end
    return count
  end
  
end
