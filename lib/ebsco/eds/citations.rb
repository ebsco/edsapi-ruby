require 'ebsco/eds/jsonable'
require 'erb'

module EBSCO
  module EDS
    class Citations
      include JSONable

      attr_accessor :eds_database_id, :eds_accession_number, :eds_record_id, :items

      def initialize(dbid:, an:, citation_result:, eds_config: nil)


        (ENV.has_key? 'EDS_DEBUG') ?
            if %w(y Y yes Yes true True).include?(ENV['EDS_DEBUG'])
              @debug = true
            else
              @debug = false
            end :
            @debug = eds_config[:debug]

        # citation link find and replace?
        (ENV.has_key? 'EDS_CITATION_LINK_FIND') ?
            if !ENV['EDS_CITATION_LINK_FIND'].empty?
              @citation_link_find = ENV['EDS_CITATION_LINK_FIND']
            else
              @citation_link_find = ""
            end :
            @citation_link_find = eds_config[:citation_link_find]

        (ENV.has_key? 'EDS_CITATION_LINK_REPLACE') ?
            if !ENV['EDS_CITATION_LINK_REPLACE'].empty?
              @citation_link_replace = ENV['EDS_CITATION_LINK_REPLACE']
            else
              @citation_link_replace = ""
            end :
            @citation_link_replace = eds_config[:citation_link_replace]

        # citation db find and replace?
        (ENV.has_key? 'EDS_CITATION_DB_FIND') ?
            if !ENV['EDS_CITATION_DB_FIND'].empty?
              @citation_db_find = ENV['EDS_CITATION_DB_FIND']
            else
              @citation_db_find = ""
            end :
            @citation_db_find = eds_config[:citation_db_find]

        (ENV.has_key? 'EDS_CITATION_DB_REPLACE') ?
            if !ENV['EDS_CITATION_DB_REPLACE'].empty?
              @citation_db_replace = ENV['EDS_CITATION_DB_REPLACE']
            else
              @citation_db_replace = ""
            end :
            @citation_db_replace = eds_config[:citation_db_replace]


        # citation link find and replace?
        (ENV.has_key? 'EDS_RIS_LINK_FIND') ?
            if !ENV['EDS_RIS_LINK_FIND'].empty?
              @ris_link_find = ENV['EDS_RIS_LINK_FIND']
            else
              @ris_link_find = ""
            end :
            @ris_link_find = eds_config[:ris_link_find]

        (ENV.has_key? 'EDS_RIS_LINK_REPLACE') ?
            if !ENV['EDS_RIS_LINK_REPLACE'].empty?
              @ris_link_replace = ENV['EDS_RIS_LINK_REPLACE']
            else
              @ris_link_replace = ""
            end :
            @ris_link_replace = eds_config[:ris_link_replace]

        # citation db find and replace?
        (ENV.has_key? 'EDS_RIS_DB_FIND') ?
            if !ENV['EDS_RIS_DB_FIND'].empty?
              @ris_db_find = ENV['EDS_RIS_DB_FIND']
            else
              @ris_db_find = ""
            end :
            @ris_db_find = eds_config[:ris_db_find]

        (ENV.has_key? 'EDS_RIS_DB_REPLACE') ?
            if !ENV['EDS_RIS_DB_REPLACE'].empty?
              @ris_db_replace = ENV['EDS_RIS_DB_REPLACE']
            else
              @ris_db_replace = ""
            end :
            @ris_db_replace = eds_config[:ris_db_replace]

        @eds_database_id = dbid
        @eds_accession_number = an
        @eds_record_id = @eds_database_id + '__' + @eds_accession_number

        @items = []

        if citation_result.key? 'Citations'

          # citation styles
          citation_result['Citations'].each do |style|
            item = {}

            if style.key? 'Id'
              item['id'] = JSON.parse(style['Id'].to_json)
            end

            if style.key? 'Label'
              item['label'] = JSON.parse(style['Label'].to_json)
            end

            if style.key? 'Data'
              data = JSON.parse(style['Data'].to_json)

              if data
                # apply citation link find & replace
                unless @citation_link_find.empty?
                  replace_template = ERB.new(@citation_link_replace)
                  find_template = ERB.new(@citation_link_find)
                  replace_link = replace_template.result(binding)
                  find_link_regex = find_template.result(binding)
                  link_regex = Regexp.new find_link_regex
                  data = data.gsub!(link_regex, replace_link) || data
                end

                # apply citation db find & replace
                unless @citation_db_find.empty?
                  replace_template = ERB.new(@citation_db_replace)
                  find_template = ERB.new(@citation_db_find)
                  replace_db = replace_template.result(binding)
                  find_db_regex = find_template.result(binding)
                  link_regex = Regexp.new find_db_regex
                  data = data.gsub!(link_regex, replace_db) || data
                end
              end

              item['data'] = data
            end

            if style.key? 'Caption'
              item['caption'] = JSON.parse(style['Caption'].to_json)
            end

            if style.key? 'SectionLabel'
              item['section_label'] = JSON.parse(style['SectionLabel'].to_json)
            end

            if style.key? 'Error'
              item['error'] = JSON.parse(style['Error'].to_json)
            end

            @items.push item

          end

        else

          # citation exports
          item = {}
          if citation_result.key? 'Format'
            item['id'] = JSON.parse(citation_result['Format'].to_json)
          end

          if citation_result.key? 'Label'
            item['label'] = JSON.parse(citation_result['Label'].to_json)
          end

          if citation_result.key? 'Data'
            data = JSON.parse(citation_result['Data'].to_json)

            if data
              # apply ris link find & replace
              unless @citation_link_find.empty?
                replace_template = ERB.new(@ris_link_replace)
                find_template = ERB.new(@ris_link_find)
                replace_link = replace_template.result(binding)
                find_link_regex = find_template.result(binding)
                link_regex = Regexp.new find_link_regex
                data = data.gsub!(link_regex, replace_link) || data
              end

              # apply ris db find & replace
              unless @ris_db_find.empty?
                replace_template = ERB.new(@ris_db_replace)
                find_template = ERB.new(@ris_db_find)
                replace_db = replace_template.result(binding)
                find_db_regex = find_template.result(binding)
                link_regex = Regexp.new find_db_regex
                data = data.gsub!(link_regex, replace_db) || data
              end
            end

            item['data'] = data
          end

          if citation_result.key? 'Error'
            item['error'] = JSON.parse(citation_result['Error'].to_json)
          end

          @items.push item

        end

      end


      def removeLinksFromStyles(citation)

        # 1. abnt
        #
        # CHITEA, F. Electrical Signatures of Mud Volcanoes Case Studies from Romania. <b>Proceedings of the International Multidisciplinary Scientific GeoConference SGEM</b>, jul. 2016. v. 3, p. 467–474. Disponível em: <http://search.ebscohost.com/login.aspx?direct=true&site=eds-live&db=asn&AN=118411536>. Acesso em: 15 out. 2018.
        #
        # 2. ama
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt;. Germany, Europe: Massachusetts Medical Society; 2016. http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780. Accessed October 12, 2018.
        #
        # 3. apa
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt;. (2016). Germany, Europe: Massachusetts Medical Society. Retrieved from http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780
        #
        # 4. chicago
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt;. 2016. Germany, Europe: Massachusetts Medical Society. http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780.
        #
        # 5. harvard
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt; (2016). Germany, Europe: Massachusetts Medical Society. Available at: http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780 (Accessed: 12 October 2018).
        #
        # 6. harvardaustralian
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt; 2016, Massachusetts Medical Society, Germany, Europe, viewed 12 October 2018, &lt;http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780&gt;.
        #
        # 7. mla
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt;. Massachusetts Medical Society, 2016. &lt;i&gt;EBSCOhost&lt;/i&gt;, search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780.
        #
        # 8. turbanian
        # &lt;i&gt;Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura&lt;/i&gt;. Germany, Europe: Massachusetts Medical Society, 2016. http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780.
        #
        # 9. vancouver
        # Caplacizumab for Acquired Thrombotic Thrombocytopenic Purpura [Internet]. Germany, Europe: Massachusetts Medical Society; 2016 [cited 2018 Oct 12]. Available from: http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780
        #
        #
        #
        #
        if citation
          citation.gsub!(/[.,]\s+(&lt;i&gt;EBSCOhost|viewed|Available|Retrieved from|http:\/\/search.ebscohost.com|Disponível em).+$/, '.')
        end
        citation

      end

      def removeLinksFromExports(citation)

        # 1. RIS
        # UR  - http://search.ebscohost.com/login.aspx?direct=true&amp;site=eds-live&amp;db=edsbas&amp;AN=edsbas.AA261780
        # DP  - EBSCOhost
        #
        if citation
          citation.gsub!(/UR\s+-\s+http:\/\/search\.ebscohost\.com.+\s+/,'')
          citation.gsub!(/DP\s+-\s+EBSCOhost\s+/, '')
        end
        citation
      end

      def applyLinksTemplateToExports(data, dbid, an)
        if data
          renderer = ERB.new(@links_template)
          new_link = renderer.result(binding)
          unless new_link.empty?
            if @debug
              puts 'doing links template...'
              puts 'BEFORE:'
              puts data.inspect
            end
            data.gsub!(/UR\s+--\s+http:\/\/search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=#{dbid}&AN=#{an}/, 'UR  - ' + new_link)
            if @debug
              puts 'AFTER:'
              puts data.inspect
            end
          end
        end
        data
      end

      def applyDbTemplateToExports(data)
        if data
          renderer = ERB.new(@db_template)
          new_db = renderer.result(binding)
          unless new_db.empty?
            if @debug
              puts 'doing db template...'
              puts 'BEFORE:'
              puts data.inspect
            end
            data.gsub!(/DP\s+-\s+EBSCOhost/, 'DP  - ' + new_db)
            if @debug
              puts 'AFTER:'
              puts data.inspect
            end
          end
        end
        data
      end

      def applyLinksTemplateToStyles(data, dbid, an)
        if data
          renderer = ERB.new(@links_template)
          new_link = renderer.result(binding)
          unless new_link.empty?
            if @debug
              puts 'doing links template...'
              puts 'BEFORE:'
              puts data.inspect
            end
            data.gsub!(/(http:\/\/)?search\.ebscohost\.com\/login\.aspx\?direct=true&site=eds-live&db=#{dbid}&AN=#{an}/, new_link)
            if @debug
              puts 'AFTER:'
              puts data.inspect
            end
          end
        end
        data
      end

      def applyDbTemplateToStyles(data)
        if data
          renderer = ERB.new(@db_template)
          new_db = renderer.result(binding)
          unless new_db.empty?
            if @debug
              puts 'doing db template...'
              puts 'BEFORE:'
              puts data.inspect
            end
            data.gsub!(/<i>EBSCOhost<\/i>/, '<i>' + new_db + '</i>')
            if @debug
              puts 'AFTER:'
              puts data.inspect
            end
          end
        end
        data
      end

    end
  end
end
