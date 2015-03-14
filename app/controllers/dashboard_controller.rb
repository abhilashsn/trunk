# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class DashboardController < ApplicationController
  
  # require_role ["admin","processor","manager","supervisor","qa","partner","TL","client","facility"]
  layout 'standard'
  
  def index     
    flash[:notice] = nil    
    if current_user
      payer_count_obj = Payer.find_by_sql("	SELECT COUNT(*) as payer_count FROM (
        SELECT DISTINCT payers.id AS pid, micr_line_informations.id AS MID
        FROM `payers`
        INNER JOIN `check_informations` ON `check_informations`.`payer_id` = `payers`.`id`
       LEFT OUTER JOIN micr_line_informations  ON payers.id = micr_line_informations.payer_id
        WHERE (payers.status = 'CLASSIFIED' OR payers.status = 'CLASSIFIED_BY_DEFAULT' OR
        payers.status = 'NEW') OR (micr_line_informations.status = 'NEW')
        )  AS count_table")
      @new_payer_count = payer_count_obj[0].payer_count
      job_count_object = Job.find_by_sql("SELECT COUNT(id) AS additional_job_request_queue_count \
        FROM jobs WHERE job_status = 'ADDITIONAL_JOB_REQUESTED'")
      @additional_job_request_queue_count = job_count_object[0].additional_job_request_queue_count if job_count_object[0].present?
      if (current_user.has_role?(:client)  or current_user.has_role?(:facility))
        if(current_user.lockboxes.first.client.name == 'Navicure')
          render :layout => 'navicure'
        end
      end
    else
      redirect_to :controller=> 'devise/sessions',:action => 'new'
    end
  end

end
