module Ocr
  class OcrPackage
    
    def initialize inbound
      @inbound = inbound      
      @parent_dir = Rails.root.to_s + "/OCR"
    end

    
    def perform
      job_and_images do |batch, job, images|
        directory = ocr_job_directory batch, job
        ocr_copy_images directory, batch, job, images
        #job_given_to_ocr job
      end      
    end

    private

    def ocr_job_directory batch,job
      #directory_name = batch.batchid + "/" + job.id.to_s
      directory_name = ""
      abs_dir_path = @parent_dir + "/" + directory_name
      FileUtils.mkdir_p(abs_dir_path)
      return abs_dir_path
    end

    def ocr_copy_images directory, batch, job, images
      image_paths = images.collect(&:public_filename_url)
      if images.size > 0
        system_command = "tiffcp " +  image_paths.join(" ") + " #{directory}/#{batch.batchid}_#{job.id.to_s}.tif" 
        system system_command
      end
    end

    def job_given_to_ocr job
      job.update_attribute(:job_status, "#{JobStatus::OCR}")
    end
    
    #find all images_for jobs
    def job_and_images
      @batches = Batch.includes(:jobs=>[:images_for_jobs]).where("inbound_file_information_id = #{@inbound.id} AND correspondence != '1'")      
      @batches.each do |batch|        
        batch.jobs.each do |job|                
          if job.job_status == JobStatus::NEW
            yield batch, job, job.images_for_jobs 
          end
        end
      end            
    end    
  end

end
