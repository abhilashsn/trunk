require 'csv'
class ImageShuffleController < ApplicationController
  layout "standard"
  require_role ["admin","supervisor"]
  
  #This is for shuffling images from one check to another. Suppose there are two checks, check1 and check2. 
  #Check1 has got 10 images and check2 has got 5 images.If we want to add 
  # two images form check1 to check2, then specify the check2, from image name &
  #To image name.

  def index
    @batch = Batch.select("batches.id AS id,batches.batchid AS batchid,batches.date AS date").where("status IN ('#{BatchStatus::NEW}','#{BatchStatus::PROCESSING}')")
  end

  def batch_details
    @batch = Batch.find(params[:batch_id])
  end

  def shuffle
    @job = Job.find(params[:job_id])    
  end
  
  def update_image_shuffle
    image_from = params[:image_from]
    image_to = params[:image_to]
    relation_include = [{:client_images_to_jobs => :job}]
    
    if(image_from.blank? && image_to.blank?)
      flash[:notice] = 'Please Enter Image From Name & Image To Name'
      redirect_to :back
    elsif(image_from.blank? && !image_to.blank?)
      flash[:notice] = 'Please Enter Image From Name'
      redirect_to :back
    elsif(!image_from.blank? && image_to.blank?)
      flash[:notice] = 'Please Enter Image To Name'
      redirect_to :back
    else
      job = Job.find(params[:job_id])
      batch = Batch.find(params[:batch_id])
      if !job.blank? && !batch.blank?
        client_name = batch.facility.client.name
        if client_name.upcase == 'QUADAX'
          condition = "images_for_jobs.batch_id = #{batch.id} AND "
        else
          batch_ids = Batch.where("date = '#{batch.date}'").select("id").map{ |batch| batch.id}
          condition = "images_for_jobs.batch_id IN (#{batch_ids.join(',')}) AND " if !batch_ids.blank?
        end
        jobid = job.id
        shuffled_images = ImagesForJob.find(:all,
          :conditions => ["#{condition} images_for_jobs.image_file_name BETWEEN ? and ?", image_from, image_to],
          :include => relation_include, :readonly => false)
        old_job_id_of_image = nil
        last_index = job.images_for_jobs.count
        
        unless shuffled_images.blank?
          shuffled_images.each_with_index do |image, i|
            client_image_to_job = ClientImagesToJob.find_by_images_for_job_id(image.id)
            old_job_id_of_image = client_image_to_job.job_id
            job_of_the_image = Job.find(client_image_to_job.job_id)
            job_of_the_image.pages_to -= 1
            job_of_the_image.save
            client_image_to_job.update_attributes(:job_id => jobid, :sub_job_id => nil)
            client_image_to_job.save(:validate=>false)
            image.updated_at = Time.now
            image.image_number = last_index + i + 1
            image.save
          end
          job.pages_to += shuffled_images.count
          job.save

          if old_job_id_of_image
            JobActivityLog.create_activity({:job_id => old_job_id_of_image,
                :allocated_user_id => @current_user.id,
                :activity => 'Images Are Removed', :start_time => Time.now,
                :object_name => 'jobs', :object_id => old_job_id_of_image,
                :field_name => 'images', :old_value => image_from + " TO " + image_to})
          end
          JobActivityLog.create_activity({:job_id => jobid,
              :allocated_user_id => @current_user.id,
              :activity => 'Images Are Added', :start_time => Time.now,
              :object_name => 'jobs', :object_id => jobid,
              :field_name => 'images', :new_value => image_from + " TO " + image_to})

          flash[:notice] = 'Images Updated'
          redirect_to :action => 'index'
        else
          flash[:notice] = 'No Images found!!'
          redirect_to :back
        end
      else
        flash[:notice] = 'No Check found!!'
        redirect_to :back
      end
    end
  end
  
  def update_images_pages
    count = 0 
    @parsed_file = CSV::Reader.parse(params[:upload][:file])
    @parsed_file.each  do |row|
     
      if(count > 0)
        job = Job.find(:first,:conditions=>"check_number = '#{row[0]}' and batch_id = #{params[:batch]}")
        job.pages_from = 1
        job.pages_to   = row[1].to_i
        job.save
      end
      count = count + 1 
      
    end
    redirect_to :controller => '/admin/batch' ,:action => 'add_job' ,:id => params[:batch]
  end
end
