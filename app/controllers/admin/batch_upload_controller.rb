class Admin::BatchUploadController < ApplicationController
  require_role ["admin","supervisor"]
  layout 'standard'
  def upload_zipfile
    @user_has_access = current_user.has_role?(:admin) || current_user.has_role?(:supervisor)
    @facilities = Facility.find(:all, :conditions => ["batch_upload_check=?", true])
    @layout_needed = params[:layout]
    if @layout_needed == "false"
      render :layout => false
    end
  end

  def uploadFile
    original_facility_name = params[:facility]['name']
    facility_name = original_facility_name.gsub("\s","_").downcase
    filename = params[:upload]['datafile'].original_filename
    arrival_date = DateTime.civil(params[:arrival_date][:year].to_i, params[:arrival_date][:month].to_i, params[:arrival_date][:day].to_i, params[:arrival_date][:hour].to_i, params[:arrival_date][:minute].to_i)
    format_arrival_date = arrival_date.strftime("%Y%m%d%H%M")
    file_created, file_size = DataFile.upload_batch(current_user.login,params[:upload],facility_name,params[:inbound_id], format_arrival_date)
    bool_ok = true
    flash[:notice] = case file_created
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
    mail_on_success =  bool_ok ? "Successfully" : "Unsuccessfully "
    subject = "Batch copied #{mail_on_success} for #{params[:facility]['name'].gsub("\s"," ")} at #{Time.now}"
    recipient = $RR_REFERENCES['email']['batch_upload']['notification']#current_user.email
    if file_size.nil?
      flash[:notice] = "Error while uploading.....directory with facility name Does not exist in the application"
      redirect_to :action => 'upload_zipfile'
    else
      require 'socket'
      RevremitMailer.notify_batch_upload(recipient,subject,filename,
        original_facility_name,request.host_with_port,file_size,
        request.remote_ip,current_user.name,bool_ok).deliver
      redirect_to :action => 'upload_zipfile'
    end
  end

  def get_inbound_records
    facility_id = params[:facility_name].present? ? Facility.find_by_name(params[:facility_name]).id : nil
    inbound_records = []
    (inbound_records = InboundFileInformation.where(:status => 'ARRIVED', :arrival_date => params[:date], :facility_id => facility_id)) if facility_id
    formated_inbound_records = inbound_records.collect{|i| [i.id, i.name, i.arrival_time.strftime("%Y-%m-%d %H:%M:%S")]}
    respond_to do |format|
      format.json { render :json => formated_inbound_records }
    end
  end
 
end
