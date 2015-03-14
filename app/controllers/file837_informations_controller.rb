class File837InformationsController < ApplicationController

  layout 'standard', :except => [:claim_retrieval]
  require_role ["processor", "qa", "admin", "supervisor", "manager", "TL", "partner", "client", "facility"]

  def list
    @arrival_date_from = params[:arrival_date_from]
    @arrival_date_to = params[:arrival_date_to]
    @client_code = params[:client_code]
    @zip_file_name = params[:zip_file_name]
    @file_name_837 = params[:file_name_837]
    @status = params[:status]
    
    conds = []
    if current_user.has_role?(:admin) || current_user.has_role?(:supervisor)
      conds << "deleted != 1"
    end
    if @arrival_date_from.blank? && @arrival_date_to.blank? && @client_code.blank? && @zip_file_name.blank? && @file_name_837.blank? && @status.blank?
      if current_user.has_role?(:admin) || current_user.has_role?(:supervisor)      
        conds << "Left(arrival_time,10) >= '#{1.week.ago.strftime('%Y-%m-%d')}'"
      else
        conds << "status = 'SUCCESS' and total_claim_count > 0 and loaded_claim_count > 0 and deleted != 1 and Left(arrival_time,10) >= '#{1.week.ago.strftime('%Y-%m-%d')}'"
      end
    end

    #apply filters
    unless @arrival_date_from.blank? && @arrival_date_to.blank?
      if @arrival_date_from.blank? && !@arrival_date_to.blank?
        flash[:notice] = 'Please select "From" Date'
      elsif @arrival_date_to.blank? && !@arrival_date_from.blank?
        flash[:notice] = 'Please select "To" Date'
      else
        conds << "Left(arrival_time,10) >= '#{Date.strptime(@arrival_date_from, '%m/%d/%Y')}' AND Left(arrival_time,10) <= '#{Date.strptime(@arrival_date_to, '%m/%d/%Y')}'"
      end
    end
   
    unless @client_code.blank?
      begin
        facility = Facility.where("sitecode like '%#{@client_code}%'")
        if facility.blank?
          flash[:notice] = "Invalid Client Code format"
        else
          facility_id = facility.select(:id).first.id
          conds << "facility_id = '#{facility_id}'"
        end
      rescue ArgumentError
        flash[:notice] = "Invalid Client Code format"
      end
    end
    unless @zip_file_name.blank?
      begin
        conds << "zip_file_name like '%#{@zip_file_name}%'"
      rescue ArgumentError
        flash[:notice] = "Invalid Zip File Name format"
      end
    end
    unless @file_name_837.blank?
      begin
        conds << "name like '%#{@file_name_837}%'"
      rescue ArgumentError
        flash[:notice] = "Invalid 837 File Name format"
      end
    end
    unless @status.blank?
      begin
        conds << "status like '%#{@status}%'"
      rescue ArgumentError
        flash[:notice] = "Invalid Status"
      end
    end
      
    #if request.xml_http_request?
    #  render :partial => "file_837_report", :layout => false
    #end
   
    #allow csv format
    respond_to do |format|
      format.html { @file_837_informations = ClaimFileInformation.where(conds.join(' and ')).order("arrival_time desc, load_start_time desc").limit(1000).paginate(:page => params[:page], :per_page => 30) }
      format.csv {
        compatible_csv
        @file_837_informations = ClaimFileInformation.where(conds.join(' and ')).order("arrival_time desc, load_start_time desc").limit(10000)
      }
    end
  end

  def delete
    if params[:id].present? && (current_user.has_role?(:admin) || current_user.has_role?(:supervisor))
      claim_file_information = ClaimInformation.select("claim_informations.claim_file_information_id AS claim_file_information_id, \
        claim_informations.id AS claim_information_id, COUNT(insurance_payment_eobs.id) AS count_of_eobs").
        joins(:insurance_payment_eob).where(:claim_file_information_id => params[:id])
      @eob_link_exists = claim_file_information.present?
      if @eob_link_exists
        @eob_containing_claim_information_ids = claim_file_information.map(&:claim_information_id).join(", ")
      end
      @file_837_information_id = params[:id]
      respond_to do |format|
        format.js
      end
    end
  end

  # EOB related claim_info is not deleted. Claim file is defintly deleted.
  # The alert comes for claim file where EOB are present
  def delete_confirmed
    if params[:id].present?
      conditions = "claim_file_information_id = #{params[:id]}"
      claim_with_eob_ids = params[:eob_containing_claim_information_ids]
      if claim_with_eob_ids.present?
        conditions += " AND id NOT IN (#{claim_with_eob_ids})"
      end
      ClaimInformation.where(conditions).delete_all
      ClaimFileInformation.where(:id => params[:id]).update_all(:deleted => 1, :status => "DELETED", :updated_at => Time.now)
    end
    redirect_to :action => 'list'
  end

  def update
    file_837_information = ClaimFileInformation.find(params[:id])
    file_837_information.update_attributes(params[:claim_file_information])
    
    respond_to do |format|
      format.html { redirect_to :action => 'list' }
      format.json { respond_with_bip(file_837_information) }
    end
  end

  def search
    begin

      raise "No filter to do Claim search!" if params[:search_input].blank?

      @claim_informations = ClaimInformation.search params[:search_input],
        :per_page => 30, :page => params[:page],
        :start => true, :match_mode => :boolean,
        :index => get_mpi_index_name,
        :classes => [ClaimInformation], :populate => true

      @claim_informations.compact!
    end
  end

  def claim_retrieval
    flash[:notice] = 'Only a maximum of 1000 results are returned, please narrow down your searches'
    render :layout =>'ext'
  end

  def ret_search

    lockboxes = current_user.lockboxes
    claim_file_conds = []
    claim_file_information = nil
    claim_file_conds << "id = #{params[:cf_id]}" unless params[:cf_id].blank?
    claim_file_conds << "name LIKE '%#{params[:filename]}%'" unless params[:filename].blank?
    claim_file_conds << "Left(arrival_time,10) = '#{params[:arrival_date]}'" unless params[:arrival_date].blank?
    claim_file_information = ClaimFileInformation.where(claim_file_conds.join(' and ')).first unless claim_file_conds.blank?

    page = (params[:start].to_i/30)+1
    mpi_conditions = []
    condition_list = []
    condition_list << "("
    condition_list << "@patient_account_number #{Riddle.escape(params[:account_number])}" unless params[:account_number].blank?
    condition_list << "@patient_last_name #{Riddle.escape(params[:pat_lastname])}" unless params[:pat_lastname].blank?
    condition_list << "@patient_first_name #{Riddle.escape(params[:pat_firstname])}" unless params[:pat_firstname].blank?
    condition_list << "@claim_from_date #{Riddle.escape(params[:claim_from_date])}" unless params[:claim_from_date].blank?
    condition_list << "@total_charges #{Riddle.escape(sprintf('%.2f', params[:charges]))}" unless params[:charges].blank?
    condition_list << ")"

    mpi_conditions = condition_list.join(" ")
    mpi_conditions = "" if mpi_conditions == "( )"

    if claim_file_information.blank?
      if mpi_conditions.blank?
        unless current_user.has_role?(:admin) || lockboxes.empty?
          sort_conditions = {:created_at => Time.now.beginning_of_day..Time.now.end_of_day,:facility_id => lockboxes.collect(&:id)}
        else
          sort_conditions = {:created_at => Time.now.beginning_of_day..Time.now.end_of_day}
        end
        claims = ClaimInformation.search :per_page => 30, :page => page,
          :start => true, :match_mode => :extended,
          :index => get_mpi_index_name,
          :with => sort_conditions,
          :classes => [ClaimInformation], :populate => true
      else
        unless current_user.has_role?(:admin) || lockboxes.empty?
          sort_conditions = {:facility_id => lockboxes.collect(&:id)}
        end
        claims = ClaimInformation.search mpi_conditions,
          :per_page => 30, :page => page, :with => sort_conditions,
          :start => true, :match_mode => :extended,
          :index => get_mpi_index_name,
          :classes => [ClaimInformation], :populate => true
      end
    else
      unless current_user.has_role?(:admin) || lockboxes.empty?
        sort_conditions = {:claim_file_information_id => claim_file_information.id,:facility_id => lockboxes.collect(&:id)}
      else
        sort_conditions = {:claim_file_information_id => claim_file_information.id}
      end
      id = [1,2]
      claims = ClaimInformation.search mpi_conditions,
        :per_page => 30, :page => page,
        :start => true, :match_mode => :extended,
        :index => get_mpi_index_name,
        :with => sort_conditions,
        :classes => [ClaimInformation], :populate => true
    end


    total_entries = claims.total_entries
    #All query results maxed at 1000 to prevent db load issues
    total_entries = 1000 if total_entries > 1000

    return_data = Hash.new()
    return_data[:Total] = total_entries
    return_data[:Claims] = claims.collect{ |data|
      claim_filename = nil
      claim_file_arrival_date = nil
      claim_from_date = nil
      claim_to_date = nil
      no_of_services = data.claim_service_informations.count
      svc_lnk = "0"
      svc_lnk = "<a href='#' onclick='svcPopup(\"svc_popup?c_id=#{data.id}\");return false'>#{no_of_services}</a>" unless no_of_services.zero?

      if data.patient_middle_initial.blank?
        patient_name = "#{data.patient_first_name} #{data.patient_last_name}"
      else
        patient_name = "#{data.patient_first_name} #{data.patient_middle_initial} #{data.patient_last_name}"
      end
      if data.subscriber_middle_initial.blank?
        member_name = "#{data.subscriber_first_name} #{data.subscriber_last_name}"
      else
        member_name = "#{data.subscriber_first_name} #{data.subscriber_middle_initial} #{data.subscriber_last_name}"
      end
      if data.claim_statement_period_start_date.blank?
        svc_info = data.claim_service_informations.order("service_from_date ASC").first
        claim_from_date = svc_info.service_from_date.strftime("%m/%d/%Y") if (!svc_info.blank? && !svc_info.service_from_date.blank?)
      else
        claim_from_date = data.claim_statement_period_start_date.strftime("%m/%d/%Y")
      end
      if data.claim_statement_period_end_date.blank?
        svc_info = data.claim_service_informations.order("service_to_date DESC").first
        claim_to_date = svc_info.service_to_date.strftime("%m/%d/%Y") if (!svc_info.blank? && !svc_info.service_to_date.blank?)
      else
        claim_to_date = data.claim_statement_period_end_date.strftime("%m/%d/%Y")
      end
      unless data.claim_file_information.blank?
        claim_filename = data.claim_file_information.name
        claim_file_arrival_date = data.claim_file_information.arrival_time.strftime("%m/%d/%Y")
      end

      { :a_no => data.patient_account_number,
        :pat_name => patient_name,
        :m_name => member_name,
        :claim_from_date => claim_from_date,
        :claim_to_date => claim_to_date,
        :s_charges => "$#{data.total_charges}",
        :no_of_services => svc_lnk,
        :c_type => data.claim_type,
        :pay_name => data.payer_name,
        :c_fname => claim_filename,
        :c_file_arrival_date => claim_file_arrival_date
      }
    }
    render :text=>"#{return_data.to_json}", :layout => false
  end

  def svc_popup
    flash[:notice] = nil
    @claim_information = ClaimInformation.find(params[:c_id])
    @claim_service_informations = @claim_information.claim_service_informations.paginate(:page => params[:page], :per_page => 30)
  end

end
