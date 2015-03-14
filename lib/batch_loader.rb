class BatchLoader
  attr_accessor :inbound_info_id

  def initialize(inbound_info_id)
    self.inbound_info_id = inbound_info_id
  end

  def perform
    inbound_info = InboundFileInformation.find(inbound_info_id)
    unless inbound_info.facility.blank?
      facility = inbound_info.facility
    else
      lockbox = Lockbox::Identification.new(inbound_info.name)
      lockbox.parse
      lockbox.lockbox
      facility = lockbox.findFacility
    end
    begin
      load_start_time = Time.now
      inbound_info.update_batch_loading_estimates 
      #inbound_info.update_attributes({:file_type => "LOCKBOX", :status => "#{InboundStatus::BATCH_LOADING}", :load_start_time => load_start_time,:facility_id => facility.id})      
      lock_file = File.open(Rails.root.to_s + "/tmp/batchloading.txt", "w")      
      batch_file_full_path = inbound_info.file_path + "/" + inbound_info.name
      raise Exception.new("File \"#{batch_file_full_path} \" Not Found. ") unless File.exists?(batch_file_full_path)
      raise Exception.new("Facility cannot be indentified.") unless facility.present?
      InputBatch::Log.setup_log File.basename(batch_file_full_path), facility.name
      zip_index = InputBatch::IndexExtractor.new(facility.name, batch_file_full_path, nil, inbound_info)
      zip_index.extract_file lock_file
      InputBatch::Log.status_log.info "Batch loading ends at #{Time.now}"
    rescue Exception => e
      InputBatch::Log.setup_log File.basename(batch_file_full_path), "Cannot be Identified" if InputBatch::Log.error_log.blank?
      InputBatch::Log.error_log.error "Batch Loading Failed with following error"
      InputBatch::Log.error_log.error e.message
      InputBatch::Log.error_log.error e.backtrace.join("\n")
      revremit_exception = RevremitException.create({:exception_type =>"BatchLoading", :system_exception => e.message + "\n" + e.backtrace.join("\n")})
      inbound_info.mark_exception(revremit_exception) if inbound_info
    ensure
      InputBatch::Log.error_log.close
      InputBatch::Log.status_log.close
    end
    
  end
end
