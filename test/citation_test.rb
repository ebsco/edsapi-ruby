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

  # def test_citation_as_guest
  #   VCR.use_cassette('citation_test/profile_1/test_citation_as_guest') do
  #     session = EBSCO::EDS::Session.new({use_cache: false, guest: true, profile: 'eds-api'})
  #     # puts session.inspect
  #     citation_list = session.get_citation_exports_list(id_list: ['asn__108974507', 'cat02060a__d.uga.3690122'])
  #     assert citation_list.count == 2
  #     session.end
  #   end
  # end

  def test_citations_keep_links
    VCR.use_cassette('citation_test/profile_1/test_citations_keep_links') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api', citation_link_find: ''})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '118411536'})
        citation_exports = record.eds_citation_exports
        citation_styles = record.eds_citation_styles
        assert citation_exports.items.first['data'].include?('UR  - http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=asn&AN=118411536')
        style_items = citation_styles.items
        assert style_items.count >= 9
        apa_style = style_items.select { |item| item['id'] == 'apa' }
        assert apa_style.first['data'].include?(" Retrieved from http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=asn&AN=118411536")
      else
        puts 'WARNING: skipping test_citations_keep_links since asn db not in profile.'
      end
      session.end
    end
  end

  def test_citations_remove_links
    VCR.use_cassette('citation_test/profile_1/test_citations_remove_links') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api',
                                         citation_link_find: '[.,]\s+(&lt;i&gt;EBSCOhost|viewed|Available|Retrieved from|(http:\/\/)?search.ebscohost.com|Disponível em).+$',
                                         citation_link_replace: '.',
                                         citation_db_find: '\s+<i>EBSCOhost<\/i>\.?',
                                         citation_db_replace: '',
                                         debug: false
                                        })
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '118411536'})
        citation_exports = record.eds_citation_exports
        citation_styles = record.eds_citation_styles
        # assert(!citation_exports.items.first['data'].include?('UR  - http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=asn&AN=118411536'))
        style_items = citation_styles.items
        assert style_items.count >= 9
        apa_style = style_items.select { |item| item['id'] == 'apa' }
        assert(!apa_style.first['data'].include?(" Retrieved from http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=asn&AN=118411536"))
      else
        puts 'WARNING: skipping test_citations_remove_links since asn db not in profile.'
      end
      session.end
    end
  end

  def test_citations_remove_links_abnt
    VCR.use_cassette('citation_test/profile_1/test_citations_remove_links_abnt') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api',
                                         citation_link_find: '[.,]\s+(&lt;i&gt;EBSCOhost|viewed|Available|Retrieved from|http:\/\/search.ebscohost.com|Disponível em).+$'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '118411536'})
        citation_styles = record.eds_citation_styles
        abnt_style = citation_styles.items.select { |item| item['id'] == 'abnt' }
        assert(!abnt_style.first['data'].include?('search.ebscohost.com'))
     else
        puts 'WARNING: skipping test_citations_remove_links_abnt since asn db not in profile.'
      end
      session.end
    end
  end

  def test_citations_include_doi
    VCR.use_cassette('citation_test/profile_1/test_citations_include_doi') do
      session = EBSCO::EDS::Session.new({use_cache: false, guest: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '108974507'})
        citation_styles = record.eds_citation_styles
        style_items = citation_styles.items
        assert style_items.count >= 9
        apa_style = style_items.select { |item| item['id'] == 'apa' }
        assert apa_style.first['data'].include?("Weissman, K. J. (2015). The structural biology of biosynthetic megaenzymes. <i>Nature Chemical Biology</i>, <i>11</i>(9), 660–670. https://doi.org/10.1038/nchembio.1883")
      else
        puts 'WARNING: skipping test_citations_include_doi since asn db not in profile.'
      end
      session.end
    end
  end

  def test_citations_links_replace_links_in_styles
    VCR.use_cassette('citation_test/profile_1/test_citations_links_replace_links_in_styles') do
      session = EBSCO::EDS::Session.new({use_cache: false,
                                         guest: false,
                                         debug: false,
                                         profile: 'eds-api',
                                         citation_link_find: '(http:\/\/)?search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=<%= dbid %>&AN=<%= an %>',
                                         citation_link_replace: 'https://searchworks.stanford.edu/articles/<%= dbid %>__<%= an %>',
                                         citation_db_find: '<i>EBSCOhost<\/i>',
                                         citation_db_replace: '<i>SearchWorks</i>'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'edsbas', an: 'edsbas.AA261780'})
        citation_styles = record.eds_citation_styles
        style_items = citation_styles.items
        assert style_items.count >= 9
        apa_style = style_items.select { |item| item['id'] == 'apa' }
        mla_style = style_items.select { |item| item['id'] == 'mla' }
        # puts 'APA TEST: ' + apa_style.first['data'].inspect
        assert apa_style.first['data'].include?("<i>Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura</i>. (2016). Germany, Europe: Massachusetts Medical Society. Retrieved from https://searchworks.stanford.edu/articles/edsbas__edsbas.AA261780")
        # puts 'MLA TEST: ' + mla_style.first['data'].inspect
        assert mla_style.first['data'].include?("<i>Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura</i>. Massachusetts Medical Society, 2016. <i>SearchWorks</i>, https://searchworks.stanford.edu/articles/edsbas__edsbas.AA261780.")
      else
        puts 'WARNING: skipping test_citations_links_replace_links_in_styles since asn db not in profile.'
      end
      session.end
    end
  end

  def test_citations_links_replace_links_in_styles_with_proxy
    #VCR.use_cassette('citation_test/profile_2/test_citations_links_replace_links_in_styles_with_proxy') do
      session = EBSCO::EDS::Session.new({use_cache: false,
                                         guest: false,
                                         debug: false,
                                         profile: 'edsapi',
                                         citation_link_find: '(https:\/\/)?stanford\.idm\.oclc\.org\/login\?url=(http:\/\/)?search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=<%= dbid %>&AN=<%= an %>',
                                         citation_link_replace: 'https://searchworks.stanford.edu/articles/<%= dbid %>__<%= an %>',
                                         citation_db_find: '<i>EBSCOhost<\/i>',
                                         citation_db_replace: '<i>SearchWorks</i>'})
      if session.dbid_in_profile 'edsdoj'
        record = session.retrieve({dbid: 'edsgpr', an: 'edsgpr.001022076'})
        citation_styles = record.eds_citation_styles
        style_items = citation_styles.items
        assert style_items.count >= 9
        vancouver_style = style_items.select { |item| item['id'] == 'vancouver' }
        harvardaustralian_style = style_items.select { |item| item['id'] == 'harvardaustralian' }
        # puts 'vancouver_style TEST: ' + vancouver_style.first['data'].inspect
        # assert vancouver_style.first['data'].include?("Available from: https://searchworks.stanford.edu/articles/edsdoj__edsdoj.0c69e36d48524a758c900c1e66dc0d7e")
        # puts 'harvardaustralian TEST: ' + harvardaustralian_style.first['data'].inspect
        # assert harvardaustralian_style.first['data'].include?(" <https://searchworks.stanford.edu/articles/edsdoj__edsdoj.0c69e36d48524a758c900c1e66dc0d7e>.")
      else
        puts 'WARNING: skipping test_citations_links_replace_links_in_styles_with_proxy since db not in profile.'
      end
      session.end
    #end
  end

  def test_citations_links_and_db_templates_in_exports
    VCR.use_cassette('citation_test/profile_1/test_citations_links_and_db_templates_in_exports') do
      session = EBSCO::EDS::Session.new({use_cache: false,
                                         guest: false,
                                         debug: false,
                                         profile: 'eds-api',
                                         citation_link_find: '(http:\/\/)?search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=<%= dbid %>&AN=<%= an %>',
                                         citation_link_replace: 'https://searchworks.stanford.edu/articles/<%= dbid %>__<%= an %>',
                                         citation_db_find: '<i>EBSCOhost<\/i>',
                                         citation_db_replace: '<i>SearchWorks</i>',
                                         ris_link_find: 'UR\s+-\s+http:\/\/search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=<%= dbid %>&AN=<%= an %>',
                                         ris_link_replace: 'UR  - https://searchworks.stanford.edu/articles/<%= dbid %>__<%= an %>',
                                         ris_db_find: 'DP\s+-\s+EBSCOhost',
                                         ris_db_replace: 'DP  - SearchWorks'
                                        })

      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'edsbas', an: 'edsbas.AA261780'})
        citation_exports = record.eds_citation_exports
        # puts citation_exports.items.first['data'].inspect
        assert citation_exports.items.first['data'].include?('UR  - https://searchworks.stanford.edu/articles/edsbas__edsbas.AA261780')
        assert citation_exports.items.first['data'].include?('DP  - SearchWorks')
      else
        puts 'WARNING: skipping test_citations_links_and_db_templates_in_exports since asn db not in profile.'
      end
      session.end
    end
  end

  def test_citations_links_and_db_templates_in_exports_with_proxy
    #VCR.use_cassette('citation_test/profile_2/test_citations_links_and_db_templates_in_exports_with_proxy') do
      session = EBSCO::EDS::Session.new({use_cache: false,
                                         guest: false,
                                         debug: true,
                                         profile: 'edsapi',
                                         ris_link_find: 'UR\s+-\s+https:\/\/stanford.idm.oclc.org\/login\?url=http:\/\/search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=<%= dbid %>&AN=<%= an %>',
                                         ris_link_replace: 'UR  - https://searchworks.stanford.edu/articles/<%= dbid %>__<%= an %>',
                                         ris_db_find: 'DP\s+-\s+EBSCOhost',
                                         ris_db_replace: 'DP  - SearchWorks'
                                        })

      if session.dbid_in_profile 'edsgpr'
        record = session.retrieve({dbid: 'edsgpr', an: 'edsgpr.001022076'})
        citation_exports = record.eds_citation_exports
        #puts citation_exports.items.first['data']
        assert citation_exports.items.first['data'].include?('UR  - https://searchworks.stanford.edu/articles/edsbas__edsbas.AA261780')
        assert citation_exports.items.first['data'].include?('DP  - SearchWorks')
      else
        puts 'WARNING: skipping test_citations_links_and_db_templates_in_exports since asn db not in profile.'
      end
      session.end
    #end
  end

  def test_remove_citation_links_and_db_in_ris_with_proxy
    #VCR.use_cassette('citation_test/profile_2/test_remove_citation_links_and_db_in_ris_with_proxy') do
    session = EBSCO::EDS::Session.new({use_cache: false,
                                       guest: false,
                                       debug: false,
                                       profile: 'edsapi',
                                       ris_link_find: 'UR\s+-\s+https:\/\/stanford.idm.oclc.org\/login\?url=http:\/\/search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=<%= dbid %>&AN=<%= an %>\s+',
                                       ris_link_replace: '',
                                       ris_db_find: 'DP\s+-\s+EBSCOhost\s+',
                                       ris_db_replace: ''
                                      })

    if session.dbid_in_profile 'edsgpr'
      record = session.retrieve({dbid: 'edsgpr', an: 'edsgpr.001022076'})
      citation_exports = record.eds_citation_exports
      # puts citation_exports.items.first['data']
      assert citation_exports.items.first['data'].include?('UR  - https://searchworks.stanford.edu/articles/edsbas__edsbas.AA261780')
      assert citation_exports.items.first['data'].include?('DP  - SearchWorks')
    else
      puts 'WARNING: skipping test_remove_citation_links_and_db_in_ris_with_proxy since asn db not in profile.'
    end
    session.end
    #end
  end

end
