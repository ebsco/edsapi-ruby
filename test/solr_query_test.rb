require_relative 'test_helper'
require 'json'

class EdsApiTests < Minitest::Test

  def test_basic_solr_search
    VCR.use_cassette('solr_query_test/profile_1/test_basic_solr_search', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results_yellow = session.search({'q' => 'yellow'})
      refute_nil results_yellow
      results_yellow_blue = session.search({'q' => 'yellow blue'})
      refute_nil results_yellow_blue
      assert results_yellow.stat_total_hits > results_yellow_blue.stat_total_hits
      session.end
    end
  end

  def test_pagination
    VCR.use_cassette('solr_query_test/profile_1/test_pagination', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'volcano', 'start' => 0, 'rows' => 10})
      refute_nil results
      assert results.records.length == 10
      assert results.page_number == 1
      session.end
    end
  end

  def test_solr_search_fields
    VCR.use_cassette('solr_query_test/profile_1/test_solr_search_fields', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results1 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1})
      results2 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'title'})
      results3 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'subject'})
      results4 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'source'})
      results5 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'text'})
      results6 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'abstract'})
      results7 = session.search({'q' => '01692046', 'start' => 0, 'rows' => 1, 'search_field' => 'issn'})
      results8 = session.search({'q' => '9781443816281', 'start' => 0, 'rows' => 1, 'search_field' => 'isbn'})
      results9 = session.search({'q' => 'sheiber', 'start' => 0, 'rows' => 1, 'search_field' => 'author'})
      results10 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'descriptor'})
      results11 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'series'})
      results12 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'subject_heading'})
      results13 = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'search_field' => 'keywords'})
      refute_nil results1
      refute_nil results2
      refute_nil results3
      refute_nil results4
      refute_nil results5
      refute_nil results6
      refute_nil results7
      refute_nil results8
      refute_nil results9
      refute_nil results10
      refute_nil results11
      refute_nil results12
      refute_nil results13
      session.end
    end
  end

  def test_highlighting
    VCR.use_cassette('solr_query_test/profile_1/test_highlighting', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'volcano', 'start' => 0, 'rows' => 10, 'hl' => 'on'})
      refute_empty results.to_solr.fetch('highlighting',{})
      session.end
    end
  end

  def test_solr_options_part_1
    VCR.use_cassette('solr_query_test/profile_1/test_solr_options_part_1', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'f' => {
              'eds_publication_type_facet'=>['Books'],
              'eds_language_facet'=>['english'],
              'eds_publication_year_facet'=>['Last 10 years'],
              'eds_category_facet'=>['psychology / general'],
              'eds_subject_topic_facet'=>['psychoanalysis'],
              'eds_publisher_facet'=>['karnac books']
          },
          'q'=>'white nose syndrome',
          'page'=>'2',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'on' }
      results = session.search(query)
      refute_nil results.to_solr
      session.end
    end
  end

  def test_solr_options_part_2
    VCR.use_cassette('solr_query_test/profile_1/test_solr_options_part_2', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'f' => {
              'eds_journal_facet'=>['new york times'],
              'eds_subjects_geographic_facet'=>['united states'],
              'eds_content_provider_facet'=>['Academic Search Ultimate'],
              'eds_publication_year_facet'=>['Last 3 years']
          },
          'per_page'=>'10',
          'sort'=>'pub_date_sort desc',
          'q'=>'lincoln',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      session.end
    end
  end

  def test_solr_options_part_3
    VCR.use_cassette('solr_query_test/profile_1/test_solr_options_part_3', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'f' => {
              'eds_library_location_facet'=>['Main Library'],
              'eds_publication_year_facet'=>['Last 50 years']
          },
          'per_page'=>'10',
          'sort'=>'score desc',
          'q'=>'lincoln',
          'search_field'=>'subject',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      query = {
          'f' => {
              'eds_publication_year_facet'=>['More than 50 years ago']
          },
          'per_page'=>'10',
          'q'=>'lincoln',
          'search_field'=>'author',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      session.end
    end
  end

  def test_search_limiters
    VCR.use_cassette('solr_query_test/profile_1/test_search_limiters', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'f' => {
              'eds_search_limiters_facet'=>['Available in Library Collection', 'Full Text', 'Peer Reviewed']
          },
          'q'=>'lincoln',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      session.end
    end
  end

  def test_search_limiters_by_id
    VCR.use_cassette('solr_query_test/profile_1/test_search_limiters_by_id', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'f' => {
              'eds_search_limiters_facet'=>['FT1', 'FT', 'RVC']
          },
          'q'=>'lincoln',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      session.end
    end
  end

  def test_this_year
    VCR.use_cassette('solr_query_test/profile_1/test_this_year', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'f' => {
              'eds_publication_year_facet'=>['This year']
          },
          'per_page'=>'10',
          'sort'=>'pub_date_sort desc',
          'q'=>'lincoln',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      session.end
    end
  end

  def test_spellcheck
    VCR.use_cassette('solr_query_test/profile_1/test_spellcheck', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'per_page'=>'10',
          'sort'=>'pub_date_sort desc',
          'q'=>'blesing',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off' }
      results = session.search(query)
      refute_nil results.to_solr
      assert results.to_solr.to_s.include?('"suggestion"=>[{"word"=>"bleeding", "freq"=>1}]}]')
      session.end
    end
  end

  def test_auto_correction
    VCR.use_cassette('solr_query_test/profile_1/test_auto_correction', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      query = {
          'per_page'=>'1',
          'sort'=>'pub_date_sort desc',
          'q'=>'string thery',
          'search_field'=>'all_fields',
          'controller'=>'catalog',
          'action'=>'index',
          'hl'=>'off',
          'auto_correct' => true}
      results = session.search(query)
      refute_nil results.to_solr
      assert results.to_solr.to_s.include?('"correction"=>[{"word"=>"string theory", "freq"=>1}]}]')
      assert results.to_solr.to_s.include?('"suggestion"=>[{"word"=>"string thery", "freq"=>1}]}]')
      session.end
    end
  end

  def test_solr_retrieve_list
    VCR.use_cassette('solr_query_test/profile_1/test_solr_retrieve_list', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      response = session.solr_retrieve_list(list: ['e000xna__719559', 'ers__100039113'])
      assert response['response']['numFound'] == 2
      session.end
    end
  end

  # def test_solr_dbid_accession_number_parsing
  #   VCR.use_cassette('solr_query_test/profile_4/test_solr_dbid_accession_number_parsing') do
  #     session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds_api'})
  #     # double dot accession numbers split correctly?
  #     response = session.solr_retrieve_list(list: ['edsbas__edsbas.ftunivalberta.oai.era.library.ualberta.ca.ark..54379.t7h128ng843'])
  #     assert response['response']['numFound'] == 1
  #     session.end
  #   end
  # end

  def test_solr_next_previous_links
    VCR.use_cassette('solr_query_test/profile_1/test_solr_next_previous_links', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      opts = {'f' =>
                  {'eds_language_facet' => ['spanish']},
              'q' => 'white nose syndrome',
              'search_field' => 'all_fields',
              'controller' => 'catalog',
              'action' => 'index',
              'hl' => 'on',
              'previous-next-index' => 4}
      results = session.solr_retrieve_previous_next(opts)
      refute_nil results
      assert results['response']['numFound'] > 2
      assert results['response']['docs'].length == 2
    end
  end

  def test_solr_next_previous_links_first_result
    VCR.use_cassette('solr_query_test/profile_1/test_solr_next_previous_links_first_result', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      opts = {'f' =>
                  {'eds_language_facet' => ['spanish']},
              'q' => 'white nose syndrome',
              'search_field' => 'all_fields',
              'controller' => 'catalog',
              'action' => 'index',
              'hl' => 'on',
              'previous-next-index' => 1}
      results = session.solr_retrieve_previous_next(opts)
      refute_nil results
      assert results['response']['numFound'] > 2
      assert results['response']['docs'].length == 1
    end
  end


  def test_solr_related_content
    VCR.use_cassette('solr_query_test/profile_2/test_solr_related_content', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({'q' => 'nature', 'per_page'=>'1'})
      refute_nil results
      solr_results = results.to_solr
      assert solr_results['research_starters'].length > 0
      assert solr_results['publication_matches'].length > 0
      # puts solr_results['research_starters'].inspect
    end
  end

  def test_solr_research_starters
    VCR.use_cassette('solr_query_test/profile_2/test_solr_research_starters', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({'q' => 'climate change', 'start' => 0, 'rows' => 1, 'hl' => 'off'})
      #results = session.search({query: 'climate change', results_per_page: 1, highlight: 'y'})
      refute_nil results.research_starters
      results.research_starters.each { |starter|
        refute_nil starter.eds_abstract
      }
      session.end
    end
  end

  def test_solr_date_range
    VCR.use_cassette('solr_query_test/profile_1/test_solr_date_range', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({'q' => 'white nose syndrome', 'rows' => 1})
      refute_nil results
      range = results.to_solr.fetch('date_range',{})
      refute_empty range
      assert range[:mindate] == '1000-01'
      assert range[:maxdate] == '2018-10'
      assert range[:minyear] == '1000'
      assert range[:maxyear] == '2018'
      session.end
    end
  end

  # note: maxdate/maxyear assertions need to be updated each year
  def test_solr_date_range_max_year_cleanup
    VCR.use_cassette('solr_query_test/profile_2/test_solr_date_range_max_year_cleanup', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'edsapi'})
      results = session.search({'q' => 'climate change', 'rows' => 1})
      refute_nil results
      range = results.to_solr.fetch('date_range',{})
      refute_empty range
      assert range[:mindate] == '1000-01'
      assert range[:maxdate] == '2020-01'
      assert range[:minyear] == '1000'
      assert range[:maxyear] == '2020'
      session.end
    end
  end

  def test_auto_correct_in_spellcheck_response
    VCR.use_cassette('solr_query_test/profile_1/test_auto_correct_in_spellcheck_response', :allow_playback_repeats => true) do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      results = session.search({query: 'string thery', results_per_page: 1, auto_correct: true})
      assert results.to_solr.to_s.include?('"corrections"=>["string", {"numFound"=>1, "startOffset"=>0, "endOffset"=>7, "origFreq"=>0, "correction"=>[{"word"=>"string theory", "freq"=>1}]')
      assert results.to_solr.to_s.include?('"suggestions"=>["string", {"numFound"=>1, "startOffset"=>0, "endOffset"=>7, "origFreq"=>0, "suggestion"=>[{"word"=>"string thery", "freq"=>1}]}]')
      session.end
    end
  end

end