require_relative 'test_helper'
require 'json'

class EdsApiTests < Minitest::Test

  def test_basic_search
    VCR.use_cassette('test_basic_search') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results_yellow = session.search({query: 'yellow', results_per_page: 1, mode: 'all', include_facets: false})
      refute_nil results_yellow
      results_yellow_blue = session.search({query: 'yellow blue', results_per_page: 1})
      refute_nil results_yellow_blue
      assert results_yellow.stat_total_hits > results_yellow_blue.stat_total_hits
      session.end
    end
  end

  def test_no_results
    VCR.use_cassette('test_no_results') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'siengu934ow45', results_per_page: 1, mode: 'all', include_facets: false})
      assert results.stat_total_hits == 0
      session.end
    end
  end

  def test_simple_search
    VCR.use_cassette('test_simple_search') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.simple_search('volcano')
      refute_nil results
      session.end
    end
  end

  def test_missing_query
    VCR.use_cassette('test_missing_query') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search
      refute_nil results
      assert results.stat_total_hits == 0
      session.end
    end
  end

  def test_unknown_search_mode
    VCR.use_cassette('test_unknown_search_mode') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'yellow', results_per_page: 1, mode: 'bogus'})
      refute_nil results
      assert session.search_options.SearchCriteria.SearchMode == session.info.default_search_mode
      session.end
    end
  end

  def test_search_in_publication
    VCR.use_cassette('test_search_in_publication') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      if session.publication_match_in_profile
        results = session.search({query: 'volcano', results_per_page: 1, publication_id: 'eric'})
        refute_nil results
      else
        "WARNING: skipping test_search_in_publication, profile isn't configured for publication match."
      end
      session.end
    end
  end

  def test_sort_known
    VCR.use_cassette('test_sort_known') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      session.search({query: 'volcano', results_per_page: 1, sort: 'relevance'})
      assert session.search_options.SearchCriteria.Sort == 'relevance'
      session.end
    end
  end

  def test_sort_unknown
    VCR.use_cassette('test_sort_unknown') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      session.search({query: 'volcano', results_per_page: 1, sort: 'bogus'})
      assert session.search_options.SearchCriteria.Sort == 'relevance'
      session.end
    end
  end

  def test_sort_alias_newest
    VCR.use_cassette('test_sort_alias_newest') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      session.search({query: 'volcano', results_per_page: 1, sort: 'newest'})
      assert session.search_options.SearchCriteria.Sort == 'date'
      session.end
    end
  end

  def test_sort_alias_oldest
    VCR.use_cassette('test_sort_alias_oldest') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      session.search({query: 'volcano', results_per_page: 1, sort: 'oldest'})
      assert session.search_options.SearchCriteria.Sort == 'date2'
      session.end
    end
  end

  def test_auto_suggest_on
    VCR.use_cassette('test_auto_suggest_on') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'string thery', results_per_page: 1, auto_suggest: true})
      assert results.did_you_mean == 'string theory'
      session.end
    end
  end

  def test_auto_suggest_off
    VCR.use_cassette('test_auto_suggest_off') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'string thery', results_per_page: 1, auto_suggest: false})
      assert results.did_you_mean.nil?
      session.end
    end
  end

  def test_related_content_research_starters
    VCR.use_cassette('test_related_content_research_starters') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      # puts 'RELATED CONTENT: ' + session.info.available_related_content_types.inspect
      results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['rs','emp']})
      dbids = results.database_stats.map{|hash| hash[:id]}
      assert dbids.include? 'ers'
      session.end
    end
  end

  def test_unknown_related_content_type
    VCR.use_cassette('test_unknown_related_content_type') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['bogus','also bogus']})
      refute_nil results
      session.end
    end
  end

  def test_setter_methods
    VCR.use_cassette('test_setter_methods') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      session.search({query: 'volcano'})
      session.set_sort('date')
      session.set_search_mode('any')
      session.set_view('title')
      session.set_highlight('n')
      session.results_per_page(2)
      results = session.include_related_content('rs')
      refute_nil results
      session.end
    end
  end

end