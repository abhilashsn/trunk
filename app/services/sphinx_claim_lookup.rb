class SphinxClaimLookup

  # Returns claim results via a Sphinx index search. 
  # 
  # Accepts a hash of parameters from the data entry grid and converts to 
  # Sphinx query terms.
  #
  # params - A hash containing the parameters to search. Valid keys are:
  # * patient_no
  # * patient_lname
  # * patient_fname
  # * date_of_service_from
  #
  # Returns array of ClaimInformation containing the claim search results.
  #
  # ==== Examples
  #
  #   SphinxClaimLookup.search(patient_no: "729706684")
  #   SphinxClaimLookup.search(patient_lname: "WILSON", patient_fname: "ARTHUR", date_of_service_from: "27042011")

  def self.search(params)
    claim_search_result = ClaimSearchResult.new
    account_number = params[:patient_no]
    patient_last_name = params[:patient_lname]
    patient_first_name = params[:patient_fname]
    total_charges = params[:total_charges]
    date_of_service_from = params[:date_of_service_from]
    insured_id = params[:insured_id]
    exact_serach = params [:exact_serach]
    payer_name = params[:payer_name]
    cpt_code = params[:cpt_code]
    service_from_date = normalize_date date_of_service_from unless date_of_service_from.nil?
    facility_id = params[:facility_id]                             if params[:mpi_search_type].eql?("FACILITY")
    client_id = params[:client_id]                                 if params[:mpi_search_type].eql?("CLIENT")
    mpi_serach_facility_group = params[:mpi_serach_facility_group]
    unless params[:sort].blank?
      sort_by = (params[:sort].class == String ? params[:sort] : params[:sort].keys[0])
      unless sort_by.match('_reverse') == nil
        sort_by = sort_by.chomp('_reverse')
        sort_mode_for_header = "desc"
      else
        sort_mode_for_header = "asc"
      end
    end    
mpi_results = ClaimInformation.mpi_search_for_sphinx(facility_id,client_id,account_number,patient_last_name,patient_first_name,service_from_date,insured_id,total_charges,params[:page],exact_serach,payer_name,  sort_mode_for_header, sort_by,mpi_serach_facility_group,cpt_code)
    claim_search_result.mpi_results = mpi_results
    claim_search_result.response_code = mpi_results.empty? ? 404 : 200
    claim_search_result.response_message = "Found"
    claim_search_result
  end

  def self.normalize_date(date)
    if (date != "mm/dd/yy" && !date.blank? )
      date_parts = date.to_s.split("/")
      "20"+date_parts[2] + "-" + date_parts[0] + "-" +date_parts[1]
    end
  end
  
end