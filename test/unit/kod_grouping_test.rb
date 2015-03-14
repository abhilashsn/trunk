require File.dirname(__FILE__) + '/../test_helper'

class KodGroupingTest < ActiveSupport::TestCase
  fixtures  :check_informations, :jobs, :batches,
    :facilities,:facility_output_configs,
    :payers


  def test_segregate
    batch_id = batches(:batch_boa_14).id
    assert_equal 234,batch_id
    eobs = InsurancePaymentEob.by_eob(batch_id)
    assert_equal 1,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    check_eob_groups = @eob_segregator.segregate(batch_id,eobs)
    assert_equal "C10502B.835",check_eob_groups.keys[0]
    assert_equal 2220,check_eob_groups.values[0].keys[0]
    assert_equal eobs,check_eob_groups.values[0].values[0]
  end

 def test_group_name
    batch = batches(:batch_boa_15)
    eobs = InsurancePaymentEob.by_eob(batch.id)
    assert_equal 6,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    group_name=@eob_segregator.group_name(eobs[0],batch)
    assert_equal "D10502B_429.835",group_name
    group_name=@eob_segregator.group_name(eobs[1],batch)
    assert_equal "E10502B_429.835",group_name
    group_name=@eob_segregator.group_name(eobs[2],batch)
    assert_equal "F10502B_429.835",group_name
    group_name=@eob_segregator.group_name(eobs[3],batch)
    assert_equal "B10502B.835",group_name
    group_name=@eob_segregator.group_name(eobs[4],batch)
    assert_equal "G10502B_429.835",group_name
    group_name=@eob_segregator.group_name(eobs[5],batch)
    assert_equal "B10502B.835",group_name
 end

end