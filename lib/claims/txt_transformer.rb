class TXTTransformer 
  attr_reader :cnf, :cntnt, :clm_fl_info

  def initialize
    @cnf = nil
    @clm_fl_info = nil
    # TODO::Should be moved to higher level
  end
  
  # This method triggers the loading process by invoking the process_claim and process_claim_items methods.
  def transform(fl, cnf)
    begin
      @cnf = cnf
      
      # Collecting the file content into an array for easy navigation
      @cntnt = File.new(fl).readlines
      
      @clm_fl_info = ClaimFileInformation.new
      @clm_fl_info.claim_informations << process_claim
      collect_file_info(fl)
      
      # @clm_fl_info.save!
      p clm_fl_info
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
    end  
  end

  # This method processes the claims.
  def process_claim
    clm = ClaimInformation.new
    
    # Row, column index reduced to match user specification
    @cnf['CLAIM'].each { |k, v| clm[k] = @cntnt[v[0]-1][v[1]-1, v[2]].strip }
    @cnf['CLAIM_DATES'].each { |k, v| clm[k] = frame_date(@cntnt[v[0]-1][v[1]-1, v[2]].strip) }
    
    @clm_fl_info.total_claim_count += 1
    process_claim_services(clm)
    refine_claim(clm)
    # if clm.save!
      @clm_fl_info.loaded_claim_count += 1
      @clm_fl_info.loaded_svcline_count += 1
    # end
    p clm
    return clm
  end

  # This method processes the claim service informations.
  def process_claim_services(clm)
    row = @cnf['CLAIM_SERVICE_START_LINE']-1
    while(row < @cnf['CLAIM_SERVICE_END_LINE'])
      
      # New line characters may in a blank line
      if @cntnt[row].length > 1
        clm_items = ClaimServiceInformation.new
        @cnf['CLAIM_SERVICE'].each { |k, v| clm_items[k] = @cntnt[row][v[1]-1, v[2]].strip }
        @cnf['CLAIM_SERVICE_DATES'].each { |k, v| clm_items[k] = frame_date(@cntnt[row][v[1]-1, v[2]].strip) }
        @clm_fl_info.total_svcline_count += 1
        p clm_items
        clm.claim_service_informations << clm_items
      end
      row += 1
    end
  end

  private
    
  def collect_file_info(fl)
    @clm_fl_info.size = File.size(fl)
    @clm_fl_info.name = nil
    @clm_fl_info.zip_file_name = nil
    @clm_fl_info.name = File.basename(fl)
    @clm_fl_info.load_start_time = Time.now
    # @clm_fl_info.file_arrival_time = nil
    # @clm_fl_info.facility << Facility.find_by_name(@cnf['facility_name'])
  end
    
  def frame_date(dat, frmt = "%m%d%y")
    Date.strptime(dat, frmt)
  end

  def refine_claim(clm)
  
    # Framing Patient Name
    clm['patient_last_name'], clm['patient_first_name'] = clm['patient_last_name'].split(',')
    
    # Framing City, State & Zip
    clm['payee_city'], clm['payee_state'], clm['payee_zipcode'] = clm['payee_city'].split(' ')
    
  end
end

