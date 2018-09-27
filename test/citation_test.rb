require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_journal_citations
    VCR.use_cassette('citation_test/profile_1/test_journal_citations') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '108974507'})
        citation_exports = record.eds_citation_exports
        citation_styles = record.eds_citation_styles
        assert citation_exports.items.first['data'].include?('polymeric chains and tailor their functionalities')
        style_items = citation_styles.items
        assert style_items.count >= 9
        chicago_style = style_items.select { |item| item['id'] == 'chicago' }
        assert chicago_style.first['data'].include?("Weissman, Kira J. 2015. “The Structural Biology of Biosynthetic Megaenzymes.”")
      else
        puts 'WARNING: skipping test_journal_citations since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_styles_not_found_bad_record
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_not_found_bad_record') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        styles = session.get_citation_styles({dbid: 'asn', an: '999999'})
        assert styles.items.first['error'] == "Record not found"
        assert styles.items.first['data'] == ""

      else
        puts 'WARNING: skipping test_journal_citation_styles_not_found_bad_record since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_exports_not_found_bad_record
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_exports_not_found_bad_record') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        exports = session.get_citation_exports({dbid: 'asn', an: '999999'})
        assert exports.items.first['error'] == "Record not found"
      else
        puts 'WARNING: skipping test_journal_citation_exports_not_found_bad_record since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_style_one_specified
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_style_one_specified') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        mla_style = session.get_citation_styles({dbid: 'asn', an: '108974507', format: 'mla'})
        assert mla_style.items.count == 1
        assert mla_style.items.first['id'] == 'mla'
      else
        puts 'WARNING: skipping test_journal_citation_style_specified since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_export_one_specified
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_export_one_specified') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        ris_export = session.get_citation_exports({dbid: 'asn', an: '108974507', format: 'ris'})
        assert ris_export.items.count == 1
        assert ris_export.items.first['id'] == 'RIS'
        refute_nil ris_export.items.first['data']
      else
        puts 'WARNING: skipping test_journal_citation_export_one_specified since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_export_one_specified_unsupported
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_export_one_specified_unsupported') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        bogus_export = session.get_citation_exports({dbid: 'asn', an: '108974507', format: 'bogus'})
        bogus_export.items.first['error'] == "Invalid citation export format"
      else
        puts 'WARNING: skipping test_journal_citation_export_one_specified_unsupported since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_style_list_specified
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_style_list_specified') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        list_of_styles = session.get_citation_styles({dbid: 'asn', an: '108974507', format: 'mla,apa'})
        assert list_of_styles.items.count == 2
        mla_style = list_of_styles.items.select { |item| item['id'] == 'mla' }
        refute_nil mla_style
        apa_style = list_of_styles.items.select { |item| item['id'] == 'apa' }
        refute_nil apa_style
      else
        puts 'WARNING: skipping test_journal_citation_style_list_specified since asn db not in profile.'
      end
      session.end
    end
  end


  def test_journal_citation_style_list_specified_one_bad
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_style_list_specified_one_bad') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        list_of_styles = session.get_citation_styles({dbid: 'asn', an: '108974507', format: 'mla,bogus'})
        assert list_of_styles.items.count == 2
        mla_style = list_of_styles.items.select { |item| item['id'] == 'mla' }
        refute_nil mla_style
        bogus_style = list_of_styles.items.select { |item| item['id'] == 'bogus' }
        assert bogus_style.first['error'] == "Invalid citation style"
        assert_nil bogus_style.first['data']
      else
        puts 'WARNING: skipping test_journal_citation_style_list_specified since asn db not in profile.'
      end
      session.end
    end
  end

  def test_journal_citation_export_list_specified
    VCR.use_cassette('citation_test/profile_1/test_journal_citation_export_list_specified') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        list_of_exports = session.get_citation_exports({dbid: 'asn', an: '108974507', format: 'ris,bibtex'})
        assert list_of_exports.items.first['error'] == "Invalid citation export format"
      else
        puts 'WARNING: skipping test_journal_citation_export_list_specified since asn db not in profile.'
      end
      session.end
    end
  end

  def test_book_citations
    VCR.use_cassette('citation_test/profile_1/test_book_citations') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'cat02060a', an: 'd.uga.3690122'})
        citation_exports = record.eds_citation_exports
        citation_styles = record.eds_citation_styles
        assert citation_exports.items.count == 1
        assert citation_exports.items.first['data'].include?("AU  - Rowling, J. K.")
        assert citation_styles.items.count >= 9
        abnt_style = citation_styles.items.select { |item| item['id'] == 'abnt' }
        assert abnt_style.first['data'].include?("ROWLING, J. K.; GRANDPRÉ, M. <b>Harry Potter and the sorcerer’s stone</b>.")
      else
        puts 'WARNING: skipping test_book_citations since cat02060a db not in profile.'
      end
      session.end
    end
  end

  def test_conference_citations
    VCR.use_cassette('citation_test/profile_1/test_conference_citations') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '118411536'})
        citation_exports = record.eds_citation_exports
        citation_styles = record.eds_citation_styles
        assert citation_exports.items.count == 1
        assert citation_exports.items.first['data'].include?("JO  - Proceedings of the International Multidisciplinary Scientific GeoConference SGEM")
        assert citation_styles.items.count >= 9
        abnt_style = citation_styles.items.select { |item| item['id'] == 'abnt' }
        assert abnt_style.first['data'].include?("CHITEA, F. Electrical Signatures of Mud Volcanoes Case Studies from Romania.")
      else
        puts 'WARNING: skipping test_conference_citations since asn db not in profile.'
      end
      session.end
    end
  end

  def test_all_citation_styles_for_a_list_of_ids
    VCR.use_cassette('citation_test/profile_1/test_all_citation_styles_for_a_list_of_ids') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      citation_list = session.get_citation_styles_list(id_list: ['asn__108974507', 'cat02060a__d.uga.3690122'])
      assert citation_list.count == 2
      session.end
    end
  end

  def test_all_citation_exports_for_a_list_of_ids
    VCR.use_cassette('citation_test/profile_1/test_all_citation_exports_for_a_list_of_ids') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      citation_list = session.get_citation_exports_list(id_list: ['asn__108974507', 'cat02060a__d.uga.3690122'])
      assert citation_list.count == 2
      session.end
    end
  end

  def test_specified_styles_in_config
    VCR.use_cassette('citation_test/profile_1/test_specified_styles_in_config') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api', citation_styles_formats: 'apa,mla,chicago'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '108974507'})
        citation_styles = record.eds_citation_styles
        style_items = citation_styles.items
        assert style_items.count >= 3
        chicago_style = style_items.select { |item| item['id'] == 'chicago' }
        assert chicago_style.first['data'].include?("Weissman, Kira J. 2015. “The Structural Biology of Biosynthetic Megaenzymes.”")
      else
        puts 'WARNING: skipping test_specified_styles_in_config since asn db not in profile.'
      end
      session.end
    end
  end


end
