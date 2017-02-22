require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_create_session_with_user_credentials
    session = EBSCO::EDS::Session.new({:user => ENV['EDS_USER'], :pass => ENV['EDS_PASS'], :auth => 'user'})
    refute_nil session.session_token, 'Expected session token not to be nil.'
    refute_nil session.auth_token, 'Expected auth token not to be nil.'
    session.end
  end

  def test_create_session_with_using_all_env_vars
    session = EBSCO::EDS::Session.new
    refute_nil session
  end

  def test_create_session_with_ip
    ClimateControl.modify EDS_USER: '', EDS_PASS: '' do
      if ENV.has_key? 'EDS_AUTH'
        if ENV['EDS_AUTH'].casecmp('ip') == 0
          session = EBSCO::EDS::Session.new
          assert session.session_token != nil, 'Expected session token not to be nil.'
        else
          e = assert_raises EBSCO::EDS::BadRequest do
            EBSCO::EDS::Session.new
          end
          #assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
        end
      else
        e = assert_raises EBSCO::EDS::BadRequest do
          EBSCO::EDS::Session.new
        end
        #assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
      end
    end
  end

  def test_create_session_missing_profile
    ClimateControl.modify EDS_PROFILE: '' do
      e = assert_raises EBSCO::EDS::InvalidParameter do
        EBSCO::EDS::Session.new
      end
      assert_match 'Session must specify a valid api profile.', e.message
    end
  end

  def test_create_session_with_unknown_profile
    e = assert_raises EBSCO::EDS::BadRequest do
      EBSCO::EDS::Session.new({:profile => 'eds-none'})
    end
  end

  def test_create_session_failed_user_credentials
    ClimateControl.modify EDS_AUTH: 'user' do
      e = assert_raises EBSCO::EDS::BadRequest do
        EBSCO::EDS::Session.new({:profile => 'eds-api', :auth => 'user', :user => 'fake', :pass => 'none', :guest => false, :org => 'test'})
      end
    end
  end

  def test_api_request_with_unsupported_method
    session = EBSCO::EDS::Session.new
    e = assert_raises EBSCO::EDS::ApiError do
      session.do_request(:put, path: 'testing')
    end
    #assert e.message.include? "EBSCO API error:\nMethod put not supported for endpoint testing"
    session.end
  end

  def test_api_request_beyond_max_attempt
    session = EBSCO::EDS::Session.new
    assert_raises EBSCO::EDS::ApiError do
      session.do_request(:get, path: 'testing', attempt: 5)
    end
    session.end
  end

  def test_api_request_no_session_token_force_refresh
    # should trigger 108
    session = EBSCO::EDS::Session.new
    session.session_token = ''
    info = EBSCO::EDS::Info.new(session.do_request(:get, path: EBSCO::EDS::INFO_URL))
    refute_nil info
    session.end
  end

  def test_api_request_invalid_auth_token_force_refresh
    # should trigger 104 and too many attempts failure
    session = EBSCO::EDS::Session.new
    session.auth_token = 'AB_-wWmVp56RKhVhP6olUUdZVLND3liTv2F7IkN1c3RvbWVySWQiOiJiaWxsbWNraW5uIiwiR3JvdXBJZCI6Im1haW4ifQ'
    assert_raises EBSCO::EDS::ApiError do
      EBSCO::EDS::Info.new(session.do_request(:get, path: EBSCO::EDS::INFO_URL))
    end
  end

end