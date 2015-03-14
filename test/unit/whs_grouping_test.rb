require File.dirname(__FILE__) + '/../test_helper'

class WhsGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:business_unit_indicator_lookup_fields,:facility_output_configs,
    :payers,:service_payment_eobs


  def test_segregate
    batch_id = batches(:batch_boa_5).id
    assert_equal 205,batch_id
    eobs = InsurancePaymentEob.by_eob(batch_id)
    assert_equal 1,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    check_eob_groups = @eob_segregator.segregate(batch_id,eobs)
    assert_equal "05022344B.835",check_eob_groups.keys[0]
    assert_equal 2015,check_eob_groups.values[0].keys[0]
    assert_equal eobs,check_eob_groups.values[0].values[0]
  end

  def test_group_name
    batch = batches(:batch_boa_6)
    eobs = InsurancePaymentEob.by_eob(batch.id)
    assert_equal 6,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    group_name=@eob_segregator.group_name(eobs[0],batch)
    assert_equal "05022354B.835",group_name
    group_name=@eob_segregator.group_name(eobs[1],batch)
    assert_equal "05022354A.835",group_name
    group_name=@eob_segregator.group_name(eobs[2],batch)
    assert_equal "05022354C.835",group_name
    group_name=@eob_segregator.group_name(eobs[3],batch)
    assert_equal "05022354D.835",group_name
    group_name=@eob_segregator.group_name(eobs[4],batch)
    assert_equal "05022354G.835",group_name
    group_name=@eob_segregator.group_name(eobs[5],batch)
    assert_equal "05022354F.835",group_name
  end

end