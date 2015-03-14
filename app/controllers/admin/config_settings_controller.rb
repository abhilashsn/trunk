class Admin::ConfigSettingsController < ApplicationController

  layout 'standard_inline_edit', :only => [:partners_list, :default_config_835]

  def upload    
    args = {:client_id => params[:client_id], :partner_id => params[:partner_id], 
            :facility_id => params[:facility_id], :output_type => params[:output_type], 
            :file => params[:file] }
    result = ConfigSetting.upload_config_file(args)
    flash[:notice] = result ? "Successfully Uploaded" : "Failed to upload."
    redirect_to request.referer
  end
  
  def download    
    record = ConfigSetting.where(:facility_id => params[:facility_id], :client_id => params[:client_id],
                                 :partner_id => params[:partner_id], :output_type => params[:output_type]).first
    if record.blank?
      flash[:notice] = "Configuration details are not available"
      redirect_to request.referer
    else
      @file = get_file_name
      write_to_file(record)
      send_file(@file)
    end    
  end

  def write_to_file(record)
    details = record.details
    CSV.open( @file, 'w' ) do |writer|
      writer << ["Segment Name","Description","Value","Rule","Expected Values"]
      details.each do |k,v|
        writer << [k, v[:description],v[:value],v[:rule],v[:expected_value]]
      end
    end 
  end

  def get_file_name
    if params[:facility_id]
      temp_name = Facility.find(params[:facility_id]).name + "_facility"
    elsif params[:client_id]
      temp_name = Client.find(params[:client_id]).name + "_client"
    else
      temp_name = Partner.find(params[:partner_id]).name + "_partner"
    end
    file_name = temp_name.downcase.gsub(' ','_')
    "#{file_name}_#{params[:output_type].downcase}_config_settings.csv"
  end

  def partners_list
    @partners = Partner.all
  end

  def default_config_835
    @partner = Partner.find(params[:id])
  end

end
