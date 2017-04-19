require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_options_retrieval_criteria
    VCR.use_cassette('test_options_retrieval_criteria') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', view: 'brief', results_per_page: 5, page_number: 2, highlight: false})
      refute_nil results
      session.end
    end
  end

  def test_options_retrieval_criteria_unknown_view
    VCR.use_cassette('test_options_retrieval_criteria_unknown_view') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', view: 'notfound'})
      refute_nil results
      assert session.search_options.RetrievalCriteria.View == session.info.default_result_list_view
      session.end
    end
  end

  def test_options_too_many_results_per_page
    VCR.use_cassette('test_options_too_many_results_per_page') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'volcano', results_per_page: 105})
      refute_nil results
      assert session.search_options.RetrievalCriteria.ResultsPerPage == session.info.max_results_per_page
      session.end
    end
  end

end