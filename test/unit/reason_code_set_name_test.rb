require 'test_helper'

class ReasonCodeSetNameTest < ActiveSupport::TestCase

  fixtures :reason_codes, :payers, :reason_code_set_names

  def test_for_footnote_payer_when_footnote_indicator_is_true
    set_name = reason_code_set_names(:set_name5)
    is_footnote = set_name.is_footnote?
    assert_equal true, is_footnote
  end

  def test_for_nonfootnote_payer_when_footnote_indicator_is_false
    set_name = reason_code_set_names(:set_name1)
    is_footnote = set_name.is_footnote?
    assert_equal false, is_footnote
  end

  def test_for_nonfootnote_payer_when_footnote_indicator_is_blank
    set_name = reason_code_set_names(:set_name4)
    is_footnote = set_name.is_footnote?
    assert_equal false, is_footnote
  end

  def test_for_nonfootnote_payer_when_payer_is_blank
    set_name = reason_code_set_names(:set_name6)
    is_footnote = set_name.is_footnote?
    assert_equal false, is_footnote
  end

  def test_should_not_switch_rcs_to_new_set_and_should_not_destroy_when_old_rc_set_has_more_than_one_payer
    old_set_name = reason_code_set_names(:set_with_two_payers)
    new_rc_set_name = reason_code_set_names(:new_rc_set_name)
    payer = payers(:payer1_sharing_the_set_name_with_another)
    assert_equal true, old_set_name.switch_rcs_to_new_set_and_destroy(new_rc_set_name, payer.id)
    old_set_name.reload
    assert_equal false, old_set_name.destroyed?
    assert_equal 2, old_set_name.reason_codes.length
    assert_equal 1, new_rc_set_name.reason_codes.length
  end

  def test_switch_rcs_to_new_set_and_destroy_should_return_true_when_old_rc_set_has_only_one_payer
    old_set_name = reason_code_set_names(:set_with_one_payer)
    new_rc_set_name = reason_code_set_names(:new_rc_set_name)
    payer = payers(:payer_with_an_exclusive_set_name)

    assert_equal true, old_set_name.switch_rcs_to_new_set_and_destroy(new_rc_set_name, payer.id)    
    assert_equal true, old_set_name.destroyed?
    assert_equal 3, new_rc_set_name.reason_codes.length
  end

end
