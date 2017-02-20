require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_next_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.next_page
    assert results.page_number == 2
    session.end
  end

  def test_get_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.get_page(10)
    assert results.page_number == 10
    session.end
  end

  def test_prev_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.next_page
    assert results.page_number == 2
    results = session.prev_page
    assert results.page_number == 1
    session.end
  end

  def test_prev_page_before_one
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.prev_page
    assert results.page_number == 1
    session.end
  end

  def test_next_page_past_last_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    last_page = (results.stat_total_hits / results.retrieval_criteria['ResultsPerPage']).ceil
    e = assert_raises EBSCO::BadRequest do
      session.get_page(last_page + 1)
    end
    #assert e.message.include? "Number: 138\nDescription: Max Record Retrieval Exceeded"
  end

  def test_next_page_with_only_one_page_of_results
    session = EBSCO::Session.new
    results = session.search({query: 'megaenzymes', results_per_page: 100})
    assert results.page_number == 1
    e = assert_raises EBSCO::BadRequest do
      session.get_page(10)
    end
    #assert e.message.include? "Number: 138\nDescription: Max Record Retrieval Exceeded"
  end

  def test_move_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.move_page(2)
    assert results.page_number == 3
    session.end
  end

  def test_reset_page
    session = EBSCO::Session.new
    results = session.search({query: 'economic development'})
    assert results.page_number == 1
    results = session.move_page(2)
    assert results.page_number == 3
    results = session.reset_page
    assert results.page_number == 1
    session.end

  end

end