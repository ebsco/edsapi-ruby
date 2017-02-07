require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::EBSCO::VERSION
  end

  # ====================================================================================
  # SESSION TESTS
  # ====================================================================================

  def test_create_session_missing_profile
    ENV['EDS_PROFILE'] = ''
    e = assert_raises EBSCO::InvalidParameterError do
      EBSCO::Session.new()
    end
    assert_match 'Session must specify a valid api profile.', e.message
  end

  def test_create_session_with_unknown_profile
    e = assert_raises EBSCO::ApiError do
      EBSCO::Session.new({:profile => 'eds-none'})
    end
    assert_match "EBSCO API returned error:\nNumber: 144\nDescription: Profile ID is not assocated with caller's credentials.\nDetails:\n", e.message
  end

  def test_create_session_failed_user_credentials
    e = assert_raises EBSCO::ApiError do
      EBSCO::Session.new({:profile => 'eds-api', :user_id => 'fake', :password => 'none'})
    end
    assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
  end

  def test_create_session_failed_ip_auth
    ENV['EDS_USER_ID'] = ''
    ENV['EDS_USER_PASSWORD'] = ''
    e = assert_raises EBSCO::ApiError do
      EBSCO::Session.new({:profile => 'eds-api'})
    end
    assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
  end


  def test_it_does_something_useful
    assert true
  end
end
