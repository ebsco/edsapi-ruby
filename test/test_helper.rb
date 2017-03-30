require 'dotenv'
require 'climate_control'
require 'simplecov'
require 'active_support'

Dotenv.load('.env.test')

SimpleCov.start do
  add_filter 'test'
  command_name 'Mintest'
end

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

# clear any previous faraday EDS cache
cache_dir = File.join(ENV['TMPDIR'] || '/tmp', 'faraday_eds_cache')
cache_store = ActiveSupport::Cache::FileStore.new cache_dir
cache_store.clear

require 'minitest/autorun'
require 'ebsco/eds'