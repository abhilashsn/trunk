class Admin::DownloadClientLevelOutputController < ApplicationController

  require_role ["admin","supervisor"]
  layout 'standard'

  def index
    
    @user_has_access = current_user.has_role?(:admin) || current_user.has_role?(:supervisor)
    @layout_needed = params[:layout]
    if !params[:commit].nil? && params[:commit] == "Download Client Level Output"
      client_name = params[:client]['name'].gsub("\s","_").downcase unless params[:client]['name'].nil?
      download_date = params[:download_date] unless params[:download_date].nil?

      #selecting directry to copy if exist
      directory_to_copy_newdata_exist = Dir.exist?("#{Rails.root}/private/datanew/#{client_name}/operation_log/#{download_date}")
      directory_to_copy_newdata = "#{Rails.root}/private/datanew/#{client_name}/operation_log/#{download_date}" if directory_to_copy_newdata_exist

      #Location to copy if exist
      copy_newdata_in = "#{Rails.root}/client_data_download/#{client_name}_#{download_date}/datanew/operation_log"
      
      #base folder where zipping is done
      directory_to_zip = "#{Rails.root}/client_data_download/#{client_name}_#{download_date}"
      begin
        #Cleaning up the already existing temp folders which where used to zip
        unless Dir["#{Rails.root}/client_data_download"].empty?
          FileUtils.rm_r Dir.glob("#{Rails.root}/client_data_download/*")
        end

        #Creating Folder structure
        FileUtils.rm Dir.glob("#{Rails.root}/client_data_download/#{client_name}_#{download_date}/*")
        Dir.mkdir("#{Rails.root}/client_data_download/#{client_name}_#{download_date}")
        Dir.mkdir("#{Rails.root}/client_data_download/#{client_name}_#{download_date}/datanew")
        Dir.mkdir("#{Rails.root}/client_data_download/#{client_name}_#{download_date}/datanew/operation_log")
        
        #Copying the files
        FileUtils.cp_r directory_to_copy_newdata, copy_newdata_in if directory_to_copy_newdata_exist
        
        #Zipping it
        Zipper.compress_folder(directory_to_zip)
        if directory_to_copy_newdata_exist
          send_file("#{Rails.root}/client_data_download/#{client_name}_#{download_date}/#{client_name}_#{download_date}.zip",
                    :type=>"application/zip" ,:stream=>false)
        else
          flash[:notice] = "There are no files in the selected Date for selected client to be Zipped"
        end
        rescue => e
           flash[:notice] = "Error while Downloading data for selected date and client may not be available"
           logger.info "------------checking why not working #{e}"
      end

    end
    
    if @layout_needed == "false"
      render :layout => false
    end
  end

end
