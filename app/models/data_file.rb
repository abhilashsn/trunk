class DataFile < ActiveRecord::Base
  validates_presence_of :file_name
  validates_uniqueness_of :file_name
  has_one :error_popup
  def self.save(upload)
    if upload.present? && upload['datafile'].present?
      name =  upload['datafile'].original_filename
      directory = "public/documents"
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
      file = DataFile.new
      file.file_name = name
      file.save
    else
      0
    end
  end


  def self.upload_batch(user_login_name,upload,facility,inbound_id, format_arrival_date)
    if upload.present? && upload['datafile'].present?
      begin
        name =  upload['datafile'].original_filename
        new_name = inbound_id.present? ? "#{format_arrival_date}_#{user_login_name}_#{name}_#{inbound_id}" : "#{format_arrival_date}_#{user_login_name}_#{name}"
        directory = "batchupload/#{facility}"
        # create the file path
        path = File.join(directory, new_name)
        # write the file
        File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
        return true, File.size(path)
      rescue => e
        logger.info "..check for files..................#{e}"
        return false, nil
      end
    else
      return 0, nil
    end
  end
  
  def self.upload_837(user_login_name,upload,facility)
    if upload.present? && upload['datafile'].present?
      begin
        name =  upload['datafile'].original_filename
        time_stamp = "#{Time.now.strftime("%Y%m%d%H%M%S")}".delete(" ").delete(":").delete("+").delete("+").delete("-")
        new_name = "#{time_stamp}_#{user_login_name}_#{name}"
        directory = "837upload/#{facility}"
        # create the file path
        path = File.join(directory, new_name)
        # write the file
        File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
        return true
      rescue => e
        logger.info "..check for files..................#{e}"
        return false
      end
    else
      return 0
    end
  end

  def self.save_upload_document(upload)
    if upload.present? && upload['datafile'].present?
      name =  upload['datafile'].original_filename
      directory = "public/documents"
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
      file = DataFile.create
      file.file_name = name
      flag = file.save
      id = file.id
      name= file.file_name


    else
      flag = 0
      id =''
      name =''
    end
    return flag,id,name
  end



end
