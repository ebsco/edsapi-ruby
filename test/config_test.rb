require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_options_config
    VCR.use_cassette('config_test/profile_1/test_options_config') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', interface_id: 'just a test'})
      assert session.config[:interface_id] == 'just a test'
      session.end
    end
  end

  def test_yaml_file_config

    test_config = {
        :debug=>false,
        :guest=>true,
        :org=>'',
        :auth=>'user',
        :auth_token=>'',
        :session_token=>'',
        :eds_api_base=>'https://eds-api.ebscohost.com',
        :uid_auth_url=>'/authservice/rest/uidauth',
        :ip_auth_url=>'/authservice/rest/ipauth',
        :create_session_url=>'/edsapi/rest/CreateSession',
        :end_session_url=>'/edsapi/rest/EndSession',
        :info_url=>'/edsapi/rest/Info',
        :search_url=>'/edsapi/rest/Search',
        :retrieve_url=>'/edsapi/rest/Retrieve',
        :user_agent=>'EBSCO EDS GEM v0.0.1',
        :interface_id=>'ok ok ok',
        :log=>'faraday.log',
        :max_attempts=>2,
        :max_results_per_page=>100,
        :ebook_preferred_format=>'ebook-pdf',
        :use_cache=>false,
        :eds_cache_dir=>'/tmp'
    }

    File.open('eds-test.yaml','w') do |file|
      file.write test_config.to_yaml
    end
    VCR.use_cassette('config_test/profile_1/test_yaml_file_config') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', config: 'eds-test.yaml'})
      assert session.config[:interface_id] == 'ok ok ok'
      session.end
    end
    File.delete 'eds-test.yaml'

  end

  def test_yaml_file_bad_syntax

    bad_config = {
        :debug=>false,
        :guest=>true,
        :org=>'',
        :auth=>'user',
        :auth_token=>'',
        :session_token=>'',
        :eds_api_base=>'https://eds-api.ebscohost.com',
        :uid_auth_url=>'/authservice/rest/uidauth',
        :ip_auth_url=>'/authservice/rest/ipauth',
        :create_session_url=>'/edsapi/rest/CreateSession',
        :end_session_url=>'/edsapi/rest/EndSession',
        :info_url=>'/edsapi/rest/Info',
        :search_url=>'/edsapi/rest/Search',
        :retrieve_url=>'/edsapi/rest/Retrieve',
        :user_agent=>'EBSCO EDS GEM v0.0.1',
        :interface_id=>'blah blah blah',
        :log=>'faraday.log',
        :max_attempts=>2,
        :max_results_per_page=>100,
        :ebook_preferred_format=>'ebook-pdf',
        :use_cache=>false,
        :eds_cache_dir=>'/tmp'
    }

    yaml_string = bad_config.to_yaml.to_s
    yaml_string.gsub!(':org: \'\'', ':org: \'')

    File.open('eds-test-2.yaml','w') do |file|
      file.write yaml_string
    end

    VCR.use_cassette('config_test/profile_1/test_yaml_file_bad_syntax') do
      s2 = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', config: 'eds-test-2.yaml'})
      assert s2.config[:interface_id] == 'edsapi_ruby_gem'
      s2.end
    end
    File.delete 'eds-test-2.yaml'

  end

  def test_yaml_no_file
    VCR.use_cassette('config_test/profile_1/test_yaml_no_file', :record => :new_episodes) do
      s = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api', config: 'eds-test88.yaml'})
      assert s.config[:interface_id] == 'edsapi_ruby_gem'
      s.end
    end
  end

end