require File.dirname(__FILE__) + '/../test_helper'

class ReasonCodeServiceControllerTest < ActiveSupport::TestCase
  
  fixtures :users, :roles, :roles_users, :clients, :facilities,
    :reason_codes, :reason_code_set_names

  def setup
    @controller = ReasonCodeServiceController.new
    @error_codes = {
      "reason_code_update" => {
        "29" => "Empty crosswalk for an existing RC and description which has a crosswalk",
        "30" => "Empty crosswalk for an existing RC and description"
      }
    }
    @controller.instance_variable_set("@error_codes", @error_codes)
    @controller.instance_variable_set("@errors", [])
  end

  def test_validate_reason_code_when_payer_is_nonfootnote_payer
    code = 'RM_25'
    description = 'abc'
    set_name = reason_code_set_names(:set_name4)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal false, reason_code_validation
  end

  def test_validate_reason_code_when_there_is_no_payer
    code = 'RC9'
    description = 'abc'
    set_name = reason_code_set_names(:set_name6)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal false, reason_code_validation
  end

  def test_validate_reason_code_when_code_doesnot_start_with_rm_for_footnote_payer
    code = 'RC9'
    description = 'abc'
    set_name = reason_code_set_names(:set_name5)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal false, reason_code_validation
  end

  def test_validate_reason_code_for_existing_footnote_code
    code = 'RM_1k'
    description = 'DESC RC6'
    set_name = reason_code_set_names(:set_name5)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal false, reason_code_validation
  end

  def test_validate_reason_code_for_non_existing_footnote_code_but_existing_with_description
    code = 'RM_25'
    description = 'DESC RC6'
    set_name = reason_code_set_names(:set_name5)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal true, reason_code_validation
  end

  def test_validate_reason_code_for_non_existing_footnote_code_and_non_existing_description
    code = 'RM_25'
    description = 'abc'
    set_name = reason_code_set_names(:set_name5)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal true, reason_code_validation
  end

  def test_validate_reason_code_for_non_existing_footnote_code_and_non_existing_description_when_code_doesnot_start_with_rm
    code = '25'
    description = 'abc'
    set_name = reason_code_set_names(:set_name5)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal false, reason_code_validation
  end

  def test_validate_reason_code_for_non_existing_footnote_code_and_blank_description_when_code_doesnot_start_with_rm
    code = '25'
    description = ''
    set_name = reason_code_set_names(:set_name5)
    reason_code_validation = @controller.validate_reason_code(code, description, set_name)
    assert_equal true, reason_code_validation
  end
  
end