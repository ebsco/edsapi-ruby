require_relative 'test_helper'

class EdsApiTests < Minitest::Test

  def test_all_change_subject_fields
    VCR.use_cassette('test_all_change_subject_fields') do
      session_with_sanitize = EBSCO::EDS::Session.new({guest: false,
                                                       use_cache: false,
                                                       profile: 'edsapi',
                                                       decode_sanitize_html: true,
                                                       all_subjects_search_links: true})
      session_no_sanitize = EBSCO::EDS::Session.new({guest: false,
                                                       use_cache: false,
                                                       profile: 'edsapi',
                                                       decode_sanitize_html: false,
                                                       all_subjects_search_links: true})
      if session_with_sanitize.dbid_in_profile 'cmedm'
        record = session_with_sanitize.retrieve({dbid: 'cmedm', an: '27748641'})
        assert record.eds_subjects_mesh.to_s == '<searchLink fieldcode="DE" term="%22Nanotubes%2C+Carbon%22">Nanotubes, Carbon*</searchLink> <br><searchLink fieldcode="DE" term="%22Water+Pollutants%2C+Chemical%22">Water Pollutants, Chemical*</searchLink><br><searchLink fieldcode="DE" term="%22Catalysis%22">Catalysis</searchLink> ; <searchLink fieldcode="DE" term="%22Hydrogen+Peroxide%22">Hydrogen Peroxide</searchLink> ; <searchLink fieldcode="DE" term="%22Ozone%22">Ozone</searchLink>'

        record = session_no_sanitize.retrieve({dbid: 'cmedm', an: '27748641'})
        assert record.eds_subjects_mesh.to_s == '&lt;searchLink fieldCode=&quot;DE&quot; term=&quot;%22Nanotubes%2C+Carbon%22&quot;&gt;Nanotubes, Carbon*&lt;/searchLink&gt; &lt;br /&gt;&lt;searchLink fieldCode=&quot;DE&quot; term=&quot;%22Water+Pollutants%2C+Chemical%22&quot;&gt;Water Pollutants, Chemical*&lt;/searchLink&gt;&lt;br /&gt;&lt;searchLink fieldCode=&quot;DE&quot; term=&quot;%22Catalysis%22&quot;&gt;Catalysis&lt;/searchLink&gt; ; &lt;searchLink fieldCode=&quot;DE&quot; term=&quot;%22Hydrogen+Peroxide%22&quot;&gt;Hydrogen Peroxide&lt;/searchLink&gt; ; &lt;searchLink fieldCode=&quot;DE&quot; term=&quot;%22Ozone%22&quot;&gt;Ozone&lt;/searchLink&gt;'
      else
        puts "WARNING: skipping test_all_change_subject_fields, cmedm db isn't in the profile."
      end
      session_no_sanitize.end
      session_with_sanitize.end
    end
  end

  def test_author_html_sanitize
    VCR.use_cassette('test_author_html_sanitize') do
     session_with_sanitize = EBSCO::EDS::Session.new({guest: false,
                                                       use_cache: false,
                                                       profile: 'edsapi',
                                                       decode_sanitize_html: true,
                                                       all_subjects_search_links: true})
      if session_with_sanitize.dbid_in_profile 'cmedm'
        record = session_with_sanitize.retrieve({dbid: 'cmedm', an: '27748641'})
        assert record.eds_authors_composed.to_s.include? '<searchLink fieldcode="AU" term="%22Bai+Z%22">Bai Z</searchLink>'
      else
        puts "WARNING: skipping test_author_html_sanitize, cmedm db isn't in the profile."
      end
      session_with_sanitize.end
    end
  end

  def test_sanitize_html_fulltext
    VCR.use_cassette('test_sanitize_html_fulltext') do
    session_with_sanitize = EBSCO::EDS::Session.new({guest: false,
                                                     use_cache: false,
                                                     profile: 'edsapi',
                                                     decode_sanitize_html: true,
                                                     all_subjects_search_links: true})

    if session_with_sanitize.dbid_in_profile 'bah'
      record = session_with_sanitize.retrieve({dbid: 'bah', an: '116897973'})
      #puts 'HTML AFTER: ' + record.eds_html_fulltext.to_s
      assert record.eds_html_fulltext.to_s.include? '<h1 id="AN0116897973-3">YOU\'VE GOT TO BE KITTEN ME! </h1>'
    else
      puts "WARNING: skipping test_sanitize_html_fulltext, bah db isn't in the profile."
    end
    session_with_sanitize.end
    end
  end

end
