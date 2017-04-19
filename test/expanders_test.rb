require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_some_valid_expanders_in_list
    VCR.use_cassette('test_some_valid_expanders_in_list') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'earthquake', expanders: ['fake expander', 'fulltext']})
      refute_nil results
      assert session.search_options.SearchCriteria.Expanders.include? 'fulltext'
      assert !(session.search_options.SearchCriteria.Expanders.include? 'fake expander')
      session.end
    end
  end

  def test_no_valid_expanders_in_list
    VCR.use_cassette('test_no_valid_expanders_in_list') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'earthquake', expanders: ['fake expander', 'also bogus']})
      refute_nil results
      assert session.search_options.SearchCriteria.Expanders.include? 'fulltext'
      assert !(session.search_options.SearchCriteria.Expanders.include? 'also bogus')
      assert !(session.search_options.SearchCriteria.Expanders.include? 'fake expander')
      session.end
    end
  end

  def test_add_expander
    VCR.use_cassette('test_add_expander') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1, expanders: ['thesaurus']})
      results2 = session.add_expander('thesaurus,fulltext,relatedsubjects')
      assert results.stat_total_hits < results2.stat_total_hits
      session.end
    end
  end

  def test_remove_expander
    VCR.use_cassette('test_remove_expander') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1, expanders: ['thesaurus']})
      results2 = session.add_expander('thesaurus,fulltext,relatedsubjects')
      assert results.stat_total_hits < results2.stat_total_hits
      results3 = session.remove_expander('fulltext')
      assert results3.stat_total_hits < results2.stat_total_hits
      session.end
    end
  end

  def test_clear_expanders
    VCR.use_cassette('test_clear_expanders') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1, expanders: ['thesaurus']})
      refute_nil results
      results2 = session.add_expander('thesaurus,fulltext,relatedsubjects')
      assert results2.applied_expanders.length == 3
      results3 = session.clear_expanders
      assert results3.applied_expanders == []
      session.end
    end
  end

end