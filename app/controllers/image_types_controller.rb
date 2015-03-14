class ImageTypesController < ApplicationController
  layout 'image_types'
  before_filter :prepare
  in_place_edit_for :image_type, :patient_last_name
  in_place_edit_for :image_type, :patient_first_name
  in_place_edit_for :image_type, :patient_account_number
  in_place_edit_with_validation_for :image_type, :image_type
  # GET /image_types
  # GET /image_types.xml
  def index
    redirect_to :action => "list"
  end
 
  # GET /image_types/1
  # GET /image_types/1.xml
  def list
    job = Job.find(params[:job_id], :include => :images_for_jobs)
    exact_job_id = job.get_parent_job_id
    job = Job.find(exact_job_id, :include => :images_for_jobs) if exact_job_id != job.id
    batch = job.batch
    @facility = batch.facility
    images_for_jobs = job.images_for_jobs
    unless images_for_jobs.blank?
      images_for_jobs_ids = []
      images_for_jobs.each do |images_for_job|
        images_for_jobs_ids << images_for_job.id
      end
    end
    @image_types = ImageType.includes(:insurance_payment_eob).where(["images_for_job_id IN (?) ", images_for_jobs_ids]).order("image_page_number asc").paginate( :per_page => 50,:page => params[:page]) unless images_for_jobs_ids.blank?
  end
  
 
  # POST /image_types
  # POST /image_types.xml
  def create
    patient_last_name = params[:image_type][:patient_last_name].strip
    patient_first_name = params[:image_type][:patient_first_name].strip
    patient_account_number = params[:image_type][:patient_account_number].strip
    image_type = params[:image_type][:image_type]
    image_page_no = params[:image_type][:image_page_number]
    if image_page_no.blank?
      flash[:notice] = "Can't create image type without image page number."
    else
      image_page_no = image_page_no.strip
      job_id = params[:job_id]
      job = Job.find(job_id)
      exact_job_id = job.get_parent_job_id
      job = Job.find(exact_job_id) if exact_job_id != job.id
      images_for_job_id = job.get_exact_images_for_job_reference(image_page_no)
      unless images_for_job_id.blank?
        image_type_for_job = ImageType.create( :image_type => image_type, 
          :patient_account_number => patient_account_number,
          :patient_last_name => patient_last_name, 
          :patient_first_name => patient_first_name,
          :image_page_number => image_page_no, 
          :images_for_job_id => images_for_job_id)
      end
      unless image_type_for_job.blank?
        flash[:notice] = "Image_type created successfully."
      else
        flash[:notice] = "Failed creating image_type."
      end
      logger.debug "Imagetype Creation ends"  
    end
    redirect_to :action => "list", :job_id => params[:job_id], :page => params[:page]
  end
  
  # DELETE /image_types/1
  # DELETE /image_types/1.xml
  def destroy
    image_type = ImageType.find(params[:id])
    unless image_type.blank?
      image_type.destroy
      flash[:notice] = "Image_type deleted successfully."
    else
      flash[:notice] = "Failed deleting image_type."
    end
    redirect_to :action => "list", :job_id => params[:job_id], :page => params[:page]
  end

  private

  def prepare
    logger.debug "prepare ->"
    @is_partner_bac = $IS_PARTNER_BAC
  end
  
end
