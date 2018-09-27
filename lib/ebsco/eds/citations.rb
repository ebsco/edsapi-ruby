require 'ebsco/eds/jsonable'

module EBSCO
  module EDS
    class Citations
      include JSONable

      attr_accessor :eds_database_id, :eds_accession_number, :eds_record_id, :items

      def initialize(dbid:, an:, citation_result:, eds_config: nil)

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
              item['data'] = JSON.parse(style['Data'].to_json)
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
            item['data'] = JSON.parse(citation_result['Data'].to_json)
          end

          if citation_result.key? 'Error'
            item['error'] = JSON.parse(citation_result['Error'].to_json)
          end

          @items.push item

        end

      end

    end
  end
end
