require 'httparty'
require 'will_paginate/array'
require 'pp'
require 'hashie/mash'

class RmsClaimLookup
  include HTTParty
  config = Settings.rms_claim_lookup
  debug_output
  base_uri config.base_uri
  default_params :un => config.username, :pw => config.password

  parser(
    Proc.new do |body, format|
      if body.start_with?("<?xml")
        Crack::XML.parse(body)
      else
        body
      end
    end
  )

  PARAM_MAPPINGS = { "pid" => "pid", "patient_no" => "pan", "patient_lname" => "patientlastname", "patient_fname" => "patientfirstname", "date_of_service_from" => "dateofservice", "total_charges" => "submittedamount"}
  CLAIM_TYPES = ["P", "S", "T"]

  def self.translate_params(params)
    rms_params = Hash[PARAM_MAPPINGS.map {|k, v| [v, params[k.to_sym]] unless params[k.to_sym].blank?}]
    if rms_params["dateofservice"]
      rms_params["dateofservice"] = Date.strptime(rms_params["dateofservice"], "%m/%d/%y").strftime("%d%m%Y")
    end
    rms_params
  end

  def self.get_response(params)
    start = Time.now
    response = get('/mbx-claim-lookup/LookupClaim', :query => params)
    WebServiceLog.create!(:service => '/mbx-claim-lookup/LookupClaim', 
                          :query => params.to_json, 
                          :response_code => response.code,
                          :response_time => (Time.now - start) * 1000)
    response
  end

  def self.parse_response(response)
    claim_search_result = ClaimSearchResult.new
    mpi_responses = []

    case response.code
    when 200
      mpi_response = Hashie::Mash.new

      claim = response["claimFacet"]
      patient = claim["patient"]
      billing_provider = claim["billingProvider"]

      subscriber_list = claim.values_at('primarySubscriber', 'secondarySubscriber', 'tertiarySubscriber').compact
      payer_list = claim.values_at('primaryPayer', 'secondaryPayer', 'tertiaryPayer').compact

      # 1.  Patient Account Number
      # 2.  Medical Record Number
      # 3.  Billing Provider – NPI
      # 4.  Total Claim Charge Amount
      # 5.  Claim Begin Date
      # 6.  Claim End Date
      # 7.  Facility Type Code
      # 8.  Claim Frequency Code
      # 9.  Primary Payer Name and Address
      # 10. Secondary Payer Name and Address
      # 11. Tertiary Payer Name and Address
      # 12. Primary Subscriber Member ID, Group # and Name
      # 13. Secondary Subscriber Member ID, Group # and Name
      # 14. Tertiary Subscriber Member ID, Group # and Name
      # 15. Patient First and Last Name

      payer_list.each_with_index do |payer, row|
        subscriber = subscriber_list[row]
        membership_info = subscriber["membershipInfo"]

        mpi_response = Hashie::Mash.new
        mpi_response.patient_account_number = claim["patientAccountNumber"]
        mpi_response.insured_id = membership_info["memberId"] # ?
        mpi_response.billing_provider_npi = billing_provider["nationalProviderId"]
        mpi_response.total_charges = claim["totalClaimChargeAmount"]
        mpi_response.claim_statement_period_start_date = claim["statementFromOrToDate"]["beginDate"]
        mpi_response.claim_statement_period_end_date = claim["statementFromOrToDate"]["endDate"]
        mpi_response.facility_type_code = claim["facilityTypeCode"]
        mpi_response.claim_frequency_type_code = claim["claimFrequencyCode"]
        mpi_response.payer_name = payer["payerName"]
        mpi_response.payer_address = payer["street"]
        mpi_response.payer_city = payer["city"]
        mpi_response.payer_state = payer["state"]
        mpi_response.payer_zipcode = payer["zipcode"]
        mpi_response.subscriber_first_name = subscriber["firstName"]
        mpi_response.subscriber_middle_initial = subscriber["middleName"]
        mpi_response.subscriber_last_name = subscriber["lastName"]
        mpi_response.patient_first_name = patient["firstName"]
        mpi_response.patient_middle_initial = patient["middleName"]
        mpi_response.patient_last_name = patient["lastName"]
        mpi_response.claim_type = CLAIM_TYPES[row]
        # mpi_response.date_of_service = Date.parse(claim["dateOfService"]).to_date

        # TODO: Clean this up. Array then flatten is ugly.
        service_lines = Array[claim["serviceLines"]].flatten
        mpi_service_lines = service_lines.map do |service_line|
          mpi_service = Hashie::Mash.new
          mpi_service.line_number = service_line["lineNumber"].to_i
          mpi_service.service_from_date = Date.parse(service_line["beginDateOfService"]).to_date
          mpi_service.service_to_date = mpi_service.service_from_date
          mpi_service.cpt_hcpcts = service_line.fetch("procedureCode",{}).fetch("code", nil)
          mpi_service.modifier1 = service_line["procedureCodeModifier1"]
          mpi_service.modifier2 = service_line["procedureCodeModifier2"]
          mpi_service.modifier3 = service_line["procedureCodeModifier3"]
          mpi_service.modifier4 = service_line["procedureCodeModifier4"]
          mpi_service.quantity = service_line["quantity"]
          mpi_service.charges = service_line["billedAmount"]
          mpi_service.non_covered_charge = service_line["noncoveredAmount"]
          mpi_service.revenue_code = service_line["revenueCode"]
          mpi_service
        end

        sorted_lines = mpi_service_lines.sort {|a, b| a.line_number <=> b.line_number}
        mpi_response.claim_service_informations = sorted_lines
        mpi_responses << mpi_response
        claim_search_result.mpi_results = mpi_responses.compact.paginate
      end
    end

    claim_search_result.response_code = response.code
    claim_search_result.response_message = response.message
    claim_search_result
  end

  # Returns claim results via a web service call. Structures results to match
  # results from ClaimInformation model searches that are used for local search.
  # 
  # Accepts a hash of parameters from the data entry grid and converts to equivalent
  # web service parameters. 
  #
  # Configurations for web service call is made at /config/settings.yml
  # 
  # params - A hash containing the parameters to search. Valid keys are:
  # * patient_no
  # * patient_lname
  # * patient_fname
  # * date_of_service_from
  # * total_charges
  #
  # Returns ClaimSearchResult.
  #
  # ==== Examples
  #
  #   RmsClaimLookup.search(patient_no: "729706684")
  #   RmsClaimLookup.search(patient_lname: "WILSON", patient_fname: "ARTHUR", date_of_service_from: "27042011")

  def self.search(params)
    begin
      claim_search_result = parse_response(get_response(translate_params(params)))
      if claim_search_result.response_code == 200
        claim_search_result.mpi_results = persist_claims(claim_search_result.mpi_results).paginate
      end
    rescue SocketError => e
      claim_search_result = ClaimSearchResult.new
      claim_search_result.response_code = 500
      claim_search_result.response_message = "Unable to connect to server!"
      Rails.logger.error e.message
      e.backtrace.each { |line| Rails.logger.error line }
    rescue Timeout::Error => e
      claim_search_result = ClaimSearchResult.new
      claim_search_result.response_code = 500
      claim_search_result.response_message = "Connection timed out!"
      Rails.logger.error e.message
      e.backtrace.each { |line| Rails.logger.error line }      
    rescue StandardError => e
      claim_search_result = ClaimSearchResult.new
      claim_search_result.response_code = 500
      claim_search_result.response_message = "Unexpected exception: #{e.message}"
      Rails.logger.error e.message
      e.backtrace.each { |line| Rails.logger.error line }      
    end
    claim_search_result
  end

  def self.persist_claims(claims)
    claims.map do |claim|
      service_lines = claim.claim_service_informations
      claim.claim_service_informations = []
      new_claim = ClaimInformation.new(claim.to_hash, :without_protection => true)
      service_lines.each do |service_line|
        new_claim.claim_service_informations.build(service_line.to_hash, :without_protection => true)
      end
      new_claim.save!
      new_claim
    end
  end
end