require_relative 'test_helper'
require 'net/http'

class EdsApiTests < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil ::EBSCO::VERSION
  end

  # ====================================================================================
  # CREATE SESSION
  # ====================================================================================

  def test_create_session_with_user_credentials
    session = EBSCO::Session.new({:user_id => ENV['EDS_USER_ID'], :password => ENV['EDS_USER_PASSWORD']})
    assert session.session_token != nil, 'Expected session token not to be nil.'
    session.end
  end

  def test_create_session_with_using_all_env_vars
    session = EBSCO::Session.new
    refute_nil session
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

  def test_create_session_missing_profile
    ClimateControl.modify EDS_PROFILE: '' do
      e = assert_raises EBSCO::InvalidParameterError do
        EBSCO::Session.new
      end
      assert_match 'Session must specify a valid api profile.', e.message
    end
  end

  def test_create_session_with_unknown_profile
    e = assert_raises EBSCO::ApiError do
      EBSCO::Session.new({:profile => 'eds-none'})
    end
    assert_match "EBSCO API returned error:\nNumber: 144\nDescription: Profile ID is not assocated with caller's" +
                     " credentials.\nDetails:\n", e.message
  end

  def test_create_session_failed_user_credentials
    e = assert_raises EBSCO::ApiError do
      EBSCO::Session.new({:profile => 'eds-api', :user_id => 'fake', :password => 'none', :guest => false, :org => 'test'})
    end
    assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
  end

  # ====================================================================================
  # PAGINATION
  # ====================================================================================

  def test_next_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.next_page
    assert results.page_number == 2
    session.end
  end

  def test_get_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.get_page(10)
    assert results.page_number == 10
    session.end
  end

  def test_prev_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.next_page
    assert results.page_number == 2
    results = session.prev_page
    assert results.page_number == 1
    session.end
  end

  def test_prev_page_before_one
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.prev_page
    assert results.page_number == 1
    session.end
  end

  def test_next_page_past_last_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    last_page = (results.stat_total_hits / results.retrieval_criteria['ResultsPerPage']).ceil
    e = assert_raises EBSCO::ApiError do
      session.get_page(last_page + 1)
    end
    assert e.message.include? "Number: 138\nDescription: Max Record Retrieval Exceeded"
  end

  def test_next_page_with_only_one_page_of_results
    session = EBSCO::Session.new
    results = session.search({query: 'megaenzymes', results_per_page: 100})
    assert results.page_number == 1
    e = assert_raises EBSCO::ApiError do
      session.get_page(10)
    end
    assert e.message.include? "Number: 138\nDescription: Max Record Retrieval Exceeded"
  end

  # ====================================================================================
  # AUTO SUGGEST or DID YOU MEAN
  # ====================================================================================

  def test_auto_suggest_on
    session = EBSCO::Session.new
    results = session.search({query: 'string thery', results_per_page: 1, auto_suggest: true})
    assert results.did_you_mean == 'string theory'
    session.end
  end

  def test_auto_suggest_off
    session = EBSCO::Session.new
    results = session.search({query: 'string thery', results_per_page: 1, auto_suggest: false})
    assert results.did_you_mean.nil?
    session.end
  end

  # ====================================================================================
  # RELATED CONTENT
  # ====================================================================================

  def test_related_content_research_starters
    session = EBSCO::Session.new
    results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['rs']})
    dbids = results.database_stats.map{|hash| hash[:id]}
    assert dbids.include? 'ers'
    session.end
  end

  # ====================================================================================
  # SEARCH
  # ====================================================================================

  def test_basic_search
    session = EBSCO::Session.new
    results_yellow = session.search({query: 'yellow', results_per_page: 1})
    refute_nil results_yellow
    results_yellow_blue = session.search({query: 'yellow blue', results_per_page: 1})
    refute_nil results_yellow_blue
    assert results_yellow.stat_total_hits > results_yellow_blue.stat_total_hits
    session.end
  end

  # ====================================================================================
  # RETRIEVE
  # ====================================================================================
  def test_retrieve_record
    session = EBSCO::Session.new
    record = session.retrieve({dbid: 'a9h', an: '12328402'})
    assert record.an == '12328402'
    session.end
  end

  # ====================================================================================
  # LIMITERS
  # ====================================================================================

  def test_known_limiters
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, limiters: ['FT:Y', 'RV:Y']})
    refute_nil results
    applied_limiters = results.applied_limiters.map{|hash| hash['Id']}
    assert applied_limiters.include? 'FT'
    assert applied_limiters.include? 'RV'
    session.end
  end

  def test_unknown_limiters_ids
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, limiters: ['XX:Y', 'YY:Y']})
    refute_nil results
    applied_limiters = results.applied_limiters.map{|hash| hash['Id']}
    assert applied_limiters.empty?
    session.end
  end

  def test_unavailable_limiter_values
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, limiters: ['LA99:Gaelic']})
    refute_nil results
    applied_limiters = results.applied_limiters.map{|hash| hash['Id']}
    assert applied_limiters.empty?
    session.end
  end

  def test_some_unavailable_limiter_values
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, limiters: ['LA99:English,Gaelic']})
    refute_nil results
    lang_limiters = results.applied_limiters.find{|item| item['Id'] == 'LA99'}
    lang_values = lang_limiters['LimiterValuesWithAction'][0].fetch('Value')
    assert lang_values == 'English'
    session.end
  end

  # should be less than 10 result differences between the api and eds date syntax
  def test_both_date_limiter_syntaxes
    session = EBSCO::Session.new
    results_api_date = session.search({query: 'volcano', limters: ['DT1:2014-01/2014-12']})
    results_eds_date = session.search({query: 'volcano', limters: ['DT1:20140101-20141231']})
    results_dif = (results_api_date.stat_total_hits - results_eds_date.stat_total_hits).abs
    assert results_dif.between?(0, 10)
    session.end
  end

  # ====================================================================================
  # EXPANDERS
  # ====================================================================================

  def test_expander
    session = EBSCO::Session.new
    results = session.search({query: 'earthquake', expanders: ['fakeexpander:Y', 'fulltext:Y']})
    refute_nil results
    assert session.search_options.SearchCriteria.Expanders.include? 'fulltext'
    assert !(session.search_options.SearchCriteria.Expanders.include? 'fakeexpander')
  end

  # ====================================================================================
  # INFO
  # ====================================================================================

  def test_info_request
    session = EBSCO::Session.new
    assert session.info.available_search_modes.length == 4
    session.end
  end

  # ====================================================================================
  # MISC
  # ====================================================================================

  def test_api_request_with_unsupported_method
    session = EBSCO::Session.new
    e = assert_raises EBSCO::ApiError do
      session.do_request(:put, path: 'testing')
    end
    assert e.message.include? "EBSCO API error:\nMethod put not supported for endpoint testing"
    session.end
  end

  def test_api_request_beyond_max_attempt
    session = EBSCO::Session.new
    assert_raises EBSCO::ApiError do
      session.do_request(:get, path: 'testing', attempt: 5)
    end
    session.end
  end

  def test_api_request_no_session_token_force_refresh
    # should trigger 108
    session = EBSCO::Session.new
    session.session_token = ''
    info = EBSCO::Info.new(session.do_request(:get, path: EBSCO::INFO_URL))
    refute_nil info
    session.end
  end

  def test_api_request_invalid_auth_token_force_refresh
    # should trigger 104 and too many attempts failure
    session = EBSCO::Session.new
    session.auth_token = 'AB_-wWmVp56RKhVhP6olUUdZVLND3liTv2F7IkN1c3RvbWVySWQiOiJiaWxsbWNraW5uIiwiR3JvdXBJZCI6Im1haW4ifQ'
    assert_raises EBSCO::ApiError do
      EBSCO::Info.new(session.do_request(:get, path: EBSCO::INFO_URL))
    end
  end

end
