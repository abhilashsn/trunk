class ProviderController < ApplicationController
  layout "standard"
  require_role ["admin","qa","processor","manager","supervisor","TL"]
  require 'csv'
  
  def index
    @providers = Provider.scoped.paginate(:page => params[:page])
  end
  
  def create
    provider = Provider.new(params[:provider])
    facility_id = Facility.find_by_name(params[:facility]).id
    provider.facility_id = facility_id
    if(provider.save)
      flash[:notice] = 'Provider Successfully inserted'
      redirect_to :action => 'index'
    end
  end
  
  def new
    @facilities = Facility.all
  end
  
  def edit
    @provider = Provider.find(params[:id])
    @facilities = Facility.find(:all).map{ |facility| facility.name}
    @flag = params[:flag]
  end
  
  def update
    @provider = Provider.find(params[:id])
    facility_id = Facility.find_by_name(params["facility"]).id
    params["provider"]["facility_id"] =  facility_id if facility_id
    if @provider.update_attributes(params[:provider])
      flash[:notice] = 'Provider was successfully updated.'
      redirect_to :action => 'index'
    end
  end
  
  def delete_providers
    providers  = params[:providers_to_delete]
    providers.delete_if do |key, value|
      value == "0"
    end
    if providers.size != 0
      
      # REFACTORED
      # providers.keys.each do |id|
      #  Provider.find(id).destroy
      # end
      
      Provider.destroy providers.keys
      
      flash[:notice] = "Deleted #{providers.size} File(s)."
    else
      flash[:notice] = "Please select atleast one provider "
    end
    redirect_to :action => 'index'
  end
  
  def provider_name_informations
    provider_last_name = params[:provider_last_name]
    provider_based_informations = Provider.provider_name_details(provider_last_name)
    render :text => provider_based_informations
  end
  
  def upload_provider_csv
    parsed_file = CSV::Reader.parse(params[:upload][:file])
    if not (parsed_file.blank?)
      Provider.save_provider(parsed_file)
    end
    flash[:notice]  = "CSV Import Successful"
    redirect_to :controller => '/provider', :action => 'index'
  end
  
  def provider_npi_informations
    provider_npi = params[:provider_npi]
    provider_based_informations = Provider.provider_details(provider_npi)
    render :text => provider_based_informations
  end
  
end
