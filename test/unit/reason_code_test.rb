require File.dirname(__FILE__) + '/../test_helper'

class ReasonCodeTest < ActiveSupport::TestCase
  fixtures :reason_codes, :ansi_remark_codes, :payers, :reason_code_set_names,
    :reason_codes_clients_facilities_set_names, :reason_codes_ansi_remark_codes,
    :hipaa_codes, :client_codes, :clients, :facilities

  def test_map_ansi_code
    reason_code.map_ansi_code(ansi_codes)
    assert_equal reason_code.ansi_remark_codes.first.adjustment_code,ansi_remark_codes(:ansi_remark_code1).adjustment_code
    assert_not_nil(reason_code.reason_codes_ansi_remark_codes, message = "Nil")
  end

  def test_find_ansi_remark_codes
    assert_not_nil(reason_code.find_ansi_remark_codes(ansi_codes), message = "Nil")
  end

  def ntest_destroy_ansi_codes_if_necessary
    reason_code.map_ansi_code(ansi_codes)
    assert_equal [],reason_code.destroy_ansi_codes_if_necessary(ansi_codes,ansi_codes)
  end

  def test_count_of_reason_codes_with_one_description
    reason_codes = ['RC1', 'RC2', 'RC3', 'RC1', 'RC2', 'RC1', 'RC4']
    count_of_reason_codes = ReasonCode.count_of_reason_codes_with_one_description(reason_codes)
    assert_equal 2, count_of_reason_codes
  end

  def test_count_of_blank_reason_codes_with_one_description
    reason_codes = []
    count_of_reason_codes = ReasonCode.count_of_reason_codes_with_one_description(reason_codes)
    assert_equal 0, count_of_reason_codes
  end

  def test_create_unique_code
    reason_code = ReasonCode.create!(:id => 999, :reason_code => 'ABG', :reason_code_description => 'ADS')
    assert_not_nil reason_code.unique_code
  end

  def test_uniqueness_of_unique_code
    reason_code1 = ReasonCode.create!(:id => 999, :reason_code => 'ABG', :reason_code_description => 'ADS')
    reason_code2 = ReasonCode.create!(:id => 989, :reason_code => 'AFG', :reason_code_description => 'AGH')
    unique_code1 = reason_code1.unique_code
    unique_code2 = reason_code2.unique_code
    assert_not_equal unique_code1, unique_code2
  end
  # +--------------------------------------------------------------------------+
  # This  is for testing get_unique_codes_for()                                |
  # Input  : An array of multiple reason code IDs and reason code records array.
  # Output : A string of Unique codes , separated by semicolon(;).             |
  # +--------------------------------------------------------------------------+
  def test_get_unique_codes_for_ids
    reason_code_ids = [100,101,102]
    reason_code_records = []
    reason_code_records << reason_codes(:reason_code100)
    reason_code_records << reason_codes(:reason_code101)
    reason_code_records << reason_codes(:reason_code102)
    assert_equal("5D;I8;C6", ReasonCode.get_unique_codes_for(reason_code_records, reason_code_ids))
  end
  # +-------------------------------------------------------------------+
  # This  is for testing get_unique_codes_for().                        |
  # Input  : No reason code id and an array of reason_code_records.     |
  # Output : Blank                                                      |
  # +-------------------------------------------------------------------+
  def test_get_unique_codes_for_without_id
    reason_code_ids = []
    reason_code_records = [reason_codes(:reason_code100)]
    assert_equal("", ReasonCode.get_unique_codes_for(reason_code_records, reason_code_ids))
  end
  # +--------------------------------------------------------------------------+
  # This  is for testing get_unique_codes_for().                               |
  # Input  : An array with single reason code id and an array of reason code records.
  # Output : Unique code                                                       |
  # +--------------------------------------------------------------------------+
  def test_get_unique_codes_for_id
    reason_code_ids = [100]
    reason_code_records = []
    reason_code_records << reason_codes(:reason_code100)
    reason_code_records << reason_codes(:reason_code101)
    reason_code_records << reason_codes(:reason_code102)
    assert_equal("5D", ReasonCode.get_unique_codes_for(reason_code_records, reason_code_ids))
  end
  
  def test_get_unique_code_for_existing_unique_code
    reason_code = reason_codes(:reason_code51)
    unique_code = reason_code.get_unique_code
    assert_not_nil unique_code
    assert '1F', unique_code
  end
  
  def test_get_unique_code_for_non_existing_unique_code
    reason_code = reason_codes(:reason_code58)
    unique_code = reason_code.get_unique_code
    assert_not_nil unique_code
    assert '1M', unique_code
  end  
  
  def test_normalized_unique_code_for_existing_unique_code
    reason_code = reason_codes(:reason_code51)
    unique_code = reason_code.normalized_unique_code
    assert_not_nil unique_code
    assert 'RM_1F', unique_code
  end
  
  def test_normalized_unique_code_for_non_existing_unique_code
    reason_code = reason_codes(:reason_code58)
    unique_code = reason_code.normalized_unique_code
    assert_not_nil unique_code
    assert 'RM_1M', unique_code
  end

  def test_should_not_get_reason_code_when_set_name_is_blank
    code = 'RC6'
    description = 'Desc RC6'
    set_name = ''
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = nil
    assert_equal reason_code_object, expected_reason_code_object
  end

  def test_get_reason_code_for_footnote_payer_when_code_start_with_rm
    code = 'RM_1k'
    description = ''
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = reason_codes(:reason_code56)
    assert_equal reason_code_object, expected_reason_code_object
  end

  def test_get_reason_code_for_footnote_payer_when_code_doesnot_start_with_rm_and_description_is_not_blank
    code = 'RC6'
    description = 'Desc RC6'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = reason_codes(:reason_code56)
    assert_equal reason_code_object, expected_reason_code_object
  end


  def test_should_not_get_reason_code_for_footnote_payer_when_code_doesnot_start_with_rm_and__when_description_is_blank
    code = 'RC6'
    description = ''
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = nil
    assert_equal reason_code_object, expected_reason_code_object
  end

  def test_should_not_get_reason_code_for_footnote_payer_when_code_is_blank
    code = ''
    description = 'Desc'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = nil
    assert_equal reason_code_object, expected_reason_code_object
  end

  def test_get_reason_code_for_nonfootnote_payer_when_code_is_not_blank
    code = 'RC1'
    description = 'Desc RC1'
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = reason_codes(:reason_code51)
    assert_equal reason_code_object, expected_reason_code_object
  end


  def test_should_not_get_reason_code_for_nonfootnote_payer_when_code_is_blank
    code = ''
    description = 'Desc RC1'
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = nil
    assert_equal reason_code_object, expected_reason_code_object
  end

  def test_get_reason_code_for_nonfootnote_payer_when_description_is_blank
    code = 'RC74'
    description = ''
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name)
    expected_reason_code_object = reason_codes(:reason_code74)
    assert_equal reason_code_object, expected_reason_code_object
  end

  def ntest_get_reason_code_when_it_is_marked_for_deletion
    code = 'RC84'
    description = 'DESC RC84'
    set_name = reason_code_set_names(:set_name1)
    payer = payers(:payer17)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name, payer)
    expected_reason_code_object = reason_codes(:reason_code84)
    assert_equal reason_code_object, expected_reason_code_object
    assert_equal false, reason_code_object.marked_for_deletion
  end

  def test_get_reason_code_for_classified_nonfootnote_payer_when_code_is_not_blank
    code = 'RC1'
    description = 'Desc RC1'
    set_name = reason_code_set_names(:set_name1)
    payer = payers(:payer17)
    reason_code_object = ReasonCode.get_reason_code(code, description, set_name, payer)
    expected_reason_code_object = reason_codes(:reason_code51)
    assert_equal reason_code_object, expected_reason_code_object
  end

  def ntest_get_reason_code_for_unclassified_payer_having_same_code
    set_name = reason_code_set_names(:set_name4)
    payer = payers(:unclassified_non_footnote_payer)
    code1 = 'RC5'
    description1 = 'DESC RC5'
    reason_code_object1 = ReasonCode.get_reason_code(code1, description1, set_name, payer)
    expected_reason_code_object1 = reason_codes(:reason_code55)
    code2 = 'RC5'
    description2 = 'ANOTHER DESC RC5'
    reason_code_object2 = ReasonCode.get_reason_code(code2, description2, set_name, payer)
    expected_reason_code_object2 = reason_codes(:reason_code88)
    assert_equal expected_reason_code_object1, reason_code_object1
    assert_equal expected_reason_code_object2, reason_code_object2
  end

  def ntest_get_reason_code_for_unclassified_payer_having_same_description
    set_name = reason_code_set_names(:set_name4)
    payer = payers(:unclassified_non_footnote_payer)
    code1 = 'RC5'
    description1 = 'DESC RC5'
    reason_code_object1 = ReasonCode.get_reason_code(code1, description1, set_name, payer)
    expected_reason_code_object1 = reason_codes(:reason_code55)
    code2 = 'NEW_RC5'
    description2 = 'DESC RC5'
    reason_code_object2 = ReasonCode.get_reason_code(code2, description2, set_name, payer)
    expected_reason_code_object2 = reason_codes(:reason_code89)
    assert_equal expected_reason_code_object1, reason_code_object1
    assert_equal expected_reason_code_object2, reason_code_object2
  end

  def test_create_reason_code_for_nonfootnote_payer_when_code_and_description_are_not_blank
    code = '78110298'
    description = 'DESC 781102'
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = ReasonCode.new
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
  end

  def test_create_reason_code_for_nonfootnote_payer_when_code_is_not_blank_and_description_is_blank
    code = '781102455'
    description = ''
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = ReasonCode.new
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'NEW', reason_code.status
  end

  def test_create_reason_code_for_footnote_payer_when_code_and_description_are_not_blank
    code = '781102345'
    description = 'DESC 781102345'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.new
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
  end

  def test_should_not_create_reason_code_for_footnote_payer_when_code_and_description_are_not_blank_and_code_start_with_rm
    code = 'RM_781102345'
    description = 'DESC 781102345'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.new
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_nil reason_code
  end

  def test_should_not_create_reason_code_for_footnote_payer_when_code_is_blank_and_description_is_not_blank
    code = ''
    description = 'DESC 7811026897'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = ReasonCode.new
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_nil reason_code
  end

  def test_should_not_create_reason_code_for_blank_set_name
    code = '567567'
    description = 'DESC 567567'
    set_name = ''
    reason_code_object = ReasonCode.new
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_nil reason_code
  end

  def test_update_reason_code_for_nonfootnote_payer_when_code_and_description_are_not_blank
    code = 'RC1'
    description = 'DESC RC1'
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = reason_codes(:reason_code51)
    reason_code_object.marked_for_deletion = false
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
    assert_equal false, reason_code.marked_for_deletion
  end

  def test_update_description_in_reason_code_for_nonfootnote_payer_when_code_and_description_are_not_blank
    code = 'RC1'
    description = 'new desc RC1'
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = reason_codes(:reason_code51)
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
    assert_equal 'NEW DESC RC1', reason_code.reason_code_description
  end

  def test_update_description_in_accepted_reason_code_for_nonfootnote_payer_when_code_and_description_are_not_blank
    code = 'RC76'
    description = 'NEW DESC RC76'
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = reason_codes(:reason_code76)
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
    assert_equal 'NEW DESC RC76', reason_code.reason_code_description
  end

  def test_update_reason_code_for_nonfootnote_payer_when_code_is_not_blank_and_description_is_blank
    code = 'RC74'
    description = ''
    set_name = reason_code_set_names(:set_name1)
    reason_code_object = reason_codes(:reason_code74)
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
    assert_equal 'DESC RC74', reason_code.reason_code_description
  end

  def test_update_reason_code_for_footnote_payer_when_code_and_description_are_not_blank
    code = 'RC6'
    description = 'DESC RC6'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = reason_codes(:reason_code56)
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
    assert_equal 'RC6', reason_code.code
  end

  def test_should_not_update_code_in_reason_code_for_footnote_payer_when_code_and_description_are_not_blank
    code = 'RCC77'
    description = 'DESC RC77'
    set_name = reason_code_set_names(:set_name5)
    reason_code_object = reason_codes(:reason_code77)
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_not_nil reason_code.id
    assert_equal 'ACCEPT', reason_code.status
    assert_equal 'RC77', reason_code.code
    assert_equal reason_code.id, reason_code_object.id
  end

  def test_should_not_update_reason_code_for_blank_set_name
    code = '567567'
    description = 'DESC 567567'
    set_name = ''
    reason_code_object = reason_codes(:reason_code74)
    reason_code = reason_code_object.save_reason_code(code, description, set_name)
    assert_nil reason_code
  end
  
  def test_update_reason_code_for_nonfootnote_payer_with_status_accept
    code = 'RC81'
    description = 'DESC RC7777'
    check_number = '1234'
    payer_footnote_indicator = payers(:payer_224).footnote_indicator
    reason_code_object = reason_codes(:reason_code81)
    reason_code = reason_code_object.update_reason_code(code, description, payer_footnote_indicator, check_number)
    assert_equal true, reason_code
  end
  
  def test_update_reason_code_for_nonfootnote_payer_with_status_new
    code = 'RC78'
    description = 'DESC RC8888'
    check_number = '1234'
    payer_footnote_indicator = payers(:payer_224).footnote_indicator
    reason_code_object = reason_codes(:reason_code78)
    reason_code = reason_code_object.update_reason_code(code, description, payer_footnote_indicator, check_number)
    assert_equal true, reason_code
  end
  
  def test_update_reason_code_for_footnote_payer_with_status_accept
    code = 'RC9999'
    description = 'DESC RC79'
    check_number = '3456'
    payer_footnote_indicator = payers(:payer_223).footnote_indicator
    reason_code_object = reason_codes(:reason_code79)
    reason_code = reason_code_object.update_reason_code(code, description, payer_footnote_indicator, check_number)
    assert_equal true, reason_code
  end
  
  def test_update_reason_code_for_footnote_payer_with_status_new
    code = 'RC88888'
    description = 'DESC RC80'
    check_number = '3456'
    payer_footnote_indicator = payers(:payer_223).footnote_indicator
    reason_code_object = reason_codes(:reason_code80)
    reason_code = reason_code_object.update_reason_code(code, description, payer_footnote_indicator, check_number)
    assert_equal true, reason_code
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_reason_code'.           |
  # -- Reason Code - Required alphabets, numeric,hyphen,                       |
  #    underscore and period only. Otherwise error message will throw.         |
  # Input  : Reason Code with consecutive occurrence of valid special characters
  # Output : Returns error message if reason code record is not valid.         |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_reason_code_with_consecutive_occurrence_of_valid_special_characters
    reason_code1 = ReasonCode.new
    reason_code1.reason_code = "RC.."
    reason_code1.save
    assert !reason_code1.valid?, reason_code1.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_reason_code'.           |
  # -- Reason Code - Required alphabets, numeric,hyphen,                       |
  #    underscore and period only. Otherwise error message will throw.         |
  # Input  : Reason Code with invalid special characters.                      |
  # Output : Returns error message if reason code record is not valid.         |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_reason_code_with_invalid_special_characters
    reason_code1 = ReasonCode.new
    reason_code1.reason_code = "RC&&"
    reason_code1.save
    assert !reason_code1.valid?, reason_code1.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_reason_code'.           |
  # -- Reason Code - Required alphabets, numeric,hyphen,                       |
  #    underscore and period only. Otherwise error message will throw.         |
  # Input  : Reason Code with valid special characters only.                   |
  # Output : Returns error message if reason code record is not valid.         |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_reason_code_with_valid_special_characters_only
    reason_code1 = ReasonCode.new
    reason_code1.reason_code = "-._"
    reason_code1.save
    assert !reason_code1.valid?, reason_code1.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_reason_code'.           |
  # -- Reason Code - Required alphabets, numeric,hyphen,                       |
  #    underscore and period only. Otherwise error message will throw.         |
  # Input  : Reason Code with valid space only.                                |
  # Output : Returns error message if reason code record is not valid.         |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_reason_code_with_space_only
    reason_code1 = ReasonCode.new
    reason_code1.reason_code = " "
    reason_code1.save
    assert !reason_code1.valid?, reason_code1.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_reason_code'.           |
  # -- Reason Code - Required alphabets, numeric,hyphen,                       |
  #    underscore and period only. Otherwise error message will throw.         |
  # Input  : Reason Code with valid data.                                      |
  # Output : Returns error message if reason code record is not valid.         |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_reason_code_with_valid_data
    reason_code1 = ReasonCode.new
    reason_code1.reason_code = "RC.S-A_"
    reason_code1.save
    assert reason_code1.valid?, reason_code1.errors.full_messages.to_s
  end

  def test_get_the_replacement_for_inactive_reason_code
    reason_code_objects = [reason_codes(:reason_code90), reason_codes(:reason_code91)]
    expected_replacement_id = [reason_codes(:reason_code92).id]
    obtained_replacement = ReasonCode.get_the_replacements_for_inactive_reason_codes(reason_code_objects)
    assert_equal expected_replacement_id, obtained_replacement
  end

  def test_get_no_replacement_for_inactive_reason_code
    reason_code_objects = [reason_codes(:reason_code90)]
    obtained_replacement = ReasonCode.get_the_replacements_for_inactive_reason_codes(reason_code_objects)
    assert_equal [], obtained_replacement
  end

  def test_reset_notify
    rc_ids_to_reset_notify = [reason_codes(:reason_code90).id, reason_codes(:reason_code91).id,
      reason_codes(:reason_code92).id, reason_codes(:reason_code93).id]
    number_of_rows_updated = ReasonCode.reset_notify(rc_ids_to_reset_notify)
    assert_equal number_of_rows_updated, 4
  end

  def test_cleanup_duplicate_reason_codes_when_payer_is_reclassified_grouped_by_reason_code
    reason_codes = [reason_codes(:reason_code61), reason_codes(:reason_code62)]
    cleaned_up = ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes, 'reason_code')
    assert_equal true, cleaned_up
    retained_reason_code = ReasonCode.find(reason_codes(:reason_code61).id)
    soft_deleted_reason_code = ReasonCode.find(reason_codes(:reason_code62).id)
    assert_equal soft_deleted_reason_code.replacement_reason_code_id, retained_reason_code.id
    assert_equal false, soft_deleted_reason_code.active
    assert_equal true, retained_reason_code.active
  end

  def test_cleanup_duplicate_reason_codes_when_payer_is_reclassified_grouped_by_reason_code_description
    reason_codes = [reason_codes(:reason_code59), reason_codes(:reason_code60)]
    cleaned_up = ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes, 'reason_code_description')
    assert_equal true, cleaned_up
    retained_reason_code = ReasonCode.find(reason_codes(:reason_code59).id)
    soft_deleted_reason_code = ReasonCode.find(reason_codes(:reason_code60).id)
    assert_equal soft_deleted_reason_code.replacement_reason_code_id, retained_reason_code.id
    assert_equal false, soft_deleted_reason_code.active
    assert_equal true, retained_reason_code.active
  end

  def test_cleanup_duplicate_reason_codes_which_is_reclassified_to_the_initial_state_of_classification_grouped_by_reason_code_description
    reason_codes = [reason_codes(:reason_code94), reason_codes(:reason_code95), reason_codes(:reason_code96)]
    cleaned_up = ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes, 'reason_code_description')
    assert_equal true, cleaned_up
    reason_code_1 = ReasonCode.find(reason_codes(:reason_code94).id)
    reason_code_2 = ReasonCode.find(reason_codes(:reason_code95).id)
    reason_code_3 = ReasonCode.find(reason_codes(:reason_code96).id)
    assert_nil reason_code_1.replacement_reason_code_id
    assert_equal true, reason_code_1.active
    assert_nil reason_code_2.replacement_reason_code_id
    assert_equal true, reason_code_2.active
    assert_nil reason_code_3.replacement_reason_code_id
    assert_equal true, reason_code_3.active
  end

  def test_cleanup_duplicate_reason_codes_which_is_reclassified_to_the_initial_state_of_classification_grouped_by_reason_code
    reason_codes = [reason_codes(:reason_code97), reason_codes(:reason_code98), reason_codes(:reason_code99)]
    cleaned_up = ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes, 'reason_code')
    assert_equal true, cleaned_up
    reason_code_1 = ReasonCode.find(reason_codes(:reason_code97).id)
    reason_code_2 = ReasonCode.find(reason_codes(:reason_code98).id)
    reason_code_3 = ReasonCode.find(reason_codes(:reason_code99).id)
    assert_nil reason_code_1.replacement_reason_code_id
    assert_equal true, reason_code_1.active
    assert_nil reason_code_2.replacement_reason_code_id
    assert_equal true, reason_code_2.active
    assert_nil reason_code_3.replacement_reason_code_id
    assert_equal true, reason_code_3.active
  end

  def test_crosswalking_valid_remark_codes_on_global_level
    reason_code = reason_codes(:reason_code14)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)]
    expected_remark_code_ids = remark_codes_to_associate.map(&:id)
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    remark_code_crosswalked_and_client_and_facility_ids = {
      :rc_remark_code_ids => [reason_codes_ansi_remark_codes(:rc_remark_code_5).id]
    }   
    reason_code.associate_remark_codes(adjustment_codes, nil, remark_code_crosswalked_and_client_and_facility_ids)
    observerd_active_associated_remark_code_ids = reason_code.ansi_remark_codes.where("active_indicator = 1").map(&:id)
    observerd_inactive_associated_remark_code_ids = reason_code.ansi_remark_codes.where("active_indicator = 0").map(&:id)
    assert_equal expected_remark_code_ids, observerd_active_associated_remark_code_ids
    assert_equal [], observerd_inactive_associated_remark_code_ids
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_valid_and_invalid_remark_codes_on_global_level
    reason_code = reason_codes(:reason_code14)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)] 
    expected_remark_code_ids = remark_codes_to_associate.map(&:id)
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    adjustment_codes << 'INVALID'
    remark_code_crosswalked_and_client_and_facility_ids = {
      :rc_remark_code_ids => [reason_codes_ansi_remark_codes(:rc_remark_code_5).id]
    }   
    reason_code.associate_remark_codes(adjustment_codes, nil, remark_code_crosswalked_and_client_and_facility_ids)
    observerd_active_associated_remark_code_ids = reason_code.ansi_remark_codes.where("active_indicator = 1").map(&:id)
    observerd_inactive_associated_remark_code_ids = reason_code.ansi_remark_codes.where("active_indicator = 0").map(&:id)
    assert_equal expected_remark_code_ids, observerd_active_associated_remark_code_ids
    assert_equal [], observerd_inactive_associated_remark_code_ids
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_setting_of_remark_code_crosswalk_flag_on_new_global_level
    reason_code = reason_codes(:reason_code14)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)]
    expected_remark_code_ids = remark_codes_to_associate.map(&:id)
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    reason_code.associate_remark_codes(adjustment_codes)
    observerd_active_associated_remark_code_ids = reason_code.ansi_remark_codes.where("active_indicator = 1").map(&:id)
    observerd_inactive_associated_remark_code_ids = reason_code.ansi_remark_codes.where("active_indicator = 0").map(&:id)
    assert_equal expected_remark_code_ids, observerd_active_associated_remark_code_ids
    assert_equal [], observerd_inactive_associated_remark_code_ids
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_remark_code_crosswalk_on_facility_level_on_reason_code_having_an_existing_global_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)]
    expected_remark_code_ids = remark_codes_to_associate.map(&:id)
    expected_remark_code_ids << ansi_remark_codes(:ansi_remark_code1).id
    expected_remark_code_ids << ansi_remark_codes(:ansi_remark_code_1).id
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids)
    
    globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Active Global Crosswalk"

    observerd_globally_inactive_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 0)
    observerd_globally_inactive_associated_remark_code_ids = observerd_globally_inactive_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal [], observerd_globally_inactive_associated_remark_code_ids, "Inactive Global Crosswalk"
    
    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id, ansi_remark_codes(:ansi_remark_code_3).id]
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    assert_equal [], observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"


    client_level_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id, ansi_remark_codes(:ansi_remark_code_2).id]
    observerd_client_level_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observerd_client_level_associated_remark_code_ids = observerd_client_level_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal client_level_crosswalked_remark_code_ids,
      observerd_client_level_associated_remark_code_ids, "Active Client Crosswalk"

    observerd_client_level_inactive_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observerd_inactive_client_level_associated_remark_code_ids = observerd_client_level_inactive_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal [], observerd_inactive_client_level_associated_remark_code_ids, "Inactive Client Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_remark_codes_on_facility_level
    reason_code = reason_codes(:reason_code17)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes, associate_client_and_facility_ids)
    
    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_3).id, ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids, observed_facility_crosswalked_remark_code_ids
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_no_crosswalking_on_facility_level_with_empty_remark_codes
    reason_code = reason_codes(:reason_code17)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes([], associate_client_and_facility_ids)

    active_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_active_facility_crosswalked_remark_code_ids = active_rc_remark_codes.map(&:ansi_remark_code_id)
    assert_equal [], observed_active_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    assert_equal [ansi_remark_codes(:ansi_remark_code_3).id],
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal false, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_the_same_remark_codes_already_associted_on_facility_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    active_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_active_facility_crosswalked_remark_code_ids = active_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_active_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_active_facility_crosswalked_remark_code_ids,
      observed_active_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"
    assert_equal 2, active_rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = []
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_more_remark_codes_to_reason_code_having_existing_facility_level_remark_codes
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_2), ansi_remark_codes(:ansi_remark_code_3)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id,
      ansi_remark_codes(:ansi_remark_code_2).id, ansi_remark_codes(:ansi_remark_code_3).id]
    assert_equal expected_facility_crosswalked_remark_code_ids, observed_facility_crosswalked_remark_code_ids
    assert_equal 4, rc_remark_codes.length
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_deletion_of_one_of_remark_code_facility_crosswalks_and_creation_another_crosswalk
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code2), ansi_remark_codes(:ansi_remark_code_3)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code2).id, ansi_remark_codes(:ansi_remark_code_3).id]
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"
    assert_equal 2, rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_deletion_of_one_of_facility_level_remark_code_crosswalks
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code2)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids, observed_facility_crosswalked_remark_code_ids
    assert_equal 1, rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_deletion_of_all_facility_level_remark_code_crosswalks
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = []
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes, associate_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = []
    assert_equal expected_facility_crosswalked_remark_code_ids, observed_facility_crosswalked_remark_code_ids
    assert_equal 0, rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_no_remark_codes_globally_to_reason_code_having_existing_facility_level_remark_codes
    reason_code = reason_codes(:reason_code18)
    adjustment_codes = []
    reason_code.associate_remark_codes(adjustment_codes)
    
    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"
    assert_equal 2, rc_remark_codes.length

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observed_globally_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_globally_crosswalked_remark_code_ids = []
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observed_globally_crosswalked_remark_code_ids, "Active Global Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 0)
    observed_inactive_globally_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_inactive_globally_crosswalked_remark_code_ids,
      observed_inactive_globally_crosswalked_remark_code_ids, "Inctive Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_level_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_level_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id, ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_client_level_crosswalked_remark_code_ids,
      observed_client_level_crosswalked_remark_code_ids, "Client Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_no_remark_codes_in_facility_level_on_reason_code_having_an_existing_global_level
    reason_code = reason_codes(:reason_code18)
    adjustment_codes = []
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes, associate_client_and_facility_ids)

    globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = []
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"
 
    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id, ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client Crosswalk"
    
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalk_valid_remark_codes_at_client_level_with_no_existing_crosswalk
    reason_code = reason_codes(:reason_code17)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)]
    expected_remark_codes = remark_codes_to_associate.map(&:adjustment_code)
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    adjustment_codes << 'INVALID'
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes, associate_client_and_facility_ids)
    observerd_associated_remark_codes, observerd_associated_remark_code_crosswalk_ids = reason_code.get_remark_codes(associate_client_and_facility_ids[:client_id])
    assert_equal expected_remark_codes, observerd_associated_remark_codes
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_remark_code_crosswalk_on_client_level_on_reason_code_having_an_existing_global_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2),
      ansi_remark_codes(:ansi_remark_code_3)]
    expected_remark_code_ids = remark_codes_to_associate.map(&:id)
    expected_remark_code_ids << ansi_remark_codes(:ansi_remark_code1).id
    expected_remark_code_ids << ansi_remark_codes(:ansi_remark_code_1).id
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id, ansi_remark_codes(:ansi_remark_code_3).id]
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id,
      ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_no_crosswalking_on_client_level_with_empty_remark_codes
    reason_code = reason_codes(:reason_code17)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes([], associate_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    assert_equal [], observed_facility_crosswalked_remark_code_ids
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_the_same_remark_codes_already_associted_on_client_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_1), ansi_remark_codes(:ansi_remark_code_2)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = []
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    assert_equal 2, rc_remark_codes.length
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_more_remark_codes_to_reason_code_having_existing_client_level_remark_codes
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_1), ansi_remark_codes(:ansi_remark_code_2),
      ansi_remark_codes(:ansi_remark_code_3), ansi_remark_codes(:ansi_remark_code_6)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"
    assert_equal 4, rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = []
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_deletion_of_one_of_remark_code_client_level_crosswalks_and_create_another
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_2), ansi_remark_codes(:ansi_remark_code_3)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"
    assert_equal 2, rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_deletion_of_one_of_client_level_remark_code_crosswalks
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_2)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"
    assert_equal 1, rc_remark_codes.length

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"
    
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_deletion_of_all_client_level_remark_code_crosswalks   
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = []
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    client_level_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = client_level_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = []
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client level"
    assert_equal 0, client_level_rc_remark_codes.length, "Active Client Crosswalk"
    assert_equal true, reason_code.remark_code_crosswalk_flag

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id,
      ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    global_level_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observed_global_crosswalked_remark_code_ids = global_level_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_global_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_global_crosswalked_remark_code_ids,
      observed_global_crosswalked_remark_code_ids, "Global Crosswalk"

    facility_level_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_global_crosswalked_remark_code_ids = facility_level_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_global_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_global_crosswalked_remark_code_ids,
      observed_global_crosswalked_remark_code_ids, "Facility Crosswalk"
  end

  def test_crosswalking_no_remark_codes_globally_to_reason_code_having_existing_client_and_facility_level_remark_codes
    reason_code = reason_codes(:reason_code18)
    adjustment_codes = []
    reason_code.associate_remark_codes(adjustment_codes)

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id, ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client Crosswalk"
    assert_equal 2, rc_remark_codes.length

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observed_global_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_global_crosswalked_remark_code_ids = []
    assert_equal expected_global_crosswalked_remark_code_ids,
      observed_global_crosswalked_remark_code_ids, "Active Global Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 0)
    observed_inactive_global_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_global_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_inactive_global_crosswalked_remark_code_ids,
      observed_inactive_global_crosswalked_remark_code_ids, "Inactive Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_crosswalking_no_remark_codes_in_client_level_on_reason_code_having_an_existing_global_and_client_level
    reason_code = reason_codes(:reason_code18)
    adjustment_codes = []
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes, associate_client_and_facility_ids)

    globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = []
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id,
      ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"
    
    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_overwriting_of_global_level_by_client_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8), ansi_remark_codes(:ansi_remark_code_1)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :rc_remark_code_ids => [reason_codes_ansi_remark_codes(:rc_remark_code_5).id]
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    expected_globally_crosswalked_remark_code_ids = []
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Active Global Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 0)
    observed_inactive_global_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_global_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_inactive_global_crosswalked_remark_code_ids,
      observed_inactive_global_crosswalked_remark_code_ids, "Inactive Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1),
      ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8)].map(&:id)
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids, observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_overwriting_of_global_level_by_facility_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8), ansi_remark_codes(:ansi_remark_code1), ansi_remark_codes(:ansi_remark_code2)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :rc_remark_code_ids => [reason_codes_ansi_remark_codes(:rc_remark_code_5).id]
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    expected_globally_crosswalked_remark_code_ids = []
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Active Global Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 0)
    observed_inactive_global_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_global_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    assert_equal expected_inactive_global_crosswalked_remark_code_ids,
      observed_inactive_global_crosswalked_remark_code_ids, "Inactive Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id, ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1),
      ansi_remark_codes(:ansi_remark_code2), ansi_remark_codes(:ansi_remark_code_6),
      ansi_remark_codes(:ansi_remark_code_7), ansi_remark_codes(:ansi_remark_code_8)].map(&:id)
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_overwriting_of_client_level_by_global_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    remark_code_crosswalked_and_client_and_facility_ids = {      
      :client_id => clients(:Apria).id
    }
    reason_code.associate_remark_codes(adjustment_codes, nil, remark_code_crosswalked_and_client_and_facility_ids)

    expected_globally_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = []
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id,
      ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id, ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_facility_crosswalked_remark_code_ids, observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_overwriting_of_client_level_by_facility_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    remark_code_crosswalked_and_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    associate_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes, associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    expected_globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = []
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Active Client Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id =>  clients(:Apria).id, :facility_id => nil, :active_indicator => 0)
    observed_inactive_client_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id,
      ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_inactive_client_crosswalked_remark_code_ids,
      observed_inactive_client_crosswalked_remark_code_ids, "Inactive Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_overwriting_of_facility_level_by_global_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    remark_code_crosswalked_and_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes, nil, remark_code_crosswalked_and_client_and_facility_ids)

    expected_globally_crosswalked_remark_code_ids = remark_codes_to_associate.map(&:id)
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code_1).id, ansi_remark_codes(:ansi_remark_code_2).id]
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = []
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_overwriting_of_facility_level_by_client_level
    reason_code = reason_codes(:reason_code18)
    remark_codes_to_associate = [ansi_remark_codes(:ansi_remark_code_6), ansi_remark_codes(:ansi_remark_code_7),
      ansi_remark_codes(:ansi_remark_code_8), ansi_remark_codes(:ansi_remark_code1)]
    adjustment_codes = remark_codes_to_associate.map(&:adjustment_code)
    associate_client_and_facility_ids = {
      :client_id => clients(:Apria).id
    }
    remark_code_crosswalked_and_client_and_facility_ids = {
      :facility_id => facilities(:facility1).id
    }
    reason_code.associate_remark_codes(adjustment_codes,
      associate_client_and_facility_ids, remark_code_crosswalked_and_client_and_facility_ids)

    expected_globally_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id]
    observerd_globally_crosswalked_remark_code_rc_records = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => nil, :facility_id => nil, :active_indicator => 1)
    observerd_globally_associated_remark_code_ids = observerd_globally_crosswalked_remark_code_rc_records.map(&:ansi_remark_code_id)
    assert_equal expected_globally_crosswalked_remark_code_ids,
      observerd_globally_associated_remark_code_ids, "Global Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :client_id => clients(:Apria).id, :facility_id => nil, :active_indicator => 1)
    observed_client_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_client_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code_6).id, ansi_remark_codes(:ansi_remark_code_7).id,
      ansi_remark_codes(:ansi_remark_code_8).id]
    assert_equal expected_client_crosswalked_remark_code_ids,
      observed_client_crosswalked_remark_code_ids, "Client Crosswalk"

    rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 1)
    observed_facility_crosswalked_remark_code_ids = rc_remark_codes.map(&:ansi_remark_code_id)
    expected_facility_crosswalked_remark_code_ids = []
    assert_equal expected_facility_crosswalked_remark_code_ids,
      observed_facility_crosswalked_remark_code_ids, "Active Facility Crosswalk"

    inactive_rc_remark_codes = ReasonCodesAnsiRemarkCode.where(:reason_code_id => reason_code.id,
      :facility_id => facilities(:facility1).id, :active_indicator => 0)
    observed_inactive_facility_crosswalked_remark_code_ids = inactive_rc_remark_codes.map(&:ansi_remark_code_id)
    expected_inactive_facility_crosswalked_remark_code_ids = [ansi_remark_codes(:ansi_remark_code1).id,
      ansi_remark_codes(:ansi_remark_code2).id]
    assert_equal expected_inactive_facility_crosswalked_remark_code_ids,
      observed_inactive_facility_crosswalked_remark_code_ids, "Inactive Facility Crosswalk"

    assert_equal true, reason_code.remark_code_crosswalk_flag
  end

  def test_get_remark_codes_for_global_level
    reason_code = reason_codes(:reason_code18)
    observed_remark_codes, observed_rc_remark_code_crosswalk_ids = reason_code.get_remark_codes
    expected_remark_codes = [ansi_remark_codes(:ansi_remark_code1).adjustment_code]
    expected_rc_remark_code_crosswalk_ids = [reason_codes_ansi_remark_codes(:rc_remark_code_5).id]
    assert_equal expected_remark_codes, observed_remark_codes, "Remark codes"
    assert_equal expected_rc_remark_code_crosswalk_ids, observed_rc_remark_code_crosswalk_ids, "Crosswalk Ids"
  end

  def test_get_remark_codes_for_client_level
    reason_code = reason_codes(:reason_code18)
    client_id = 1
    observed_remark_codes, observed_rc_remark_code_crosswalk_ids = reason_code.get_remark_codes(client_id)
    expected_remark_codes = [ansi_remark_codes(:ansi_remark_code_1).adjustment_code,
      ansi_remark_codes(:ansi_remark_code_2).adjustment_code]
    expected_rc_remark_code_crosswalk_ids = [reason_codes_ansi_remark_codes(:rc_remark_code_15).id,
      reason_codes_ansi_remark_codes(:rc_remark_code_16).id]
    assert_equal expected_remark_codes, observed_remark_codes, "Remark codes"
    assert_equal expected_rc_remark_code_crosswalk_ids, observed_rc_remark_code_crosswalk_ids, "Crosswalk Ids"
  end

  def test_get_remark_codes_for_facility_level
    reason_code = reason_codes(:reason_code18)
    client_id = 1
    facility_id = 1
    observed_remark_codes, observed_rc_remark_code_crosswalk_ids = reason_code.get_remark_codes(client_id, facility_id)
    expected_remark_codes = [ansi_remark_codes(:ansi_remark_code1).adjustment_code,
      ansi_remark_codes(:ansi_remark_code2).adjustment_code]
    expected_rc_remark_code_crosswalk_ids = [reason_codes_ansi_remark_codes(:rc_remark_code_6).id,
      reason_codes_ansi_remark_codes(:rc_remark_code_7).id]
    assert_equal expected_remark_codes, observed_remark_codes, "Remark codes"
    assert_equal expected_rc_remark_code_crosswalk_ids, observed_rc_remark_code_crosswalk_ids, "Crosswalk Ids"
  end

  def test_not_to_get_inactive_remark_codes_for_facility_level
    reason_code = reason_codes(:reason_code21)
    client_id = nil
    facility_id = 87
    observed_remark_codes, observed_rc_remark_code_crosswalk_ids = reason_code.get_remark_codes(client_id, facility_id)
    expected_remark_codes = [ansi_remark_codes(:ansi_remark_code_1).adjustment_code]
    expected_rc_remark_code_crosswalk_ids = [reason_codes_ansi_remark_codes(:rc_remark_code_19).id]
    assert_equal expected_remark_codes, observed_remark_codes, "Remark codes"
    assert_equal expected_rc_remark_code_crosswalk_ids, observed_rc_remark_code_crosswalk_ids, "Crosswalk Ids"
  end

  private
  def ansi_codes
    "#{ansi_remark_codes(:ansi_remark_code1).adjustment_code}" + "," + "#{ansi_remark_codes(:ansi_remark_code2).adjustment_code}"
  end

  def reason_code
    reason_codes(:reason_code1)
  end

end
