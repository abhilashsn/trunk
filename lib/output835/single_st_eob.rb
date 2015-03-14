class Output835::SingleStEob < Output835::Eob
  def initialize(eob, facility, payer, index, element_seperator, check_num, count)
    @eob = eob
    @index = index
    @element_seperator = element_seperator
    @check = eob.check_information
    @job = @check.job
    @claim = eob.claim_information
    @facility = facility
    @client = facility.client
    if @check.micr_line_information && @check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = @check.micr_line_information.payer
    else
      @payer = @check.payer
    end
    @facility_config = facility.facility_output_configs.first
    @facility_output_config = facility.output_config(@job.payer_group)
    @service_eobs = eob.service_payment_eobs
    @reason_codes = nil    #this variable is used in  child class for configurable section
    @check_nums = check_num
    @count = count
  end
end