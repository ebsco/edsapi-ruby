require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  # NOTE: these test don't use cache so that the auth token is generated and
  # recorded in each test cassette. Also, the profile is specified since it
  # needs to be one that is configured for publication matching.

  def test_add_publication
    VCR.use_cassette('publications_test/profile_4/test_add_publication') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds_api'})
      if session.publication_match_in_profile
        results = session.search({query: 'earthquake', results_per_page: 1})
        results2 = session.add_publication('eric')
        assert results.stat_total_hits > results2.stat_total_hits
      else
        puts "WARNING: can't test test_add_publication - publication match not configured in profile."
      end
      session.end
    end
  end

  def test_remove_publication
    VCR.use_cassette('publications_test/profile_4/test_remove_publication') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds_api'})
      if session.publication_match_in_profile
        results = session.search({query: 'earthquake', results_per_page: 1})
        results2 = session.add_publication('eric')
        assert results.stat_total_hits > results2.stat_total_hits
        results3 = session.remove_publication('eric')
        assert results3.stat_total_hits > results2.stat_total_hits
      else
        puts "WARNING: can't test test_remove_publication - publication match not configured in profile."
      end
      session.end
    end
  end

  def test_remove_all_publications
    VCR.use_cassette('publications_test/profile_4/test_remove_all_publications') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds_api'})
      if session.publication_match_in_profile
        session.search({query: 'earthquake', results_per_page: 1})
        results2 = session.add_publication('eric')
        assert results2.applied_publications.length != []
        results3 = session.remove_all_publications
        assert results3.applied_publications == []
      else
        puts "WARNING: can't test test_remove_all_publications - publication match not configured in profile."
      end
      session.end
    end
  end

end