require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_options_config
    session = EBSCO::EDS::Session.new({:interface_id => 'just a test'})
    assert session.config[:interface_id] == 'just a test'
    session.end
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

    session = EBSCO::EDS::Session.new({:config => 'eds-test.yaml'})
    File.delete 'eds-test.yaml'
    assert session.config[:interface_id] == 'ok ok ok'
    session.end

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

    s2 = EBSCO::EDS::Session.new({:config => 'eds-test-2.yaml'})
    File.delete 'eds-test-2.yaml'
    assert s2.config[:interface_id] == 'EBSCO EDS GEM v0.0.1'
    s2.end

  end

  def test_yaml_no_file
    s = EBSCO::EDS::Session.new({:config => 'eds-test88.yaml'})
    assert s.config[:interface_id] == 'EBSCO EDS GEM v0.0.1'
    s.end
  end

end