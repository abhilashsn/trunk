 require 'HREOB/EDCHrEob.rb'
 module OtherOutput
   class Generator
     def initialize batch_id
       @batch_id = batch_id
       batch = Batch.find(@batch_id) rescue nil
       @generate = false
       if batch
         @generate = true
         @facility = batch.facility
         @configs = FacilityOutputConfig.other_outputs @facility.id            
       end
     end

     def generate
       if !@generate
         puts "Batch not found...."
         return
       end
       file_names = Array.new
       zip_files = Hash.new
       activity_logs = []
       @configs.each do |conf|
         if conf.other_output_type == "Human Readable Eob"
           generate_human_readable_eob
         else
           conf = OtherOutput::Config.new(conf.operation_log_config)        
           doc = OtherOutput::Document.new(@batch_id, conf)
           file_name = doc.instance_variable_get("@filename")
           batch_ids = doc.accumulated_batch_ids
           op_file_name = File.basename(file_name)
           if conf.zip_file_name.present?
             op_file_name = File.basename(doc.get_zip_file_name)
           end
           batch_ids.each do |batch_id|
             activity_logs << OutputActivityLog.associate_file_to_batch(op_file_name,
                                                                        File.dirname(op_file_name),
                                                                        nil,
                                                                        batch_id,
                                                                        conf.report_type.split(" ").first)
           end
           file_name = doc.generate_file
           file_names << file_name
           if conf.zip_file_name.present?
             if !zip_files[doc.get_zip_file_name] 
               zip_files[doc.get_zip_file_name] = Array.new
             end
             zip_files[doc.get_zip_file_name] << file_name
           end
         end
       end         
       post_process_files zip_files 
       activity_logs.map{|log| log.mark_generated_with_checksum}       
     end    

     def generate_specific conf
       file_names = Array.new
       zip_files = Hash.new
       doc = OtherOutput::Document.new(@batch_id, conf)
       batch_ids = doc.accumulated_batch_ids
       activity_logs = []
       file_name = doc.instance_variable_get("@filename")
       op_file_name = File.basename(file_name)
       if conf.zip_file_name.present?
         op_file_name = File.basename(doc.get_zip_file_name)
       end
       batch_ids.each do |batch_id|
         activity_logs << OutputActivityLog.associate_file_to_batch(op_file_name,
                                                                    File.dirname(file_name),
                                                                    File.size?("#{file_name}").to_i,
                                                                    batch_id,
                                                                    conf.report_type.split(" ").first)
       end
       file_name = doc.generate_file       
       file_names << file_name
       if conf.zip_file_name.present?
         if !zip_files[doc.get_zip_file_name] 
           zip_files[doc.get_zip_file_name] = Array.new
         end
         zip_files[doc.get_zip_file_name] << file_name
       end       
       post_process_files zip_files        
       activity_logs.map{|log| log.mark_generated_with_checksum}       
     end

     
     def post_process_files zip_files
       zip_files.keys.each do |z|
         OtherOutput::Zipper.new(z, zip_files[z]).archive
       end
     end

     def generate_human_readable_eob
       facility_name = @facility && @facility.name ? @facility.name : "unknown"
       directory = "private/datanew/other_outputs/#{facility_name}/txt/human_readable/#{Date.today.to_s}"    
       FileUtils.mkdir_p(directory)
       hreob = EDCHrEob.new(directory)
       hreob.generate_edc_hr_eob(@batch_id)
     end
     
   end  
 end
