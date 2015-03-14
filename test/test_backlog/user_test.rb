require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :shifts, :processor_statuses, :users, :batches, :sessions, :sampling_rates, :eob_reports, :clients

  # List of tests
  # 1. Empty user create
  # 2. Create with invalid data
  #   - Check with nil userid
  #   - Check with nil password
  # 3. Check user count
  # 4. Check Uniqueness
  #   - Check Uniqueness of userid

  #test for empty userid and passowrd
  def test_blank_user
    new_user = User.new
    assert !new_user.valid?
    assert new_user.errors.invalid?(:userid)
    assert new_user.errors.invalid?(:password)
  end

  #test user count
  def test_user_count
    first_count=User.count
    User.create(:id=>12,:userid=>"anu_new1",:password=>"anu")
    assert_not_equal(first_count,User.count)
    User.destroy(1)
    assert_equal(first_count,User.count)
  end

  #check for uniqueness of user id
  def test_for_uniqueness_for_userid
    user1=User.new(:id=>12,:userid=>"anu_new",:password=>"anu")
    assert_equal(true,user1.save)
    user2=User.new(:id=>13,:userid=>"anu_new",:password=>"anu11")
    assert_equal(false,user2.save)
  end

  #check for processing_rate_triad range
  def test_for_processing_rate_triad
    user1=User.new(:id=>12,:userid=>"anu_new",:password=>"anu",:processing_rate_triad => 36)
    assert_equal(false,user1.save)
  end

  #check for pprocessing_rate_others range
  def test_for_processing_rate_others
    user1=User.new(:id=>12,:userid=>"anu_new",:password=>"anu",:processing_rate_others => 36)
    assert_equal(false,user1.save)
  end

  #Test create
  def test_users_create
    @user = User.new(:id           =>   10,
                     :name         =>   "GauravS",
                     :userid       =>   "gs",
                     :password     =>   "gs",
                     :shift        =>   Shift.find(1),
                     :remark       =>   "user",
                     :role         =>   "Supervisor",
                     :status       =>   "Online"
                     )
    assert_valid @user
    assert @user.save
    assert_invalid @user, :userid, "gaur" # This is a duplicate, which isn't allowed
  end

  def test_invalid_data
    @gs_invalid = users(:gs_invalid)
    assert_valid @gs_invalid
  end

  def test_invalid_role
    @invalid_user = User.find_by_id(8)
    assert_not_equal(0, @invalid_user.role <=> "Supervisor")
  end

  #Test Jobs Method
  def test_proc_jobs
    u = User.find_by_role('Processor')
    assert_equal(u.processor_jobs.count, u.jobs.count)
  end

  #Test Jobs Method
  def test_qa_jobs
    u = User.find_by_role('QA')
    assert_equal(u.qa_jobs.count, u.jobs.count)
  end

  #Test has pending jobs method
  def test_has_pending_jobs?
    processor = users(:processor01)
    job = Job.create!(:check_number => 1, :tiff_number => 2, :processor => processor, :estimated_eob => 100, :processor_status => 'Processor Allocated')
    assert_equal(true, processor.has_pending_jobs?)
    qa = users(:qa01)
    job = Job.create!(:check_number => 1, :tiff_number => 2, :qa => qa, :estimated_eob => 100, :qa_status => 'QA Allocated')
    assert_equal(true, qa.has_pending_jobs?)
  end

  #Test is online Method
  def test_is_online?
    user = users(:gs)
    assert_equal(true, user.is_online?)
    user2 = User.create!(:userid => 'pro', :role => 'Processor', :password => 'yahoo', :status => 'Offline', :session => '3219023fa5e7cf57d11c587663d9b231')
    assert_equal(false, user2.is_online?)
  end

  #Test completed eob method
  def test_completed_eob
    processor1 = User.create!(:userid => 'pro', :role => 'Processor', :password => 'yahoo', :status => 'Online')
    job1 = Job.create!(:batch => batches(:batch1), :check_number => 1, :tiff_number => 2,
                       :processor => processor1, :processor_flag_time => Time.now,
                       :estimated_eob => 100, :count => 150, :processor_status => 'Processor Complete')

    job2 = Job.create!(:batch => batches(:batch1), :check_number => 3, :tiff_number => 4,
                       :processor => processor1, :processor_flag_time => Time.now,
                       :estimated_eob => 100, :count => 50, :processor_status => 'Processor Allocated')

    job3 = Job.create!(:batch => batches(:batch1), :check_number => 5, :tiff_number => 6,
                       :processor => processor1, :processor_flag_time => Time.now - 14.hours,
                       :estimated_eob => 100, :count => 250, :processor_status => 'Processor Complete')

    eobs_complete = job1.count + job2.count + job3.count
    assert_not_equal(processor1.completed_eob, eobs_complete)
    assert_equal(processor1.completed_eob, job1.count + job2.count)
  end

  #Test Completed eob by qa method
  def test_completed_eob_by_qa
    qa = users(:qa01)
    processor = users(:processor01)
    eob_report1 = EobReport.create!(:verify_time => Time.now, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Rejected', :payer => nil )
    eob_report2 = EobReport.create!(:verify_time => Time.now, :account_number => 1223, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Accepted', :payer => nil)
    assert_equal(qa.completed_eob_by_qa, 2)
  end

  ##Test convert_to_ist_time method
  #def test_convert_to_ist_time
  #  user = users(:gs)
  #  assert_in_delta(9.5.hours, (user.convert_to_ist_time(Time.now) - Time.now).to_i,1)
  #end

  #Test processing_rate_for_client method
  def test_processing_rate_for_client
    user = users(:processor01)
    client = clients(:Triad)
    assert_equal(5,user.processing_rate_for_client(client))
    client2 = clients(:Apria)
    assert_equal(8,user.processing_rate_for_client(client2))
  end

  #Test default processing_rate_for_client method
  def test_default_processing_rate_for_client
    client = clients(:Triad)
    assert_equal(5,User.default_processing_rate_for_client(client))
    client2 = clients(:Apria)
    assert_equal(8,User.default_processing_rate_for_client(client2))
  end

  #Test assign_rating_to_processor Method
  def test_assign_rating_to_processor
    processor = User.create!(:userid => 'pro', :role => 'Processor', :password => 'yippy', :status => 'Online',
                             :processing_rate_triad => 13, :processing_rate_others => 21)
    processor.assign_rating_to_processor
    assert_equal 'H', processor.rating

    processor1 = User.create!(:userid => 'pro1', :role => 'Processor', :password => 'yippy', :status => 'Online',
                             :processing_rate_triad => 8, :processing_rate_others => 13)
    processor1.assign_rating_to_processor
    assert_equal 'L', processor1.rating

    processor2 = User.create!(:userid => 'pro2', :role => 'Processor', :password => 'yippy', :status => 'Online',
                             :processing_rate_triad => 11, :processing_rate_others => 20)
    processor2.assign_rating_to_processor
    assert_equal 'L', processor2.rating
  end

  #Test assign_default_rating_to_processor Method
  def test_assign_default_rating_to_processor
    processor = User.create!(:userid => 'pro', :role => 'Processor', :password => 'yippy', :status => 'Online')
    processor.assign_default_rating_to_processor
    assert_equal 5, processor.processing_rate_triad
    assert_equal 8, processor.processing_rate_others
  end

  #Test to_s method
  def test_to_s
    user = users(:gs)
    assert_equal user.to_s, user.name, "they match"
  end

  #Test update online status method
  def test_update_online_status
    processor1 = User.create!(:userid => 'pro', :role => 'Processor', :password => 'yahoo', :status => 'Online', :session => '3219023fa5e7cf57d11c587663d9b231')
    processor1.update_online_status
    assert_equal(processor1.status, 'Online')
    Session.delete_all
    processor1.update_online_status
    assert_equal(processor1.status, 'Offline')
  end

  #Test on sample rate method
  def test_sampling_rate
    processor = User.create!(:userid => 'pro', :role => 'Processor', :password => 'yippy', :status => 'Online',
                             :total_fields => 10, :total_incorrect_fields => 2)
    processor.sampling_rate
    assert_equal processor.sampling_rate, 18
    assert_equal processor.field_accuracy, 80

    processor.total_fields = 100
    processor.total_incorrect_fields = 75
    processor.update
    processor.sampling_rate
    assert_equal processor.sampling_rate, 25
    assert_equal processor.field_accuracy, 25

    processor.total_fields = 10
    processor.total_incorrect_fields = 20
    processor.update
    processor.sampling_rate
    assert_equal processor.field_accuracy, 100
    assert_equal processor.total_fields, 0
    assert_equal processor.total_incorrect_fields, 0

    processor.total_fields = 100
    processor.total_incorrect_fields = 5
    processor.update
    processor.sampling_rate
    assert_equal processor.sampling_rate, 5
    assert_equal processor.field_accuracy, 95

    processor.total_fields = 100
    processor.total_incorrect_fields = 9
    processor.update
    processor.sampling_rate
    assert_equal processor.sampling_rate, 10
    assert_equal processor.field_accuracy, 91

    processor.total_fields = 100
    processor.total_incorrect_fields = 14
    processor.update
    processor.sampling_rate
    assert_equal processor.sampling_rate, 15
    assert_equal processor.field_accuracy, 86

    processor.total_fields = 100
    processor.total_incorrect_fields = 23
    processor.update
    processor.sampling_rate
    assert_equal processor.sampling_rate, 20
    assert_equal processor.field_accuracy, 77
  end

  def test_eobs_qaed
    qa = users(:qa01)
    processor = users(:processor01)
    eob_report1 = EobReport.create!(:verify_time => Time.now, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Accepted', :payer => nil )
    eob_report2 = EobReport.create!(:verify_time => Time.now, :account_number => 1223, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Accepted', :payer => nil)
    assert_equal(qa.eobs_qaed(processor), 2)
  end

  def test_rejected_eobs_qaed
    qa = users(:qa01)
    processor = users(:processor01)
    eob_report1 = EobReport.create!(:verify_time => Time.now, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Rejected', :payer => nil )
    eob_report2 = EobReport.create!(:verify_time => Time.now, :account_number => 1223, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Accepted', :payer => nil)
    eob_report3 = EobReport.create!(:verify_time => Time.now, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Rejected', :payer => nil )
    assert_equal(qa.rejected_eobs_qaed(processor), 2)
  end

  def test_reset_eob_qa_checked
    processor = users(:processor01)
    processor.eob_qa_checked = 10
    processor.update
    assert_equal 10, processor.eob_qa_checked
    processor.reset_eob_qa_checked
    assert_equal 0, processor.eob_qa_checked
  end

  #Commented Because User Model is not suporting validation
  #Ticket#275 validates_* not honored for user model alone
  def test_processing_rate_range
    user1=User.new(:id=>12,:userid=>"anu",:password=>"anu",:processing_rate_triad => 36,:processing_rate_others => 8)
    assert_equal(false,user1.save)
    user2=User.new(:id=>13,:userid=>"anu1",:password=>"anu1",:processing_rate_triad => 20,:processing_rate_others => 38)
    assert_equal(false,user2.save)
    user3=User.new(:id=>14,:userid=>"anu2",:password=>"anu2",:processing_rate_triad => 20,:processing_rate_others => 30)
    assert_equal(true,user3.save)
    #user3.processing_rate_triad = 36
    #assert_equal(false,user3.update)
  end
  
  def test_completed_eob_by_qa_for_12_hrs
    qa = users(:qa01)
    processor = users(:processor01)
    eob_report1 = EobReport.create!(:verify_time => Time.now, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Rejected', :payer => nil )
    eob_report2 = EobReport.create!(:verify_time => Time.now, :account_number => 1223, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Accepted', :payer => nil)
    eob_report3 = EobReport.create!(:verify_time => Time.now, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Rejected', :payer => nil )
    assert_equal(qa.completed_eob_by_qa, 3)
    eob_report4 = EobReport.create!(:verify_time => Time.now - 13.hours, :account_number => 123, :processor => processor.userid, :accuracy => 100,
                     :qa => qa.userid, :batch_id => batches(:batch1), :batch_date => batches(:batch1).date, :total_fields => 10,
                     :incorrect_fields => 1, :error_type => 'OK', :error_severity => 8,
                     :error_code => 'COR', :status => 'Rejected', :payer => nil )
    assert_equal(qa.completed_eob_by_qa, 3)
    eob_report4.verify_time = Time.now - 3.hours
    eob_report4.update
    assert_equal(qa.completed_eob_by_qa, 4)
  end
end
