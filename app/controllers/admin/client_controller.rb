# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Admin::ClientController < ApplicationController
  require_role ["admin","supervisor"]
  layout 'standard' ,:except => [:config_oplog]
  before_filter :check_edit_permissions, :only => [:config_oplog_save]
  include Admin::FacilityHelper
  in_place_edit_with_validation_for :client, :tat
  in_place_edit_with_validation_for :client, :internal_tat
  in_place_edit_with_validation_for :client, :max_jobs_per_user_client_wise
  in_place_edit_with_validation_for :client, :max_jobs_per_user_payer_wise
  in_place_edit_with_validation_for :client, :max_eobs_per_job
  in_place_edit_with_validation_for :client, :associate_claim_npi

  # This is for listing clients.
  def list
    conditions =  ["name like ?", "%#{params[:name].strip}%"] unless params[:name].blank?
    unless conditions.blank?
      @clients = Client.select("clients.id as id \
                    , clients.name as name \
                    , clients.group_code as group_code \
                    , clients.tat as tat \
                    , clients.internal_tat as internal_tat \
                    , clients.max_jobs_per_user_client_wise as max_jobs_per_user_client_wise \
                    , clients.max_jobs_per_user_payer_wise as max_jobs_per_user_payer_wise \
                    , clients.max_eobs_per_job as max_eobs_per_job \
                    , clients.partener_bank_group_code as partener_bank_group_code \
                    , clients.associate_claim_npi as associate_claim_npi \
                    , clients.supplemental_outputs as supplemental_outputs").\
        where(conditions).order("clients.name ASC").\
        paginate(:page => params[:page], :per_page => 30)
    else
      @clients = Client.select("clients.id as id \
                    , clients.name as name \
                    , clients.group_code as group_code \
                    , clients.tat as tat \
                    , clients.internal_tat as internal_tat \
                    , clients.max_jobs_per_user_client_wise as max_jobs_per_user_client_wise \
                    , clients.max_jobs_per_user_payer_wise as max_jobs_per_user_payer_wise \
                    , clients.max_eobs_per_job as max_eobs_per_job \
                    , clients.partener_bank_group_code as partener_bank_group_code \
                    ,clients.associate_claim_npi as associate_claim_npi \
                    , clients.supplemental_outputs as supplemental_outputs").\
        order("clients.name ASC").\
        paginate(:page => params[:page], :per_page => 30)
    end
    render :layout => "standard_inline_edit"
  end

  def new
    @client ||= Client.new
    @partners = []
    partners = Partner.all
    if partners
      partners.each do |partner|
        @partners << [partner.name, partner.id]
      end
    end
  end

  def edit
    @client = Client.find(params[:id])
    partners = Partner.all
    @partners = []
    if partners
      partners.each do |partner|
        @partners << [partner.name, partner.id]
      end
    end
  end
  
  def add
    partners = Partner.all
    @partners = []
    if partners
      partners.each do |partner|
        @partners << [partner.name, partner.id]
      end
    end
    if params[:id].present?
      @client = Client.find(params[:id])
    else
      @client = Client.new
    end
    if(!params[:client].blank?)
      is_saved = @client.update_attributes(:name =>(params[:client][:name].strip),
        :partner_id => params[:partner_id].strip,
        :tat => (params[:client][:tat].strip),
        :group_code => (params[:client][:group_code].strip),
        :max_jobs_per_user_client_wise => (params[:client][:max_jobs_per_user_client_wise].strip),
        :max_jobs_per_user_payer_wise => (params[:client][:max_jobs_per_user_payer_wise].strip),
        :max_eobs_per_job => (params[:client][:max_eobs_per_job].strip),
        :partener_bank_group_code => (params[:partener_bank_group_code].strip),
        :internal_tat => (params[:client][:internal_tat].strip),
        :associate_claim_npi => params[:client][:associate_claim_npi])
      if(is_saved)
        flash[:notice]= "Client saved successfully"
        redirect_to :controller => '/admin/client', :action => 'list'
      else
        render :new
      end
    else
      redirect_to :controller => '/admin/client', :action => 'new'
    end
  end

  def update_or_delete_clients
    if params[:option1] == 'delete'
      ids = params[:clients_to_delete]
      Client.delete_all(["id in (?)",ids])
      flash[:notice]="Client Deleted successfully"
      redirect_to :controller => '/admin/client', :action => 'list'
    elsif params[:option1] == 'Save Oplog Config'
      ids = params[:clients_to_set_oplog]
      all_client_oplog_configs = Client.find(:all, :select => "id, supplemental_outputs")
      all_client_oplog_configs.each { |config| config.update_attribute :supplemental_outputs, "(NULL)"}
      Client.where(["id in (?)",ids]).update_all(:supplemental_outputs => "Operation Log", :updated_at => Time.now)
      flash[:notice] = "Operation log settings updated successfully"
      redirect_to :controller => '/admin/client', :action => 'list'
    end
  end

  def check_presence_of_facility
    client_list =[]
    client_id = params[:client_id]
    client_id = client_id.chomp(',')
    facility_count = Facility.select(" clients.name as name").where("facilities.client_id in (#{client_id})").joins("INNER JOIN clients on clients.id = facilities.client_id ").group('clients.name')
    facility_count.each do |facility|
      client_list<< facility.name
    end
    if(client_list.length>0)
      client_name = client_list.join(', ')
    else
      client_name = "nothing"
    end
    render :text => client_name.to_json
  end

  def check_presence_of_alert
    client_list =[]
    client_id = params[:client_id]
    client_id = client_id.chomp(',')
    facility_count = ErrorPopup.select(" clients.name as name").where("error_popups.client_id in (#{client_id})").joins("INNER JOIN clients on clients.id = error_popups.client_id ").group('clients.name')
    facility_count.each do |facility|
      client_list<< facility.name
    end
    if(client_list.length>0)
      client_name = client_list.join(', ')
    else
      client_name = "nothing"
    end
    render :text => client_name.to_json
  end

  def config_835
    @client = Client.find(params[:id])
  end

end
