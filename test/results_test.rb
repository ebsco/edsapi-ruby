require_relative 'test_helper'
require 'json'

class EdsApiTests < Minitest::Test

  def test_results_list
    VCR.use_cassette('results_test/profile_1/test_results_list', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1})
      assert results.records.length > 0
      refute_nil results.stat_total_hits
      refute_nil results.stat_total_time
      refute_nil results.retrieval_criteria
      refute_nil results.search_queries
      refute_nil results.page_number
      refute_nil results.search_criteria
      assert results.search_terms == ['volcano']
      session.end
    end
  end

  def test_results_with_date_range
    VCR.use_cassette('results_test/profile_1/test_results_with_date_range', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1, limiters: ['DT1:2014-01/2014-12']})
      assert results.date_range[:mindate] == '2014-01'
      assert results.date_range[:maxdate] == '2014-12'
      session.end
    end
  end

  def test_results_with_expanders
    VCR.use_cassette('results_test/profile_1/test_results_with_expanders', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1, expanders: ['fulltext']})
      refute_nil results.applied_expanders
      session.end
    end
  end

  def test_results_with_research_starters
    VCR.use_cassette('results_test/profile_1/test_results_with_research_starters', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1, related_content: ['rs']})
      refute_nil results.research_starters
      session.end
    end
  end

  def test_results_with_related_publications
    VCR.use_cassette('results_test/profile_1/test_results_with_related_publications', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'new england journal of medicine', results_per_page: 1, related_content: ['emp']})
      refute_nil results.publication_match
      session.end
    end
  end

  def test_results_applied_facets
    VCR.use_cassette('results_test/profile_1/test_results_applied_facets', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      facet_filters = [{'FilterId' => 1, 'FacetValues' => [{'Id' => 'SourceType', 'Value' => 'Academic Journals'},
                                                           {'Id' => 'SourceType', 'Value' => 'News'}] }]
      results = session.search({query: 'volcano', results_per_page: 1, facet_filters: facet_filters})
      refute_nil results.applied_facets
      session.end
    end
  end

  def test_results_with_facets_via_actions
    VCR.use_cassette('results_test/profile_1/test_results_with_facets_via_actions', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1, actions: ['addfacetfilter(SubjectGeographic:hawaii)']})
      refute_nil results.applied_facets
      session.end
    end
  end

  def test_results_all_available_facets
    VCR.use_cassette('results_test/profile_1/test_results_all_available_facets', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1})
      available_facets = results.facets
      refute_nil available_facets
      session.end
    end
  end

  def test_results_find_available_facet
    VCR.use_cassette('results_test/profile_1/test_results_find_available_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 1})
      find_facet = results.facets('SubjectEDS')
      refute_nil find_facet
      session.end
    end
  end

  def test_clear_search
    VCR.use_cassette('results_test/profile_1/test_clear_search', :allow_playback_repeats => true) do
      facet_filters = [{'FilterId' => 1, 'FacetValues' => [{'Id' => 'SourceType', 'Value' => 'Academic Journals'},
                                                           {'Id' => 'SourceType', 'Value' => 'News'}] }]
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'earthquake',
                                results_per_page: 1,
                                limiters: ['FT:Y', 'LA99:English'],
                                related_content: ['rs'],
                                expanders: ['fulltext'],
                                facet_filters: facet_filters})
      refute_nil results
      results = session.get_page(3)
      assert results.page_number == 3
      refute_nil results.search_queries
      assert results.applied_facets.length > 0
      assert results.applied_limiters.length > 0
      assert results.applied_expanders.length > 0
      results = session.clear_search
      assert results.page_number.nil?
      assert results.search_queries.nil?
      assert results.applied_facets == []
      assert results.applied_limiters == []
      assert results.applied_expanders == []
      session.end
    end
  end

  def test_clear_queries
    VCR.use_cassette('results_test/profile_1/test_clear_queries', :allow_playback_repeats => true) do
      facet_filters = [{'FilterId' => 1, 'FacetValues' => [{'Id' => 'SourceType', 'Value' => 'Academic Journals'},
                                                           {'Id' => 'SourceType', 'Value' => 'News'}] }]
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'earthquake',
                                results_per_page: 1,
                                limiters: ['FT:Y', 'LA99:English'],
                                related_content: ['rs'],
                                expanders: ['fulltext'],
                                facet_filters: facet_filters})
      refute_nil results
      results = session.get_page(3)
      assert results.page_number == 3
      refute_nil results.search_queries
      assert results.applied_facets.length > 0
      assert results.applied_limiters.length > 0
      assert results.applied_expanders.length > 0
      results = session.clear_queries
      assert results.page_number == 1
      assert results.search_queries.nil?
      assert results.applied_facets == []
      assert results.applied_limiters.length > 0
      assert results.applied_expanders.length > 0
      session.end
    end
  end

  def test_add_remove_query
    VCR.use_cassette('results_test/profile_1/test_add_remove_query', :allow_playback_repeats => true) do
      facet_filters = [{'FilterId' => 1, 'FacetValues' => [{'Id' => 'SourceType', 'Value' => 'Academic Journals'},
                                                           {'Id' => 'SourceType', 'Value' => 'News'}] }]
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'earthquake',
                                results_per_page: 1,
                                limiters: ['FT:Y', 'LA99:English'],
                                related_content: ['rs'],
                                expanders: ['fulltext'],
                                facet_filters: facet_filters})
      refute_nil results
      results = session.get_page(3)
      assert results.page_number == 3
      assert results.search_queries.length == 1
      assert results.applied_facets.length > 0
      assert results.applied_limiters.length > 0
      assert results.applied_expanders.length > 0
      results = session.add_query('AND,California')
      refute_nil results.search_criteria_with_actions
      assert results.search_queries.length == 2
      assert results.page_number == 1
      assert results.applied_facets == []
      # remove_query appears broke in API, only recognizes the first query for some reason
      # EdsApiTests#test_add_remove_query:
      # EBSCO::EDS::BadRequest: {"DetailedErrorDescription"=>"The RemoveQuery Action must specify a valid expression
      # ordinal to remove. Invalid Action: removequery(2)", "ErrorDescription"=>"Invalid Argument Value", "ErrorNumber"=>"112"}
      results = session.remove_query(1)
      assert results.search_queries.nil?
      session.end
    end
  end

  def test_results_list_html_fulltext_available
    VCR.use_cassette('results_test/profile_1/test_results_list_html_fulltext_available', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'Horowitz vs Berube', results_per_page: 10})
      assert results.records.length > 0
      assert results.records[0].eds_html_fulltext_available == true
      session.end
    end
  end

  def test_results_list_pdf_fulltext_available
    VCR.use_cassette('results_test/profile_1/test_results_list_pdf_fulltext_available', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'The Bamboozling Bite of Bitcoin', results_per_page: 10})
      assert results.records.length > 0
      assert results.records[0].eds_pdf_fulltext_available == true
      assert results.records[0].eds_html_fulltext_available == false
      assert results.records[0].eds_ebook_pdf_fulltext_available == false
      assert results.records[0].eds_ebook_epub_fulltext_available == false
      session.end
    end
  end

end