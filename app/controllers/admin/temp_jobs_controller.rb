class Admin::TempJobsController < ApplicationController 

  def create
    temp_job = TempJob.new(params[:temp_job])
    temp_job.image_from = params[:image_from]
    temp_job.image_to = params[:image_to]
    temp_job.image_count = params[:image_count]
    temp_job.job_id = params[:job_id]
    if temp_job.image_count.blank?
      temp_job.image_count = 1
    end
    temp_job.save
    @temp_job = temp_job

    if @temp_job.errors.blank?
      redirect_to :action => "list", :job_id => params[:job_id]
    else
      render :partial => "index"
    end
  end

  def show    
    prepare
    render :partial => "index"
  end

  def new
    prepare
    render :partial => "new"
  end

  def prepare
    @temp_jobs = TempJob.where(:job_id => params[:job_id])
    temp_job_image_ids = TempJob.get_image_ids(params[:job_id])
    @job_information = Job.find(params[:job_id])
    @job_id = @job_information.id
    if @job_information.images_for_jobs
      @images = @job_information.images_for_jobs.sort{|a,b| a.image_number <=> b.image_number}
      @images = @images.reject{|img| temp_job_image_ids.include?img.id} if temp_job_image_ids.present?
      @image_count = @images.count - 1
      @image_names = @images.map{|i| i.image_file_name}
    end
  end

  def delete
    TempJob.destroy(params[:id])
    redirect_to :action => "list", :job_id => params[:job_id]
  end

end 
