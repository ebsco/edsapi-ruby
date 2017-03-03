require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_add_publication
    session = EBSCO::EDS::Session.new
    if session.publication_match_in_profile
      results = session.search({query: 'earthquake', results_per_page: 1})
      results2 = session.add_publication('eric')
      assert results.stat_total_hits > results2.stat_total_hits
    end
    session.end
  end

  def test_remove_publication
    session = EBSCO::EDS::Session.new
    if session.publication_match_in_profile
      results = session.search({query: 'earthquake', results_per_page: 1})
      results2 = session.add_publication('eric')
      assert results.stat_total_hits > results2.stat_total_hits
      results3 = session.remove_publication('eric')
      assert results3.stat_total_hits > results2.stat_total_hits
    end
    session.end
  end

  def test_remove_all_publications
    session = EBSCO::EDS::Session.new
    if session.publication_match_in_profile
      session.search({query: 'earthquake', results_per_page: 1})
      results2 = session.add_publication('eric')
      assert results2.applied_publications.length != []
      results3 = session.remove_all_publications
      assert results3.applied_publications == []
    end
    session.end
  end

end