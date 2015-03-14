require File.dirname(__FILE__) + '/../test_helper'

class QuadaxOutputPayidTest < ActiveSupport::TestCase
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
    assert_equal "REF*2U*99999", @check.unique_output_payid(@payer)
    @payer = checks[1].payer
    @check = Output835::Check.new(checks[1],@facility, 1, "*") 
    assert_nil @check.output_payid(@payer)
  end

end
