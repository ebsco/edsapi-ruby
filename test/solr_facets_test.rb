require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_eds_publication_type_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_publication_type_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_type_facet' => ['Books']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_language_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_language_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_language_facet' => ['dutch']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_subject_topic_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_subject_topic_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_subject_topic_facet' => ['apoptosis']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_subjects_geographic_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_subjects_geographic_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_subjects_geographic_facet' => ['alaska']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_publisher_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_publisher_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publisher_facet' => ['ashgate']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_journal_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_journal_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_journal_facet' => ['bioscience']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_category_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_category_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_category_facet' => ['social science / general']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_content_provider_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_content_provider_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_content_provider_facet' => ['PsycARTICLES']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_library_location_facet
    VCR.use_cassette('solr_facets_test/profile_1/test_eds_library_location_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_library_location_facet' => ['Owens Library']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_library_collection_facet
    VCR.use_cassette('solr_facets_test/profile_2/test_eds_library_collection_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_library_collection_facet' => ['Nc Live Module.']}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  # def test_eds_author_university_facet
  #   VCR.use_cassette('test_eds_author_university_facet') do
  #     session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
  #     results1 = session.search({query: 'climate change', results_per_page: 10})
  #     results2 = session.search({query: 'climate change', results_per_page: 10,
  #                                'f' => {'eds_author_university_facet' => ['University Of Akron']}})
  #     assert results1.stat_total_hits > 0
  #     assert results2.stat_total_hits > 0
  #     assert results1.stat_total_hits > results2.stat_total_hits
  #     session.end
  #   end
  # end

  def test_eds_search_limiters_facet
    VCR.use_cassette('solr_facets_test/profile_2/test_eds_search_limiters_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_search_limiters_facet' => ['RV']}})
      results3 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_search_limiters_facet' => ['FT1']}})

      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results3.stat_total_hits > 0

      assert results1.stat_total_hits > results2.stat_total_hits
      assert results1.stat_total_hits > results3.stat_total_hits

      session.end
    end
  end

  def test_eds_publication_year_range_facet
    VCR.use_cassette('solr_facets_test/profile_2/test_eds_publication_year_range_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_year_range_facet' => ['This year']}})
      results3 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_year_range_facet' => ['Last 3 years']}})
      results4 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_year_range_facet' => ['Last 10 years']}})
      results5 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_year_range_facet' => ['Last 50 years']}})
      results6 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_year_range_facet' => ['More than 50 years ago']}})

      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results3.stat_total_hits > 0
      assert results4.stat_total_hits > 0
      assert results5.stat_total_hits > 0
      assert results6.stat_total_hits > 0


      assert results1.stat_total_hits > results2.stat_total_hits
      assert results1.stat_total_hits > results3.stat_total_hits
      assert results1.stat_total_hits > results4.stat_total_hits
      assert results1.stat_total_hits > results5.stat_total_hits
      assert results1.stat_total_hits > results6.stat_total_hits

      session.end
    end
  end

  def test_eds_publication_year_facet
    VCR.use_cassette('solr_facets_test/profile_2/test_eds_publication_year_facet', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results1 = session.search({query: 'climate change', results_per_page: 10})
      results2 = session.search({query: 'climate change', results_per_page: 10,
                                 'f' => {'eds_publication_year_facet' => [2012]}})
      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  def test_eds_publication_year_range
    VCR.use_cassette('solr_facets_test/profile_2/test_eds_publication_year_range', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results1 = session.search({'q' => 'volcano'})
      results2 = session.search({'q' => 'volcano', 'range'=>{'pub_year_tisim'=>{'begin'=>'2001', 'end'=>'2007'}}})

      assert results1.stat_total_hits > 0
      assert results2.stat_total_hits > 0
      assert results1.stat_total_hits > results2.stat_total_hits
      session.end
    end
  end

  # No PublicationYear facet when a content provider is specified in the search
  def test_eds_publication_year_range_with_content_provider
    VCR.use_cassette('solr_facets_test/profile_2/test_eds_publication_year_range_with_content_provider', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results1 = session.search({'q' => 'carbon nanotubes'})
      results2 = session.search({'q' => 'carbon nanotubes',
                                 results_per_page: 1,
                                 'f' => {'eds_content_provider_facet' => ['MEDLINE']}})
      assert results1.solr_facets('PublicationYear').any?
      assert !results2.solr_facets('PublicationYear').any?
      session.end
    end
  end

  def test_facet_titleize_on
    VCR.use_cassette('solr_facets_test/profile_2/test_facet_titleize_on', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi', titleize_facets: true})
      results = session.search({query: 'white nose syndrome', results_per_page: 1})
      assert results.to_solr.to_json.include?('U.S. G.P.O.') # publisher
      assert results.to_solr.to_json.include?('Albany (N.Y.)') # subjectGeographic
      assert results.to_solr.to_json.include?('White-Nose Syndrome') # subjectEDS
      assert results.to_solr.to_json.include?('Spanish; Castilian') # language
      assert results.to_solr.to_json.include?('Earth Island Journal') # journal
      session.end
    end
  end

  def test_facet_titleize_on_using_env
    VCR.use_cassette('solr_facets_test/profile_2/test_facet_titleize_on_using_env', :allow_playback_repeats => true) do
      ENV['EDS_TITLEIZE_FACETS'] = 'y'
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({query: 'white nose syndrome', results_per_page: 1})
      assert results.to_solr.to_json.include?('U.S. G.P.O.') # publisher
      assert results.to_solr.to_json.include?('Albany (N.Y.)') # subjectGeographic
      assert results.to_solr.to_json.include?('White-Nose Syndrome') # subjectEDS
      assert results.to_solr.to_json.include?('Spanish; Castilian') # language
      assert results.to_solr.to_json.include?('Earth Island Journal') # journal
      session.end
      ENV['EDS_TITLEIZE_FACETS'] = nil
    end
  end

  def test_facet_titleize_off
    VCR.use_cassette('solr_facets_test/profile_2/test_facet_titleize_off', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({query: 'white nose syndrome', results_per_page: 1})
      assert results.to_solr.to_json.include?('u.s. g.p.o.') # publisher
      assert results.to_solr.to_json.include?('albany (n.y.)') # subjectGeographic
      assert results.to_solr.to_json.include?('white-nose syndrome') # subjectEDS
      assert results.to_solr.to_json.include?('spanish; castilian') # language
      assert results.to_solr.to_json.include?('earth island journal') # journal
      session.end
    end
  end

end