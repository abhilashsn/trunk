class EobReportsController < ApplicationController
  layout 'standard'
  
  def list
    @db_clients = Client.find(:all)
    @clients = @db_clients.collect {|p| [p.name ,p.id]}
  end

  #EOB Report Generation functionality
  def eob_list
    require 'aggregate_report'
    conditions = frame_eob_report_criteria
    batches = Batch.where(conditions)
    if !batches.blank?
      flash_notice = "Generating EOB report"
      start_generating_eob_report(batches)
    else
      flash_notice = "No batches qualified of EOB report generation"
      flash[:notice] = flash_notice if flash_notice.present?
      redirect_to :action => 'list'
    end
  end

end
