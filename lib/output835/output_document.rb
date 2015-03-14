################################################################################
# Description : This class is responsible for generating configured document level
#               segments in 835 output.
# Created     : 28-04-11 by Sunil Antony @ Revenuemed
################################################################################

class Output835::OutputDocument < Output835::Document
  
  def initialize(checks, conf = {}, check_eob_hash = nil)
    super                                                                        #calling initialize method of super class  

    write_log
    @batch = checks.first.batch

    #instance variables for each segments, Here we are setting unconfigured part
    # of a segment. size hash is added for providing justification for each segment
    @isa = {0=> 'ISA', 2 => ' ' * 10, 4 => ' ' * 10, 9 => "#{Time.now().strftime('%y%m%d')}",
      10 => "#{Time.now().strftime('%H%M')}", :size => {6 => 15, 8 => 15} }
    @gs = {0 => 'GS', 1 => 'HP', 5 => "#{Time.now().strftime('%H%M')}", 7 => 'X'  }
    @iea = {0 => 'IEA', 1 => '1'}
    @ge = {0 => 'GE', 1 => checks_in_functional_group(nil)}
    
    create_config_hash
  end
  
  def create_config_hash
    fac_abbr = facility.abbr_name ? facility.abbr_name.strip + 'MCIOCR' : ''
    counter =  @isa_record? @isa_record.isa_number.to_s.justify(9, '0') : nil
  
    # configuration hash for UI to datapoint mapping.
    # keys represent UI selected value which is saved in the database and values
    # represent corresponding datapoint.
    @config_hash = { "[Blank]" => '', 
      "[Payer ID]" => payer_id.to_s,
      "[Payer ID Left Padded With 5 Zeroes]" => payer_id.to_s.left_padd(15, 5, '0'),
      "[Client TIN]" => facility.facility_tin.to_s.strip, 
      "[Counter]" => counter,
      "[Lockbox Number]" => facility.lockbox_number.to_s,
      "[Lockbox Number Left Padded With 0]" => facility.lockbox_number.to_s.justify(9, '0'),
      "[Current Date(YYMMDD)]" => Time.now().strftime("%y%m%d"),
      "[Current Date(CCYYMMDD)]" => Time.now().strftime("%Y%m%d"),
      "[Facilty ABB + MCI + OCR]" =>  fac_abbr,
      "[Facility Abbreviation]" => facility.abbr_name.to_s.strip,
      "[Batch Date]" => @batch.date.strftime("%Y%m%d"),
      "[CPID From 837]" => cpid.to_s,
      "[CPID From 837 Left Padded With X]" => cpid.to_s.justify(15, 'X') ,
      "[Facility Name]" => facility.name.to_s,
      "[Batch ID Left Padded With 9 Zeroes]" => @batch.batchid.to_s.justify(9, '0'),
      "[Batch ID]" => @batch.batchid.to_s
    }
    @config_hash_keys = @config_hash.keys
  end
   
  # method names and corresponding segment. This hash is used for dynamic method
  # definition. Method name should match corresponding segments method in base 
  # class. This method name matching logic is for handling both bank and non-bank
  # outputs. Segment name should match corrresponding segment name from databse. 
  methods = [{:method => "interchange_control_header", :segment =>  :isa_segment},
    {:method => "functional_group_header", :segment =>  :gs_segment},
    {:method => "interchange_control_trailer", :segment =>  :iea_segment},
    {:method => "functional_group_trailer", :segment => :ge_segment}
  ]
  
  # Dynamically defining methods for corresponding configured seqments
  methods.each do |method_params|
    define_method "#{method_params[:method]}" do |*args|
      if !(@facility_config.details[:configurable_segments].has_key?method_params[:segment].to_s.split("_").first)             # if the segment is not configured call correponding method from super class
        super()
      elsif !@facility_config.details[:configurable_segments][method_params[:segment].to_s.split("_").first]     # need not print this segment in 835
        nil
      else
        parse_output_configurations(method_params[:segment])
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is responsible for parsing output configurations and
  #               generating equivalent segment string.                   
  # Input       : segment to be parsed
  # Output      : parsed segment string
  #-----------------------------------------------------------------------------    
  def parse_output_configurations(segment)
    if !@facility_config.details[segment].blank?
      segment_hash = @facility_config.details[segment].convert_keys
    end
    if !segment_hash.blank?
      segment_array = make_segment_array(segment_hash, segment)
    end
    if !segment_array.blank?
      segment_array = segment_array.collect do |element|
        actual , size = element.split('#')               #handling size of a segment which is seperated by '#'
        actual, default = actual.split('@') if actual          #handling default values which is seperated by '@'
        if default && @config_hash[actual].blank?
          default
        elsif @config_hash_keys.include? actual
          @config_hash[actual].ljust(size.to_i)
        else
          actual.to_s.ljust(size.to_i)
        end
      end
      Output835.remove_blank(segment_array).join('*')
    end
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method generates segment string from the output configuration
  #               hash.                   
  # Input       : configuration hash, segment to be parsed
  # Output      : segment string
  #-----------------------------------------------------------------------------    
  def make_segment_array(segment_hash, segment)
    merged_hash = nil
    segment_variable = segment.to_s.split('_').first
    if !segment_hash.blank?
      # This is to insert '#' to the segment option for which size hash is defined
      eval(" if @#{segment_variable}[:size]
              @#{segment_variable}[:size].each do |key, value|
               segment_hash[key] += \"#\#{value}\" if segment_hash[key]
            end
          end
    merged_hash =  segment_hash.merge(@#{segment_variable})")
    end
    if !merged_hash.blank?
      merged_hash.delete(:size)
      segment_array = merged_hash.segmentize.to_string
    end
  end
  
  
  #-----------------------------------------------------------------------------
  # Description : CPID is Payer id for Goodman Campbell. The method is to pick the
  #               payer id from the 837 if available, else use the payer id from
  #               the payer table.
  # Input       : None
  # Output      : Payerid string
  #-----------------------------------------------------------------------------
  def cpid
    first_mpi_claim  = @eobs.detect{|eob| eob.claim_information}
    if first_mpi_claim && first_mpi_claim.claim_information.payid
      first_mpi_claim.claim_information.payid
    else
      payer_id
    end
  end

  def write_log
    Output835.log.info "**** Configured Segments and Values ****"
    @facility_config.details.each do |key,value|
      if key[-7..-1] == "segment"
        Output835.log.info "========#{key.upcase}========"
        value.each do |k,v|
          Output835.log.info "#{k}  :  #{v}"
        end
      end
    end
  end

end
