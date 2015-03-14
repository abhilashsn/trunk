class DatabaseClaimLookup

  # Returns claim results via a local database search. 
  # 
  # Accepts a hash of parameters from the data entry grid and converts to 
  # database query terms.
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
  #   DatabaseClaimLookup.search(patient_no: "729706684")
  #   DatabaseClaimLookup.search(patient_lname: "WILSON", patient_fname: "ARTHUR", date_of_service_from: "27042011")

  def self.search(params)
    account_number = params[:patient_no]
    patient_last_name = params[:patient_lname]
    patient_first_name = params[:patient_fname]
    date_of_service_from = params[:date_of_service_from]
    service_from_date = date_of_service_from


    query_condition = []
    mpi_query_condition = []

    mpi_results = []
    
    claim_search_result = ClaimSearchResult.new
    query_condition << "facility_id = #{params[:facility_id]  }" if params[:mpi_search_type].eql?("FACILITY")
    query_condition << "client_id = #{params[:client_id]}" if params[:mpi_search_type].eql?("CLIENT")
    query_condition << condition('patient_account_number', account_number) unless account_number.blank?
    query_condition << condition('patient_last_name', patient_last_name) unless patient_last_name.blank?
    query_condition << condition('patient_first_name', patient_first_name) unless patient_first_name.blank?
    query_condition << "active = 1"
        
    # query_condition << "facility_id = #{@facility.id}"
    mpi_query_condition = query_condition.join(" and ")
     
    join_condition = "inner join claim_service_informations on claim_service_informations.claim_information_id = claim_informations.id"
    
    mpi_results = ClaimInformation.select("claim_informations.*, sum(claim_service_informations.charges) as total_charge").
      where(mpi_query_condition).joins(join_condition).group("claim_informations.id").paginate(:page => params[:page])
    
    claim_search_result.mpi_results = mpi_results
    claim_search_result.response_code = mpi_results.empty? ? 404 : 200
    claim_search_result.response_message = "Found"
    claim_search_result
  end

  def self.condition(column_name, query)
    if query.include?("*")
      like_condition(column_name, query)
    else
      equal_condition(column_name, query)
    end
  end

  def self.like_condition(column_name, query)
    "#{column_name} like #{ActiveRecord::Base.connection.quote(query.gsub('*', '%'))}"
  end

  def self.equal_condition(column_name, query)
    "#{column_name} = #{ActiveRecord::Base.connection.quote(query)}"
  end
end