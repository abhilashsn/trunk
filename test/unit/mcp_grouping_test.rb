require File.dirname(__FILE__) + '/../test_helper'

class McpGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:business_unit_indicator_lookup_fields,:facility_output_configs,
    :payers,:service_payment_eobs

  def test_segregate
    batch_id = batches(:batch_boa_10).id
    assert_equal 210,batch_id
    eobs = InsurancePaymentEob.by_eob(batch_id)
    assert_equal 1,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    check_eob_groups = @eob_segregator.segregate(batch_id,eobs)
    assert_equal "UB10502BAMCHPAY.835",check_eob_groups.keys[0]
    assert_equal 2210,check_eob_groups.values[0].keys[0]
    assert_equal eobs,check_eob_groups.values[0].values[0]
  end

  def test_group_name
    batch = batches(:batch_boa_9)
    eobs = InsurancePaymentEob.by_eob(batch.id)
    assert_equal 3,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    group_name=@eob_segregator.group_name(eobs[0],batch)
    assert_nil (group_name)
    group_name=@eob_segregator.group_name(eobs[1],batch)
    assert_equal "UB10502ABMCPPAY.835",group_name
    group_name=@eob_segregator.group_name(eobs[2],batch)
    assert_equal "UB10502AZMCPPAY.835",group_name
  end

end