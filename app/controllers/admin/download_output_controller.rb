class Admin::DownloadOutputController < ApplicationController

  require_role ["admin","supervisor"]
  layout 'standard'

  def index
    
    @user_has_access = current_user.has_role?(:admin) || current_user.has_role?(:supervisor)
    @layout_needed = params[:layout]
    if !params[:commit].nil? && params[:commit] == "Download Output"
      facility_name = params[:facility]['name'].gsub("\s","_").downcase unless params[:facility]['name'].nil?
      download_date = params[:download_date] unless params[:download_date].nil?

      #selecting directry to copy if exist
      directory_to_copy_data_exist = Dir.exist?("#{Rails.root}/private/data/#{facility_name}/835s/#{download_date}")
      directory_to_copy_data = "#{Rails.root}/private/data/#{facility_name}/835s/#{download_date}" if directory_to_copy_data_exist
      
      directory_to_copy_data_xml_exist = Dir.exist?("#{Rails.root}/private/data/#{facility_name}/xml/#{download_date}")
      directory_to_copy_data_xml = "#{Rails.root}/private/data/#{facility_name}/xml/#{download_date}" if directory_to_copy_data_xml_exist

      directory_to_copy_data_op_log_exist = Dir.exist?("#{Rails.root}/private/data/#{facility_name}/operation_log/#{download_date}")
      directory_to_copy_data_op_log = "#{Rails.root}/private/data/#{facility_name}/operation_log/#{download_date}" if directory_to_copy_data_op_log_exist

      directory_to_copy_newdata_exist = Dir.exist?("#{Rails.root}/private/datanew/#{facility_name}/operation_log/#{download_date}")
      directory_to_copy_newdata = "#{Rails.root}/private/datanew/#{facility_name}/operation_log/#{download_date}" if directory_to_copy_newdata_exist

      directory_to_copy_data_exception_report_exist = Dir.exist?("#{Rails.root}/private/data/#{facility_name}/exception_report/#{download_date}")
      directory_to_copy_data_exception_report = "#{Rails.root}/private/data/#{facility_name}/exception_report/#{download_date}" if directory_to_copy_data_exception_report_exist

      directory_to_copy_data_indexed_image_exist = Dir.exist?("#{Rails.root}/private/data/#{facility_name}/indexed_image/#{download_date}")
      directory_to_copy_data_indexed_image = "#{Rails.root}/private/data/#{facility_name}/indexed_image/#{download_date}" if directory_to_copy_data_indexed_image_exist

      #Location to copy if exist
      copy_data_in_835s = "#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/835s" 
      copy_data_in_xml = "#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/xml" 
      copy_data_op_log_in = "#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/operation_log/"
      copy_newdata_in = "#{Rails.root}/data_download/#{facility_name}_#{download_date}/datanew/operation_log"
      copy_data_exception_report_in = "#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/exception_report"
      copy_data_indexed_image_in = "#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/indexed_image"
      
      #base folder where zipping is done
      directory_to_zip = "#{Rails.root}/data_download/#{facility_name}_#{download_date}"
      begin
        #Cleaning up the already existing temp folders which where used to zip
        unless Dir["#{Rails.root}/data_download"].empty?
          FileUtils.rm_r Dir.glob("#{Rails.root}/data_download/*")
        end

        #Creating Folder structure
        FileUtils.rm Dir.glob("#{Rails.root}/data_download/#{facility_name}_#{download_date}/*")
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}")
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/data")
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/835s") if directory_to_copy_data_exist
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/xml") if directory_to_copy_data_xml_exist
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/datanew") if directory_to_copy_newdata_exist
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/operation_log") if directory_to_copy_data_op_log_exist
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/datanew/operation_log") if directory_to_copy_newdata_exist
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/exception_report") if directory_to_copy_data_exception_report_exist
        Dir.mkdir("#{Rails.root}/data_download/#{facility_name}_#{download_date}/data/indexed_image") if directory_to_copy_data_indexed_image_exist

        #Copying the files
        FileUtils.cp_r directory_to_copy_data, copy_data_in_835s if directory_to_copy_data_exist
        FileUtils.cp_r directory_to_copy_data_xml, copy_data_in_xml if directory_to_copy_data_xml_exist
        FileUtils.cp_r directory_to_copy_data_op_log, copy_data_op_log_in if directory_to_copy_data_op_log_exist
        FileUtils.cp_r directory_to_copy_newdata, copy_newdata_in if directory_to_copy_newdata_exist
        FileUtils.cp_r directory_to_copy_data_exception_report, copy_data_exception_report_in if directory_to_copy_data_exception_report_exist
        FileUtils.cp_r directory_to_copy_data_indexed_image, copy_data_indexed_image_in if directory_to_copy_data_indexed_image_exist
        
        #Zipping it
        Zipper.compress_folder(directory_to_zip)
        if directory_to_copy_data_exist || directory_to_copy_newdata_exist ||
            directory_to_copy_data_op_log_exist || directory_to_copy_data_xml_exist ||
            directory_to_copy_data_exception_report_exist ||
            directory_to_copy_data_indexed_image_exist
          send_file("#{Rails.root}/data_download/#{facility_name}_#{download_date}/#{facility_name}_#{download_date}.zip",
                    :type=>"application/zip" ,:stream=>false)
        else
          flash[:notice] = "There are no files in the selected Date for selected facility to be Zipped"
        end
        rescue => e
           flash[:notice] = "Error while Downloading data for selected date and facility may not be available"
           logger.info "------------checking why not working #{e}"
      end

    end
    
    if @layout_needed == "false"
      render :layout => false
    end
  end

end
