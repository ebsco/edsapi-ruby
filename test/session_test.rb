require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_create_session_with_user_credentials
    VCR.use_cassette('test_create_session_with_user_credentials') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', user: 'billmckinn', auth: 'user'})
      refute_nil session.session_token, 'Expected session token not to be nil.'
      refute_nil session.auth_token, 'Expected auth token not to be nil.'
      session.end
    end
  end

  def test_create_session_with_using_all_env_vars
    VCR.use_cassette('test_create_session_with_using_all_env_vars') do

      session = EBSCO::EDS::Session.new({use_cache: false})
      refute_nil session
      session.end

      env_test_eds_debug = ENV['EDS_DEBUG']
      env_test_eds_use_cache = ENV['EDS_USE_CACHE']
      env_test_guest = ENV['EDS_GUEST']

      ENV['EDS_DEBUG'] = 'y'
      ENV['EDS_USE_CACHE'] = 'n'
      ENV['EDS_GUEST'] = 'n'
      session = EBSCO::EDS::Session.new()
      refute_nil session
      session.end

      ENV['EDS_DEBUG'] = 'y'
      ENV['EDS_GUEST'] = 'true'
      session = EBSCO::EDS::Session.new({caller: 'unit-tests', session_token: 'asdaljdfadfjalsdfkj'})
      refute_nil session
      session.end

      # reset to .env.test values again
      ENV['EDS_DEBUG'] = env_test_eds_debug
      ENV['EDS_USE_CACHE'] = env_test_eds_use_cache
      ENV['EDS_GUEST'] = env_test_guest

    end
  end

  def test_create_session_with_ip
    VCR.use_cassette('test_create_session_with_ip') do
            session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', user: nil, pass: nil, auth: 'ip'})
            assert session.session_token != nil, 'Expected session token not to be nil.'
            session.end
    end
  end

  def test_create_session_missing_profile
    VCR.use_cassette('test_create_session_missing_profile') do
      e = assert_raises EBSCO::EDS::InvalidParameter do
        EBSCO::EDS::Session.new({use_cache: false, profile: ''})
      end
      assert_match 'Session must specify a valid api profile.', e.message
    end
  end

  def test_create_session_with_unknown_profile
    VCR.use_cassette('test_create_session_with_unknown_profile') do
      assert_raises EBSCO::EDS::BadRequest do
        EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-none'})
      end
    end
  end

  def test_create_session_failed_user_credentials
    VCR.use_cassette('test_create_session_failed_user_credentials') do
      assert_raises EBSCO::EDS::BadRequest do
        EBSCO::EDS::Session.new({
            use_cache: false,
            profile: 'eds-api',
            auth: 'user',
            user: 'fake',
            pass: 'none',
            guest: false,
            org: 'test'
                                })
      end
    end
  end

  def test_api_request_with_unsupported_method
    VCR.use_cassette('test_api_request_with_unsupported_method') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      assert_raises EBSCO::EDS::ApiError do
        session.do_request(:put, path: 'testing')
      end
      session.end
    end
  end

  def test_api_request_beyond_max_attempt
    VCR.use_cassette('test_api_request_beyond_max_attempt') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      assert_raises EBSCO::EDS::ApiError do
        session.do_request(:get, path: 'testing', attempt: 5)
      end
      session.end
    end
  end

  def test_api_request_no_session_token_force_refresh
    VCR.use_cassette('test_api_request_no_session_token_force_refresh') do
      # should trigger 108
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      session.session_token = ''
      info = EBSCO::EDS::Info.new(session.do_request(:get, path: session.config[:info_url]))
      refute_nil info
      session.end
    end
  end

  def test_api_request_invalid_auth_token_force_refresh
    # should trigger 104 and too many attempts failure
    VCR.use_cassette('test_api_request_invalid_auth_token_force_refresh') do
      session = EBSCO::EDS::Session.new({
          use_cache: false,
          profile: 'eds-api',
          auth_token: 'bogus'
                                        })
      info = EBSCO::EDS::Info.new(session.do_request(:get, path: session.config[:info_url]))
      refute_nil info
      session.end
    end
  end

end