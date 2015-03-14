class ImageController < ApplicationController
  skip_before_filter :authenticate_user!

  def show
    request.path =~ /unzipped_files/ #hack to get it working since request.path is giving whole path including the url
    if $& &&  FileTest.exists?(File.join(Rails.root, "private", ($& + $') ))
      send_file File.join(Rails.root, "private", ($& + $')), :type => 'image/gif', :disposition => 'inline'
    else
      render :text => "File Not Found!"
    end
  end

end
