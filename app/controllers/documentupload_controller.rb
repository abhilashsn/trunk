class DocumentuploadController < ApplicationController
  require_role ["admin", "processor", "qa", "manager", "supervisor", "TL"]
  layout 'standard'
  
  def uploadfile
    @user_has_access = current_user.has_role?(:admin) || current_user.has_role?(:supervisor) || current_user.has_role?(:manager)
    @documents = DataFile.scoped.paginate(:page => params[:page])
    @layout_needed = params[:layout]
    if @layout_needed == "false"
      render :layout => false
    end
  end
  
  def uploadFile
    file = DataFile.save(params[:upload])
    flash[:notice] = case file
    when 0
      "Select a file to upload"
    when true
      "File successfully uploaded"
    when false
      "Error while uploading"
    end
    redirect_to :action => 'uploadfile'
  end
  
  def delete_files
    files  = params[:files_to_delete]
    files.delete_if do |key, value|
      value == "0"
    end
     delet_popup =  ErrorPopup.where(:data_file_id =>files.keys).update_all(:data_file_id => nil)
    files.keys.each do |id|
      file_name = DataFile.find(id).file_name
      file_location = Rails.root.to_s + "/public/documents/" + file_name
      File.delete(file_location)
      DataFile.destroy id
    end
    if files.size != 0
      flash[:notice] = "Deleted #{files.size} File(s)."
    else
      flash[:notice] = "Please select atleast one File "
    end
    redirect_to :action => 'uploadfile'
  end
  
  def show 
    send_file File.join(Rails.root,"public","/documents/#{params[:filename]}"),:type => 'text/html',:disposition => 'attachment'
  end
  
end
