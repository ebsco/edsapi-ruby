module EBSCO
  module EDS
    class Citation

      attr_accessor :format # :nodoc:
      attr_accessor :label # :nodoc:
      attr_accessor :data # :nodoc:

      def initialize(citation_result, eds_config = nil)

        @format = ''
        @label = ''
        @data = ''

        if citation_result.key? 'Format'
          @format = JSON.parse(citation_result['Format'].to_json)
        end

        if citation_result.key? 'Label'
          @label = JSON.parse(citation_result['Label'].to_json)
        end

        if citation_result.key? 'Data'
          @data = JSON.parse(citation_result['Data'].to_json)
        end

      end


    end
  end
end
