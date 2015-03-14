require File.dirname(__FILE__) + '/../test_helper'

class QuadaxOutputBatchidTest < ActiveSupport::TestCase
  fixtures :check_informations, :jobs, :batches,
    :facilities, :facility_output_configs, :payers

  def test_unique_output_payid
    batch = batches(:batch_quadax)
    assert_equal 30,batch.id
    checks = batch.check_informations
    assert_equal 2,checks.length
    @payer = checks.first.payer
    @facility = batch.facility
    assert_equal 301,checks.first.id
    @check = Output835::Check.new(checks.first,@facility, 1, "*") 
    assert_equal "REF*EV*12345_quadax", @check.ref_ev_loop
  end

end
