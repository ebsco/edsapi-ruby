require 'yaml'

module EBSCO

  module EDS

    class Configuration

      attr_reader :valid_config_keys

      def initialize
        # Configuration defaults
        @config  = {
            :debug => false,
            :guest => true,
            :org => '',
            :auth => 'user',
            :auth_token => '',
            :session_token => '',
            :api_hosts_list => ['eds-api.ebscohost.com'],
            :uid_auth_url => '/authservice/rest/uidauth',
            :ip_auth_url => '/authservice/rest/ipauth',
            :create_session_url => '/edsapi/rest/CreateSession',
            :end_session_url => '/edsapi/rest/EndSession',
            :info_url => '/edsapi/rest/Info',
            :search_url => '/edsapi/rest/Search',
            :retrieve_url => '/edsapi/rest/Retrieve',
            :citation_exports_url => '/edsapi/rest/ExportFormat',
            :citation_exports_formats => 'all',
            :citation_styles_url => '/edsapi/rest/CitationStyles',
            :citation_styles_formats => 'all',
            :user_agent => 'EBSCO EDS GEM v0.0.1',
            :interface_id => 'edsapi_ruby_gem',
            :log => 'faraday.log',
            :log_level => 'INFO',
            :max_attempts => 3,
            :max_results_per_page => 100,
            :ebook_preferred_format => 'ebook-pdf',
            :use_cache => true,
            :eds_cache_dir => ENV['TMPDIR'] || '/tmp',
            :timeout => 60,
            :open_timeout => 12,
            :max_page_jumps => 6,
            :max_page_jump_attempts => 10,
            :recover_from_bad_source_type => false,
            :all_subjects_search_links => false,
            :decode_sanitize_html => false,
            :titleize_facets => false,
            :citation_link_find => '[.,]\s+(&lt;i&gt;EBSCOhost|viewed|Available|Retrieved from|http:\/\/search.ebscohost.com|Disponível em).+$',
            :citation_link_replace => '.',
            :citation_db_find => '',
            :citation_db_replace => '',
            :ris_link_find => '',
            :ris_link_replace => '',
            :ris_db_find => '',
            :ris_db_replace => ''
        }
        @valid_config_keys = @config.keys
      end

      def configure(opts = {})
        opts.each do |k, v|
          @config[k] = v if @valid_config_keys.include? k
        end
        @config
      end

      def configure_with(file)
        begin
          config = YAML.load_file(file ||= 'eds.yaml').symbolize_keys
        rescue Errno::ENOENT
          #puts 'YAML configuration file couldn\'t be found. Using defaults.'
          return
        rescue Psych::SyntaxError
          #puts 'YAML configuration file contains invalid syntax. Using defaults'
          return
        end
        @config[:file] = file
        configure(config)
      end
    end

  end
end