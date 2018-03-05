require_relative '../test_helper'

class EdsApiTests < Minitest::Test

  def test_create_session_with_ip
    VCR.use_cassette('test_create_session_with_ip') do
            session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', user: nil, pass: nil, auth: 'ip'})
            assert session.session_token != nil, 'Expected session token not to be nil.'
            session.end
    end
  end

end
