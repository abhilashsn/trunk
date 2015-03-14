require File.dirname(__FILE__) + '/../test_helper'

class FacilitiesUserTest < ActiveSupport::TestCase
  fixtures :facilities, :users, :facilities_users

  def test_save_the_count_of_eobs_processed_for_existing_record
    user_id = users(:processor_13).id
    facility_id = facilities(:facility_93).id
    count_of_eobs = 12
    saved_user_related_facility_record = FacilitiesUser.save_eobs_processed(user_id, facility_id, count_of_eobs)
    assert_equal 22, saved_user_related_facility_record.eobs_processed
  end

  def test_save_the_count_of_eobs_processed_for_non_existing_record
    user_id = users(:processor_14).id
    facility_id = facilities(:facility_32).id
    count_of_eobs = 10
    saved_user_related_facility_record = FacilitiesUser.save_eobs_processed(user_id, facility_id, count_of_eobs)
    assert_not_nil saved_user_related_facility_record
    assert_equal 10, saved_user_related_facility_record.eobs_processed
  end
  
end