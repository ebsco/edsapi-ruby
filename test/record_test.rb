require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  # JOURNAL ARTICLE, SINGLE AUTHOR
  def test_retrieve_journal_article
    session = EBSCO::Session.new({:guest => false})
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
      assert record.subjects.include? 'Enterobactin'
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
      assert record.fulltext_links.first == record.best_fulltext_link
      assert record.all_links == record.fulltext_links
    end
    session.end
  end

  # JOURNAL, MULTIPLE ARTICLES
  def test_retrieve_journal_multiple_authors
    session = EBSCO::Session.new({:guest => false})
    if session.dbid_in_profile 'asn'
      record = session.retrieve({dbid: 'asn', an: '119572050'})
      refute_nil record.subjects_geographic
      assert record.authors.include? 'Becerril'
      assert record.author_affiliations.include? 'University of Granada'
    end
    session.end
  end

  # EBOOK
  def test_retrieve_ebook
    session = EBSCO::Session.new({:guest => false})
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
    end
    session.end
  end

  # CONFERENCE PROCEEDINGS
  def test_retrieve_conference
    session = EBSCO::Session.new({:guest => false})
    if session.dbid_in_profile 'asn'
      record = session.retrieve({dbid: 'asn', an: '118411536'})
      assert record.document_type == 'Article'
      assert record.publication_type == 'Conference'
      refute_nil record.author_supplied_keywords
    end
    session.end
  end

  # NEWS ARTICLE, FULLTEXT
  def test_retrieve_newspaper
    session = EBSCO::Session.new({:guest => false})
    if session.dbid_in_profile 'asn'
      record = session.retrieve({dbid: 'asn', an: '112761583'})
      assert record.document_type == 'Article'
      assert record.publication_type == 'News'
      assert record.html_fulltext.include? 'The Curious Incident of the Dog'
      assert record.fulltext_word_count == 3757
      assert record.fulltext_links.first()[:type] == 'html'
    end
    session.end
  end

  # SCORE
  def test_retrieve_score
    session = EBSCO::Session.new({:guest => false})
    if session.dbid_in_profile 'cat02060a'
      record = session.retrieve({dbid: 'cat02060a', an: 'd.uga.3690112'})
    end
    session.end

  end

  # BOOK
  def test_retrieve_book
    session = EBSCO::Session.new({:guest => false})
    if session.dbid_in_profile 'cat02060a'
      record = session.retrieve({dbid: 'cat02060a', an: 'd.uga.3690122'})
      #puts record.to_yaml
      refute_nil record.physical_description
      refute_nil record.subjects_person
      refute_nil record.notes
      refute_nil record.other_titles
    end
    session.end
  end

end