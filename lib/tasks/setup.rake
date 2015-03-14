namespace :setup do
  
  task :partner => :environment do
    clients = Client.all
    clients.each do |client|
      if client.name.upcase == "POLYMEDICA"
        client.partner_id = Partner.find_by_name("Healthlogic") ? Partner.find_by_name("Healthlogic").id : nil
        client.save!
      else
        client.partner_id = Partner.find_by_name("REVENUE MED").id
        client.save!
      end
    end
  end

  # Unix version for extracting images
  # Prints the physical path name of the images related to a batch.
  # 'batchid' is the parameter provided to identify the batch.
  # 'directory_1' & 'directory_2' corresponds to the
  # DB primary id of table 'images_for_jobs'.
  # Run as rake setup:extract_image_path["batchid"]
  task :extract_image_path, [:batchid]  => [:environment] do |t, args|
    batch = Batch.find(:first, :conditions => ["batchid = ?", args.batchid],
      :include => [:jobs, :images_for_jobs])
    start_time = Time.now
    unless batch.blank?
      directory_path = "#{Rails.root}/multipage_image/#{batch.batchid}"
      puts "Copying images to #{directory_path}"
      system "rm -R #{directory_path}"
      system "mkdir -p #{directory_path}"

      if batch.facility.incoming_image_type == true
        # For milti tiff images        
        batch.jobs.each do |job|
          unless job.is_excluded == true
            image_paths = []
            image_records = job.images_for_jobs
            count_of_images = image_records.length
            directory_1, directory_2 = nil, nil
            image_name = job.initial_image_name

            image_records.each do |image|
              id_in_string = image.id.to_s
              id_in_string = id_in_string.rjust(8, '0')
              directory_1 = id_in_string.slice(0..3) # this indicates the dir name under /unzipped_files
              directory_2 = id_in_string.slice(4..7) # this indicates the second level dir name under /unzipped_files/<directory_1>
              image_paths << "#{Rails.root}/private/unzipped_files/#{directory_1}/#{directory_2}/#{image.filename}"
            end
            system("cd #{directory_path}; tiffcp #{image_paths.join(' ')} #{directory_path}/#{image_name}")
            # Making all the file names that end with .tif or .tiff or .TIF or .TIFF into .tif
            system "find #{directory_path} -type f ! -name '*.tif' ! -name '*.tiff' ! -name '*.TIF' ! -name '*.TIFF' | xargs -I{} mv {} {}.tif"
          end
        end
      else
        # For single tiff images

        batch.jobs.each do |job|
          unless job.is_excluded == true
            job.images_for_jobs.each do |image|
              id_in_string = image.id.to_s
              id_in_string = id_in_string.rjust(8, '0')
              directory_1 = id_in_string.slice(0..3) # this indicates the dir name under /unzipped_files
              directory_2 = id_in_string.slice(4..7) # this indicates the second level dir name under /unzipped_files/<directory_1>
              system "cp #{Rails.root}/private/unzipped_files/#{directory_1}/#{directory_2}/#{image.filename} #{directory_path}"
              # Making all the file names that end with .tif or .tiff or .TIF or .TIFF into .tif
              system "find #{directory_path} -type f ! -name '*.tif' ! -name '*.tiff' ! -name '*.TIF' ! -name '*.TIFF' | xargs -I{} mv {} {}.tif"
            end
          end
        end
      end
      JobActivityLog.create_activity({:activity => 'Image Generated', :start_time => start_time,
          :end_time => Time.now, :object_name => 'batches', :object_id => batch.id }, true)
      puts "Generation is completed. Please see if the images are available at #{directory_path}. Else please contact system administrator."
    else
      puts "Batch not found. Please provide a valid batchid"
    end
  end

  # Windows version for extracting images
  # Prints the physical path name of the images related to a batch.
  # 'batchid' is the parameter provided to identify the batch.
  # 'directory_1' & 'directory_2' corresponds to the
  # DB primary id of table 'images_for_jobs'.
  # Run as rake setup:extract_image_path_w["batchid"]
  task :extract_image_path_w, [:batchid] => [:environment] do |t, args|
    batch = Batch.find(:first, :conditions => ["batchid = ?", args.batchid],
      :include => [:jobs, :images_for_jobs])
    unless batch.blank?
      railsRoot = Rails.root.to_s.gsub("/","\\")
      directory_path = "#{Rails.root}\\multipage_image\\#{batch.batchid}"
      system "rmdir #{directory_path}"
      system "mkdir #{directory_path}"
      
      batch.jobs.each do |job|
        job.images_for_jobs.each do |image|
          id_in_string = image.id.to_s
          id_in_string = id_in_string.rjust(8, '0')
          directory_1 = id_in_string.slice(0..3)
          directory_2 = id_in_string.slice(4..7)          
          system "copy #{railsRoot}\\private\\unzipped_files\\#{directory_1}\\#{directory_2}\\#{image.filename} #{directory_path} "
        end
      end
      puts "Generation is completed. Please see if the images are available at #{directory_path}. Else please contact system administrator."
    else
      puts "Batch not found. Please provide a valid batchid"
    end
  end

  # Creates the default user Admin for initial setup of the application.
  # Run as rake setup:admin
  task :admin => :environment do

    admin = User.find_by_name("Admin")
    if admin.blank?
      admin = User.new
      admin.name = "Admin"
      admin.login = "admin"
      admin.password = "revadmin"
      admin.password_confirmation = "revadmin"
      admin.email = "support@revenuemed.com"
      admin.image_permision = 1
      admin.image_grid_permision = 1
      admin.image_835_permision = 1
      admin.activity_log_permission = 1
      admin.roles << Role["admin"]
      setup = admin.save(:validate => false)
      unless setup.blank?
        puts "Default Admin User is created."
      else
        puts "Default Admin User is not created."
        puts "Please contact the Software Wing support to trace the problem."
      end      
    end
  end

  desc "To Migrate orphan users by changing login id to MIG_{user_id} and salt replatced with remittor_id."
  task :migrate_orphan_users => :environment do
    sqls = Array.new
    sqls << "INSERT INTO users(id,login,NAME,crypted_password,salt,created_at,updated_at,remember_token,remember_token_expires_at,STATUS,is_deleted,field_accuracy,total_eobs,rejected_eobs,eob_accuracy,shift_id,image_permision,image_835_permision,image_grid_permision) SELECT id,concat('MIG_',userid),NAME,PASSWORD,remittor_id,CURRENT_DATE(),CURRENT_DATE(),NULL,NULL,STATUS,1,field_accuracy,total_eobs,rejected_eobs,eob_accuracy,shift_id,image_permision,image_835_permision,image_grid_permision FROM users_old WHERE id NOT IN (SELECT id FROM users)"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    # execute each sql
    sqls.each do |sql|
      ActiveRecord::Base.connection.execute(sql)
    end
  end
    
  desc "To do data migration from total_fields of eob_qas table to processor_input_fields of insurance_payment_eobs table."
  
  task :migrate_total_fields => :environment do
    sqls = Array.new
    sqls << "UPDATE insurance_payment_eobs ins_pay, eob_qas eob_qa SET 
  ins_pay.processor_input_fields = eob_qa.total_fields 
  WHERE eob_qa.eob_id = ins_pay.id and eob_qa.created_at >= '2011-01-01'"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    # execute each sql
    sqls.each do |sql|
      ActiveRecord::Base.connection.execute(sql)  
    end
  end

  desc "To do data population in facility_lookup_fields table related to 
        supplemental output formats and grouping."
       
  task :populate_facility_lookup_fields => :environment do
    output_groupings = ["By Check"]
    supplemental_output_groupings = ["By Batch", "By Batch Date"]
    supplemental_output_content_layouts = ["By Check", "By EOB", "By Payer"]
    supplemental_output_formats = ["XLS", "CSV", "TXT"]
    index_file_format = ['TXT', 'IDX']
    index_file_parser_types = ["BOA", "Apria", "PNC", "Wachovia", "WellsFargo", "WellsFargo_bank","Rmed_Single", "JPMC_Single", "Barnabas"]
    supplemental_output_groupings.each do |group|
      output_grouping = FacilityLookupField.find_by_name_and_lookup_type(group, "Supplemental Output Group")
      FacilityLookupField.create(:name => group, :lookup_type => "Supplemental Output Group") if output_grouping.blank?
    end

    index_file_format.each do |format|
      index_format = FacilityLookupField.find_by_name_and_lookup_type(format, "Index File Format")
      FacilityLookupField.create(:name => format, :lookup_type => "Index File Format") if index_format.blank?
    end

    supplemental_output_content_layouts.each do |group|
      output_content = FacilityLookupField.find_by_name_and_lookup_type(group, "Supplemental Output Content Layout")
      FacilityLookupField.create(:name => group, :lookup_type => "Supplemental Output Content Layout") if output_content.blank?
    end
    
    supplemental_output_formats.each do |format|
      output_format = FacilityLookupField.find_by_name_and_lookup_type(format, "Supplemental Output Format")
      FacilityLookupField.create(:name => format, :lookup_type => "Supplemental Output Format") if output_format.blank?
    end
    
    output_groupings.each do |group|
      output_group = FacilityLookupField.find_by_name_and_lookup_type(group, "Output Group")
      FacilityLookupField.create(:name => group, :lookup_type => "Output Group") if output_group.blank?
    end
    index_file_parser_types.each do |format|
      lookup_type = FacilityLookupField.find_by_name_and_lookup_type(format, "Index File Parser Type")
      FacilityLookupField.create(:name => format, :lookup_type => "Index File Parser Type") if lookup_type.blank?
    end
  end
     
  desc "To set default value as zero for footnote_indicator field of existing payers in payers table."
  
  task :default_payer_footnote_indicator => :environment do
    sqls = Array.new
    sqls << "UPDATE payers payer SET 
  payer.footnote_indicator = 0 
  WHERE payer.footnote_indicator is null"
    # used to connect active record to the database
    ActiveRecord::Base.establish_connection
    # execute each sql
    sqls.each do |sql|
      ActiveRecord::Base.connection.execute(sql)  
    end
  end
  
  desc "This is for deleting batch statuses, HLSC Verified and HLSC Rejected from table batch_statuses."
    
  desc "Preparing database for deployment"
  tasks = ["db:migrate","setup:populate_facility_lookup_fields","facility_lookup:output_grouping","setup:admin", "setup:create_default_payer", "setup:default_payer_footnote_indicator", "prepare_throughput_report_configuration"]
  task :prepare_db => tasks do
    puts "Database setup completed successfully"
  end


  desc "Creates the default payer to be assigned to each job"
  task :create_default_payer => :environment do
  
    sqls = Array.new
    sqls << "INSERT INTO `payers` ( `payer`,  `payid`,`gateway`) VALUES( 'No Payer', 'No Payer',  'anodyne')"
    ActiveRecord::Base.establish_connection
    sqls.each do |sql|
      ActiveRecord::Base.connection.execute(sql)  
    end
  end
  
  
  desc "prepare static data values for throughput report"
  task :prepare_throughput_report_configuration => :environment do
    
    sqls = Array.new
    sqls << "delete from facility_lookup_fields where name='Throughput_Summary'"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Tolerance_Threshold','20','LBX_File_Load')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Duration_Threshold','20','LBX_File_Load')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Threshold_time',NULL,'LOCKBOX')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Tolerance_Threshold','20','Claims_File_Load')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Duration_Threshold','20','Claims_File_Load')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Threshold_time',NULL,'CLAIM')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Tolerance_Threshold','20','Batch_Keying')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Duration_Threshold','20','Batch_Keying')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Threshold_time',NULL,'BATCH')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Tolerance_Threshold','20','Batch_QAing')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Duration_Threshold','20','Batch_QAing')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Threshold_time',NULL,'QA')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Tolerance_Threshold','20','EDC_Output_Generation')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Duration_Threshold','20','EDC_Output_Generation')"
    sqls << "insert into facility_lookup_fields (name,lookup_type,value,category) values ('Throughput_Summary','Threshold_time',NULL,'OUTPUT')"
      
    ActiveRecord::Base.establish_connection
    sqls.each do |sql|
      ActiveRecord::Base.connection.execute(sql)
    end
    puts "Throughput report configuration completed."
  end
    
  desc "populate custom fields for clients\
  Input params :\
  client_group_code : group code of the client you want to populate with custom fields\
  field1 through field5 : the field names of custom fields"
  task :populate_custom_fields_for_client, [:client_group_code, :field1, :field2, :field3, :field4, :field5] => :environment do |t, args|
    client = Client.find_by_group_code(args.client_group_code)
    if client
      p args.field1, args.field2, args.field3, args.field4, args.field5
      client.custom_fields = Hash.new
      client.custom_fields[:field1] = args.field1
      client.custom_fields[:field2] = args.field2
      client.custom_fields[:field3] = args.field3
      client.custom_fields[:field4] = args.field4
      client.custom_fields[:field5] = args.field5
      result = client.save!
      if result == true
        puts "Custom fields were saved for client #{client.name}"
      else
        puts "Unable to save custom fields for client #{client.name}"
        puts "Exception occured : #{result}"
        logger.error result
      end
    else
      puts "Client with group code #{client_group_code} does not exist"
    end
  end
end
