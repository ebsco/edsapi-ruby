require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_available_actions
    VCR.use_cassette('actions_test/profile_1/test_available_actions', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      refute_nil session.info.available_actions
      session.end
    end
  end

  def test_add_single_action
    VCR.use_cassette('actions_test/profile_1/test_add_single_action') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({query: 'earthquake'})
      results2 = session.add_actions('addfacetfilter(SourceType:Academic Journals,SubjectEDS:earthquakes)')
      assert results.stat_total_hits > results2.stat_total_hits
      refute_nil results2.applied_facets
      session.end
    end
  end

  def test_add_multiple_actions
    VCR.use_cassette('actions_test/profile_1/test_add_multiple_actions') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({query: 'patriots', results_per_page: 1})
      results2 = session.add_actions(['addfacetfilter(SubjectGeographic:massachusetts)', 'addlimiter(LA99:English)'])
      assert results.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_add_unknown_action
    VCR.use_cassette('actions_test/profile_1/test_add_unknown_action') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({query: 'patriots', results_per_page: 1})
      assert results.stat_total_hits > 0
      results2 = session.add_actions('addfacetfilter(Bogus:massachusetts)')
      assert results2.stat_total_hits == 0
      session.end
    end
  end

end