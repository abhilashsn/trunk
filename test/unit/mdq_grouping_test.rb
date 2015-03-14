require File.dirname(__FILE__) + '/../test_helper'

class MdqGroupingTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities,:facility_output_configs
  def test_grouping
     batch = batches(:batch_boa_3)
     checks = Batch.by_cut_and_extension(batch)
     assert_equal 2,checks.length
     @check_segregator = CheckSegregator.new('by_cut_and_extension','')
    check_groups = @check_segregator.segregate(batch)
    assert_equal 1,check_groups.length
  end
end
