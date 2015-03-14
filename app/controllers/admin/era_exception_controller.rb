class Admin::EraExceptionController < ApplicationController

  require_role ["admin", "supervisor", "manager"]
  layout 'standard'

  def index
    #find all exceptions
    @era_checks = EraCheck.exceptions

    #apply filters
    unless params[:arrival_date_from].blank? && params[:arrival_date_to].blank?
      if params[:arrival_date_from].blank? && !params[:arrival_date_to].blank?
        flash[:notice] = 'Please select "From" Date'
      elsif params[:arrival_date_to].blank? && !params[:arrival_date_from].blank?
        flash[:notice] = 'Please select "To" Date'
      else
        @era_checks = @era_checks.where("eras.arrival_date BETWEEN '#{Date.strptime(params[:arrival_date_from], "%m/%d/%Y")}' AND '#{Date.strptime(params[:arrival_date_to], "%m/%d/%Y")}'")
      end
    end
    @era_checks = @era_checks.where("eras.name LIKE '%#{params[:filename].strip}%'") unless params[:filename].blank?
    @era_checks = @era_checks.where("era_jobs.payee_name LIKE '%#{params[:site_name].strip}%'") unless params[:site_name].blank?
    @era_checks = @era_checks.where("check_number LIKE '%#{params[:check_number].strip}%'") unless params[:check_number].blank?
    @era_checks = @era_checks.where("payer_name LIKE '%#{params[:payer_name].strip}%'") unless params[:payer_name].blank?
    @era_checks = @era_checks.where("exception_status = '#{params[:exception]}'") unless params[:exception].blank?
    @era_checks = @era_checks.where("era_payid LIKE '%#{params[:payer_id].strip}%'") unless params[:payer_id].blank?
    
    #order by status and paginate
    @era_checks = @era_checks.by_status.paginate(:page => params[:page])
  end

  def approval
    @era_check = EraCheck.find(params[:chk_id])
    redirect_to :controller => 'admin/era_exception' if !@era_check.exception_status
    @era_job = @era_check.era_jobs.first
  end

  def site_search
    flash[:notice] = nil
    @era_check = EraCheck.find(params[:chk_id])
    @era_client = @era_check.era.inbound_file_information.client
    if params[:reject_site_button]
      @era_check.update_attributes(:status => "QUARANTINE", :exception_status => nil)
      redirect_to :controller => 'admin/era_exception' 
    else
      if params[:site_name].blank? && params[:site_tin].blank? && params[:site_npi].blank? && params[:site_address_1].blank? && params[:site_address_2].blank? && params[:site_city].blank? && params[:site_state].blank? && params[:site_zip].blank?
        flash[:notice] = 'Please fill in one of the search fields'
        @facilities = Facility.none
      else
        if @era_client.try(:name).try(:upcase) == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
          @facilities = UpmcFacility
          unless params[:site_tin].blank?
            npi_and_tins = FacilitiesNpiAndTin.where(:tin => params[:site_tin].strip)
            @facilities = @facilities.where("id in (#{npi_and_tins.collect(&:upmc_facility_id).join(",")})") unless npi_and_tins.blank?
          end
          unless params[:site_npi].blank?
            npi_and_tins = FacilitiesNpiAndTin.where(:npi => params[:site_npi].strip)
            @facilities = @facilities.where("id in (#{npi_and_tins.collect(&:upmc_facility_id).join(",")})") unless npi_and_tins.blank?
          end
          @facilities = @facilities.where("zip = '#{params[:site_zip].strip}'") unless params[:site_zip].blank?
        else
          @facilities = Facility
          unless params[:site_tin].blank?
            npi_and_tins = FacilitiesNpiAndTin.where(:tin => params[:site_tin].strip)
            @facilities = @facilities.where("id in (#{npi_and_tins.collect(&:facility_id).join(",")})") unless npi_and_tins.blank?
          end
          unless params[:site_npi].blank?
            npi_and_tins = FacilitiesNpiAndTin.where(:npi => params[:site_npi].strip)
            @facilities = @facilities.where("id in (#{npi_and_tins.collect(&:facility_id).join(",")})") unless npi_and_tins.blank?
          end
          @facilities = @facilities.where("zip_code = '#{params[:site_zip].strip}'") unless params[:site_zip].blank?
        end

        @facilities = @facilities.where("name LIKE '%#{params[:site_name].strip}%'") unless params[:site_name].blank?
        @facilities = @facilities.where("address_one LIKE '%#{params[:site_address_1].strip}%'") unless params[:site_address_1].blank?
        @facilities = @facilities.where("address_two LIKE '%#{params[:site_address_2].strip}%'") unless params[:site_address_2].blank?
        @facilities = @facilities.where("city = '#{params[:site_city].strip}'") unless params[:site_city].blank?
        @facilities = @facilities.where("state = '#{params[:site_state].strip}'") unless params[:site_state].blank?
      end
     
      @facilities = Facility.none if @facilities == Facility || @facilities == UpmcFacility
      @facilities = @facilities.paginate(:per_page => 5, :page => params[:page])
    end
  end

  def approve_site
    era_job = EraJob.find(params[:job_id])
    era_client = era_job.era.inbound_file_information.client
    if era_client.try(:name).try(:upcase) == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"

      @facility = UpmcFacility.find(params[:id])
    else
      @facility = Facility.find(params[:id])
    end
    EraJob.map_site(@facility, era_job)
    
    respond_to do |format|
      format.js
    end
  end
  
  def payer_search
    flash[:notice] = nil
    if params[:create_payer_button]
      @era_check = EraCheck.find(params[:chk_id])
      @payer = Payer.new(:payer => @era_check.payer_name, :pay_address_one => @era_check.payer_address_1, :pay_address_two => @era_check.payer_address_2, :payer_city => @era_check.payer_city, :payer_state => @era_check.payer_state, :payer_zip => @era_check.payer_zip, :payer_tin => @era_check.trn_payer_company_identifier, :source => "ERA")
      if !@era_check.era_payid.blank?
        @payer.payid = @era_check.era_payid
      elsif !@era_check.payer_npi.blank?
        @payer.payid = @era_check.payer_npi
      else
        @payer.payid = "No Payer"
      end
      @payer.save!
      EraCheck.map_payer(@payer, @era_check)
      redirect_to :controller => 'admin/era_exception' 
    else
      if params[:payer_name].blank? && params[:payer_address_1].blank? && params[:payer_address_2].blank? && params[:payer_city].blank? && params[:payer_state].blank? && params[:payer_zip].blank? && params[:payer_id].blank? && params[:payer_npi].blank? && params[:payer_tin].blank?
        flash[:notice] = 'Please fill in one of the search fields'
        @payers = Payer.none
      else
        @payers = Payer

        @payers = @payers.where("payer LIKE '%#{params[:payer_name].strip}%'") unless params[:payer_name].blank?
        @payers = @payers.where("pay_address_one LIKE '%#{params[:payer_address_1].strip}%'") unless params[:payer_address_1].blank?
        @payers = @payers.where("pay_address_two LIKE '%#{params[:payer_address_2].strip}%'") unless params[:payer_address_2].blank?
        @payers = @payers.where("payer_city = '#{params[:payer_city].strip}'") unless params[:payer_city].blank?
        @payers = @payers.where("payer_state = '#{params[:payer_state].strip}'") unless params[:payer_state].blank?
        @payers = @payers.where("payer_zip = '#{params[:payer_zip].strip}'") unless params[:payer_zip].blank?
        @payers = @payers.where("payid = '#{params[:payer_id].strip}'") unless params[:payer_id].blank?
        @payers = @payers.where("payid = '#{params[:payer_plan_id].strip}'") unless params[:payer_plan_id].blank?
        @payers = @payers.where("payer_tin = '#{params[:payer_tin].strip}'") unless params[:payer_tin].blank?
      end
      
      @payers = @payers.paginate(:per_page => 5, :page => params[:page])
    end
  end
  
  def approve_payer
    @payer = Payer.find(params[:id])
    @era_check = EraCheck.find(params[:chk_id])
    EraCheck.map_payer(@payer, @era_check)
    
    respond_to do |format|
      format.js
    end
  end

end
