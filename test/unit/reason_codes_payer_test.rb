require 'test_helper'

class ReasonCodesPayerTest < ActiveSupport::TestCase
  fixtures :batches, :jobs, :check_informations, :payers, :reason_codes, :reason_codes_jobs, :reason_codes_payers
  
  def do_not_test_footnote_code
    footnote_code = reason_codes_payers(:two).footnote_code
    assert_equal 'RM_T', footnote_code
  end
  
end
