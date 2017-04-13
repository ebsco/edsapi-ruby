require_relative 'test_helper'
require 'json'

class EdsApiTests < Minitest::Test

  def test_basic_solr_search
    session = EBSCO::EDS::Session.new
    results_yellow = session.search({'q' => 'yellow'})
    refute_nil results_yellow
    results_yellow_blue = session.search({'q' => 'yellow blue'})
    refute_nil results_yellow_blue
    assert results_yellow.stat_total_hits > results_yellow_blue.stat_total_hits
    session.end
  end

  def test_pagination
    session = EBSCO::EDS::Session.new
    results = session.search({'q' => 'volcano', 'start' => 0, 'rows' => 10})
    refute_nil results
    assert results.records.length == 10
    assert results.page_number == 1
    session.end
  end

  def test_search_fields
    session = EBSCO::EDS::Session.new
    results1 = session.search({'q' => 'volcano', 'start' => 0, 'rows' => 10})
    results2 = session.search({'q' => 'volcano', 'start' => 0, 'rows' => 10, 'search_field' => 'title'})
    refute_nil results1
    refute_nil results2
    assert results1.stat_total_hits > results2.stat_total_hits
    session.end
  end

  def test_highlighting
    session = EBSCO::EDS::Session.new
    results = session.search({'q' => 'volcano', 'start' => 0, 'rows' => 10, 'hl' => 'on'})
    refute_empty results.to_solr.fetch('highlighting',{})
    session.end
  end

  def test_solr_options_part_1
    session = EBSCO::EDS::Session.new
    query = {
        'f' => {
            'format'=>['Books'],
            'language_facet'=>['english'],
            'pub_date_facet'=>['Last 10 years'],
            'category_facet'=>['psychology / general'],
            'subject_topic_facet'=>['psychoanalysis'],
            'publisher_facet'=>['karnac books']
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

  def test_solr_options_part_2
    session = EBSCO::EDS::Session.new
    query = {
        'f' => {
            'journal_facet'=>['new york times'],
            'geographic_facet'=>['united states'],
            'content_provider_facet'=>['Academic Search Ultimate'],
            'pub_date_facet'=>['Last 3 years']
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

  def test_solr_options_part_3
    session = EBSCO::EDS::Session.new
    query = {
        'f' => {
            'library_location_facet'=>['Main Library'],
            'pub_date_facet'=>['Last 50 years']
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
            'pub_date_facet'=>['More than 50 years ago']
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

  def test_search_limiters
    session = EBSCO::EDS::Session.new
    query = {
        'f' => {
            'search_limiters'=>['Available in Library Collection', 'Full Text', 'Peer Reviewed']
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

  def test_this_year
    session = EBSCO::EDS::Session.new
    query = {
        'f' => {
            'pub_date_facet'=>['This year']
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

  def test_spellcheck
    session = EBSCO::EDS::Session.new
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

  def test_solr_retrieve_list
    session = EBSCO::EDS::Session.new
    response = session.solr_retrieve_list(list: ['e000xna__719559', 'ers__100039113'])
    assert response['response']['numFound'] == 2
    session.end
  end

end