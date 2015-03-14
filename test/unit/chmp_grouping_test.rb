require File.dirname(__FILE__) + '/../test_helper'

class ChmpGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:business_unit_indicator_lookup_fields,:facility_output_configs,
    :payers,:service_payment_eobs

  def test_segregate
    batch_id = batches(:batch_boa_7).id
    assert_equal 207,batch_id
    eobs = InsurancePaymentEob.by_eob(batch_id)
    assert_equal 1,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    check_eob_groups = @eob_segregator.segregate(batch_id,eobs)
    assert_equal "HLSCBATCH710502C.DAT",check_eob_groups.keys[0]
    assert_equal 2206,check_eob_groups.values[0].keys[0]
    assert_equal eobs,check_eob_groups.values[0].values[0]
  end


  def test_group_name
    batch = batches(:batch_boa_8)
    eobs = InsurancePaymentEob.by_eob(batch.id)
    assert_equal 2,eobs.length
    @eob_segregator = EobSegregator.new('SITE SPECIFIC','')
    group_name=@eob_segregator.group_name(eobs[0],batch)
    assert_equal "HLSCBATCH910502D.DAT",group_name
    group_name=@eob_segregator.group_name(eobs[1],batch)
    assert_equal "HLSCBATCH310502D.DAT",group_name
   end

end
