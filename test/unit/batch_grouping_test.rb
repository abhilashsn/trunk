require File.dirname(__FILE__) + '/../test_helper'

class Batch_grouping_test < ActiveSupport::TestCase
  fixtures :batches, :jobs, :check_informations, :facilities
  def test_by_cut_grouping
    batch = Batch.find(202)
    assert_equal(batch.cut,'B')
    @batch_cut_groups = cut_grouping(batch.cut,batch.facility_id) 
    assert_equal(@batch_cut_groups.size,2)
    batch = Batch.find(201)
    assert_equal(batch.cut,'A')
    @batch_cut_groups = cut_grouping(batch.cut,batch.facility_id)
    assert_equal(@batch_cut_groups.size,1)
  end


  def test_by_lockbox_cut_grouping
    batch = Batch.find(203)
    assert_equal(batch.cut,'B')
    @batch_cut_groups = lockbox_cut_grouping(batch.lockbox,batch.facility_id)
    assert_equal(@batch_cut_groups.size,1)
    batch = Batch.find(201)
    assert_equal(batch.cut,'A')
    @batch_cut_groups = lockbox_cut_grouping(batch.lockbox,batch.facility_id) 
    assert_equal(@batch_cut_groups.size,3)
  end

  private

  def cut_grouping(cut,facility_id)
    batches = Batch.find(:all,:conditions=>"cut='#{cut}' and facility_id = #{facility_id}")
    return batches
  end

  def lockbox_cut_grouping(lockbox,facility_id)
    batches = Batch.find(:all,:conditions =>("lockbox = '#{lockbox}' and facility_id = #{facility_id}"),:group=>"cut")
    return batches
  end
end
