require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_next_page
    VCR.use_cassette('test_next_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      results = session.next_page
      assert results.page_number == 2
      session.end
    end
  end

  def test_get_page
    VCR.use_cassette('test_get_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      results = session.get_page(10)
      assert results.page_number == 10
      session.end
    end
  end

  def test_prev_page
    VCR.use_cassette('test_prev_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      results = session.next_page
      assert results.page_number == 2
      results = session.prev_page
      assert results.page_number == 1
      session.end
    end
  end

  def test_prev_page_before_one
    VCR.use_cassette('test_prev_page_before_one') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      results = session.prev_page
      assert results.page_number == 1
      session.end
    end
  end

  def test_next_page_past_last_page
    VCR.use_cassette('test_next_page_past_last_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      last_page = (results.stat_total_hits / results.retrieval_criteria['ResultsPerPage']).ceil
      assert_raises EBSCO::EDS::ApiError do
        session.get_page(last_page + 3)
      end
    end
  end

  def test_next_page_with_only_one_page_of_results
    VCR.use_cassette('test_next_page_with_only_one_page_of_results') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'megaenzymes', results_per_page: 100})
      assert results.page_number == 1
      assert_raises EBSCO::EDS::ApiError do
        session.get_page(10)
      end
    end
  end

  def test_move_page
    VCR.use_cassette('test_move_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      results = session.move_page(2)
      assert results.page_number == 3
      session.end
    end
  end

  def test_reset_page
    VCR.use_cassette('test_reset_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'economic development'})
      assert results.page_number == 1
      results = session.move_page(2)
      assert results.page_number == 3
      results = session.reset_page
      assert results.page_number == 1
      session.end
    end
  end

  def test_solr_beyond_250_results
    VCR.use_cassette('test_beyond_250_results') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats', 'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  def test_solr_beyond_250_results_with_limiter
    VCR.use_cassette('test_solr_beyond_250_results_with_limiter') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
        'f' => {'eds_search_limiters_facet'=>['Peer Reviewed']},
        'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  def test_solr_beyond_250_results_with_source_type_facet_only
    VCR.use_cassette('test_solr_beyond_250_results_with_source_type_facet_only') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
                                'f' => {'eds_publication_type_facet'=>['Books']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  def test_solr_beyond_250_results_with_content_provider_facet_only
    VCR.use_cassette('test_solr_beyond_250_results_with_content_provider_facet_only') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
                                'f' => {'eds_content_provider_facet'=>['Academic Search Ultimate']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  def test_solr_beyond_250_results_with_source_type_facet_and_limiter
    VCR.use_cassette('test_solr_beyond_250_results_with_source_type_facet_and_limiter') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
                                'f' => {'eds_publication_type_facet'=>['Books'],
                                        'eds_search_limiters_facet'=>['Peer Reviewed']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  def test_solr_beyond_250_results_with_content_provider_facet_and_limiter
    VCR.use_cassette('test_solr_beyond_250_results_with_content_provider_facet_and_limiter') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
                                'f' => {'eds_content_provider_facet'=>['Academic Search Ultimate'],
                                        'eds_search_limiters_facet'=>['Peer Reviewed']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  # TODO: resolve
  def test_solr_beyond_250_results_with_source_type_facet_and_language_facet
    VCR.use_cassette('test_solr_beyond_250_results_with_source_type_facet_and_language_facet') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      assert_raises EBSCO::EDS::ApiError do
        session.search({'q' => 'cats',
                                'f' => {'eds_language_facet' => ['english'],
                                        'eds_publication_type_facet'=>['Books']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      end
      session.end
    end
  end

  # TODO: resolve
  def test_solr_beyond_250_results_with_content_provider_facet_and_language_facet
    VCR.use_cassette('test_solr_beyond_250_results_with_content_provider_facet_and_language_facet') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      assert_raises EBSCO::EDS::ApiError do
        session.search({'q' => 'cats',
                              'f' => {'eds_content_provider_facet'=>['Academic Search Ultimate'],
                                      'eds_language_facet'=>['english']},
                              'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      end
      session.end
    end
  end

  # TODO: resolve
  def test_solr_beyond_250_results_with_content_provider_facet_and_source_type_facet
    VCR.use_cassette('test_solr_beyond_250_results_with_content_provider_facet_and_source_type_facet') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      assert_raises EBSCO::EDS::ApiError do
        session.search({'q' => 'cats',
                        'f' => {'eds_content_provider_facet'=>['Academic Search Ultimate'],
                                'eds_publication_type_facet'=>['Academic Journals']},
                        'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      end
      session.end
    end
  end

  def test_solr_beyond_250_results_with_multiple_facets
    VCR.use_cassette('test_solr_beyond_250_results_with_multiple_facets') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
                                'f' => {'eds_language_facet'=>['english'],
                                        'eds_subject_topic_facet'=>['cats'],
                                        'eds_subjects_geographic_facet' => ['united states']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

  def test_solr_beyond_250_results_with_multiple_facets_and_limiter
    VCR.use_cassette('test_solr_beyond_250_results_with_multiple_facets_and_limiter') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'cats',
                                'f' => {'eds_language_facet'=>['english'],
                                        'eds_subject_topic_facet'=>['cats'],
                                        'eds_subjects_geographic_facet' => ['united states'],
                                        'eds_search_limiters_facet'=>['Peer Reviewed']},
                                'page' => 5, 'per_page' => 100, 'search_field' => 'all_fields'})
      assert results.page_number == 5
      session.end
    end
  end

end