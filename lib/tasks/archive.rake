namespace :archive do 
  desc "archival script for deleting images"
  task :prepareScript => :environment do
     obj = DeletedImageDetailsTemp.find_by_sql("select concat('rm ./private/unzipped_files/',left(lpad(folder_name,8,0),4),'/',right(lpad(folder_name,8,0),4),'/',image_file_name)img from deleted_image_details_temps")
     file = File.open("deleteImage.sh","w")
     obj.each do |line |
     file << line.img
     file << "\n"
     end
     obj = DeletedImageDetailsTemp.find_by_sql("select distinct(concat('find  ./private/unzipped_files/',left(lpad(folder_name,8,0),4),'/ -depth -empty -type d -exec rmdir {} \;')) img from deleted_image_details_temps")
     obj.each do |line |
     	file << line.img
     	file << "\n"
     end
     file.close()
     system "chmod+x deleteImage.sh"
     puts "Script for deleting images completed - deleteImage.sh"

  end
  
  desc "deletig the obsolete images after archival"
  task :executeScript => [:prepareScript] do
      system "./deleteImage.sh"
      puts "Executed the script to delete the obsolete images"
  end
  
  
   
    desc "Prepare for Data archival . input format YYYY-MM-DD"
    task :prepare, [:archDate] => :environment do |t, args|

	sqls = Array.new
	sqls << "TRUNCATE TABLE batch_temps"
	sqls << "TRUNCATE TABLE deleted_image_details_temps"
	sqls << "INSERT INTO deleted_image_details_temps(folder_name,image_file_name)SELECT id ,filename  FROM images_for_jobs WHERE batch_id IN(SELECT id FROM batches WHERE updated_at<'" + args[:archDate] + "')"
	sqls << "CREATE INDEX idx_client_job_id ON client_activity_logs(job_id)"
	sqls << "CREATE INDEX idx_job_job_id ON job_activity_logs(job_id)"
	sqls << "CREATE INDEX idx_job_id ON output_activity_logs(batch_id)"
	ActiveRecord::Base.establish_connection
	sqls.each do |sql|
	    ActiveRecord::Base.connection.execute(sql)  
	end
	puts "Preparation for Archival completed."
	
    end


    desc "cleanup after Data archival"
    task :cleanup => :environment do

	sqls = Array.new
	sqls << "ALTER TABLE client_activity_logs DROP INDEX idx_client_job_id"
	sqls << "ALTER TABLE job_activity_logs DROP INDEX idx_job_job_id"
	sqls << "ALTER TABLE output_activity_logs DROP INDEX idx_job_id"
	sqls << "TRUNCATE TABLE batch_temps"
	ActiveRecord::Base.establish_connection
	sqls.each do |sql|
	    ActiveRecord::Base.connection.execute(sql)  
	end
	puts "Cleanup after Archival completed."
    end


end