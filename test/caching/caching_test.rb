require_relative '../test_helper'
require 'json'

class EdsApiTests < Minitest::Test

  def test_search_caching_as_guest_and_not_guest

    test_cache_dir = './test/cache'
    env_test_guest = ENV['EDS_GUEST']
    query = {
        'f' => {
            'eds_content_provider_facet'=>['PsycINFO'],
        },
        'per_page'=>'10',
        'q'=>'climate change',
        'search_field'=>'all_fields',
        'controller'=>'catalog',
        'action'=>'index'
    }

    VCR.use_cassette('caching_test/profile_1/test_search_caching_as_guest_and_not_guest') do

      # [1] search as guest and not-guest, creating cache files
      ENV['EDS_GUEST'] = 'y'
      guest_session = EBSCO::EDS::Session.new({use_cache: true, eds_cache_dir: test_cache_dir, profile: 'eds-api'})
      guest_results = guest_session.search(query)
      refute_nil guest_results
      assert guest_results.records[0].eds_title == 'This title is unavailable for guests, please login to see more information.'
      file_count = Dir[File.join(test_cache_dir, '**', '*')].count { |file| File.file?(file) }
      assert file_count == 4 # Info, uidauth, Search (guest=true)

      ENV['EDS_GUEST'] = 'n'
      not_guest_session = EBSCO::EDS::Session.new({use_cache: true, eds_cache_dir: test_cache_dir, profile: 'eds-api'})
      not_guest_results = not_guest_session.search(query)
      refute_nil not_guest_results
      assert not_guest_results.records[0].eds_title != 'This title is unavailable for guests, please login to see more information.'
      file_count = Dir[File.join(test_cache_dir, '**', '*')].count { |file| File.file?(file) }
      assert file_count == 6 # Info, uidauth, Search (guest=true), Search (guest=false)

      # [2] try searches again just using the cache
      guest_results = guest_session.search(query)
      refute_nil guest_results
      assert guest_results.records[0].eds_title == 'This title is unavailable for guests, please login to see more information.'
      not_guest_results = not_guest_session.search(query)
      refute_nil not_guest_results
      assert not_guest_results.records[0].eds_title != 'This title is unavailable for guests, please login to see more information.'

      not_guest_session.end
      guest_session.end

    end

    # reset to .env.test values again
    ENV['EDS_GUEST'] = env_test_guest
    # remove test cache
    FileUtils.remove_dir(test_cache_dir)
  end

  def test_retrieve_caching_as_guest_and_not_guest

    test_cache_dir = './test/cache'
    env_test_guest = ENV['EDS_GUEST']
    opts = {dbid: 'psyh', an: '2017-31191-002'}

    VCR.use_cassette('caching_test/profile_1/test_retrieve_caching_as_guest_and_not_guest') do

      # [1] Retrieve documents, create cache files
      ENV['EDS_GUEST'] = 'y'
      guest_session = EBSCO::EDS::Session.new({use_cache: true, eds_cache_dir: test_cache_dir, profile: 'eds-api'})
      guest_record = guest_session.retrieve opts
      refute_nil guest_record
      assert guest_record.eds_title == 'This title is unavailable for guests, please login to see more information.'
      file_count = Dir[File.join(test_cache_dir, '**', '*')].count { |file| File.file?(file) }
      assert file_count == 3 # Info, uidauth, Retrieve (guest=true)

      ENV['EDS_GUEST'] = 'n'
      not_guest_session = EBSCO::EDS::Session.new({use_cache: true, eds_cache_dir: test_cache_dir, profile: 'eds-api'})
      not_guest_record = not_guest_session.retrieve opts
      refute_nil not_guest_record
      assert not_guest_record.eds_title == 'Climate change versus global warming: Who is susceptible to the framing of climate change?'
      file_count = Dir[File.join(test_cache_dir, '**', '*')].count { |file| File.file?(file) }
      assert file_count == 4 # Info, uidauth, Retrieve (guest=true), Retrieve (guest=false)

      # [2] Retrieve documents again just using cache
      guest_record = guest_session.retrieve opts
      refute_nil guest_record
      assert guest_record.eds_title == 'This title is unavailable for guests, please login to see more information.'
      not_guest_record = not_guest_session.retrieve opts
      refute_nil not_guest_record
      assert not_guest_record.eds_title == 'Climate change versus global warming: Who is susceptible to the framing of climate change?'

      not_guest_session.end
      guest_session.end

    end

    # reset to .env.test values again
    ENV['EDS_GUEST'] = env_test_guest
    # remove test cache
    FileUtils.remove_dir(test_cache_dir)
  end

end
