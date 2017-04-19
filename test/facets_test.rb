require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_set_include_facets
    VCR.use_cassette('test_set_include_facets') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1, :include_facets => false})
      assert session.search_options.SearchCriteria.IncludeFacets == 'n'
      results = session.set_include_facets('y')
      assert session.search_options.SearchCriteria.IncludeFacets == 'n'
      session.end
    end
  end

  def test_add_facet
    VCR.use_cassette('test_add_facet') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_facet('SubjectGeographic', 'massachusetts')
      assert results.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_remove_facet
    VCR.use_cassette('test_remove_facet') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_facet('SubjectGeographic', 'massachusetts')
      assert results.stat_total_hits > results2.stat_total_hits
      results3 = session.remove_facet(1)
      assert results3.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_remove_facet_value
    VCR.use_cassette('test_remove_facet_value') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_facet('SubjectGeographic', 'massachusetts')
      assert results.stat_total_hits > results2.stat_total_hits
      results3 = session.remove_facet_value(1,'SubjectGeographic', 'massachusetts')
      assert results3.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_clear_facets
    VCR.use_cassette('test_clear_facets') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_facet('SubjectGeographic', 'massachusetts')
      assert results.stat_total_hits > results2.stat_total_hits
      results3 = session.clear_facets
      assert results3.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

end