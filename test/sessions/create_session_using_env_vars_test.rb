require_relative '../test_helper'

class EdsApiTests < Minitest::Test

  def test_create_session_with_using_all_env_vars
    VCR.use_cassette('session_test/profile_none/test_create_session_with_using_all_env_vars') do

      session = EBSCO::EDS::Session.new({use_cache: false})
      refute_nil session
      session.end

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

    end
  end

end
