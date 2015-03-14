require File.dirname(__FILE__) + '/../test_helper'

class TatTest < Test::Unit::TestCase
  fixtures :tats, :batches
  
  # List of tests
  # 1. Empty tat create 
  # 2. Create with invalid data
  #   - Check with nil expected_time
  # 3. check the tat count
  # 4. check tat association
  #   - Without batch_id  
 
  #test empty attribute
  def test_invalid_with_empty_attributes
    tat = Tat.new
    assert !tat.valid?
    assert tat.errors.invalid?(:batch_id)
  end
  
  #Check the count
  def test_tat_count
    first_count = Tat.count
    tat1 = Tat.create(:expected_time => '12/12/06', :batch_id => 1)
    assert_equal(true, tat1.save)
    second_count = Tat.count
    assert_not_equal(first_count,second_count)
    Tat.destroy(tat1.id)
    third_count = Tat.count
    assert_equal(first_count,third_count)
  end
  
  #Check Count after Parent delete
  def test_count_after_parent_delete
    tat1 = Tat.create(:expected_time => '12/12/06', :batch_id => 1)
    first_count = Tat.count
    Batch.destroy(1)
    second_count = Tat.count
    assert_not_equal(first_count,second_count)   
  end
  
  #Check the presence of estimated time
  def test_presence_of_estimated_time
    tat2 = Tat.new(:id => 6, :expected_time => '12/12/06')
    assert_equal(false, tat2.save)
  end
  
  def test_expected_time_for_comparison
    tat1 = Tat.create!(:expected_time => '12/12/06', :batch_id => 1)
    assert_equal(tat1.expected_time_for_comparison, tat1.expected_time)
    tat2 = Tat.create!(:batch_id => 1)
    assert_equal(tat2.expected_time_for_comparison, Time.now + 1000.days)
  end
 
end
