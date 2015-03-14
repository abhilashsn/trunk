require File.dirname(__FILE__) + '/../test_helper'

class PayerTest < Test::Unit::TestCase
  fixtures :payers, :jobs, :batches, :facilities, :clients

  # List of tests
  # 1. Empty payer create
  # 2. Create with invalid data
  #   - Check with nil payid
  #   - Check with nil payer
  #   - Check with nil gateway
  # 3. Check payer count
  # 4. Check Uniqueness
  #   - Check Uniqueness of payid

 #test for empty payid, payer and gateway
  def test_blank_payer
    payer = Payer.new
    assert !payer.valid?
    assert payer.errors.invalid?(:payer)
    assert payer.errors.invalid?(:payid)
    assert payer.errors.invalid?(:gateway)
  end

  #test payer count
  def test_payer_count
    first_count=Payer.count
    Payer.create(:id=>12,:payer=>"anu",:payid=>'4',:gateway=>"gateway1")
    assert_not_equal(first_count,Payer.count)
    Payer.destroy(1)
    assert_equal(first_count,Payer.count)
  end

  #check for uniqueness of user id
  def test_uniqueness_for_userid
    payer1 = Payer.new(:id=>12,:payer => "anu", :payid => '4', :gateway => "gateway1")
    assert_equal(true,payer1.save)
    payer2 = Payer.new(:id=>13,:payer=>"raj",:payid=>'4',:gateway=>"gateway2")
    assert_equal(false,payer2.save)
  end

  def test_to_s
    new_payer = Payer.create!(:payer => "Payer", :payid => '3', :gateway => 'what_gateway')
    assert_equal new_payer.to_s, new_payer.payer
  end
  
  def test_least_time
    payer = Payer.find(2)
    assert_in_delta(jobs(:job11).batch.expected_time, payer.least_time, 1)
    
    #job_11 has minimum eobs for the payer found above
    job_11 = Job.find(11)
    job_11.payer = Payer.find(1) #change payer for the job
    job_11.update
    assert_not_equal(jobs(:job11).batch.expected_time, payer.least_time)
    
    batch = Batch.find(1)
    batch.status = 'Processing'
    batch.update
    
    payer = Payer.find(1)
    assert_in_delta(jobs(:job11).batch.expected_time, payer.least_time, 1)
    
    job_11 = Job.find(11)
    job_11.payer = Payer.find(2) #change payer for the job
    assert_not_equal(jobs(:job11).batch.expected_time, payer.least_time)
  end

end
