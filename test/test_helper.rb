# this must come first!
require 'simplecov'
SimpleCov.start do
  add_filter 'test'
  command_name 'Mintest'
end

require 'minitest/autorun'
require 'ebsco/eds'
require 'dotenv'
require 'active_support'
require 'fileutils'
require 'vcr'
require 'minitest-vcr'

Dotenv.load('.env.test')

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

# clear any previous faraday EDS cache
cache_dir = File.join(ENV['TMPDIR'] || '/tmp', 'faraday_eds_cache')
FileUtils.mkdir_p(cache_dir) unless File.directory?(cache_dir)
cache_store = ActiveSupport::Cache::FileStore.new cache_dir
cache_store.clear

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :faraday
  c.filter_sensitive_data('<EDS_USER>') { ENV['EDS_USER'] }
  c.filter_sensitive_data('<EDS_PASS>') { ENV['EDS_PASS'] }
end

MinitestVcr::Spec.configure!
