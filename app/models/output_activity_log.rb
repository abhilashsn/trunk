class OutputActivityLog < ActiveRecord::Base
  has_many :eobs_output_activity_logs, :dependent => :destroy
  has_many :insurance_payment_eobs, :through => :eobs_output_activity_logs
  has_many :patient_pay_eobs, :through => :eobs_output_activity_logs
  has_many :claim_file_informations
  belongs_to :batch
  belongs_to :user
  before_save :update_activity

  def self.purge_all(batch_ids, frmt=nil, file_name=nil)
    if frmt.present? && file_name.present?
      destroy_all(["file_format = ? AND file_name in (?) AND batch_id in (?) ", frmt, file_name, batch_ids.join(',')])
    elsif frmt.present?
      destroy_all(["file_format = ? and batch_id in (?) ", frmt, batch_ids.join(',')])
    else
      destroy_all(["batch_id in ( ? ) ", batch_ids.join(',')])
    end
  end
  
  def self.purge_last_log(batch_id, frmt="HREOB")
    destroy_all(["file_format = ? and batch_id = ?", frmt, batch_id])
  end  
  
  def self.post_file_info(fl_ref, eob, btch, frmt="HREOB")
    new_op_log = self.new
    new_op_log.assign_attributes({:file_format => frmt,:file_name => File.basename(fl_ref),
        :start_time => Time.now,:file_location => File.dirname(fl_ref),
        :file_size => File.size(fl_ref)}, :without_protection => true)
   
    new_op_log.batch = btch
    new_op_log.save

    new_op_log.insurance_payment_eobs << eob 
    new_op_log.save
  end

  def self.associate_file_to_batch(fname, dname, size, batch_id, frmt)
    return self.create({:file_format => frmt,
        :file_name => fname,
        :file_location => dname,
        :start_time => Time.now,
        :user_id => (@current_user ? @current_user.id : nil),
        :batch_id => batch_id,
        :status => OutputActivityStatus::GENERATING})
    
  end

  def mark_generated_with_checksum time
    file_path = Rails.root.to_s + "/" +  file_location.to_s +  "/" +  file_name.to_s
    puts file_path
    if File.exists?(file_path)
      file_size = File.size?("#{file_path}").to_i rescue nil
      checksum = ` md5sum \"#{file_path}\" ` rescue nil
    end
    checksum = checksum.split(" ")[0] if checksum
    self.update_attributes({:end_time=>time, :file_size => file_size, :checksum => checksum, :status => OutputActivityStatus::GENERATED})    
  end


  def self.mark_generated_with_checksum activity_logs, time, ack_latest_count
    if activity_logs.present?
      file_path = Rails.root.to_s + "/" +  activity_logs.first.file_location.to_s +  "/" +  activity_logs.first.file_name.to_s
      if File.exists?(file_path)
        file_size = File.size?("#{file_path}").to_i rescue nil
        checksum = ` md5sum \"#{file_path}\" ` rescue nil
      end
      checksum = checksum.split(" ")[0] if checksum
      self.update_all({:end_time => time, :file_size =>file_size, :checksum =>checksum, :status => OutputActivityStatus::GENERATED, :ack_latest_count => ack_latest_count},
        "id in (#{activity_logs.collect(&:id).join(',')})")
    end
  end

  def self.create_entry_for_zipped_835 activity_logs, zip_file_name , ack_latest_count
    logs = activity_logs.select{|oal| oal.file_format == "835_source"}
    zip_logs = []
    time_now = Time.now
    logs.each do |log|
      clone = log.dup
      clone.checksum = ""
      clone.file_format = "835"
      clone.file_name = zip_file_name
      clone.ack_latest_count = ack_latest_count
      clone.save
      zip_logs << clone
    end
    OutputActivityLog.mark_generated_with_checksum(zip_logs, time_now, ack_latest_count)
    OutputActivityLog.mark_uploaded(zip_logs)
  end

  def OutputActivityLog.get_latest_number
    ack_latest_count = OutputActivityLog.maximum(:ack_latest_count)

    if ack_latest_count.blank?
      ack_latest_count = 1
    else
      ack_latest_count = ack_latest_count + 1
    end
  end

  def self.mark_uploaded activity_logs
    self.update_all({:upload_start_time => Time.now, :status => OutputActivityStatus::UPLOADING},
      "id in (#{activity_logs.collect(&:id).join(',')})")
    sleep(2)
    self.update_all({:upload_end_time => Time.now, :status => OutputActivityStatus::UPLOADED},
      "id in (#{activity_logs.collect(&:id).join(',')})")
  end
  
  def mark_uploaded
    self.update_attributes({:upload_start_time=>Time.now, :status => OutputActivityStatus::UPLOADING})    
    sleep(2)
    self.update_attributes({:upload_end_time=>Time.now, :status => OutputActivityStatus::UPLOADED})    
  end

  def self.record_activity(batch_ids, activity, format, file_name, file_location, start_time, end_time, user_id, ack_latest_count = nil)
    formats =["EOB_Report"]
    if file_location
      file_location = file_location.gsub(' ','_') unless file_location.blank?
      file_path = Rails.root.to_s + "/" +  file_location.to_s +  "/" +  file_name.to_s    
      if File.exists?(file_path)
        checksum = ` md5sum \"#{file_path}\" ` rescue nil
      end
      checksum = checksum.split(" ")[0] if checksum
    end
    if formats.include? format
      batch_ids.each do |batch_id|
        self.create({:batch_id => batch_id, :activity => activity,
            :file_format => format, :file_name => file_name, 
            :file_location => file_location, :start_time => start_time,
            :end_time => end_time, :user_id => user_id,
            :status => OutputActivityStatus::GENERATED, :checksum => checksum,
            :ack_latest_count => ack_latest_count})
      end
    end
  end


  private
  
  def update_activity     
    self.activity = case self.file_format
    when "HREOB"
      "HR EOB Output Generated"
    when "A37"
      "A37 Generated"
    when "A36"
      "A36 Generated"
    else
      activity
    end
  end  
  

end
