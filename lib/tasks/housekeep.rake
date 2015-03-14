#===============================================================================
# Rake used to remove all Batch related information from database
# and its associated image files from file system.
#
# This takes a date argument (ddate), to clear all information which are
# earlier to the date. 
#===============================================================================

require 'logger'

class MyFormatter < Logger::Formatter
  def call(severity, timestamp, progname, msg)
    "[%s: %s #%d] %s\n" % [severity, timestamp.strftime("%y%m%d %H:%M:%S"), $$, msg]    
  end
end

class HouseKeeping
  attr_reader :log, :dt
  
  def initialize(dt)
    @log = Logger.new("log/delete_old_batches.log")
    ActiveRecord::Base.logger = @log
    @log.level = Logger::INFO
    @log.formatter = MyFormatter.new
    @dt = dt
  end

  def remove_data
    @log.info "Housekeeping started for removing records earlier than #{dt}"
    Batch.transaction do
      begin
        # remove_batches
        remove_batches_dependent
      rescue => err
        @log.error "Unable to remove batch, due to " + err.message
        puts "ERROR::Unable to remove batch, due to " + err.message + " Refer log file for details."
        raise ActiveRecord::Rollback
      end
    end # transaction
    @log.info "Housekeeping completed by removing records earlier than #{dt}"
  end
  
  def remove_batches_dependent
    del_cnt = Batch.destroy_all(["updated_at < ? and updated_at is not null",dt])
    @log.info "Deleted batches rows #{del_cnt}"
  end

  def remove_batches
    @log.info "Started removing batches"
    remove_jobs
    remove_mpi_statistics_reports
    remove_images_for_jobs
    del_cnt = Batch.delete_all!(["updated_at < ? and updated_at is not null",dt])
    @log.info "Deleted batches rows #{del_cnt}"
  end
  
  def remove_jobs
    @log.info "Started removing jobs"
    remove_check_informations
    remove_eob_qas
    remove_client_images_to_jobs
    del_cnt = Job.delete_all!(["batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null)",dt])
    @log.info "Deleted jobs rows #{del_cnt}"
  end

  def remove_patient_pay_eobs
    @log.info "Started removing PatientPayEob"
    del_cnt = PatientPayEob.delete_all(["check_information_id IN (SELECT id FROM check_informations WHERE job_id IN (SELECT id FROM jobs WHERE batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null)))",dt])
    @log.info "Deleted PatientPayEob rows #{del_cnt}"
  end

  def remove_eob_qas
    @log.info "Started removing EobQa"
    del_cnt = EobQa.delete_all(["job_id IN (SELECT id FROM jobs WHERE batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null))",dt])
    @log.info "Deleted EobQa rows #{del_cnt}"
  end

  def remove_check_informations
    @log.info "Started removing CheckInformation"
    remove_insurance_payment_eobs
    remove_patient_pay_eobs
    del_cnt = CheckInformation.delete_all!(["job_id IN (SELECT id FROM jobs WHERE batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null))",dt])
    @log.info "Deleted CheckInformation rows #{del_cnt}"
  end

  def remove_insurance_payment_eobs
    @log.info "Started removing InsurancePaymentEob"
    remove_service_payment_eobs
    del_cnt = InsurancePaymentEob.delete_all(["check_information_id IN (SELECT id FROM check_informations WHERE job_id IN (SELECT id FROM jobs WHERE batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null)))",dt])
    @log.info "Deleted InsurancePaymentEob rows #{del_cnt}"
  end

  def remove_service_payment_eobs
    @log.info "Started removing ServicePaymentEob"
    del_cnt = ServicePaymentEob.delete_all(["insurance_payment_eob_id IN (SELECT id FROM insurance_payment_eobs WHERE check_information_id IN (SELECT id FROM check_informations WHERE job_id IN (SELECT id FROM jobs WHERE batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null))))",dt])
    @log.info "Deleted ServicePaymentEob rows #{del_cnt}"
  end

  def remove_mpi_statistics_reports
    @log.info "Started removing MpiStatisticsReport"
    del_cnt = MpiStatisticsReport.delete_all(["batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null)",dt])
    @log.info "Deleted MpiStatisticsReport rows #{del_cnt}"
  end

  def remove_images_for_jobs
    @log.info "Started removing ImagesForJob"
    hoskp_file = File.new("log/house_keep_#{dt}.sh","w")
    hoskp_file.write "rm -r "
    ImagesForJob.find_with_deleted(:all, :select => "id,filename", :conditions => ["batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null)",dt]).each do |ifj|
      @log.info "Recording file details #{ifj.filename}"
      dirs = "%08d" % ifj.id
      hoskp_file.write "#{Rails.root}/private/unzipped_files/#{dirs[0..3]}/#{dirs[4..8]}/#{ifj.filename} "
    end
    hoskp_file.close
    del_cnt = ImagesForJob.delete_all!(["batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null)",dt])
    @log.info "Deleted ImagesForJob rows #{del_cnt}"
  end

  def remove_client_images_to_jobs
    @log.info "Started removing ClientImagesToJob"
    del_cnt = ClientImagesToJob.delete_all!(["job_id IN (SELECT id FROM jobs WHERE batch_id IN (SELECT id FROM batches WHERE updated_at < ? and updated_at is not null))",dt])
    @log.info "Deleted ClientImagesToJob rows #{del_cnt}"
  end
    
end #class

def validate_date(dt)
  puts "Validating Date .. "
  begin
    return true if (Date.today - Date.parse(dt)) > 180
  rescue ArgumentError
    puts "ERROR::Invalid Date!"
  end
  return false
end


namespace :housekeep do
  task :clean, [:ddate]  => [:environment]  do |t, args|
    unless args.ddate.blank?
      if validate_date(args.ddate)
        puts "Started Housekeeping .. "
        hkp = HouseKeeping.new(args.ddate)
        hkp.remove_data
        puts "Housekeeping Completed."
      else
        puts "ERROR::Given date is not older than 180 days, unable to start Housekeeping!" 
      end
    else
      puts "ERROR::Date missing, unable to locate Batch!"
    end
  end
end
