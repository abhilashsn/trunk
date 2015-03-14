require File.dirname(__FILE__) + '/../test_helper'

class SingleDailyMergedCutGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:business_unit_indicator_lookup_fields,:facility_output_configs,
    :payers
  def test_segregate
    batch_ids = []
    batch_ids << batches(:batch_boa_12).id
    batch_ids << batches(:batch_boa_13).id
    assert_equal 2,batch_ids.length
    eobs = InsurancePaymentEob.by_eob(batch_ids.join(","))
    assert_equal 4,eobs.length
    @eob_segregator = EobSegregator.new('SINGLE DAILY MERGED CUT','')
    check_eob_groups = @eob_segregator.segregate(batch_ids.join(","),eobs)
    assert_equal "UB_20110502_835.TXT",check_eob_groups.keys[0]
    assert_equal 2216,check_eob_groups.values[0].keys[0]
    assert_equal [eobs[0]],check_eob_groups.values[0].values[0]
  end

  def test_group_name
    batch = batches(:batch_boa_12)
    batch_ids = []
    batch_ids << batches(:batch_boa_12).id
    batch_ids << batches(:batch_boa_13).id
    eobs = InsurancePaymentEob.by_eob(batch_ids.join(","))
    assert_equal 4,eobs.length
    @eob_segregator = EobSegregator.new('SINGLE DAILY MERGED CUT','')
    group_name=@eob_segregator.group_name(eobs[0],batch)
    assert_equal "UB_20110502_835.TXT",group_name
    group_name=@eob_segregator.group_name(eobs[1],batch)
    assert_equal "US_20110502_835.TXT",group_name
  end

end
