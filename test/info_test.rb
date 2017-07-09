require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_info_request
    VCR.use_cassette('test_info_request') do
      session = EBSCO::EDS::Session.new({use_cache: false, profile: 'eds-api'})
      assert session.info.available_search_modes.length == 4
      refute_nil session.info.available_sorts
      refute_nil session.info.search_fields
      refute_nil session.info.available_expanders
      refute_nil session.info.available_expanders('fulltext')
      refute_nil session.info.default_limiter_ids
      refute_nil session.info.available_limiter_ids
      refute_nil session.info.available_limiters
      refute_nil session.info.max_record_jump
      refute_nil session.info.session_timeout
      refute_nil session.info.available_result_list_views
      refute_nil session.info.max_results_per_page
      refute_nil session.info.available_related_content
      refute_nil session.info.available_related_content('rs')
      refute_nil session.info.did_you_mean
      refute_nil session.info.did_you_mean('AutoSuggest')

      assert session.research_starters_match_in_profile
      assert !session.publication_match_in_profile

      session.end
    end
  end

end