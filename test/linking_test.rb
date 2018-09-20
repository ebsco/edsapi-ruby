require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_smartlinks
    VCR.use_cassette('linking_test/profile_3/test_smartlinks') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'edslinkapi'})
      if session.dbid_in_profile 'cmedm'
        record = session.retrieve({dbid: 'cmedm', an: '27788591'})
        # now its a pdf for some reason?
        assert record.fulltext_link[:type] == 'pdf'
        assert record.bib_issn_electronic == '1556-9519'
      else
        puts "WARNING: skipping test_smartlinks, cmedm db isn't in the profile."
      end
      session.end
    end
  end

  def test_customlinks_fulltext
    VCR.use_cassette('linking_test/profile_3/test_customlinks_fulltext') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'edslinkapi'})
      if session.dbid_in_profile 'edsoai'
        record = session.retrieve({dbid: 'edsoai', an: 'edsoai.975318230'})
        found_catalog_link = false
        found_custom_fulltext = false
        record.fulltext_links.each do |link|
          found_catalog_link = true if link[:type] == 'cataloglink'
          found_custom_fulltext = true if link[:type] = 'customlink-fulltext'
        end
        assert found_custom_fulltext && found_catalog_link
      else
        puts "WARNING: skipping test_customlinks_fulltext, cmedm edsoai isn't in the profile."
      end
      session.end
    end
  end

  def test_non_fulltext_links
    VCR.use_cassette('linking_test/profile_3/test_non_fulltext_links') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'edslinkapi'})
      if session.dbid_in_profile 'cat02069a'
        record = session.retrieve({dbid: 'cat02069a', an: 'd.mvs.601243'})
        assert record.non_fulltext_links.first[:type] == 'customlink-other'
        found_catalog_link = false
        found_custom_other = false
        record.all_links.each do |link|
          found_catalog_link = true if link[:type] == 'cataloglink'
          found_custom_other = true if link[:type] = 'customlink-other'
        end
        assert found_custom_other && found_catalog_link
      else
        puts "WARNING: skipping test_non_fulltext_links, cat02069a db isn't in the profile."
      end
      session.end
    end
  end

end