require File.dirname(__FILE__)+'/../test_helper'

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper
   fixtures :jobs, :reason_codes, :reason_codes_jobs

  # +---------------------------------------------------------------------------+
  # This is for testing the method, named as get_unique_codes_of_parent_job().  |
  # Input  : Parent_job_id.                                                     |
  # Output : A string contains multiple unique_codes associated to that         |
  # parent_job, seperated by ';'.                                               |
  # +---------------------------------------------------------------------------+
  def test_get_unique_codes_of_parent_job_with_reason_codes
    parent_job_id = 222; 
    assert_equal("5D;I8;C6", get_unique_codes_of_parent_job(parent_job_id))
  end

  # +---------------------------------------------------------------------------+
  # This is for testing the method, named as get_unique_codes_of_parent_job().  |
  # Input  : Parent_job_id.                                                     |
  # Output : ""                                                                 |
  # +---------------------------------------------------------------------------+
  def test_get_unique_codes_of_parent_job_without_reason_code
    parent_job_id = 223;
    assert_equal("", get_unique_codes_of_parent_job(parent_job_id))
  end
end
