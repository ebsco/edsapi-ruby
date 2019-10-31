require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_set_include_facets
    VCR.use_cassette('facets_test/profile_1/test_set_include_facets', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1, :include_facets => false})
      assert session.search_options.SearchCriteria.IncludeFacets == 'n'
      results = session.set_include_facets('y')
      assert session.search_options.SearchCriteria.IncludeFacets == 'n'
      session.end
    end
  end

  def test_add_facet
    VCR.use_cassette('facets_test/profile_1/test_add_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_facet('SubjectGeographic', 'massachusetts')
      assert results.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_remove_facet
    VCR.use_cassette('facets_test/profile_1/test_remove_facet', :allow_playback_repeats => true) do
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
    VCR.use_cassette('facets_test/profile_1/test_remove_facet_value', :allow_playback_repeats => true) do
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
    VCR.use_cassette('facets_test/profile_1/test_clear_facets', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_facet('SubjectGeographic', 'massachusetts')
      assert results.stat_total_hits > results2.stat_total_hits
      results3 = session.clear_facets
      assert results3.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_sanitize_facets
    VCR.use_cassette('facets_test/profile_2/test_sanitize_facets', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      # using session's add_facet method
      results = session.search({query: 'interest', results_per_page: 1})
      results2 = session.add_facet('ContentProvider', 'Business Insights: Essentials')
      assert results2.stat_total_hits > 0
      # using options
      results3 = session.search({query: 'interest', results_per_page: 10,
                                 'f' => {'eds_content_provider_facet' => ['Business Insights: Essentials']}})
      assert results3.stat_total_hits > 0
      session.end
    end
  end

  def test_gpo_facet_bug_workaround
    VCR.use_cassette('facets_test/profile_2/test_gpo_facet_bug_workaround', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({query: 'poverty', results_per_page: 1})
      results2 = session.add_facet('ContentProvider', 'Government Printing Office Catalog')
      assert results2.stat_total_hits > 0
      assert_raises(EBSCO::EDS::BadRequest) do
        session.add_facet('SourceType', 'Government Documents')
      end
      # turn on recover_from_bad_source_type
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi', :allow_playback_repeats => true, recover_from_bad_source_type: true})
      results = session.search({query: 'poverty', results_per_page: 1})
      results2 = session.add_facet('ContentProvider', 'Government Printing Office Catalog')
      assert results2.stat_total_hits > 0
      results3 = session.add_facet('SourceType', 'Government Documents')
      assert results3.stat_total_hits > 0
      session.end
    end
  end

end