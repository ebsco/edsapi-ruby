require_relative 'test_helper'
require 'json'

class EdsApiTests < Minitest::Test

  def test_basic_search
    session = EBSCO::EDS::Session.new
    results_yellow = session.search({query: 'yellow', results_per_page: 1, mode: 'all', include_facets: false})
    refute_nil results_yellow
    results_yellow_blue = session.search({query: 'yellow blue', results_per_page: 1})
    refute_nil results_yellow_blue
    assert results_yellow.stat_total_hits > results_yellow_blue.stat_total_hits
    session.end
  end

  def test_no_results
    session = EBSCO::EDS::Session.new
    results = session.search({query: 'siengu934ow45', results_per_page: 1, mode: 'all', include_facets: false})
    assert results.stat_total_hits == 0
    session.end
  end

  def test_simple_search
    session = EBSCO::EDS::Session.new
    results = session.simple_search('volcano')
    refute_nil results
    session.end
  end

  def test_missing_query
    session = EBSCO::EDS::Session.new
    assert_raises EBSCO::EDS::InvalidParameter do
      session.search()
    end
    session.end
  end

  def test_unknown_search_mode
    session = EBSCO::EDS::Session.new
    results = session.search({query: 'yellow', results_per_page: 1, mode: 'bogus'})
    refute_nil results
    assert session.search_options.SearchCriteria.SearchMode == session.info.default_search_mode
    session.end
  end

  def test_search_in_publication
    session = EBSCO::EDS::Session.new
    if session.publication_match_in_profile
      results = session.search({query: 'volcano', results_per_page: 1, publication_id: 'eric'})
      refute_nil results
    end
    session.end
  end

  def test_sort_known
    session = EBSCO::EDS::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'relevance'})
    assert session.search_options.SearchCriteria.Sort == 'relevance'
    session.end
  end

  def test_sort_unknown
    session = EBSCO::EDS::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'bogus'})
    assert session.search_options.SearchCriteria.Sort == 'relevance'
    session.end
  end

  def test_sort_alias_newest
    session = EBSCO::EDS::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'newest'})
    assert session.search_options.SearchCriteria.Sort == 'date'
    session.end
  end

  def test_sort_alias_oldest
    session = EBSCO::EDS::Session.new
    session.search({query: 'volcano', results_per_page: 1, sort: 'oldest'})
    assert session.search_options.SearchCriteria.Sort == 'date2'
    session.end
  end

  def test_auto_suggest_on
    session = EBSCO::EDS::Session.new
    results = session.search({query: 'string thery', results_per_page: 1, auto_suggest: true})
    assert results.did_you_mean == 'string theory'
    session.end
  end

  def test_auto_suggest_off
    session = EBSCO::EDS::Session.new
    results = session.search({query: 'string thery', results_per_page: 1, auto_suggest: false})
    assert results.did_you_mean.nil?
    session.end
  end

  def test_related_content_research_starters
    session = EBSCO::EDS::Session.new
    # puts 'RELATED CONTENT: ' + session.info.available_related_content_types.inspect
    results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['rs','emp']})
    dbids = results.database_stats.map{|hash| hash[:id]}
    assert dbids.include? 'ers'
    session.end
  end

  def test_unknown_related_content_type
    session = EBSCO::EDS::Session.new
    results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['bogus','also bogus']})
  end

  def test_setter_methods
    session = EBSCO::EDS::Session.new
    results = session.search({query: 'volcano'})
    results = session.set_sort('date')
    results = session.set_search_mode('any')
    results = session.set_view('title')
    results = session.set_highlight('n')
    results = session.results_per_page(2)
    results = session.include_related_content('rs')
    session.end
  end

end