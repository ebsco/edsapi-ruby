require_relative 'test_helper'
require 'net/http'

class EdsApiTests < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::EBSCO::VERSION
  end

  # ====================================================================================
  # SESSION TESTS
  # ====================================================================================

  def test_create_session_missing_profile
    ClimateControl.modify EDS_PROFILE: '' do
      e = assert_raises EBSCO::InvalidParameterError do
        EBSCO::Session.new
      end
      assert_match 'Session must specify a valid api profile.', e.message
    end
  end

  def test_create_session_with_unknown_profile
    Dotenv.load('.env.test')
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

  def test_create_session_with_ip
    public_ip = Net::HTTP.get URI 'https://api.ipify.org' || '127.0.0.1'
    ClimateControl.modify EDS_USER_ID: '', EDS_USER_PASSWORD: '' do
      if ENV.has_key? 'EDS_IP'
        if public_ip.include? ENV['EDS_IP']
          session = EBSCO::Session.new
          assert session.session_token != nil, 'Expected session token not to be nil.'
        else
          e = assert_raises EBSCO::ApiError do
            EBSCO::Session.new
          end
          assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
        end
      else
        e = assert_raises EBSCO::ApiError do
          EBSCO::Session.new
        end
        assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
      end
    end
  end


  # ====================================================================================
  # INFO TESTS
  # ====================================================================================

  def test_info_request
    session = EBSCO::Session.new
    assert session.info.available_search_modes.length == 4
  end

  def test_it_does_something_useful
    assert true
  end
end
