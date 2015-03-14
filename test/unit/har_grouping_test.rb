require File.dirname(__FILE__) + '/../test_helper'

class HarGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:business_unit_indicator_lookup_fields,:facility_output_configs,
    :payers

  def test_segregate
    batch_id = batches(:batch_boa_11).id
    assert_equal 211,batch_id
    eobs = InsurancePaymentEob.by_eob(batch_id)
    assert_equal 2,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    check_eob_groups = @eob_segregator.segregate(batch_id,eobs)
    assert_equal "UB_20110502_835.TXT",check_eob_groups.keys[0]
    assert_equal 2213,check_eob_groups.values[0].keys[0]
    assert_equal [eobs[0]],check_eob_groups.values[0].values[0]
  end


  def test_group_name
    batch = batches(:batch_boa_11)
    eobs = InsurancePaymentEob.by_eob(batch.id)
    assert_equal 2,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    group_name=@eob_segregator.group_name(eobs[0],batch)
    assert_equal "UB_20110502_835.TXT",group_name
    group_name=@eob_segregator.group_name(eobs[1],batch)
    assert_equal "US_20110502_835.TXT",group_name
  end

end