require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_journal_citations
    VCR.use_cassette('test_journal_citations') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '108974507'})
        apa_cite = record.citation('apa').first
        mla_cite = record.citation('modern-language-association').first
        chicago_cite = record.citation('chicago-author-date').first
        expect_apa_cite = 'Weissman, K. J. (2015). The structural biology of biosynthetic megaenzymes. Nature Chemical Biology, (9), 660–670. https://doi.org/10.1038/nchembio.1883'
        expect_chicago_cite = 'Weissman, Kira J. 2015. “The Structural Biology of Biosynthetic Megaenzymes.” Nature Chemical Biology, no. 9 (September): 660–70. doi:10.1038/nchembio.1883.'
        expect_mla_cite = 'Weissman, Kira J. “The Structural Biology of Biosynthetic Megaenzymes.” Nature Chemical Biology 9 (2015): 660–670. Web.'
        assert apa_cite == expect_apa_cite
        assert chicago_cite == expect_chicago_cite
        assert mla_cite == expect_mla_cite
      else
        puts 'WARNING: skipping test_journal_citations since asn db not in profile.'
      end
      session.end
    end
  end

  def test_book_citations
    VCR.use_cassette('test_book_citations') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'cat02060a', an: 'd.uga.3690122'})
        apa_cite = record.citation('apa').first
        mla_cite = record.citation('modern-language-association').first
        chicago_cite = record.citation('chicago-author-date').first
        assert apa_cite == 'Rowling, J. K., & GrandPré, M. (1999). Harry Potter and the sorcerer\'s stone. New York : Scholastic, [1999].'
        assert chicago_cite == 'Rowling, J. K., and Mary GrandPré. 1999. Harry Potter and the Sorcerer\'s Stone. New York : Scholastic, [1999].'
        assert mla_cite == 'Rowling, J. K., and Mary GrandPré. Harry Potter and the Sorcerer\'s Stone. New York : Scholastic, [1999], 1999. Print.'
      else
        puts 'WARNING: skipping test_book_citations since asn db not in profile.'
      end
      session.end
    end
  end

  def test_conference_citations
    VCR.use_cassette('test_conference_citations') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '118411536'})
        apa_cite = record.citation('apa').first
        mla_cite = record.citation('modern-language-association').first
        chicago_cite = record.citation('chicago-author-date').first
        # puts 'APA: ' + apa_cite.inspect
        # puts 'CHICAGO: ' + chicago_cite.inspect
        # puts 'MLA: ' + mla_cite.inspect
        assert apa_cite == 'Chitea, F. (2016). ELECTRICAL SIGNATURES OF MUD VOLCANOES CASE STUDIES FROM ROMANIA. In Proceedings of the International Multidisciplinary Scientific GeoConference SGEM (pp. 467–474).'
        assert chicago_cite == 'Chitea, Florina. 2016. “ELECTRICAL SIGNATURES OF MUD VOLCANOES CASE STUDIES FROM ROMANIA.” In Proceedings of the International Multidisciplinary Scientific GeoConference SGEM, 467–74.'
        assert mla_cite == 'Chitea, Florina. “ELECTRICAL SIGNATURES OF MUD VOLCANOES CASE STUDIES FROM ROMANIA.” Proceedings of the International Multidisciplinary Scientific GeoConference SGEM. 2016. 467–474. Print.'
      else
        puts 'WARNING: skipping test_conference_citations since asn db not in profile.'
      end
      session.end
    end
  end

end
