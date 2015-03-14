require File.dirname(__FILE__) + '/../test_helper'

class NyuGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:business_unit_indicator_lookup_fields,:facility_output_configs


  def test_segregate
    batch_id = batches(:batch_boa_3).id
    assert_equal 203,batch_id
    eobs = InsurancePaymentEob.by_eob(batch_id)
    assert_equal 1,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    check_eob_groups = @eob_segregator.segregate(batch_id,eobs)
    assert_equal "SAL10502B_11_PAY_ABC.835",check_eob_groups.keys[0]
    assert_equal 203,check_eob_groups.values[0].keys[0]
    assert_equal eobs,check_eob_groups.values[0].values[0]
  end

  def test_group_name
    batch = batches(:batch_boa_3)
    eob = InsurancePaymentEob.by_eob(batch.id)
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    group_name=@eob_segregator.group_name(eob[0],batch)
    assert_equal "SAL10502B_11_PAY_ABC.835",group_name
  end

end
