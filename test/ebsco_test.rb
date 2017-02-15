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
          e = assert_raises EBSCO::BadRequest do
            EBSCO::Session.new
          end
          #assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
        end
      else
        e = assert_raises EBSCO::BadRequest do
          EBSCO::Session.new
        end
        #assert_match "EBSCO API returned error:\nCode: 1102\nReason: Invalid Credentials.\nDetails:\n", e.message
      end
    end
  end

  def test_create_session_missing_profile
    ClimateControl.modify EDS_PROFILE: '' do
      e = assert_raises EBSCO::InvalidParameter do
        EBSCO::Session.new
      end
      assert_match 'Session must specify a valid api profile.', e.message
    end
  end

  def test_create_session_with_unknown_profile
    e = assert_raises EBSCO::BadRequest do
      EBSCO::Session.new({:profile => 'eds-none'})
    end
  end

  def test_create_session_failed_user_credentials
    e = assert_raises EBSCO::BadRequest do
      EBSCO::Session.new({:profile => 'eds-api', :user_id => 'fake', :password => 'none', :guest => false, :org => 'test'})
    end
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
    e = assert_raises EBSCO::BadRequest do
      session.get_page(last_page + 1)
    end
    #assert e.message.include? "Number: 138\nDescription: Max Record Retrieval Exceeded"
  end

  def test_next_page_with_only_one_page_of_results
    session = EBSCO::Session.new
    results = session.search({query: 'megaenzymes', results_per_page: 100})
    assert results.page_number == 1
    e = assert_raises EBSCO::BadRequest do
      session.get_page(10)
    end
    #assert e.message.include? "Number: 138\nDescription: Max Record Retrieval Exceeded"
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
    # puts 'RELATED CONTENT: ' + session.info.available_related_content_types.inspect
    results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['rs','emp']})
    dbids = results.database_stats.map{|hash| hash[:id]}
    assert dbids.include? 'ers'
    session.end
  end

  def test_unknown_related_content_type
    session = EBSCO::Session.new
    results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['bogus','also bogus']})
  end

  # ====================================================================================
  # SEARCH
  # ====================================================================================

  def test_basic_search
    session = EBSCO::Session.new
    results_yellow = session.search({query: 'yellow', results_per_page: 1, mode: 'all', include_facets: false})
    refute_nil results_yellow
    results_yellow_blue = session.search({query: 'yellow blue', results_per_page: 1})
    refute_nil results_yellow_blue
    assert results_yellow.stat_total_hits > results_yellow_blue.stat_total_hits
    session.end
  end

  def test_missing_query
    session = EBSCO::Session.new
    assert_raises EBSCO::InvalidParameter do
      session.search()
    end
    session.end
  end

  def test_unknown_search_mode
    session = EBSCO::Session.new
    results = session.search({query: 'yellow', results_per_page: 1, mode: 'bogus'})
    refute_nil results
    assert session.search_options.SearchCriteria.SearchMode == session.info.default_search_mode
    session.end
  end

  def test_publication_feature_not_configured_in_profile
    session = EBSCO::Session.new
    assert_raises EBSCO::BadRequest do
      session.search({query: 'volcano', results_per_page: 1, publication_id: 'something'})
    end
    session.end
  end

  def test_sort_known
    session = EBSCO::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'relevance'})
    assert session.search_options.SearchCriteria.Sort == 'relevance'
    session.end
  end

  def test_sort_unknown
    session = EBSCO::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'bogus'})
    assert session.search_options.SearchCriteria.Sort == 'relevance'
    session.end
  end

  def test_sort_alias_newest
    session = EBSCO::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'newest'})
    assert session.search_options.SearchCriteria.Sort == 'date'
    session.end
  end

  def test_sort_alias_oldest
    session = EBSCO::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'oldest'})
    assert session.search_options.SearchCriteria.Sort == 'date2'
    session.end
  end

  # ====================================================================================
  # ACTIONS
  # ====================================================================================

  def test_add_single_action
    session = EBSCO::Session.new
    results = session.search({query: 'earthquake'})
    results2 = session.add_actions('addfacetfilter(SourceType:Academic Journals,SubjectEDS:earthquakes)')
    assert results.stat_total_hits > results2.stat_total_hits
    refute_nil results2.applied_facets
    session.end
  end

  def test_add_multiple_actions
    session = EBSCO::Session.new
    results = session.search({query: 'patriots', results_per_page: 1})
    results2 = session.add_actions(['addfacetfilter(SubjectGeographic:massachusetts)', 'addlimiter(LA99:English)'])
    assert results.stat_total_hits > results2.stat_total_hits
    session.end
  end

  def test_add_unknown_action
    session = EBSCO::Session.new
    results = session.search({query: 'patriots', results_per_page: 1})
    assert results.stat_total_hits > 0
    results2 = session.add_actions('addfacetfilter(Bogus:massachusetts)')
    assert results2.stat_total_hits == 0
    session.end
  end

  # ====================================================================================
  # RETRIEVE
  # ====================================================================================
  def test_retrieve_record
    session = EBSCO::Session.new
    record = session.retrieve({dbid: 'asn', an: '12328402'})
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

  def test_some_valid_expanders_in_list
    session = EBSCO::Session.new
    results = session.search({query: 'earthquake', expanders: ['fake expander', 'fulltext']})
    refute_nil results
    assert session.search_options.SearchCriteria.Expanders.include? 'fulltext'
    assert !(session.search_options.SearchCriteria.Expanders.include? 'fake expander')
  end

  def test_no_valid_expanders_in_list
    session = EBSCO::Session.new
    results = session.search({query: 'earthquake', expanders: ['fake expander', 'also bogus']})
    refute_nil results
    assert session.search_options.SearchCriteria.Expanders.include? 'fulltext'
    assert !(session.search_options.SearchCriteria.Expanders.include? 'also bogus')
    assert !(session.search_options.SearchCriteria.Expanders.include? 'fake expander')
  end

  # ====================================================================================
  # INFO
  # ====================================================================================

  def test_info_request
    session = EBSCO::Session.new
    assert session.info.available_search_modes.length == 4
    refute_nil session.info.available_sorts
    refute_nil session.info.search_fields
    refute_nil session.info.available_expanders
    refute_nil session.info.available_expanders('fulltext')
    refute_nil session.info.default_limiter_ids
    refute_nil session.info.available_limiter_ids
    refute_nil session.info.available_limiters
    refute_nil session.info.max_record_jump
    refute_nil session.info.session_timeout
    refute_nil session.info.available_result_list_views
    refute_nil session.info.max_results_per_page
    refute_nil session.info.available_related_content
    refute_nil session.info.available_related_content('rs')
    refute_nil session.info.did_you_mean
    refute_nil session.info.did_you_mean('AutoSuggest')
    session.end
  end

  # ====================================================================================
  # OPTIONS
  # ====================================================================================

  def test_options_retrieval_criteria
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', view: 'brief', results_per_page: 5, page_number: 2, highlight: false})
    refute_nil results
    session.end
  end

  def test_options_retrieval_criteria_unknown_view
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', view: 'notfound'})
    refute_nil results
    assert session.search_options.RetrievalCriteria.View == session.info.default_result_list_view
    session.end
  end

  def test_options_too_many_results_per_page
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 105})
    refute_nil results
    assert session.search_options.RetrievalCriteria.ResultsPerPage == session.info.max_results_per_page
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
    #assert e.message.include? "EBSCO API error:\nMethod put not supported for endpoint testing"
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


  # ====================================================================================
  # RESULTS
  # ====================================================================================

  def test_results_list
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1})
    assert results.records.length > 0
    # puts "RESULTS:\n" + results.inspect
    refute_nil results.stat_total_hits
    refute_nil results.stat_total_time
    refute_nil results.retrieval_criteria
    refute_nil results.search_queries
    refute_nil results.page_number
    refute_nil results.search_criteria
    assert results.search_terms == ['volcano']
    session.end
  end

  def test_results_with_date_range
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, limiters: ['DT1:2014-01/2014-12']})
    assert results.date_range[:mindate] == '2014-01'
    assert results.date_range[:maxdate] == '2014-12'
    session.end
  end

  def test_results_with_expanders
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, expanders: ['fulltext']})
    refute_nil results.applied_expanders
    session.end
  end

  def test_results_with_research_starters
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, related_content: ['rs']})
    refute_nil results.research_starters
    session.end
  end

  def test_results_with_related_publications
    session = EBSCO::Session.new
    results = session.search({query: 'new england journal of medicine', results_per_page: 1, related_content: ['emp']})
    # puts 'PUB MATCH: ' + results.publication_match.inspect
    refute_nil results.publication_match
    session.end
  end

  def test_results_applied_facets
    session = EBSCO::Session.new
    facet_filters = [{'FilterId' => 1, 'FacetValues' => [{'Id' => 'SourceType', 'Value' => 'Academic Journals'}, {'Id' => 'SourceType', 'Value' => 'News'}] }]
    results = session.search({query: 'volcano', results_per_page: 1, facet_filters: facet_filters})
    refute_nil results.applied_facets
    session.end
  end

  def test_results_with_facets_via_actions
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1, actions: ['addfacetfilter(SubjectGeographic:hawaii)']})
    refute_nil results.applied_facets
    session.end
  end

  def test_results_all_available_facets
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1})
    available_facets = results.facets
    refute_nil available_facets
    session.end
  end

  def test_results_find_available_facet
    session = EBSCO::Session.new
    results = session.search({query: 'volcano', results_per_page: 1})
    find_facet = results.facets('SubjectEDS')
    refute_nil find_facet
    session.end
  end

  # ====================================================================================
  # RECORD
  # ====================================================================================

  def test_record_from_retrieve
    session = EBSCO::Session.new
    record = session.retrieve({dbid: 'asn', an: '108974507'})
    puts record.inspect
    assert record.an == '108974507'
    assert record.dbid == 'asn'
    refute_nil record.plink
    refute_nil record.pubtype
    refute_nil record.pubtype_id
    refute_nil record.resultid
    refute_nil record.db_label
    refute_nil record.access_level
    refute_nil record.authors
    puts 'AUTHORS: ' + record.authors.inspect
    refute_nil record.authors_raw
    puts 'AUTHORS RAW: ' + record.authors_raw.inspect
    refute_nil record.title
    puts 'TITLE: ' + record.title.inspect
    refute_nil record.title_raw
    puts 'TITLE RAW: ' + record.title_raw.inspect
    refute_nil record.subjects
    puts 'SUBJECTS: ' + record.subjects.inspect
    refute_nil record.subjects_raw
    puts 'SUBJECTS RAW: ' + record.subjects_raw.inspect

    session.end
  end


end
