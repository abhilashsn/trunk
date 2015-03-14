require File.dirname(__FILE__) + '/../test_helper'

class EobQaTest < Test::Unit::TestCase
  fixtures :eob_qas

  # List of tests
  # 1. Empty Eobqa create
  # 2. Create with invalid data
  #   - Check with nil total_fields
  #   - Check with nil total_incorrect_fields
  #   - Check with nil account_number
  #   - Check Uniqueness of name
  # 3. Check Eobqa count when we created and distroy

  #Blank EOBQA
  def test_blank_eobqa
    eobqa = EobQa.new(:total_fields => 10, :total_incorrect_fields => 2)
    assert_equal(false, eobqa.save)
  end

  # Test with nil total_fields total_incorrect_fields & account_number
  def test_with_blank_data
    eobqa = EobQa.new(:id => 4, :total_fields => 10, :total_incorrect_fields => 2,
                      :account_number => '00001', :payer => 'abcd')
    assert_equal(true, eobqa.save)
    eobqa3 = EobQa.new(:id => 7, :total_fields => 10, :total_incorrect_fields => 2)
    assert_equal(false, eobqa3.save)
  end

  # Test EobQa count
  def test_EobQa_count
    first_count=EobQa.count
    eobqa1 = EobQa.create(:id => 3, :total_fields => 10, :total_incorrect_fields => 2, :account_number => '00013', :payer => 'abcd')
    assert_not_equal(first_count,EobQa.count)
  end

end
