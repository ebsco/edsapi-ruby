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
            :eds_api_base => 'https://eds-api.ebscohost.com',
            :uid_auth_url => '/authservice/rest/uidauth',
            :ip_auth_url => '/authservice/rest/ipauth',
            :create_session_url => '/edsapi/rest/CreateSession',
            :end_session_url => '/edsapi/rest/EndSession',
            :info_url => '/edsapi/rest/Info',
            :search_url => '/edsapi/rest/Search',
            :retrieve_url => '/edsapi/rest/Retrieve',
            :user_agent => 'EBSCO EDS GEM v0.0.1',
            :interface_id => 'EBSCO EDS GEM v0.0.1',
            :log => 'faraday.log',
            :max_attempts => 2,
            :max_results_per_page => 100,
            :ebook_preferred_format => 'ebook-pdf',
            :use_cache => true,
            :eds_cache_dir => ENV['TMPDIR'] || '/tmp'
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
          config = YAML.load_file(file ||= 'eds.yaml')
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