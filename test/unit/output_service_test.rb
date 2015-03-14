require File.dirname(__FILE__)+'/../test_helper'

class OutputServiceTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :insurance_payment_eobs, :service_payment_eobs, :payers , :facility_output_configs
  
  def setup
    @service = Output835::OutputService.new(service_payment_eobs(:svc205), facilities(:facility_3), payers(:payer7),1, '*')
    @fac_config = facility_output_configs(:facility_output_config_9)
    @ser_eob = service_payment_eobs(:svc205)
    @svc = "SVC*#{@service.composite_med_proc_id}*#{@ser_eob.amount('service_procedure_charge_amount').to_s.to_dollar}*#{@ser_eob.amount('service_paid_amount').to_s.to_dollar}*#{@ser_eob.service_quantity}"
  end
  
  def test_parse_output_configurations
     assert_equal(@svc, @service.parse_output_configurations(:svc_segment))
  end
  
  def test_make_segment_array
    svc = ["SVC","#{@service.composite_med_proc_id}","#{@ser_eob.amount('service_procedure_charge_amount').to_s.to_dollar}", "#{@ser_eob.amount('service_paid_amount').to_s.to_dollar}", "#{@fac_config.details[:svc_segment]['5']}"]
    assert_equal(svc, @service.make_segment_array(@fac_config.details[:svc_segment].convert_keys,:svc_segment) )
  end

  def test_service_payment_information
    assert_equal(@svc, @service.service_payment_information)
  end

  def test_composite_med_proc_id
    proc_id = "AD#{@fac_config.details[:isa_segment]['16']}#{@ser_eob.service_procedure_code}"
    assert_equal(proc_id, @service.composite_med_proc_id)
  end

  def test_dtm_151
    assert_equal("DTM*151*#{@ser_eob. date_of_service_to.strftime("%Y%m%d")}", @service.dtm_151)
  end
  
  def test_dtm_150
    assert_equal("DTM*150*#{@ser_eob. date_of_service_from.strftime("%Y%m%d")}", @service.dtm_150)
  end

end