require File.dirname(__FILE__) + '/../test_helper'

class RemittorTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :remittors

  def test_should_require_login
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_not_allow_password_outside_the_allowed_limit
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:password => "foo$1")
      assert u.errors.on(:password)
    end
  end

  def test_should_not_allow_password_with_less_number_of_required_digits
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:password => "Foobar$foobar")
      assert u.errors.on(:password)
    end
  end

  def test_should_not_allow_password_with_less_number_of_required_capital_letters
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:password => "foobar123$")
      assert u.errors.on(:password)
    end
  end

  def test_should_not_allow_password_with_less_number_of_required_special_characters
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:password => "foobar1234")
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference 'Remittor.count' do
      u = create_remittor(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    remittors(:quentin).update_attributes(:password => 'Test!1', :password_confirmation => 'Test!1')
    assert_equal remittors(:quentin), Remittor.authenticate('quentin', 'Test!1')
  end

  def test_should_not_rehash_password
    remittors(:quentin).update_attributes(:login => 'quentin2', :password => 'Test!2', :password_confirmation => "Test!2")
    assert_equal remittors(:quentin), Remittor.authenticate('quentin2', 'Test!2')
  end

  # TODO: This test needs to be fixed commenting it for now
  def ntest_should_authenticate_remittor
    assert_equal remittors(:quentin), Remittor.authenticate('quentin', 'Test!2')
  end

  def test_should_set_remember_token
    remittors(:quentin).remember_me
    assert_not_nil remittors(:quentin).remember_token
    assert_not_nil remittors(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    remittors(:quentin).remember_me
    assert_not_nil remittors(:quentin).remember_token
    remittors(:quentin).forget_me
    assert_nil remittors(:quentin).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    remittors(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil remittors(:quentin).remember_token
    assert_not_nil remittors(:quentin).remember_token_expires_at
    assert remittors(:quentin).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    remittors(:quentin).remember_me_until time
    assert_not_nil remittors(:quentin).remember_token
    assert_not_nil remittors(:quentin).remember_token_expires_at
    assert_equal remittors(:quentin).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    remittors(:quentin).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil remittors(:quentin).remember_token
    assert_not_nil remittors(:quentin).remember_token_expires_at
    assert remittors(:quentin).remember_token_expires_at.between?(before, after)
  end

protected
  def create_remittor(options = {})
    record = Remittor.new({ :login => 'quire', :email => 'quire@example.com', :password => 'quire69', :password_confirmation => 'quire69' }.merge(options))
    record.save
    record
  end
end
