class Admin::Import837Controller < ApplicationController
  require_role ["admin", "supervisor"]
  layout "standard"

  def index
    @user_has_access = current_user.has_role?(:admin) || current_user.has_role?(:supervisor)
    @facilities = Facility.find(:all)

    @layout_needed = params[:layout]
    if @layout_needed == "false"
      render :layout => false
    end
  end

 def upload837
    original_facility_name = params[:facility]['name']
    facility_name = original_facility_name.gsub("\s","_").downcase
    filename = params[:upload]['datafile'].original_filename
    file = DataFile.upload_837(current_user.login,params[:upload],facility_name)
    bool_ok = true
    flash[:notice] = case file
    when 0
       bool_ok = false
       "Select a file to upload"

    when true
       bool_ok = true
       "File successfully uploaded"

    when false
       bool_ok = false
      "Error while uploading"

    end
    time_stamp = "#{Time.now.strftime("%Y%m%d%H%M%S")}".delete(" ").delete(":").delete("+").delete("+").delete("-")
    new_name = "#{time_stamp}_#{current_user.login}_#{filename}"
    new_path = File.join("837upload/#{facility_name}",new_name)
    begin
      file_size = File.new(new_path).size
    rescue=>e
      flash[:notice] = "Error while uploading.....directory with facility name Does not exist in the application"
    end
    require 'socket'

    redirect_to :action => 'index'
  end

end
