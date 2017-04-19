require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  # JOURNAL ARTICLE, SINGLE AUTHOR
  def test_retrieve_journal_article
    VCR.use_cassette('test_retrieve_journal_article') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '108974507'})
        assert record.accession_number == '108974507'
        assert record.database_id == 'asn'
        assert record.database_name == 'Academic Search Ultimate'
        assert record.publication_type == 'Academic Journal'
        assert record.publication_type_id == 'academicJournal'
        assert record.document_type == 'Article'
        assert record.abstract.include? 'polyketide'
        assert record.authors == 'Weissman, Kira J'
        assert record.languages.include? 'English'
        assert record.title == 'The structural biology of biosynthetic megaenzymes.'
        assert record.bib_title == 'The structural biology of biosynthetic megaenzymes.'
        assert record.source_title == 'Nature Chemical Biology'
        assert record.issn_print == '1552-4450'
        assert record.bib_issn_print == '15524450'
        assert record.bib_issns.include? '15524450'
        refute_nil record.issns
        assert record.doi == '10.1038/nchembio.1883'
        assert record.bib_doi == '10.1038/nchembio.1883'
        assert record.subjects.include? 'ENTEROBACTIN'
        assert record.volume == '11'
        assert record.issue == '9'
        assert record.publication_date == '2015-09-01'
        assert record.publication_year == '2015'
        assert record.page_count == '11'
        assert record.page_start == '660'
        assert_nil record.series
        assert record.result_id == 1
        assert record.plink == 'http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=asn&AN=108974507'
        assert_nil record.access_level
        assert record.retrieve_options == {'an'=>'108974507', 'dbid'=>'asn'}
        assert record.fulltext_links.first == record.fulltext_link
        assert record.all_links == record.fulltext_links
      else
        puts "WARNING: skipping test_retrieve_journal_article test, asn db isn't in the profile."
      end
      session.end
    end
  end

  # JOURNAL, MULTIPLE ARTICLES
  def test_retrieve_journal_multiple_authors
    VCR.use_cassette('test_retrieve_journal_multiple_authors') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '119572050'})
        refute_nil record.subjects_geographic
        assert record.authors.include? 'Becerril'
        assert record.author_affiliations.include? 'University of Granada'
      else
        puts "WARNING: skipping test_retrieve_journal_multiple_authors test, asn db isn't in the profile."
      end
      session.end
    end
  end

  # EBOOK
  def test_retrieve_ebook
    VCR.use_cassette('test_retrieve_ebook') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'e000xna'
        record = session.retrieve({dbid: 'e000xna', an: '553416'})
        assert record.publisher_info == 'Newcastle upon Tyne : Cambridge Scholars Publishing. 2009'
        assert record.isbn_electronic == '9781443816281'
        assert record.isbn_print == '9781443813945'
        assert record.isbns.include? '9781443816281'
        assert record.oclc == '830167932'
        refute_nil record.relevancy_score
        assert record.covers.length == 2
        assert record.cover_thumb_url == 'http://rps2images.ebscohost.com/rpsweb/othumb?id=NL$553416$PDF&s=r'
        assert record.cover_medium_url == 'http://rps2images.ebscohost.com/rpsweb/othumb?id=NL$553416$PDF&s=d'
        assert record.fulltext_links.first()[:type] == 'ebook-pdf'
      else
        puts "WARNING: skipping test_retrieve_ebook test, e000xna db isn't in the profile."
      end
      session.end
    end
  end

  # CONFERENCE PROCEEDINGS
  def test_retrieve_conference
    VCR.use_cassette('test_retrieve_conference') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '118411536'})
        assert record.document_type == 'Article'
        assert record.publication_type == 'Conference'
        refute_nil record.author_supplied_keywords
      else
        puts "WARNING: skipping test_retrieve_conference test, asn db isn't in the profile."
      end
      session.end
    end
  end

  # NEWS ARTICLE, FULLTEXT
  def test_retrieve_newspaper
    VCR.use_cassette('test_retrieve_newspaper') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '112761583'})
        assert record.document_type == 'Article'
        assert record.publication_type == 'News'
        assert record.html_fulltext.include? 'The Curious Incident of the Dog'
        assert record.fulltext_word_count == 3757
        # assert record.fulltext_links.first()[:type] == 'html'
      else
        puts "WARNING: skipping test_retrieve_newspaper test, asn db isn't in the profile."
      end
      session.end
    end
  end

  # SCORE
  def test_retrieve_score
    VCR.use_cassette('test_retrieve_score') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'cat02060a'
        session.retrieve({dbid: 'cat02060a', an: 'd.uga.3690112'})
      else
        puts "WARNING: skipping test_retrieve_score test, cat02060a db isn't in the profile."
      end
      session.end
    end
  end

  # BOOK
  def test_retrieve_book
    VCR.use_cassette('test_retrieve_book') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'cat02060a'
        record = session.retrieve({dbid: 'cat02060a', an: 'd.uga.3690122'})
        #puts record.to_yaml
        refute_nil record.physical_description
        refute_nil record.subjects_person
        refute_nil record.notes
        refute_nil record.other_titles
      else
        puts "WARNING: skipping test_retrieve_book test, cat02060a db isn't in the profile."
      end
      session.end
    end
  end

  # EPUB
  def test_retrieve_epub_book
    VCR.use_cassette('test_retrieve_epub_book') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'e000xna'
        record = session.retrieve({dbid: 'e000xna', an: '719559', ebook: 'ebook-epub'})
        # puts record.to_yaml
        assert record.fulltext_links.first()[:type] == 'ebook-epub'
        assert record.fulltext_links.first()[:url] == 'http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=e000xna&AN=719559&ebv=EK&ppid='
      else
        puts "WARNING: skipping test_retrieve_epub_book test, e000xna db isn't in the profile."
      end
      session.end
    end
  end

  # CATALOG LINK (Institutional Repository exmaple)
  def test_retrieve_ir_article
    VCR.use_cassette('test_retrieve_ir_article') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'edshld'
        record = session.retrieve({dbid: 'edshld', an: 'edshld.1.3372911'})
        # puts record.to_yaml
        assert record.fulltext_links.first()[:type] == 'cataloglink'
        assert record.fulltext_links.first()[:url] == 'http://nrs.harvard.edu/urn-3:HUL.InstRepos:3372911'
      else
        puts "WARNING: skipping test_retrieve_ir_article test, edshld db isn't in the profile."
      end
      session.end
    end
  end

  def test_record_to_solr_with_fulltext
    VCR.use_cassette('test_record_to_solr_with_fulltext') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'ers'
        record = session.retrieve({dbid: 'ers', an: '100039113'})
        refute_nil record.to_solr
      else
        puts "WARNING: skipping test_record_to_solr_with_fulltext test, ers db isn't in the profile."
      end
      session.end
    end
  end

  def test_record_to_solr_with_doi
    VCR.use_cassette('test_record_to_solr_with_doi') do
      session = EBSCO::EDS::Session.new({guest: false, use_cache: false, profile: 'eds-api'})
      if session.dbid_in_profile 'asn'
        record = session.retrieve({dbid: 'asn', an: '121479599'})
        refute_nil record.to_solr
      else
        puts "WARNING: skipping test_record_to_solr_with_doi test, asn db isn't in the profile."
      end
      session.end
    end
  end

end