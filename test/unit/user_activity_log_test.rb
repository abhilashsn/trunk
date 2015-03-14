require File.dirname(__FILE__) + '/../test_helper'

class UserActivityLogTest < ActiveSupport::TestCase

  fixtures :user_activity_logs, :users, :roles, :roles_users, :batches
  
  def test_successful_creation_of_activity_with_user_and_activity_and_entity_and_description
    user = users(:admin)
    activity = 'TAT Comment Created'
    entity_object = batches(:batch1)
    description = 'TAT missed due to power failure.'
    activity_log = UserActivityLog.create_activity_log(user, activity, entity_object, description)
    assert_equal true, activity_log 
  end
  
  def test_successful_creation_of_activity_with_user_and_activity
    user = users(:admin)
    activity = 'Logged in'
    activity_log = UserActivityLog.create_activity_log(user, activity)
    assert_equal true, activity_log 
  end
  
  def test_failure_of_creation_of_activity_without_activity
    user = users(:admin)
    activity = 'Logged in'
    activity_log = UserActivityLog.create_activity_log(user, nil)
    assert_equal "Creation of UserActivityLog has failed : Activity can't be blank\n", activity_log 
  end
  
  def test_failure_of_creation_of_activity_without_user
    activity = 'Logged in'
    activity_log = UserActivityLog.create_activity_log(nil, activity)
    assert_equal "Creation of UserActivityLog has failed : User can't be blank\n" , activity_log 
  end
  
  def test_search_by_activity_tat_comments
    expected_activity_logs = [user_activity_logs(:activity_log_1),
      user_activity_logs(:activity_log_2)]
    obtained_activity_logs = UserActivityLog.search_all_by('ACTIVITY', 'TAT Comments')
    assert_equal expected_activity_logs, obtained_activity_logs
  end
  
  def test_search_by_entity
    expected_activity_logs = [user_activity_logs(:activity_log_1),
      user_activity_logs(:activity_log_2)]
    obtained_activity_logs = UserActivityLog.search_all_by('ENTITY', 'BATCH')
    assert_equal expected_activity_logs, obtained_activity_logs
  end
  
  def test_search_by_activity_logged_in
    expected_activity_logs = [user_activity_logs(:activity_log_3),
      user_activity_logs(:activity_log_5)]
    obtained_activity_logs = UserActivityLog.search_all_by('ACTIVITY', 'Logged in')
    assert_equal expected_activity_logs, obtained_activity_logs
  end
  
  def test_search_by_a_processor_user
    user = users(:processor_12).login
    expected_activity_logs = [user_activity_logs(:activity_log_3),
      user_activity_logs(:activity_log_4), user_activity_logs(:activity_log_5),
      user_activity_logs(:activity_log_6)]
    obtained_activity_logs = UserActivityLog.search_all_by('USER', user)
    assert_equal expected_activity_logs, obtained_activity_logs
  end
  
  def test_search_by_an_admin_user
    user = users(:admin).login
    expected_activity_logs = [user_activity_logs(:activity_log_1), user_activity_logs(:activity_log_2)]
    obtained_activity_logs = UserActivityLog.search_all_by('USER', user)
    assert_equal expected_activity_logs, obtained_activity_logs
  end

end
