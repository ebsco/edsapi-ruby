require 'dotenv'
require 'climate_control'
require 'simplecov'

Dotenv.load('.env.test')

SimpleCov.start do
  add_filter 'test'
  command_name 'Mintest'
end

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'minitest/autorun'
require 'ebsco/eds'