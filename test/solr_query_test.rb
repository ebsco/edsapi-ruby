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

end